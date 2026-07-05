import { Request, Response } from 'express';
import { PrismaClient, WorkOrderStatus, PaymentMethod, ApprovalStatus } from '@prisma/client';
import { createNotificationForAdmins, checkAndWarnLowStock, createNotificationForUser } from './notification.controller';

const prisma = new PrismaClient();

const sendSystemChatMessage = async (customerId: string, text: string) => {
  try {
    let conv = await prisma.chatConversation.findFirst({
      where: { userId: customerId },
    });
    if (!conv) {
      conv = await prisma.chatConversation.create({
        data: { userId: customerId },
      });
    }
    await prisma.chatMessage.create({
      data: {
        conversationId: conv.id,
        role: 'system',
        content: text,
      },
    });
  } catch (error) {
    console.error('Failed to send system chat message:', error);
  }
};

const buildServiceSummary = (services: Array<{ serviceType: string; description?: string | null; serviceName?: string | null }>) => {
  return services
    .map((service) => service.description || service.serviceName || service.serviceType)
    .filter((value): value is string => Boolean(value && value.trim()))
    .join(', ');
};

const formatScheduledTime = (date: Date) => {
  const pad = (value: number) => String(value).padStart(2, '0');
  return date.toISOString();
};

const buildScheduledTime = (estimatedHours?: number | null) => {
  if (typeof estimatedHours !== 'number' || !Number.isFinite(estimatedHours) || estimatedHours <= 0) {
    return undefined;
  }

  const completionTime = new Date(Date.now() + estimatedHours * 60 * 60 * 1000);
  return formatScheduledTime(completionTime);
};

const computeWorkOrderRevenue = (workOrder: {
  partsUsed?: Array<{ quantity: number; unitPrice: number }>;
}) => {
  return (workOrder.partsUsed ?? []).reduce((sum, part) => {
    const quantity = typeof part.quantity === 'number' ? part.quantity : 0;
    const unitPrice = typeof part.unitPrice === 'number' ? part.unitPrice : 0;
    return sum + quantity * unitPrice;
  }, 0);
};

const computeMaintenanceServiceTotal = (workOrder: {
  services?: Array<{ price?: number | null }>;
}) => {
  return (workOrder.services ?? []).reduce((sum, service) => {
    const price = typeof service.price === 'number' && Number.isFinite(service.price)
      ? service.price
      : 0;
    return sum + price;
  }, 0);
};

const computeWorkOrderTotalRevenue = (workOrder: {
  totalPrice?: number | null;
  partsUsed?: Array<{ quantity: number; unitPrice: number }>;
  services?: Array<{ price?: number | null }>;
}) => {
  if (typeof workOrder.totalPrice === 'number' && Number.isFinite(workOrder.totalPrice)) {
    return workOrder.totalPrice;
  }

  return computeWorkOrderRevenue(workOrder) + computeMaintenanceServiceTotal(workOrder);
};

/**
 * Get all work orders
 * GET /api/work-orders
 * Query params: status, technicianId, vehicleId, sortBy
 */
export const getWorkOrders = async (req: Request, res: Response) => {
  try {
    const { status, technicianId, vehicleId, sortBy, search } = req.query;
    const authUser = (req as any).user;

    const where: any = {};
    if (status) where.status = status;
    if (technicianId) where.technicianId = technicianId;
    if (vehicleId) where.vehicleId = vehicleId;

    if (search && (search as string).trim()) {
      const q = (search as string).trim();
      where.OR = [
        { orderNumber: { contains: q, mode: 'insensitive' } },
        { vehicle: { licensePlate: { contains: q, mode: 'insensitive' } } },
        { vehicle: { owner: { name: { contains: q, mode: 'insensitive' } } } },
      ];
    }

    if (authUser?.role === 'CUSTOMER') {
      if (vehicleId) {
        const vehicle = await prisma.vehicle.findUnique({
          where: { id: vehicleId as string },
          select: { ownerId: true },
        });

        if (!vehicle || vehicle.ownerId !== authUser.userId) {
          return res.status(403).json({
            success: false,
            message: 'Access denied',
          });
        }
      } else {
        const vehicles = await prisma.vehicle.findMany({
          where: { ownerId: authUser.userId },
          select: { id: true },
        });
        const vehicleIds = vehicles.map((v) => v.id);

        if (vehicleIds.length === 0) {
          return res.json({
            success: true,
            data: [],
          });
        }

        where.vehicleId = { in: vehicleIds };
      }
    }

    const workOrders = await prisma.workOrder.findMany({
      where,
      include: {
        vehicle: {
          include: {
            owner: {
              select: {
                id: true,
                name: true,
                phoneNumber: true,
              },
            },
          },
        },
        technician: {
          select: {
            id: true,
            name: true,
            phoneNumber: true,
          },
        },
        services: true,
        photos: true,
        partsUsed: {
          include: {
            part: true,
          },
        },
        createdBy: {
          select: {
            id: true,
            name: true,
          },
        },
      },
      orderBy: sortBy === 'paidAt'
        ? { paidAt: 'desc' }
        : { createdAt: 'desc' },
    });

    res.json({
      success: true,
      data: workOrders,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch work orders',
      error: error.message,
    });
  }
};

/**
 * Get work order by ID
 * GET /api/work-orders/:id
 */
export const getWorkOrderById = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const authUser = (req as any).user;

    const workOrder = await prisma.workOrder.findUnique({
      where: { id },
      include: {
        vehicle: {
          include: {
            owner: {
              select: {
                id: true,
                name: true,
                email: true,
                phoneNumber: true,
                loyaltyPoints: true,
                treesPlanted: true,
              },
            },
          },
        },
        technician: {
          select: {
            id: true,
            name: true,
            email: true,
            phoneNumber: true,
          },
        },
        services: true,
        photos: true,
        partsUsed: {
          include: {
            part: true,
          },
        },
        createdBy: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });

    if (!workOrder) {
      return res.status(404).json({
        success: false,
        message: 'Work order not found',
      });
    }

    if (
      authUser?.role === 'CUSTOMER' &&
      workOrder.vehicle?.owner?.id !== authUser.userId
    ) {
      return res.status(403).json({
        success: false,
        message: 'Access denied',
      });
    }

    res.json({
      success: true,
      data: workOrder,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch work order',
      error: error.message,
    });
  }
};

