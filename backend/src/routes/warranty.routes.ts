import { Router } from 'express';
import {
  getVehicleWarranties,
  getAllWarranties,
  getWarrantyById,
  createWarranty,
  updateWarranty,
  deleteWarranty,
} from '../controllers/warranty.controller';
import { authenticate, requireRole } from '../middleware/auth.middleware';

const router = Router();

// All routes require authentication
router.use(authenticate);

// GET /api/vehicles/:vehicleId/warranties - Get warranties for a specific vehicle
// Accessible by all authenticated users (permission checked in controller)
router.get('/vehicles/:vehicleId/warranties', getVehicleWarranties);

// GET /api/warranties - Get all warranties (Admin only)
router.get('/', requireRole('ADMIN'), getAllWarranties);

// GET /api/warranties/:id - Get warranty by ID
router.get('/:id', getWarrantyById);

// POST /api/warranties - Create new warranty (Admin only)
router.post('/', requireRole('ADMIN'), createWarranty);

// PUT /api/warranties/:id - Update warranty (Admin only)
router.put('/:id', requireRole('ADMIN'), updateWarranty);

// DELETE /api/warranties/:id - Delete warranty (Admin only)
router.delete('/:id', requireRole('ADMIN'), deleteWarranty);

export default router;
