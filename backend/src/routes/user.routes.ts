import { Router } from 'express';
import { authenticate } from '../middleware/auth.middleware';
import { getTechnicians } from '../controllers/user.controller';

const router = Router();

// All routes require authentication
router.use(authenticate);

// GET /api/users/technicians - Get technician list
router.get('/technicians', getTechnicians);

export default router;
