import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export const getTechnicians = async (req: Request, res: Response) => {
  try {
    const technicians = await prisma.user.findMany({
      where: {
        role: 'TECHNICIAN',
      },
      select: {
        id: true,
        name: true,
        phoneNumber: true,
      },
    });

    res.json({
      success: true,
      data: technicians,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch technicians',
      error: error.message,
    });
  }
};