/**
 * Create new work order (Vehicle Intake)
 * POST /api/work-orders
 */
export const createWorkOrder = async (req: Request, res: Response) => {
  try {
    const {
      vehicleId,
      status,
      notes,
      technicianId,
      estimatedHours,
      scheduledTime,
      services, // Array of { serviceType, description }
      photos, // Array of { photoUrl, description }
      partsUsed, // Array of { partId, quantity, unitPrice }
      appointmentId,
    } = req.body;

    // Get user from auth middleware
    const createdById = (req as any).user.userId;

    // Generate order number
    const count = await prisma.workOrder.count();
    const orderNumber = `WO-${new Date().getFullYear()}-${String(count + 1).padStart(3, '0')}`;

    const workOrder = await prisma.$transaction(async (tx) => {
      const normalizedParts = Array.isArray(partsUsed) ? partsUsed : [];

      for (const part of normalizedParts) {
        const partRecord = await tx.inventory.findUnique({
          where: { id: part.partId },
        });

        if (!partRecord) {
          throw new Error(`Part not found: ${part.partId}`);
        }

        if (partRecord.quantity < part.quantity) {
          throw new Error(`Insufficient stock for ${partRecord.partName}`);
        }

        await tx.inventory.update({
          where: { id: part.partId },
          data: {
            quantity: {
              decrement: part.quantity,
            },
          },
        });
      }

      // If currentKm provided in request, update vehicle currentKm if it's greater than existing
      const { currentKm } = req.body as any;
      if (typeof currentKm === 'number') {
        const existing = await tx.vehicle.findUnique({ where: { id: vehicleId }, select: { currentKm: true } });
        if (!existing || existing.currentKm == null || currentKm >= existing.currentKm) {
          await tx.vehicle.update({ where: { id: vehicleId }, data: { currentKm } });
        } else {
          throw new Error(`Provided currentKm (${currentKm}) is less than existing vehicle odometer (${existing.currentKm})`);
        }
      }

      const resolvedScheduledTime = scheduledTime ?? buildScheduledTime(estimatedHours);

      return tx.workOrder.create({
        data: {
          orderNumber,
          vehicleId,
          appointmentId: appointmentId || null,
          status: status || 'PENDING',
          notes,
          technicianId,
          estimatedHours,
          scheduledTime: resolvedScheduledTime,
          createdById,
          services: {
            create: (services || []).map((s: any) => ({
              ...s,
              approvalStatus: 'APPROVED',
            })),
          },
          photos: {
            create: photos || [],
          },
          partsUsed: {
            create: normalizedParts.map((part: any) => ({
              partId: part.partId,
              quantity: part.quantity,
              unitPrice: part.unitPrice,
            })),
          },
        },
        include: {
          vehicle: {
            include: {
              owner: {
                select: {
                  id: true,
                  name: true,
                  phoneNumber: true,
                },
              },
            },
          },
          technician: {
            select: {
              id: true,
              name: true,
            },
          },
          services: true,
          photos: true,
          partsUsed: {
            include: {
              part: true,
            },
          },
        },
      });
    });

    // If linked to an appointment, mark it as COMPLETED
    if (appointmentId) {
      await prisma.appointment.update({
        where: { id: appointmentId },
        data: { status: 'COMPLETED' },
      }).catch(() => {});
    }

    // Check and notify low stock
    if (Array.isArray(partsUsed)) {
      for (const part of partsUsed) {
        if (part && part.partId) {
          await checkAndWarnLowStock(part.partId);
        }
      }
    }

    // Notify the technician of new assignment
    if (workOrder.technicianId) {
      try {
        await createNotificationForUser(
          workOrder.technicianId,
          'Yêu cầu sửa chữa mới',
          `Bạn được phân công phụ trách xe ${workOrder.vehicle.licensePlate} (${workOrder.vehicle.model}).`,
          'WORK_ORDER_ASSIGNED',
          { workOrderId: workOrder.id }
        );
      } catch (e) {
        console.error('Failed to notify assigned technician of new work order:', e);
      }
    }

    // Notify the customer of the new work order
    if (workOrder.vehicle && workOrder.vehicle.owner) {
      try {
        await createNotificationForUser(
          workOrder.vehicle.owner.id,
          'Yêu cầu dịch vụ mới',
          `Phiếu sửa chữa ${workOrder.orderNumber} cho xe ${workOrder.vehicle.licensePlate} (${workOrder.vehicle.model}) đã được khởi tạo thành công.`,
          'CUSTOMER_WORK_ORDER_CREATED',
          { workOrderId: workOrder.id }
        );
      } catch (e) {
        console.error('Failed to notify customer of new work order:', e);
      }
    }

    res.status(201).json({
      success: true,
      message: 'Work order created successfully',
      data: workOrder,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to create work order',
      error: error.message,
    });
  }
};

/**
 * Add parts to work order
 * PATCH /api/work-orders/:id/parts
 */
export const addPartsToWorkOrder = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { partsUsed } = req.body;

    const updated = await prisma.$transaction(async (tx) => {
      const normalizedParts = Array.isArray(partsUsed) ? partsUsed : [];

      for (const part of normalizedParts) {
        const partRecord = await tx.inventory.findUnique({
          where: { id: part.partId },
        });

        if (!partRecord) {
          throw new Error(`Part not found: ${part.partId}`);
        }

        if (partRecord.quantity < part.quantity) {
          throw new Error(`Insufficient stock for ${partRecord.partName}`);
        }

        await tx.inventory.update({
          where: { id: part.partId },
          data: {
            quantity: {
              decrement: part.quantity,
            },
          },
        });
      }

      return tx.workOrder.update({
        where: { id },
        data: {
          partsUsed: {
            create: normalizedParts.map((part: any) => ({
              partId: part.partId,
              quantity: part.quantity,
              unitPrice: part.unitPrice,
            })),
          },
        },
        include: {
          vehicle: {
            include: {
              owner: {
                select: {
                  id: true,
                  name: true,
                  phoneNumber: true,
                },
              },
            },
          },
          technician: {
            select: {
              id: true,
              name: true,
            },
          },
          services: true,
          photos: true,
          partsUsed: {
            include: {
              part: true,
            },
          },
        },
      });
    });

    // Check and notify low stock
    const normalizedParts = Array.isArray(partsUsed) ? partsUsed : [];
    for (const part of normalizedParts) {
      if (part && part.partId) {
        await checkAndWarnLowStock(part.partId);
      }
    }

    res.json({
      success: true,
      message: 'Parts added to work order successfully',
      data: updated,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to add parts to work order',
      error: error.message,
    });
  }
};

