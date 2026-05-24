import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

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

/**
 * Get all work orders
 * GET /api/work-orders
 * Query params: status, technicianId, priority
 */
export const getWorkOrders = async (req: Request, res: Response) => {
  try {
    const { status, technicianId, priority, vehicleId } = req.query;
    const authUser = (req as any).user;

    const where: any = {};
    if (status) where.status = status;
    if (technicianId) where.technicianId = technicianId;
    if (priority) where.priority = priority;
    if (vehicleId) where.vehicleId = vehicleId;

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
      orderBy: {
        createdAt: 'desc',
      },
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
              },
            },
          },
        },
        technician: {
          select: {
            id: true,
            name: true,
            email: true,
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
      priority,
      notes,
      technicianId,
      estimatedHours,
      scheduledTime,
      services, // Array of { serviceType, description }
      photos, // Array of { photoUrl, description }
      partsUsed, // Array of { partId, quantity, unitPrice }
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
          status: status || 'PENDING',
          priority: priority || 'NORMAL',
          notes,
          technicianId,
          estimatedHours,
          scheduledTime: resolvedScheduledTime,
          createdById,
          services: {
            create: services || [],
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
        },
      });

      if (updatedWorkOrder.status === 'COMPLETED') {
        const serviceSummary = buildServiceSummary(updatedWorkOrder.services);
        const serviceType = updatedWorkOrder.services[0]?.serviceType ?? null;

        await tx.maintenanceLog.upsert({
          where: { workOrderId: id },
          update: {
            vehicleId: updatedWorkOrder.vehicleId,
            odometerKm: updatedWorkOrder.vehicle?.currentKm ?? 0,
            serviceType,
            serviceSummary,
            notes: updatedWorkOrder.notes,
            performedAt: updatedWorkOrder.completedAt ?? new Date(),
          },
          create: {
            vehicleId: updatedWorkOrder.vehicleId,
            workOrderId: id,
            odometerKm: updatedWorkOrder.vehicle?.currentKm ?? 0,
            serviceType,
            serviceSummary,
            notes: updatedWorkOrder.notes,
            performedAt: updatedWorkOrder.completedAt ?? new Date(),
          },
        });
      }

      return updatedWorkOrder;
    });

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

/**
 * Update work order
 * PUT /api/work-orders/:id
 */
export const updateWorkOrder = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { notes, estimatedHours, scheduledTime, priority } = req.body;
    const resolvedScheduledTime = scheduledTime ?? buildScheduledTime(estimatedHours);

    const workOrder = await prisma.workOrder.update({
      where: { id },
      data: {
        notes,
        estimatedHours,
        scheduledTime: resolvedScheduledTime,
        priority,
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
        status: 'COMPLETED',
        completedAt: {
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

    res.json({
      success: true,
      data: {
        totalWorkOrders,
        pendingWorkOrders,
        inProgressWorkOrders,
        completedWorkOrders,
        completedToday,
        totalVehicles,
        totalCustomers,
        totalTechnicians,
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
