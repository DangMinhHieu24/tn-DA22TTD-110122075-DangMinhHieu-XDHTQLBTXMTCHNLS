import { Router } from 'express';
import { body } from 'express-validator';
import * as authController from '../controllers/auth.controller';
import { authenticate } from '../middleware/auth.middleware';
import { validate } from '../middleware/validation.middleware';

const router = Router();

// Register
router.post(
  '/register',
  [
    body('name').trim().notEmpty().withMessage('Tên không được để trống'),
    body('email').isEmail().withMessage('Email không hợp lệ'),
    body('phoneNumber').optional().isMobilePhone('vi-VN').withMessage('Số điện thoại không hợp lệ'),
    body('password').isLength({ min: 6 }).withMessage('Mật khẩu phải có ít nhất 6 ký tự'),
  ],
  validate,
  authController.register
);

// Login
router.post(
  '/login',
  [
    body('identifier').trim().notEmpty().withMessage('Email hoặc số điện thoại không được để trống'),
    body('password').notEmpty().withMessage('Mật khẩu không được để trống'),
  ],
  validate,
  authController.login
);

// Logout (protected)
router.post('/logout', authenticate, authController.logout);

// Get current user (protected)
router.get('/me', authenticate, authController.getCurrentUser);

export default router;