/**
 * Update single work order service status
 * PATCH /api/work-orders/:id/services/:serviceId
 */
export const updateWorkOrderServiceStatus = async (req: Request, res: Response) => {
  try {
    const { id, serviceId } = req.params;
    const { isDone } = req.body;

    const existingService = await prisma.workOrderService.findUnique({
      where: { id: serviceId },
      select: { id: true, workOrderId: true },
    });

    if (!existingService) {
      return res.status(404).json({
        success: false,
        message: 'Service not found',
      });
    }

    if (existingService.workOrderId !== id) {
      return res.status(400).json({
        success: false,
        message: 'Service does not belong to this work order',
      });
    }

    const service = await prisma.workOrderService.update({
      where: { id: serviceId },
      data: {
        isDone: Boolean(isDone),
      },
    });

    res.json({
      success: true,
      message: 'Work order service updated successfully',
      data: service,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to update work order service',
      error: error.message,
    });
  }
};

/**
 * Update work order status
 * PATCH /api/work-orders/:id/status
 */
export const updateWorkOrderStatus = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    let normalizedStatus = typeof status === 'string'
      ? status.toUpperCase()
      : status;

    if (normalizedStatus === 'WAITING_PARTS') {
      normalizedStatus = 'INSPECTION';
    }
    if (normalizedStatus === 'INPROGRESS') {
      normalizedStatus = 'IN_PROGRESS';
    }

    const updateData: any = { status: normalizedStatus };
    
    // If status is COMPLETED, set completedAt
    if (normalizedStatus === 'COMPLETED') {
      updateData.completedAt = new Date();
    }

    // If status is PAID, set paidAt
    if (normalizedStatus === 'PAID') {
      updateData.paidAt = new Date();
    }

    const workOrder = await prisma.$transaction(async (tx) => {
      const updatedWorkOrder = await tx.workOrder.update({
        where: { id },
        data: updateData,
        include: {
          vehicle: {
            select: {
              id: true,
              currentKm: true,
            },
          },
          technician: {
            select: {
              id: true,
              name: true,
            },
          },
          services: true,
           partsUsed: {
            select: {
              id: true,
              quantity: true,
              unitPrice: true,
              partId: true,
              part: {
                select: {
                  partName: true,
                  warrantyDays: true,
                },
              },
            },
          },
        },
      });

      if (updatedWorkOrder.status === 'COMPLETED') {
        const totalPrice = computeWorkOrderRevenue(updatedWorkOrder) + computeMaintenanceServiceTotal(updatedWorkOrder);

        const savedWorkOrder = await tx.workOrder.update({
          where: { id },
          data: {
            totalPrice,
          },
          include: {
            vehicle: {
              select: {
                id: true,
                currentKm: true,
              },
            },
            technician: {
              select: {
                id: true,
                name: true,
              },
            },
            services: true,
            partsUsed: {
              select: {
                id: true,
                quantity: true,
                unitPrice: true,
                partId: true,
                part: {
                  select: {
                    partName: true,
                    warrantyDays: true,
                  },
                },
              },
            },
          },
        });

        const serviceSummary = buildServiceSummary(savedWorkOrder.services);
        const serviceType = savedWorkOrder.services[0]?.serviceType ?? null;

        await tx.maintenanceLog.upsert({
          where: { workOrderId: id },
          update: {
            vehicleId: savedWorkOrder.vehicleId,
            odometerKm: savedWorkOrder.vehicle?.currentKm ?? 0,
            serviceType,
            serviceSummary,
            notes: savedWorkOrder.notes,
            performedAt: savedWorkOrder.completedAt ?? new Date(),
          },
          create: {
            vehicleId: savedWorkOrder.vehicleId,
            workOrderId: id,
            odometerKm: savedWorkOrder.vehicle?.currentKm ?? 0,
            serviceType,
            serviceSummary,
            notes: savedWorkOrder.notes,
            performedAt: savedWorkOrder.completedAt ?? new Date(),
          },
        });

        // Create PartWarranty records for parts with warranty
        const completedAt = savedWorkOrder.completedAt ?? new Date();
        for (const pu of savedWorkOrder.partsUsed) {
          if (pu.part.warrantyDays > 0) {
            const expiryDate = new Date(completedAt.getTime() + pu.part.warrantyDays * 24 * 60 * 60 * 1000);
            await tx.partWarranty.upsert({
              where: { partUsedId: pu.id },
              update: {
                expiryDate,
              },
              create: {
                partUsedId: pu.id,
                partId: pu.partId,
                workOrderId: id,
                vehicleId: savedWorkOrder.vehicleId,
                warrantyDays: pu.part.warrantyDays,
                startDate: completedAt,
                expiryDate,
              },
            });
          }
        }

        // Update vehicle warranty expiry to the latest expiry among all part warranties
        const maxExpiryResult = await tx.partWarranty.aggregate({
          where: { vehicleId: savedWorkOrder.vehicleId },
          _max: { expiryDate: true },
        });
        if (maxExpiryResult._max.expiryDate) {
          await tx.vehicle.update({
            where: { id: savedWorkOrder.vehicleId },
            data: { warrantyExpiry: maxExpiryResult._max.expiryDate },
          });
        }

        // Loyalty: 1 tree per order + 1 per 500k, points = floor(totalPrice / 20000)
        const pointsToAward = Math.floor((savedWorkOrder.totalPrice ?? totalPrice) / 20000);
        const extraTrees = Math.floor((savedWorkOrder.totalPrice ?? totalPrice) / 500000);
        if (pointsToAward > 0) {
          const orderVehicle = await tx.vehicle.findUnique({
            where: { id: savedWorkOrder.vehicleId },
            select: { ownerId: true },
          });
          if (orderVehicle) {
            await tx.user.update({
              where: { id: orderVehicle.ownerId },
              data: {
                loyaltyPoints: { increment: pointsToAward },
                treesPlanted: { increment: 1 + extraTrees },
              },
            });
          }
        }

        return savedWorkOrder;
      }

      return updatedWorkOrder;
    });

    // Send system chat message on session start / end and trigger customer notifications
    try {
      if (workOrder.vehicleId) {
        const vehicle = await prisma.vehicle.findUnique({
          where: { id: workOrder.vehicleId },
          select: { ownerId: true, licensePlate: true, model: true },
        });
        if (vehicle?.ownerId) {
          if (normalizedStatus === 'IN_PROGRESS') {
            const techName = workOrder.technician?.name || 'Kỹ thuật viên';
            await sendSystemChatMessage(
              vehicle.ownerId,
              `Hệ thống: Kênh chat trực tiếp với KTV ${techName} đã được thiết lập. KTV đang tiến hành kiểm tra xe của bạn.`
            );

            // Notify customer of IN_PROGRESS
            await createNotificationForUser(
              vehicle.ownerId,
              'Bắt đầu sửa chữa',
              `Xe ${vehicle.licensePlate || ''} của bạn đang được tiến hành sửa chữa bởi KTV.`,
              'CUSTOMER_WORK_ORDER_IN_PROGRESS',
              { workOrderId: workOrder.id }
            );

          } else if (normalizedStatus === 'COMPLETED') {
            await sendSystemChatMessage(
              vehicle.ownerId,
              'Hệ thống: Phiếu sửa chữa đã hoàn thành. Kênh chat trực tiếp vẫn mở cho đến khi quý khách thanh toán.'
            );

            const formattedPrice = new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(workOrder.totalPrice || 0);
            await createNotificationForUser(
              vehicle.ownerId,
              'Sửa chữa hoàn tất',
              `Xe ${vehicle.licensePlate || ''} đã hoàn thành sửa chữa. Tổng chi phí: ${formattedPrice}. Vui lòng kiểm tra và thanh toán.`,
              'CUSTOMER_WORK_ORDER_COMPLETED',
              { workOrderId: workOrder.id }
            );
          } else if (normalizedStatus === 'PAID') {
            await sendSystemChatMessage(
              vehicle.ownerId,
              'Hệ thống: Phiếu sửa chữa đã được thanh toán. Phiếu chat trực tiếp đã đóng. Cảm ơn quý khách!'
            );

            await createNotificationForUser(
              vehicle.ownerId,
              'Thanh toán thành công',
              `Cảm ơn quý khách đã thanh toán phiếu sửa chữa ${workOrder.orderNumber} cho xe ${vehicle.licensePlate || ''}.`,
              'CUSTOMER_WORK_ORDER_PAID',
              { workOrderId: workOrder.id }
            );
          }
        }
      }
    } catch (err) {
      console.error('System chat and notification error:', err);
    }

    res.json({
      success: true,
      message: 'Work order status updated successfully',
      data: workOrder,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to update work order status',
      error: error.message,
    });
  }
};

