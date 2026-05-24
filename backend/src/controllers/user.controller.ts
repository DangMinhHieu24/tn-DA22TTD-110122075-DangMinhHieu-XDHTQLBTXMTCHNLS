import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export const getTechnicians = async (req: Request, res: Response) => {
  try {
    const technicians = await prisma.user.findMany({
      where: { role: 'TECHNICIAN' },
      select: {
        id: true,
        name: true,
        phoneNumber: true,
        updatedAt: true,
      },
    });

    // For each technician, compute active work order count and a simple "isOnline" heuristic
    const result = await Promise.all(technicians.map(async (t) => {
      const activeCount = await prisma.workOrder.count({
        where: {
          technicianId: t.id,
          status: { in: ['IN_PROGRESS', 'INSPECTION', 'PENDING'] },
        },
      });

      // Simple presence heuristic: consider online if they have any active work orders
      const isOnline = activeCount > 0;

      return {
        id: t.id,
        name: t.name,
        phoneNumber: t.phoneNumber,
        vehicleCount: activeCount,
        isOnline,
      };
    }));

    res.json({ success: true, data: result });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch technicians',
      error: error.message,
    });
  }
};

/**
 * Get customer by phone number (with their vehicles)
 * GET /api/users/by-phone?phone=...
 */
export const getCustomerByPhone = async (req: Request, res: Response) => {
  try {
    const { phone } = req.query;

    if (!phone || typeof phone !== 'string') {
      return res.status(400).json({
        success: false,
        message: 'Phone number is required',
      });
    }

    const user = await prisma.user.findFirst({
      where: {
        phoneNumber: phone,
        role: 'CUSTOMER',
      },
      select: {
        id: true,
        name: true,
        email: true,
        phoneNumber: true,
        ownedVehicles: {
          include: {
            workOrders: {
              orderBy: { createdAt: 'desc' },
              take: 1,
              select: {
                createdAt: true,
                status: true,
              },
            },
          },
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found',
      });
    }

    res.json({
      success: true,
      data: user,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch customer',
      error: error.message,
    });
  }
};
