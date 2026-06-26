import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { checkAndWarnLowStock } from './notification.controller';

const prisma = new PrismaClient();

export const getInventoryItems = async (req: Request, res: Response) => {
  try {
    const items = await prisma.inventory.findMany({
      orderBy: { partName: 'asc' },
    });

    res.json({
      success: true,
      data: items,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch inventory items',
      error: error.message,
    });
  }
};

export const getInventoryItemById = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    const item = await prisma.inventory.findUnique({
      where: { id },
    });

    if (!item) {
      return res.status(404).json({
        success: false,
        message: 'Inventory item not found',
      });
    }

    res.json({
      success: true,
      data: item,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch inventory item',
      error: error.message,
    });
  }
};

export const createInventoryItem = async (req: Request, res: Response) => {
  try {
    const { partName, imageUrl, quantity, minThreshold, unitPrice, sellPrice, warrantyDays } = req.body;

    const item = await prisma.inventory.create({
      data: {
        partName,
        imageUrl,
        quantity: quantity ?? 0,
        minThreshold: minThreshold ?? 0,
        unitPrice: unitPrice ?? 0,
        sellPrice: sellPrice ?? 0,
        warrantyDays: warrantyDays ?? 0,
      },
    });

    res.status(201).json({
      success: true,
      message: 'Inventory item created successfully',
      data: item,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to create inventory item',
      error: error.message,
    });
  }
};

export const updateInventoryItem = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { partName, imageUrl, quantity, minThreshold, unitPrice, sellPrice, warrantyDays } = req.body;

    const item = await prisma.inventory.update({
      where: { id },
      data: {
        partName,
        imageUrl,
        quantity,
        minThreshold,
        unitPrice,
        sellPrice,
        warrantyDays,
      },
    });

    await checkAndWarnLowStock(id);

    res.json({
      success: true,
      message: 'Inventory item updated successfully',
      data: item,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to update inventory item',
      error: error.message,
    });
  }
};

export const adjustInventoryQuantity = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { delta } = req.body;

    if (typeof delta !== 'number') {
      return res.status(400).json({
        success: false,
        message: 'delta must be a number',
      });
    }

    const item = await prisma.inventory.update({
      where: { id },
      data: {
        quantity: { increment: delta },
      },
    });

    await checkAndWarnLowStock(id);

    res.json({
      success: true,
      message: 'Inventory quantity adjusted successfully',
      data: item,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to adjust inventory quantity',
      error: error.message,
    });
  }
};

export const deleteInventoryItem = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    await prisma.inventory.delete({
      where: { id },
    });

    res.json({
      success: true,
      message: 'Inventory item deleted successfully',
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to delete inventory item',
      error: error.message,
    });
  }
};