/**
 * Assign technician to work order
 * PATCH /api/work-orders/:id/assign
 */
export const assignTechnician = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { technicianId } = req.body;

    const workOrder = await prisma.workOrder.update({
      where: { id },
      data: { technicianId },
      include: {
          vehicle: {
            include: {
            },
          },
        technician: {
          select: {
            id: true,
            name: true,
          },
        },
        services: true,
      },
    });

    // Notify the technician
    if (technicianId) {
      try {
        await createNotificationForUser(
          technicianId,
          'Yêu cầu sửa chữa mới',
          `Bạn được phân công phụ trách xe ${workOrder.vehicle.licensePlate} (${workOrder.vehicle.model}).`,
          'WORK_ORDER_ASSIGNED',
          { workOrderId: workOrder.id }
        );
      } catch (e) {
        console.error('Failed to notify assigned technician:', e);
      }
    }

    res.json({
      success: true,
      message: 'Technician assigned successfully',
      data: workOrder,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to assign technician',
      error: error.message,
    });
  }
};

export const addWorkOrderService = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { serviceType, description, price, serviceName } = req.body;

    const service = await prisma.workOrderService.create({
      data: {
        workOrderId: id,
        serviceType,
        description,
        price,
        serviceName,
        approvalStatus: 'PENDING',
      },
    });

    // Notify admins and customer about the service approval request
    try {
      const wo = await prisma.workOrder.findUnique({
        where: { id },
        select: {
          orderNumber: true,
          vehicle: {
            select: { ownerId: true }
          }
        },
      });
      const orderNumber = wo?.orderNumber || 'N/A';
      const mapServiceTypeLabel = (type: string) => {
        switch (type) {
          case 'MAINTENANCE': return 'Bảo dưỡng định kỳ';
          case 'BATTERY_CHECK': return 'Kiểm tra pin/sạc';
          case 'BRAKES_TIRES': return 'Phanh & Lốp';
          case 'OTHER_REPAIR': return 'Sửa chữa khác';
          default: return type;
        }
      };
      const sName = serviceName || mapServiceTypeLabel(serviceType);

      if (wo?.vehicle?.ownerId) {
        await createNotificationForUser(
          wo.vehicle.ownerId,
          'Đề xuất dịch vụ mới cần duyệt 🛠️',
          `Kỹ thuật viên đề xuất thêm dịch vụ "${sName}" cho xe của bạn trong phiếu ${orderNumber}. Vui lòng duyệt để tiếp tục sửa chữa.`,
          'SERVICE_APPROVAL',
          { workOrderId: id, serviceId: service.id }
        );
      }
    } catch (e) {
      console.error('Failed to notify admin/customer of service request:', e);
    }

    res.status(201).json({
      success: true,
      message: 'Service added successfully',
      data: service,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to add service',
      error: error.message,
    });
  }
};

/**
 * Approve or reject a pending service
 * PATCH /api/work-orders/:id/services/:serviceId/approval
 */
