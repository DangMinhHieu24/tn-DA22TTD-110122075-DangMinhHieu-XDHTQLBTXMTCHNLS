import { Request, Response } from 'express';
import { PrismaClient, Prisma } from '@prisma/client';

const prisma = new PrismaClient();

export const getTechnicians = async (req: Request, res: Response) => {
  try {
    const { search } = req.query;
    const where: any = { role: 'TECHNICIAN' };

    if (search && typeof search === 'string' && search.trim().length > 0) {
      const q = search.trim();
      where.OR = [
        { name: { contains: q, mode: 'insensitive' } },
        { phoneNumber: { contains: q, mode: 'insensitive' } },
      ];
    }

    const technicians = await prisma.user.findMany({
      where,
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
/**
 * Search customers by name, phone, or email
 * GET /api/users/customers?search=...
 */
export const searchCustomers = async (req: Request, res: Response) => {
  try {
    const { search } = req.query;
    const where: any = { role: 'CUSTOMER' };

    if (search && typeof search === 'string' && search.trim().length > 0) {
      const q = search.trim();
      where.OR = [
        { name: { contains: q, mode: 'insensitive' } },
        { phoneNumber: { contains: q, mode: 'insensitive' } },
        { email: { contains: q, mode: 'insensitive' } },
      ];
    }

    const customers = await prisma.user.findMany({
      where,
      select: {
        id: true,
        name: true,
        email: true,
        phoneNumber: true,
        avatarUrl: true,
        loyaltyPoints: true,
        createdAt: true,
        _count: {
          select: { ownedVehicles: true },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: 20,
    });

    res.json({ success: true, data: customers });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to search customers',
      error: error.message,
    });
  }
};

/**
 * Update user (customer or technician) by ID
 * PUT /api/users/:id
 */
export const updateUser = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { name, phoneNumber, email, isActive } = req.body;

    const data: any = {};
    if (name !== undefined) data.name = name;
    if (phoneNumber !== undefined) data.phoneNumber = phoneNumber;
    if (email !== undefined) data.email = email;
    if (isActive !== undefined) data.isActive = isActive;

    const user = await prisma.user.update({
      where: { id },
      data,
      select: {
        id: true,
        name: true,
        email: true,
        phoneNumber: true,
        avatarUrl: true,
        role: true,
        isActive: true,
        createdAt: true,
      },
    });

    res.json({ success: true, message: 'User updated successfully', data: user });
  } catch (error: any) {
    if (error.code === 'P2025') {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    res.status(500).json({
      success: false,
      message: 'Failed to update user',
      error: error.message,
    });
  }
};

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
