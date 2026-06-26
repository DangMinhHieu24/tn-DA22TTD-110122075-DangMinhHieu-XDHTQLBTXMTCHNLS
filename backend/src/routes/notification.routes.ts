import { Router } from 'express';
import * as notificationController from '../controllers/notification.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

// All routes require authentication
router.use(authenticate);

// GET /api/notifications
router.get('/', notificationController.getNotifications);

// PATCH /api/notifications/read-all
router.patch('/read-all', notificationController.markAllAsRead);

// PATCH /api/notifications/:id/read
router.patch('/:id/read', notificationController.markAsRead);

// DELETE /api/notifications/:id
router.delete('/:id', notificationController.deleteNotification);

export default router;