export const approveWorkOrderService = async (req: Request, res: Response) => {
  try {
    const authUser = (req as any).user;
    const { id, serviceId } = req.params;
    const { approvalStatus } = req.body;

    if (!approvalStatus || !['APPROVED', 'REJECTED'].includes(approvalStatus)) {
      return res.status(400).json({
        success: false,
        message: 'approvalStatus must be APPROVED or REJECTED',
      });
    }

    const existingService = await prisma.workOrderService.findUnique({
      where: { id: serviceId },
    });

    if (!existingService) {
      return res.status(404).json({
        success: false,
        message: 'Service not found',
      });
    }

    if (existingService.workOrderId !== id) {
      return res.status(400).json({
        success: false,
        message: 'Service does not belong to this work order',
      });
    }

    if (existingService.approvalStatus !== 'PENDING') {
      if (existingService.approvalStatus === approvalStatus) {
        return res.json({
          success: true,
          message: `Service already ${approvalStatus.toLowerCase()}`,
          data: existingService,
        });
      }

      return res.status(400).json({
        success: false,
        message: `Service already ${existingService.approvalStatus.toLowerCase()}`,
      });
    }

    const service = await prisma.workOrderService.update({
      where: { id: serviceId },
      data: { approvalStatus: approvalStatus as ApprovalStatus },
    });

    // Notify the technician of service approval/rejection status
    try {
      const wo = await prisma.workOrder.findUnique({
        where: { id },
        select: { technicianId: true, orderNumber: true },
      });
      if (wo?.technicianId) {
        const statusLabel = approvalStatus === 'APPROVED' ? 'được phê duyệt' : 'bị từ chối';
        const serviceLabel = existingService.serviceName || existingService.serviceType;
        const approverLabel = authUser?.role === 'CUSTOMER'
          ? 'khách hàng'
          : authUser?.role === 'TECHNICIAN'
            ? 'kỹ thuật viên'
            : 'Staff';
        await createNotificationForUser(
          wo.technicianId,
          `Dịch vụ đã ${statusLabel}`,
          `Dịch vụ "${serviceLabel}" trong phiếu ${wo.orderNumber} đã ${statusLabel} bởi ${approverLabel}.`,
          'SERVICE_APPROVAL',
          { workOrderId: id, serviceId: service.id }
        );
      }
    } catch (e) {
      console.error('Failed to notify technician of service approval:', e);
    }

    res.json({
      success: true,
      message: `Service ${approvalStatus.toLowerCase()} successfully`,
      data: service,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to update service approval',
      error: error.message,
    });
  }
};

/**
 * Update work order
 * PUT /api/work-orders/:id
 */
export const updateWorkOrder = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { notes, estimatedHours, scheduledTime } = req.body;
    const resolvedScheduledTime = scheduledTime ?? buildScheduledTime(estimatedHours);

    const workOrder = await prisma.workOrder.update({
      where: { id },
      data: {
        notes,
        estimatedHours,
        scheduledTime: resolvedScheduledTime,
      },
      include: {
          vehicle: {
            include: {
            },
          },
        technician: {
          select: {
            id: true,
            name: true,
          },
        },
        services: true,
        photos: true,
      },
    });

    res.json({
      success: true,
      message: 'Work order updated successfully',
      data: workOrder,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to update work order',
      error: error.message,
    });
  }
};

/**
 * Update the price of a service or a part used in a work order
 * PATCH /api/work-orders/:id/items/price
 */
/**
 * Add a photo to a work order
 * POST /api/work-orders/:id/photos
 */
export const addPhotoToWorkOrder = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { photoUrl, photoType, description } = req.body;

    if (!photoUrl) {
      return res.status(400).json({
        success: false,
        message: 'photoUrl is required',
      });
    }

    const photo = await prisma.workOrderPhoto.create({
      data: {
        workOrderId: id,
        photoUrl,
        photoType: photoType || 'AFTER_REPAIR',
        description: description || null,
      },
    });

    res.status(201).json({
      success: true,
      message: 'Photo added successfully',
      data: photo,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to add photo',
      error: error.message,
    });
  }
};

export const updateItemPrice = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { itemType, itemId, price } = req.body;

    if (!itemType || !itemId || typeof price !== 'number') {
      return res.status(400).json({
        success: false,
        message: 'Missing or invalid parameters: itemType, itemId, price are required.',
      });
    }

    if (itemType !== 'SERVICE' && itemType !== 'PART') {
      return res.status(400).json({
        success: false,
        message: 'itemType must be either SERVICE or PART',
      });
    }

    const updated = await prisma.$transaction(async (tx) => {
      if (itemType === 'SERVICE') {
        const service = await tx.workOrderService.findUnique({
          where: { id: itemId },
        });
        if (!service || service.workOrderId !== id) {
          throw new Error('Service not found or does not belong to this work order');
        }
        await tx.workOrderService.update({
          where: { id: itemId },
          data: { price },
        });
      } else {
        const partUsed = await tx.partsUsed.findUnique({
          where: { id: itemId },
        });
        if (!partUsed || partUsed.workOrderId !== id) {
          throw new Error('Part used not found or does not belong to this work order');
        }
        await tx.partsUsed.update({
          where: { id: itemId },
          data: { unitPrice: price },
        });
      }

      // Fetch the updated work order to recalculate total if necessary
      const wo = await tx.workOrder.findUnique({
        where: { id },
        include: {
          services: true,
          partsUsed: true,
        },
      });

      if (!wo) {
        throw new Error('Work order not found');
      }

      // Recalculate totalPrice if it is already set (completed/paid) or status is COMPLETED/PAID
      if (wo.totalPrice !== null || wo.status === 'COMPLETED' || wo.status === 'PAID') {
        const serviceTotal = (wo.services ?? []).reduce((sum, s) => sum + (s.price ?? 0), 0);
        const partsTotal = (wo.partsUsed ?? []).reduce((sum, p) => sum + (p.quantity * p.unitPrice), 0);
        const newTotal = serviceTotal + partsTotal;

        await tx.workOrder.update({
          where: { id },
          data: { totalPrice: newTotal },
        });
      }

      // Return full updated work order
      return tx.workOrder.findUnique({
        where: { id },
        include: {
          vehicle: {
            include: {
              owner: {
                select: {
                  id: true,
                  name: true,
                  email: true,
                  phoneNumber: true,
                  loyaltyPoints: true,
                  treesPlanted: true,
                },
              },
            },
          },
          technician: {
            select: {
              id: true,
              name: true,
              email: true,
              phoneNumber: true,
            },
          },
          services: true,
          photos: true,
          partsUsed: {
            include: {
              part: true,
            },
          },
          createdBy: {
            select: {
              id: true,
              name: true,
            },
          },
        },
      });
    });

    res.json({
      success: true,
      message: 'Item price updated successfully',
      data: updated,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to update item price',
    });
  }
};

