import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

/**
 * Get all vehicles
 * GET /api/vehicles
 */
export const getVehicles = async (req: Request, res: Response) => {
  try {
    const vehicles = await prisma.vehicle.findMany({
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
 * Get vehicle by license plate
 * GET /api/vehicles/plate/:licensePlate
 */
export const getVehicleByLicensePlate = async (req: Request, res: Response) => {
  try {
    const { licensePlate } = req.params;

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
    const { licensePlate, model, color, warrantyStatus, currentKm, ownerId } = req.body;

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
        model,
        color,
        warrantyStatus: warrantyStatus || false,
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
    const { model, color, warrantyStatus, currentKm } = req.body;

    const vehicle = await prisma.vehicle.update({
      where: { id },
      data: {
        model,
        color,
        warrantyStatus,
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
