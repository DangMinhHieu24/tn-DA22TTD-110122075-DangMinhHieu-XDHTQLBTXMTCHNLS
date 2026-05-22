import { Router } from 'express';
import { authenticate } from '../middleware/auth.middleware';
import { getTechnicians, getCustomerByPhone } from '../controllers/user.controller';

const router = Router();

// All routes require authentication
router.use(authenticate);

// GET /api/users/technicians - Get technician list
router.get('/technicians', getTechnicians);

// GET /api/users/by-phone?phone=... - Get customer by phone number (with vehicles)
router.get('/by-phone', getCustomerByPhone);

export default router;