/**
 * Delete work order
 * DELETE /api/work-orders/:id
 */
export const deleteWorkOrder = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    await prisma.workOrder.delete({
      where: { id },
    });

    res.json({
      success: true,
      message: 'Work order deleted successfully',
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to delete work order',
      error: error.message,
    });
  }
};

/**
 * Get dashboard stats
 * GET /api/work-orders/stats/dashboard
 */
export const getDashboardStats = async (req: Request, res: Response) => {
  try {
    const now = new Date();
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const startOfTomorrow = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
    const sevenDaysAgo = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 6);

    const paidRevenueOrders = await prisma.workOrder.findMany({
      where: {
        status: 'PAID',
        paidAt: {
          gte: sevenDaysAgo,
          lt: startOfTomorrow,
        },
      },
      select: {
        totalPrice: true,
        paidAt: true,
        partsUsed: {
          select: {
            quantity: true,
            unitPrice: true,
          },
        },
        services: {
          select: {
            price: true,
          },
        },
      },
    });

    const paidTodayRevenue = paidRevenueOrders
      .filter((workOrder) => (workOrder.paidAt ?? new Date(0)) >= startOfToday)
      .reduce((sum, workOrder) => sum + computeWorkOrderTotalRevenue(workOrder), 0);

    const weeklyRevenue = Array.from({ length: 7 }, (_, index) => {
      const currentDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - (6 - index));
      const dayStart = new Date(currentDate.getFullYear(), currentDate.getMonth(), currentDate.getDate());
      const dayEnd = new Date(currentDate.getFullYear(), currentDate.getMonth(), currentDate.getDate() + 1);

      return paidRevenueOrders
        .filter((workOrder) => {
          const paidAt = workOrder.paidAt;
          return paidAt != null && paidAt >= dayStart && paidAt < dayEnd;
        })
        .reduce((sum, workOrder) => sum + computeWorkOrderTotalRevenue(workOrder), 0);
    });

    const totalWorkOrders = await prisma.workOrder.count();
    const pendingWorkOrders = await prisma.workOrder.count({
      where: { status: 'PENDING' },
    });
    const inProgressWorkOrders = await prisma.workOrder.count({
      where: { status: 'IN_PROGRESS' },
    });
    const completedWorkOrders = await prisma.workOrder.count({
      where: { status: 'COMPLETED' },
    });
    const completedToday = await prisma.workOrder.count({
      where: {
        status: 'PAID',
        paidAt: {
          gte: startOfToday,
          lt: startOfTomorrow,
        },
      },
    });
    const totalVehicles = await prisma.vehicle.count();
    const totalCustomers = await prisma.user.count({
      where: { role: 'CUSTOMER' },
    });
    const totalTechnicians = await prisma.user.count({
      where: { role: 'TECHNICIAN' },
    });

    // --- System Alerts ---

    // 1. Low stock inventory
    const allInventory = await prisma.inventory.findMany({
      select: { id: true, partName: true, quantity: true, minThreshold: true },
    });
    const lowStockAlerts = allInventory
      .filter((item) => item.quantity <= item.minThreshold)
      .map((item) => ({
        id: `low-stock-${item.id}`,
        title: 'Phụ tùng sắp hết',
        description: `${item.partName} (Còn ${item.quantity})`,
        type: 'lowStock',
        createdAt: now.toISOString(),
      }));

    // 2. Overdue vehicles (IN_PROGRESS > 48h)
    const twoDaysAgo = new Date(now.getTime() - 48 * 60 * 60 * 1000);
    const overdueOrders = await prisma.workOrder.findMany({
      where: {
        status: 'IN_PROGRESS',
        createdAt: { lte: twoDaysAgo },
      },
      select: {
        id: true,
        createdAt: true,
        vehicle: { select: { licensePlate: true } },
      },
    });
    const overdueAlerts = overdueOrders.map((order) => {
      const hoursOverdue = Math.floor((now.getTime() - order.createdAt.getTime()) / (1000 * 60 * 60));
      return {
        id: `delayed-${order.id}`,
        title: 'Xe trễ hẹn',
        description: `Biển số: ${order.vehicle.licensePlate} (Trễ ${hoursOverdue}h)`,
        type: 'delayedVehicle',
        createdAt: order.createdAt.toISOString(),
      };
    });

    // 3. Expiring warranties (within next 7 days)
    const weekFromNow = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
    const expiringWarranties = await prisma.warranty.findMany({
      where: {
        expiryDate: { gte: now, lte: weekFromNow },
      },
      select: {
        id: true,
        expiryDate: true,
        vehicle: { select: { licensePlate: true } },
      },
    });
    const warrantyAlerts = expiringWarranties.map((w) => {
      const daysLeft = Math.ceil((w.expiryDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
      return {
        id: `warranty-${w.id}`,
        title: 'Bảo hành sắp hết hạn',
        description: `Xe ${w.vehicle.licensePlate} (Còn ${daysLeft} ngày)`,
        type: 'warrantyExpiring',
        createdAt: now.toISOString(),
      };
    });

    // 4. Expiring part warranties (within next 7 days)
    const expiringPartWarranties = await prisma.partWarranty.findMany({
      where: {
        expiryDate: { gte: now, lte: weekFromNow },
      },
      select: {
        id: true,
        expiryDate: true,
        part: { select: { partName: true } },
        vehicle: { select: { licensePlate: true } },
      },
    });
    const partWarrantyAlerts = expiringPartWarranties.map((pw) => {
      const daysLeft = Math.ceil((pw.expiryDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
      return {
        id: `part-warranty-${pw.id}`,
        title: 'Bảo hành linh kiện sắp hết',
        description: `${pw.part.partName} - Xe ${pw.vehicle.licensePlate} (Còn ${daysLeft} ngày)`,
        type: 'partWarrantyExpiring',
        createdAt: now.toISOString(),
      };
    });

    const alerts = [...lowStockAlerts, ...overdueAlerts, ...warrantyAlerts, ...partWarrantyAlerts];

    res.json({
      success: true,
      data: {
        totalWorkOrders,
        pendingWorkOrders,
        inProgressWorkOrders,
        completedWorkOrders,
        completedToday,
        revenueToday: paidTodayRevenue,
        weeklyRevenue,
        totalVehicles,
        totalCustomers,
        totalTechnicians,
        alerts,
      },
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch dashboard stats',
      error: error.message,
    });
  }
};

/**
 * Get revenue report
 * GET /api/work-orders/stats/revenue-report?start=ISO&end=ISO
 */
export const getRevenueReport = async (req: Request, res: Response) => {
  try {
    const { start, end } = req.query;

    if (!start || !end) {
      return res.status(400).json({
        success: false,
        message: 'Missing start or end query params',
      });
    }

    const startDate = new Date(start as string);
    const endDate = new Date(end as string);

    if (Number.isNaN(startDate.getTime()) || Number.isNaN(endDate.getTime())) {
      return res.status(400).json({
        success: false,
        message: 'Invalid start or end date',
      });
    }

    const rangeStart = new Date(startDate.getFullYear(), startDate.getMonth(), startDate.getDate());
    const rangeEndExclusive = new Date(endDate.getFullYear(), endDate.getMonth(), endDate.getDate() + 1);
    const msPerDay = 24 * 60 * 60 * 1000;
    const rangeDays = Math.max(1, Math.ceil((rangeEndExclusive.getTime() - rangeStart.getTime()) / msPerDay));

    const previousRangeEnd = new Date(rangeStart);
    // For full calendar month ranges, compare with the previous calendar month
    // (e.g., May 1-31 vs April 1-30). For custom/short ranges, use same-length
    // period immediately before (e.g., 7-day window vs the 7 days before).
    let previousRangeStart: Date;
    if (rangeDays >= 28 && rangeDays <= 31 && rangeStart.getDate() === 1) {
      // Full calendar month → compare with previous calendar month
      previousRangeStart = new Date(rangeStart.getFullYear(), rangeStart.getMonth() - 1, 1);
    } else {
      // Custom range → same-length previous period
      previousRangeStart = new Date(rangeStart.getTime() - rangeDays * msPerDay);
    }

    const workOrders = await prisma.workOrder.findMany({
      where: {
        status: WorkOrderStatus.PAID,
        paidAt: {
          gte: previousRangeStart,
          lt: rangeEndExclusive,
        },
      },
      select: {
        id: true,
        totalPrice: true,
        paidAt: true,
        partsUsed: {
          select: {
            quantity: true,
            unitPrice: true,
          },
        },
        services: {
          select: {
            price: true,
            description: true,
            serviceName: true,
            serviceType: true,
          },
        },
        technician: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });

    const isInRange = (date: Date | null, startBound: Date, endBound: Date) => {
      if (!date) return false;
      return date >= startBound && date < endBound;
    };

    const currentOrders = workOrders.filter((order) => isInRange(order.paidAt, rangeStart, rangeEndExclusive));
    const previousOrders = workOrders.filter((order) => isInRange(order.paidAt, previousRangeStart, rangeStart));

    const totalRevenue = currentOrders.reduce((sum, order) => sum + computeWorkOrderTotalRevenue(order), 0);
    const previousTotalRevenue = previousOrders.reduce((sum, order) => sum + computeWorkOrderTotalRevenue(order), 0);

    const growthPercent = previousTotalRevenue > 0
      ? ((totalRevenue - previousTotalRevenue) / previousTotalRevenue) * 100
      : totalRevenue > 0
        ? 100
        : 0;

    const dailyRevenue = Array.from({ length: rangeDays }, (_, index) => {
      const dayStart = new Date(rangeStart.getTime() + index * msPerDay);
      const dayEnd = new Date(dayStart.getTime() + msPerDay);
      const dayOrders = currentOrders.filter((order) => isInRange(order.paidAt, dayStart, dayEnd));
      const revenue = dayOrders.reduce((sum, order) => sum + computeWorkOrderTotalRevenue(order), 0);
      return {
        // Use local date to avoid timezone offset (toISOString returns UTC)
        date: `${dayStart.getFullYear()}-${String(dayStart.getMonth() + 1).padStart(2, '0')}-${String(dayStart.getDate()).padStart(2, '0')}`,
        revenue,
        orders: dayOrders.length,
      };
    });

    const serviceTotals = new Map<string, number>();
    currentOrders.forEach((order) => {
      (order.services ?? []).forEach((service) => {
        const label = service.serviceName || service.description || service.serviceType || 'Khác';
        const price = typeof service.price === 'number' && Number.isFinite(service.price)
          ? service.price
          : 0;
        serviceTotals.set(label, (serviceTotals.get(label) ?? 0) + price);
      });
    });

    const topServices = Array.from(serviceTotals.entries())
      .map(([name, revenue]) => ({
        name,
        revenue,
        percent: totalRevenue > 0 ? (revenue / totalRevenue) * 100 : 0,
      }))
      .sort((a, b) => b.revenue - a.revenue)
      .slice(0, 6);

    const technicianTotals = new Map<string, { id: string; name: string; revenue: number; orders: number }>();
    currentOrders.forEach((order) => {
      if (!order.technician) return;
      const key = order.technician.id;
      const existing = technicianTotals.get(key) ?? {
        id: order.technician.id,
        name: order.technician.name,
        revenue: 0,
        orders: 0,
      };
      existing.revenue += computeWorkOrderTotalRevenue(order);
      existing.orders += 1;
      technicianTotals.set(key, existing);
    });

    // Also count active (non-COMPLETED) orders per technician
    const activeStatuses: WorkOrderStatus[] = [
      WorkOrderStatus.PENDING,
      WorkOrderStatus.IN_PROGRESS,
      WorkOrderStatus.INSPECTION,
    ];

    const activeOrders = await prisma.workOrder.findMany({
      where: {
        status: { in: activeStatuses },
        technicianId: { not: null },
      },
      select: {
        technicianId: true,
      },
    });

    const activeCounts = new Map<string, number>();
    activeOrders.forEach((o) => {
      const tid = o.technicianId;
      if (!tid) return;
      activeCounts.set(tid, (activeCounts.get(tid) ?? 0) + 1);
    });

    const technicians = Array.from(technicianTotals.values())
      .map((t) => ({ ...t, activeOrders: activeCounts.get(t.id) ?? 0 }))
      .sort((a, b) => b.revenue - a.revenue);

    res.json({
      success: true,
      data: {
        rangeStart: rangeStart.toISOString(),
        rangeEnd: endDate.toISOString(),
        totalRevenue,
        previousTotalRevenue,
        growthPercent,
        totalOrders: currentOrders.length,
        dailyRevenue,
        topServices,
        technicians,
      },
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch revenue report',
      error: error.message,
    });
  }
};

/**
 * Search invoices (completed & paid work orders)
 * GET /api/work-orders/invoices?search=...&status=...&from=...&to=...
 */
export const getInvoices = async (req: Request, res: Response) => {
  try {
    const { search, status, from, to } = req.query;

    const where: any = {};

    if (status) {
      where.status = status as string;
    } else {
      where.status = { in: ['COMPLETED', 'PAID'] };
    }

    if (from || to) {
      where.completedAt = {};
      if (from) where.completedAt.gte = new Date(from as string);
      if (to) where.completedAt.lte = new Date(to as string);
    }

    if (search && (search as string).trim()) {
      const q = (search as string).trim();
      where.OR = [
        { orderNumber: { contains: q, mode: 'insensitive' } },
        { vehicle: { licensePlate: { contains: q, mode: 'insensitive' } } },
        { vehicle: { owner: { name: { contains: q, mode: 'insensitive' } } } },
        { vehicle: { owner: { phoneNumber: { contains: q, mode: 'insensitive' } } } },
      ];
    }

    const workOrders = await prisma.workOrder.findMany({
      where,
      include: {
        vehicle: {
          include: {
            owner: {
              select: { id: true, name: true, phoneNumber: true, email: true },
            },
          },
        },
        technician: {
          select: { id: true, name: true },
        },
        services: true,
        partsUsed: {
          include: { part: { select: { partName: true, imageUrl: true } } },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json({ success: true, data: workOrders });
  } catch (error: any) {
    console.error('getInvoices error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch invoices',
      error: error.message,
    });
  }
};

/**
 * Record payment for a work order
 * PATCH /api/work-orders/:id/payment
 * Body: { paymentMethod: "CASH" | "CARD" | "TRANSFER", totalPrice?: number }
 */
export const recordPayment = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { paymentMethod, totalPrice } = req.body;

    if (!paymentMethod || !['CASH', 'CARD', 'TRANSFER'].includes(paymentMethod)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid payment method. Must be CASH, CARD, or TRANSFER',
      });
    }

    const updateData: any = {
      paymentMethod: paymentMethod as PaymentMethod,
      paidAt: new Date(),
      status: 'PAID',
      completedAt: new Date(),
    };

    if (typeof totalPrice === 'number' && Number.isFinite(totalPrice)) {
      updateData.totalPrice = totalPrice;
    }

    const workOrder = await prisma.workOrder.update({
      where: { id },
      data: updateData,
      include: {
        vehicle: {
          include: {
            owner: {
              select: { id: true, name: true, phoneNumber: true },
            },
          },
        },
        services: true,
        partsUsed: {
          include: { part: { select: { partName: true } } },
        },
      },
    });

    // Send system chat message
    try {
      if (workOrder.vehicle?.owner?.id) {
        await sendSystemChatMessage(
          workOrder.vehicle.owner.id,
          'Hệ thống: Phiếu sửa chữa đã hoàn thành thanh toán. Phiếu chat trực tiếp đã đóng. Cảm ơn quý khách!'
        );
      }
    } catch (err) {
      console.error('System chat notification error in recordPayment:', err);
    }

    res.json({ success: true, data: workOrder });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to record payment',
      error: error.message,
    });
  }
};

