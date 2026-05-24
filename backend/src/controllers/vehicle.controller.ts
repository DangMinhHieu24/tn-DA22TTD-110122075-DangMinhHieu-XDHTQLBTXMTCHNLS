import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

/**
 * Get all vehicles
 * GET /api/vehicles
 */
export const getVehicles = async (req: Request, res: Response) => {
  try {
    const { ownerId } = req.query;
    const authUser = (req as any).user;
    const where: any = {};

    if (ownerId) {
      where.ownerId = ownerId;
    }

    if (authUser?.role === 'CUSTOMER') {
      where.ownerId = authUser.userId;
    }

    const vehicles = await prisma.vehicle.findMany({
      where,
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
      orderBy: {
        createdAt: 'desc',
      },
    });

    res.json({
      success: true,
      data: vehicles,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch vehicles',
      error: error.message,
    });
  }
};

/**
 * Get vehicle by ID
 * GET /api/vehicles/:id
 */
export const getVehicleById = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const authUser = (req as any).user;

    const vehicle = await prisma.vehicle.findUnique({
      where: { id },
      include: {
        owner: {
          select: {
            id: true,
            name: true,
            email: true,
            phoneNumber: true,
          },
        },
        workOrders: {
          include: {
            technician: {
              select: {
                id: true,
                name: true,
              },
            },
            services: true,
          },
          orderBy: {
            createdAt: 'desc',
          },
        },
      },
    });

    if (!vehicle) {
      return res.status(404).json({
        success: false,
        message: 'Vehicle not found',
      });
    }

    if (authUser?.role === 'CUSTOMER' && vehicle.ownerId !== authUser.userId) {
      return res.status(403).json({
        success: false,
        message: 'Access denied',
      });
    }

    res.json({
      success: true,
      data: vehicle,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch vehicle',
      error: error.message,
    });
  }
};

/**
 * Get maintenance logs for a vehicle
 * GET /api/vehicles/:id/maintenance-logs
 */
export const getVehicleMaintenanceLogs = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const authUser = (req as any).user;

    const vehicle = await prisma.vehicle.findUnique({
      where: { id },
      select: {
        id: true,
        ownerId: true,
      },
    });

    if (!vehicle) {
      return res.status(404).json({
        success: false,
        message: 'Vehicle not found',
      });
    }

    if (authUser?.role === 'CUSTOMER' && vehicle.ownerId !== authUser.userId) {
      return res.status(403).json({
        success: false,
        message: 'Access denied',
      });
    }

    const maintenanceLogs = await prisma.maintenanceLog.findMany({
      where: { vehicleId: id },
      include: {
        workOrder: {
          select: {
            id: true,
            orderNumber: true,
            status: true,
            completedAt: true,
          },
        },
      },
      orderBy: {
        performedAt: 'desc',
      },
    });

    res.json({
      success: true,
      data: maintenanceLogs,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch maintenance logs',
      error: error.message,
    });
  }
};

/**
 * Get vehicle by license plate
 * GET /api/vehicles/plate/:licensePlate
 */
export const getVehicleByLicensePlate = async (req: Request, res: Response) => {
  try {
    const { licensePlate } = req.params;
    const authUser = (req as any).user;

    const vehicle = await prisma.vehicle.findUnique({
      where: { licensePlate },
      include: {
        owner: {
          select: {
            id: true,
            name: true,
            email: true,
            phoneNumber: true,
          },
        },
        workOrders: {
          include: {
            services: true,
          },
          orderBy: {
            createdAt: 'desc',
          },
          take: 5, // Last 5 work orders
        },
      },
    });

    if (!vehicle) {
      return res.status(404).json({
        success: false,
        message: 'Vehicle not found',
      });
    }

    if (authUser?.role === 'CUSTOMER' && vehicle.ownerId !== authUser.userId) {
      return res.status(403).json({
        success: false,
        message: 'Access denied',
      });
    }

    res.json({
      success: true,
      data: vehicle,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch vehicle',
      error: error.message,
    });
  }
};

/**
 * Create new vehicle
 * POST /api/vehicles
 */
export const createVehicle = async (req: Request, res: Response) => {
  try {
    const { 
      licensePlate, 
      brand,
      model, 
      color, 
      imageUrl,
      manufactureYear,
      qrCode,
      warrantyExpiry,
      currentKm, 
      ownerId,
    } = req.body;

    // Check if vehicle already exists
    const existingVehicle = await prisma.vehicle.findUnique({
      where: { licensePlate },
    });

    if (existingVehicle) {
      return res.status(400).json({
        success: false,
        message: 'Vehicle with this license plate already exists',
      });
    }

    const vehicle = await prisma.vehicle.create({
      data: {
        licensePlate,
        brand,
        model,
        color,
        imageUrl,
        manufactureYear: manufactureYear ? parseInt(manufactureYear) : null,
        qrCode,
        warrantyExpiry: warrantyExpiry ? new Date(warrantyExpiry) : null,
        currentKm,
        ownerId,
      },
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
    });

    res.status(201).json({
      success: true,
      message: 'Vehicle created successfully',
      data: vehicle,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to create vehicle',
      error: error.message,
    });
  }
};

/**
 * Update vehicle
 * PUT /api/vehicles/:id
 */
export const updateVehicle = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { 
      brand,
      model, 
      color, 
      imageUrl,
      manufactureYear,
      qrCode,
      warrantyExpiry,
      currentKm 
    } = req.body;

    // Validate currentKm: do not allow decreasing odometer
    if (currentKm !== undefined && currentKm !== null) {
      const existing = await prisma.vehicle.findUnique({ where: { id }, select: { currentKm: true } });
      if (existing && existing.currentKm != null && currentKm < existing.currentKm) {
        return res.status(400).json({
          success: false,
          message: `currentKm (${currentKm}) cannot be less than existing value (${existing.currentKm})`,
        });
      }
    }

    const vehicle = await prisma.vehicle.update({
      where: { id },
      data: {
        brand,
        model,
        color,
        imageUrl,
        manufactureYear: manufactureYear ? parseInt(manufactureYear) : undefined,
        qrCode,
        warrantyExpiry: warrantyExpiry ? new Date(warrantyExpiry) : undefined,
        currentKm,
      },
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
    });

    res.json({
      success: true,
      message: 'Vehicle updated successfully',
      data: vehicle,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to update vehicle',
      error: error.message,
    });
  }
};

/**
 * Delete vehicle
 * DELETE /api/vehicles/:id
 */
export const deleteVehicle = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    await prisma.vehicle.delete({
      where: { id },
    });

    res.json({
      success: true,
      message: 'Vehicle deleted successfully',
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to delete vehicle',
      error: error.message,
    });
  }
};
