import { Router } from 'express';
import { authenticate } from '../middleware/auth.middleware';
import { getTechnicians, getCustomerByPhone, searchCustomers, updateUser } from '../controllers/user.controller';

const router = Router();

// All routes require authentication
router.use(authenticate);

// GET /api/users/technicians - Get technician list
router.get('/technicians', getTechnicians);

// GET /api/users/by-phone?phone=... - Get customer by phone number (with vehicles)
router.get('/by-phone', getCustomerByPhone);

// GET /api/users/customers?search=... - Search customers by name, phone, email
router.get('/customers', searchCustomers);

// PUT /api/users/:id - Update user info (name, phone, email, isActive)
router.put('/:id', updateUser);

export default router;