export const redeemPoints = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { points } = req.body as { points: number };

    if (!Number.isInteger(points) || points <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Số điểm không hợp lệ',
      });
    }

    const workOrder = await prisma.workOrder.findUnique({
      where: { id },
      include: {
        vehicle: {
          include: {
            owner: {
              select: { id: true, loyaltyPoints: true, treesPlanted: true },
            },
          },
        },
      },
    });

    if (!workOrder) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy phiếu sửa chữa' });
    }

    const owner = workOrder.vehicle?.owner;
    if (!owner) {
      return res.status(400).json({ success: false, message: 'Phiếu không có chủ xe' });
    }

    if (points > owner.loyaltyPoints) {
      return res.status(400).json({
        success: false,
        message: `Chủ xe chỉ có ${owner.loyaltyPoints} điểm, không thể dùng ${points}`,
      });
    }

    const discount = points * 1000;
    const baseTotal = workOrder.totalPrice ?? 0;
    const newTotal = Math.max(0, baseTotal - discount);

    const [updatedOrder] = await prisma.$transaction([
      prisma.workOrder.update({
        where: { id },
        data: {
          pointsRedeemed: points,
          pointsDiscount: discount,
          totalPrice: newTotal,
        },
        include: {
          vehicle: {
            include: {
              owner: {
                select: { id: true, name: true, phoneNumber: true, loyaltyPoints: true, treesPlanted: true },
              },
            },
          },
          services: { include: { workOrder: false } },
          partsUsed: { include: { part: { select: { partName: true } } } },
        },
      }),
      prisma.user.update({
        where: { id: owner.id },
        data: { loyaltyPoints: { decrement: points } },
      }),
    ]);

    res.json({ success: true, data: updatedOrder });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to redeem points',
      error: error.message,
    });
  }
};
