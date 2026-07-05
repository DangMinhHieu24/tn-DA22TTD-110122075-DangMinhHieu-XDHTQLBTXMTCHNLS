import { Router } from 'express';
import {
  getVehicleWarranties,
  getAllWarranties,
  getWarrantyById,
  createWarranty,
  updateWarranty,
  deleteWarranty,
  exportWarrantyDataByYear,
  exportAllWarrantyData,
} from '../controllers/warranty.controller';
import { authenticate, requireRole } from '../middleware/auth.middleware';

const router = Router();

// All routes require authentication
router.use(authenticate);

// GET /api/vehicles/:vehicleId/warranties - Get warranties for a specific vehicle
// Accessible by all authenticated users (permission checked in controller)
router.get('/vehicles/:vehicleId/warranties', getVehicleWarranties);

// GET /api/warranties - Get all warranties (Staff only)
router.get('/', requireRole('STAFF'), getAllWarranties);

// GET /api/warranties/export/all - Export all warranty data (Staff only)
router.get('/export/all', requireRole('STAFF'), exportAllWarrantyData);

// GET /api/warranties/export/:year - Export warranty data by year (Staff only)
router.get('/export/:year', requireRole('STAFF'), exportWarrantyDataByYear);

// GET /api/warranties/:id - Get warranty by ID
router.get('/:id', getWarrantyById);

// POST /api/warranties - Create new warranty (Staff only)
router.post('/', requireRole('STAFF'), createWarranty);

// PUT /api/warranties/:id - Update warranty (Staff only)
router.put('/:id', requireRole('STAFF'), updateWarranty);

// DELETE /api/warranties/:id - Delete warranty (Staff only)
router.delete('/:id', requireRole('STAFF'), deleteWarranty);

export default router;
