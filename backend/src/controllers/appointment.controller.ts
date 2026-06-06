import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

/**
 * GET /api/appointments/my
 * Lấy danh sách lịch hẹn của customer đang đăng nhập
 */
export const getMyAppointments = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;

    const appointments = await prisma.appointment.findMany({
      where: { customerId: userId },
      orderBy: { scheduledAt: 'desc' },
    });

    res.json({
      success: true,
      data: appointments,
    });
  } catch (error) {
    console.error('Error getting appointments:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi lấy danh sách lịch hẹn',
    });
  }
};

/**
 * POST /api/appointments
 * Tạo lịch hẹn mới
 */
export const createAppointment = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const { scheduledAt, serviceType, notes } = req.body;

    // Validate
    if (!scheduledAt) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng chọn ngày giờ hẹn',
      });
    }

    const scheduledDate = new Date(scheduledAt);
    if (scheduledDate <= new Date()) {
      return res.status(400).json({
        success: false,
        message: 'Ngày giờ hẹn phải ở tương lai',
      });
    }

    const appointment = await prisma.appointment.create({
      data: {
        customerId: userId,
        scheduledAt: scheduledDate,
        serviceType: serviceType || null,
        notes: notes || null,
        status: 'PENDING',
      },
    });

    res.status(201).json({
      success: true,
      data: appointment,
      message: 'Đặt lịch hẹn thành công',
    });
  } catch (error) {
    console.error('Error creating appointment:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi tạo lịch hẹn',
    });
  }
};

/**
 * PATCH /api/appointments/:id/cancel
 * Hủy lịch hẹn (chỉ owner mới được hủy)
 */
export const cancelAppointment = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const { id } = req.params;

    // Tìm appointment
    const appointment = await prisma.appointment.findUnique({
      where: { id },
    });

    if (!appointment) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy lịch hẹn',
      });
    }

    // Chỉ owner mới được hủy
    if (appointment.customerId !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Bạn không có quyền hủy lịch hẹn này',
      });
    }

    // Chỉ hủy được PENDING hoặc CONFIRMED
    if (appointment.status === 'CANCELLED') {
      return res.status(400).json({
        success: false,
        message: 'Lịch hẹn đã được hủy trước đó',
      });
    }

    const updated = await prisma.appointment.update({
      where: { id },
      data: { status: 'CANCELLED' },
    });

    res.json({
      success: true,
      data: updated,
      message: 'Đã hủy lịch hẹn',
    });
  } catch (error) {
    console.error('Error cancelling appointment:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi hủy lịch hẹn',
    });
  }
};
