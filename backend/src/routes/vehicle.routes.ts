import { Router } from 'express';
import {
  getVehicles,
  getVehicleById,
  getVehicleByLicensePlate,
  createVehicle,
  updateVehicle,
  deleteVehicle,
} from '../controllers/vehicle.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

// All routes require authentication
router.use(authenticate);

// GET /api/vehicles - Get all vehicles
router.get('/', getVehicles);

// GET /api/vehicles/plate/:licensePlate - Get vehicle by license plate
router.get('/plate/:licensePlate', getVehicleByLicensePlate);

// GET /api/vehicles/:id - Get vehicle by ID
router.get('/:id', getVehicleById);

// POST /api/vehicles - Create new vehicle
router.post('/', createVehicle);

// PUT /api/vehicles/:id - Update vehicle
router.put('/:id', updateVehicle);

// DELETE /api/vehicles/:id - Delete vehicle
router.delete('/:id', deleteVehicle);

export default router;
