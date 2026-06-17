import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

/**
 * GET /api/appointments/my
 * Lấy danh sách lịch hẹn của customer đang đăng nhập
 */
/**
 * GET /api/appointments
 * Admin: lấy tất cả lịch hẹn (có thông tin khách hàng)
 */
export const getAllAppointments = async (req: Request, res: Response) => {
  try {
    const authUser = (req as any).user;

    if (authUser.role !== 'STAFF') {
      return res.status(403).json({
        success: false,
        message: 'Chỉ nhân viên mới có quyền xem tất cả lịch hẹn',
      });
    }

    const { date, dateFrom, dateTo, status } = req.query;
    const where: any = {};
    const scheduledAtFilter: any = {};

    if (date) {
      // Parse the date string as Vietnam timezone (UTC+7)
      // "2026-06-07" in VN = 2026-06-06T17:00:00.000Z (start of day) to 2026-06-07T16:59:59.999Z (end of day)
      const VN_OFFSET_MS = 7 * 60 * 60 * 1000;
      const [year, month, day] = (date as string).split('-').map(Number);
      const startOfDayVN = new Date(Date.UTC(year, month - 1, day, 0, 0, 0, 0) - VN_OFFSET_MS);
      const endOfDayVN = new Date(Date.UTC(year, month - 1, day, 23, 59, 59, 999) - VN_OFFSET_MS);
      scheduledAtFilter.gte = startOfDayVN;
      scheduledAtFilter.lte = endOfDayVN;
    } else {
      if (dateFrom) {
        const VN_OFFSET_MS = 7 * 60 * 60 * 1000;
        const [y, m, d] = (dateFrom as string).split('-').map(Number);
        scheduledAtFilter.gte = new Date(Date.UTC(y, m - 1, d, 0, 0, 0, 0) - VN_OFFSET_MS);
      }
      if (dateTo) {
        const VN_OFFSET_MS = 7 * 60 * 60 * 1000;
        const [y, m, d] = (dateTo as string).split('-').map(Number);
        scheduledAtFilter.lte = new Date(Date.UTC(y, m - 1, d, 23, 59, 59, 999) - VN_OFFSET_MS);
      }
    }

    if (Object.keys(scheduledAtFilter).length > 0) {
      where.scheduledAt = scheduledAtFilter;
    }

    if (status) {
      where.status = status as string;
    } else {
      // Exclude COMPLETED appointments by default (already have work orders)
      where.status = { not: 'COMPLETED' };
    }

    const appointments = await prisma.appointment.findMany({
      where,
      include: {
        customer: {
          select: {
            id: true,
            name: true,
            phoneNumber: true,
            email: true,
          },
        },
        vehicle: {
          select: {
            id: true,
            brand: true,
            model: true,
            licensePlate: true,
          },
        },
      },
      orderBy: { scheduledAt: 'asc' },
    });

    res.json({
      success: true,
      data: appointments,
    });
  } catch (error) {
    console.error('Error getting all appointments:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi lấy danh sách lịch hẹn',
    });
  }
};

export const getMyAppointments = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;

    const appointments = await prisma.appointment.findMany({
      where: { customerId: userId },
      include: {
        vehicle: {
          select: {
            id: true,
            brand: true,
            model: true,
            licensePlate: true,
          },
        },
      },
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
    const { scheduledAt, serviceType, notes, vehicleId } = req.body;

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
        vehicleId: vehicleId || null,
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
/**
 * DELETE /api/appointments/:id
 * Admin: xóa lịch hẹn
 */
export const deleteAppointment = async (req: Request, res: Response) => {
  try {
    const authUser = (req as any).user;

    if (authUser.role !== 'STAFF') {
      return res.status(403).json({
        success: false,
        message: 'Chỉ nhân viên mới có quyền xóa lịch hẹn',
      });
    }

    const { id } = req.params;

    const appointment = await prisma.appointment.findUnique({
      where: { id },
    });

    if (!appointment) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy lịch hẹn',
      });
    }

    await prisma.appointment.delete({ where: { id } });

    res.json({
      success: true,
      message: 'Đã xóa lịch hẹn thành công',
    });
  } catch (error) {
    console.error('Error deleting appointment:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi xóa lịch hẹn',
    });
  }
};

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
