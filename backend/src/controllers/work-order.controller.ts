import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

/**
 * Get all work orders
 * GET /api/work-orders
 * Query params: status, technicianId, priority
 */
export const getWorkOrders = async (req: Request, res: Response) => {
  try {
    const { status, technicianId, priority } = req.query;

    const where: any = {};
    if (status) where.status = status;
    if (technicianId) where.technicianId = technicianId;
    if (priority) where.priority = priority;

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
    } = req.body;

    // Get user from auth middleware
    const createdById = (req as any).user.userId;

    // Generate order number
    const count = await prisma.workOrder.count();
    const orderNumber = `WO-${new Date().getFullYear()}-${String(count + 1).padStart(3, '0')}`;

    const workOrder = await prisma.workOrder.create({
      data: {
        orderNumber,
        vehicleId,
        status: status || 'PENDING',
        priority: priority || 'NORMAL',
        notes,
        technicianId,
        estimatedHours,
        scheduledTime,
        createdById,
        services: {
          create: services || [],
        },
        photos: {
          create: photos || [],
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
      },
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
 * Update work order status
 * PATCH /api/work-orders/:id/status
 */
export const updateWorkOrderStatus = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    const updateData: any = { status };
    
    // If status is COMPLETED, set completedAt
    if (status === 'COMPLETED') {
      updateData.completedAt = new Date();
    }

    const workOrder = await prisma.workOrder.update({
      where: { id },
      data: updateData,
      include: {
        vehicle: true,
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
        vehicle: true,
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

    const workOrder = await prisma.workOrder.update({
      where: { id },
      data: {
        notes,
        estimatedHours,
        scheduledTime,
        priority,
      },
      include: {
        vehicle: true,
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
