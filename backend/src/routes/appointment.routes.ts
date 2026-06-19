import { Router } from 'express';
import {
  getAllAppointments,
  getMyAppointments,
  createAppointment,
  cancelAppointment,
  deleteAppointment,
  clearMyAppointmentHistory,
} from '../controllers/appointment.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

// All routes require authentication
router.use(authenticate);

// GET /api/appointments - Admin: get all appointments
router.get('/', getAllAppointments);

// GET /api/appointments/my - Get my appointments
router.get('/my', getMyAppointments);

// PATCH /api/appointments/my/history - Clear my past history
router.patch('/my/history', clearMyAppointmentHistory);

// POST /api/appointments - Create appointment
router.post('/', createAppointment);

// DELETE /api/appointments/:id - Admin: delete appointment
router.delete('/:id', deleteAppointment);

// PATCH /api/appointments/:id/cancel - Cancel appointment
router.patch('/:id/cancel', cancelAppointment);

export default router;
