import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

/**
 * Get warranties for a specific vehicle
 * GET /api/vehicles/:vehicleId/warranties
 * Access: All roles (with permission check)
 */
export const getVehicleWarranties = async (req: Request, res: Response) => {
  try {
    const { vehicleId } = req.params;
    const authUser = (req as any).user;

    // Check if vehicle exists
    const vehicle = await prisma.vehicle.findUnique({
      where: { id: vehicleId },
      select: {
        id: true,
        licensePlate: true,
        brand: true,
        model: true,
        color: true,
        imageUrl: true,
        manufactureYear: true,
        currentKm: true,
        ownerId: true,
      },
    });

    if (!vehicle) {
      return res.status(404).json({
        success: false,
        message: 'Vehicle not found',
      });
    }

    // Permission check: CUSTOMER can only view their own vehicles
    if (authUser?.role === 'CUSTOMER' && vehicle.ownerId !== authUser.userId) {
      return res.status(403).json({
        success: false,
        message: 'Access denied: You can only view warranties of your own vehicles',
      });
    }

    // Fetch warranties
    const warranties = await prisma.warranty.findMany({
      where: { vehicleId },
      orderBy: {
        expiryDate: 'asc',
      },
    });

    // Calculate status and days remaining for each warranty
    const now = new Date();
    const warrantiesWithStatus = warranties.map((warranty) => {
      const expiryDate = new Date(warranty.expiryDate);
      const daysRemaining = Math.ceil((expiryDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
      
      let status: 'ACTIVE' | 'EXPIRING_SOON' | 'EXPIRED';
      if (daysRemaining < 0) {
        status = 'EXPIRED';
      } else if (daysRemaining <= 30) {
        status = 'EXPIRING_SOON';
      } else {
        status = 'ACTIVE';
      }

      return {
        ...warranty,
        daysRemaining,
        status,
      };
    });

    res.json({
      success: true,
      data: {
        vehicle,
        warranties: warrantiesWithStatus,
      },
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch warranties',
      error: error.message,
    });
  }
};

/**
 * Get all warranties (Admin only)
 * GET /api/warranties
 * Access: ADMIN only
 */
export const getAllWarranties = async (req: Request, res: Response) => {
  try {
    const { status, expiringSoon } = req.query;

    const where: any = {};
    const now = new Date();

    if (expiringSoon === 'true') {
      const thirtyDaysFromNow = new Date();
      thirtyDaysFromNow.setDate(now.getDate() + 30);
      
      where.expiryDate = {
        gte: now,
        lte: thirtyDaysFromNow,
      };
    } else if (status === 'EXPIRED') {
      where.expiryDate = {
        lt: now,
      };
    } else if (status === 'ACTIVE') {
      where.expiryDate = {
        gte: now,
      };
    }

    const warranties = await prisma.warranty.findMany({
      where,
      include: {
        vehicle: {
          select: {
            id: true,
            licensePlate: true,
            brand: true,
            model: true,
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
      },
      orderBy: {
        expiryDate: 'asc',
      },
    });

    // Calculate status and days remaining
    const warrantiesWithStatus = warranties.map((warranty) => {
      const expiryDate = new Date(warranty.expiryDate);
      const daysRemaining = Math.ceil((expiryDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
      
      let calculatedStatus: 'ACTIVE' | 'EXPIRING_SOON' | 'EXPIRED';
      if (daysRemaining < 0) {
        calculatedStatus = 'EXPIRED';
      } else if (daysRemaining <= 30) {
        calculatedStatus = 'EXPIRING_SOON';
      } else {
        calculatedStatus = 'ACTIVE';
      }

      return {
        ...warranty,
        daysRemaining,
        status: calculatedStatus,
      };
    });

    res.json({
      success: true,
      data: warrantiesWithStatus,
      count: warrantiesWithStatus.length,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch warranties',
      error: error.message,
    });
  }
};

/**
 * Get warranty by ID
 * GET /api/warranties/:id
 * Access: All roles (with permission check)
 */
export const getWarrantyById = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const authUser = (req as any).user;

    const warranty = await prisma.warranty.findUnique({
      where: { id },
      include: {
        vehicle: {
          select: {
            id: true,
            licensePlate: true,
            brand: true,
            model: true,
            ownerId: true,
          },
        },
      },
    });

    if (!warranty) {
      return res.status(404).json({
        success: false,
        message: 'Warranty not found',
      });
    }

    // Permission check
    if (authUser?.role === 'CUSTOMER' && warranty.vehicle.ownerId !== authUser.userId) {
      return res.status(403).json({
        success: false,
        message: 'Access denied',
      });
    }

    res.json({
      success: true,
      data: warranty,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch warranty',
      error: error.message,
    });
  }
};

/**
 * Create new warranty
 * POST /api/warranties
 * Access: ADMIN only
 */
export const createWarranty = async (req: Request, res: Response) => {
  try {
    const {
      vehicleId,
      warrantyType,
      startDate,
      expiryDate,
      terms,
      issuedBy,
    } = req.body;

    // Validation
    if (!vehicleId || !warrantyType || !startDate || !expiryDate) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: vehicleId, warrantyType, startDate, expiryDate',
      });
    }

    // Check if vehicle exists
    const vehicle = await prisma.vehicle.findUnique({
      where: { id: vehicleId },
    });

    if (!vehicle) {
      return res.status(404).json({
        success: false,
        message: 'Vehicle not found',
      });
    }

    // Validate dates
    const start = new Date(startDate);
    const expiry = new Date(expiryDate);

    if (expiry <= start) {
      return res.status(400).json({
        success: false,
        message: 'Expiry date must be after start date',
      });
    }

    const warranty = await prisma.warranty.create({
      data: {
        vehicleId,
        warrantyType,
        startDate: start,
        expiryDate: expiry,
        terms,
        issuedBy,
      },
      include: {
        vehicle: {
          select: {
            id: true,
            licensePlate: true,
            brand: true,
            model: true,
          },
        },
      },
    });

    res.status(201).json({
      success: true,
      message: 'Warranty created successfully',
      data: warranty,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to create warranty',
      error: error.message,
    });
  }
};

/**
 * Update warranty
 * PUT /api/warranties/:id
 * Access: ADMIN only
 */
export const updateWarranty = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const {
      warrantyType,
      startDate,
      expiryDate,
      terms,
      issuedBy,
    } = req.body;

    // Check if warranty exists
    const existingWarranty = await prisma.warranty.findUnique({
      where: { id },
    });

    if (!existingWarranty) {
      return res.status(404).json({
        success: false,
        message: 'Warranty not found',
      });
    }

    // Validate dates if provided
    if (startDate && expiryDate) {
      const start = new Date(startDate);
      const expiry = new Date(expiryDate);

      if (expiry <= start) {
        return res.status(400).json({
          success: false,
          message: 'Expiry date must be after start date',
        });
      }
    }

    const updateData: any = {};
    if (warrantyType !== undefined) updateData.warrantyType = warrantyType;
    if (startDate !== undefined) updateData.startDate = new Date(startDate);
    if (expiryDate !== undefined) updateData.expiryDate = new Date(expiryDate);
    if (terms !== undefined) updateData.terms = terms;
    if (issuedBy !== undefined) updateData.issuedBy = issuedBy;

    const warranty = await prisma.warranty.update({
      where: { id },
      data: updateData,
      include: {
        vehicle: {
          select: {
            id: true,
            licensePlate: true,
            brand: true,
            model: true,
          },
        },
      },
    });

    res.json({
      success: true,
      message: 'Warranty updated successfully',
      data: warranty,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to update warranty',
      error: error.message,
    });
  }
};

/**
 * Delete warranty
 * DELETE /api/warranties/:id
 * Access: ADMIN only
 */
export const deleteWarranty = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    // Check if warranty exists
    const warranty = await prisma.warranty.findUnique({
      where: { id },
    });

    if (!warranty) {
      return res.status(404).json({
        success: false,
        message: 'Warranty not found',
      });
    }

    await prisma.warranty.delete({
      where: { id },
    });

    res.json({
      success: true,
      message: 'Warranty deleted successfully',
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to delete warranty',
      error: error.message,
    });
  }
};
