import { Request, Response } from 'express';
import { prisma } from '../prisma';

/**
 * Get user notifications
 * GET /api/notifications
 */
export const getNotifications = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const { page = 1, limit = 20 } = req.query;
    
    const skip = (Number(page) - 1) * Number(limit);
    const take = Number(limit);

    const notifications = await prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      skip,
      take,
    });

    const total = await prisma.notification.count({
      where: { userId },
    });

    const unreadCount = await prisma.notification.count({
      where: { userId, isRead: false },
    });

    res.json({
      success: true,
      data: {
        notifications,
        pagination: {
          total,
          page: Number(page),
          limit: Number(limit),
          totalPages: Math.ceil(total / Number(limit)),
        },
        unreadCount,
      },
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch notifications',
      error: error.message,
    });
  }
};

/**
 * Mark notification as read
 * PATCH /api/notifications/:id/read
 */
export const markAsRead = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const userId = (req as any).user.userId;

    const notification = await prisma.notification.findUnique({
      where: { id },
    });

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found',
      });
    }

    if (notification.userId !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Access denied',
      });
    }

    const updated = await prisma.notification.update({
      where: { id },
      data: { isRead: true },
    });

    res.json({
      success: true,
      message: 'Notification marked as read',
      data: updated,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to update notification',
      error: error.message,
    });
  }
};

/**
 * Mark all notifications as read
 * PATCH /api/notifications/read-all
 */
export const markAllAsRead = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;

    await prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    });

    res.json({
      success: true,
      message: 'All notifications marked as read',
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to update notifications',
      error: error.message,
    });
  }
};

/**
 * Delete a notification
 * DELETE /api/notifications/:id
 */
export const deleteNotification = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const userId = (req as any).user.userId;

    const notification = await prisma.notification.findUnique({
      where: { id },
    });

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found',
      });
    }

    if (notification.userId !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Access denied',
      });
    }

    await prisma.notification.delete({
      where: { id },
    });

    res.json({
      success: true,
      message: 'Notification deleted successfully',
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to delete notification',
      error: error.message,
    });
  }
};

/**
 * Helper to automatically create system notifications for all active admin/staff accounts.
 */
export const createNotificationForAdmins = async (
  title: string,
  content: string,
  type: string,
  data?: any
) => {
  try {
    // Find active staff/admin users
    const admins = await prisma.user.findMany({
      where: { role: 'STAFF', isActive: true },
      select: { id: true },
    });

    if (admins.length === 0) return;

    const notificationsData = admins.map((admin) => ({
      title,
      content,
      type,
      userId: admin.id,
      data: data || undefined,
    }));

    await prisma.notification.createMany({
      data: notificationsData,
    });
  } catch (error) {
    console.error('Failed to create notification for admins:', error);
  }
};

/**
 * Checks if the inventory item quantity has fallen below minThreshold,
 * and automatically triggers a system-wide low stock alert.
 */
export const checkAndWarnLowStock = async (partId: string) => {
  try {
    const item = await prisma.inventory.findUnique({
      where: { id: partId },
    });
    if (item && item.quantity < item.minThreshold) {
      await createNotificationForAdmins(
        'Cảnh báo hết hàng',
        `Phụ tùng "${item.partName}" chỉ còn lại ${item.quantity} sản phẩm trong kho (Ngưỡng tối thiểu: ${item.minThreshold}).`,
        'INVENTORY_LOW',
        { inventoryId: item.id }
      );
    }
  } catch (error) {
    console.error('Failed to check and warn low stock:', error);
  }
};

/**
 * Helper to automatically create a system notification for a specific user ID.
 */
export const createNotificationForUser = async (
  userId: string,
  title: string,
  content: string,
  type: string,
  data?: any
) => {
  try {
    await prisma.notification.create({
      data: {
        userId,
        title,
        content,
        type,
        data: data || undefined,
      },
    });
  } catch (error) {
    console.error('Failed to create notification for user:', error);
  }
};
