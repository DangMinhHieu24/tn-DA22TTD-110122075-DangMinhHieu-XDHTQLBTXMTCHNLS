import { Router } from 'express';
import {
  getWorkOrders,
  getWorkOrderById,
  createWorkOrder,
  updateWorkOrderStatus,
  assignTechnician,
  addPartsToWorkOrder,
  updateWorkOrder,
  deleteWorkOrder,
  getDashboardStats,
} from '../controllers/work-order.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

// All routes require authentication
router.use(authenticate);

// GET /api/work-orders/stats/dashboard - Get dashboard stats
router.get('/stats/dashboard', getDashboardStats);

// GET /api/work-orders - Get all work orders (with filters)
router.get('/', getWorkOrders);

// GET /api/work-orders/:id - Get work order by ID
router.get('/:id', getWorkOrderById);

// POST /api/work-orders - Create new work order
router.post('/', createWorkOrder);

// PATCH /api/work-orders/:id/status - Update work order status
router.patch('/:id/status', updateWorkOrderStatus);

// PATCH /api/work-orders/:id/assign - Assign technician
router.patch('/:id/assign', assignTechnician);

// PATCH /api/work-orders/:id/parts - Add parts to work order
router.patch('/:id/parts', addPartsToWorkOrder);

// PUT /api/work-orders/:id - Update work order
router.put('/:id', updateWorkOrder);

// DELETE /api/work-orders/:id - Delete work order
router.delete('/:id', deleteWorkOrder);

export default router;
