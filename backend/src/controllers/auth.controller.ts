import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// Register
export const register = async (req: Request, res: Response) => {
  try {
    const { name, email, phoneNumber, password } = req.body;

    // Check if user exists
    const existingUser = await prisma.user.findFirst({
      where: {
        OR: [
          { email },
          ...(phoneNumber ? [{ phoneNumber }] : [])
        ]
      }
    });

    if (existingUser) {
      return res.status(409).json({
        message: 'Email hoặc số điện thoại đã được sử dụng'
      });
    }

    // Hash password (6 rounds for development speed, use 10+ in production)
    const hashedPassword = await bcrypt.hash(password, 6);

    // Create user
    const user = await prisma.user.create({
      data: {
        name,
        email,
        phoneNumber,
        password: hashedPassword,
        role: 'CUSTOMER' // Default role
      }
    });

    // Generate token
    const token = jwt.sign(
      { userId: user.id, role: user.role },
      process.env.JWT_SECRET as string,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' } as jwt.SignOptions
    );

    // Remove password from response
    const { password: _, ...userWithoutPassword } = user;

    res.status(201).json({
      token,
      user: {
        id: userWithoutPassword.id,
        email: userWithoutPassword.email,
        name: userWithoutPassword.name,
        role: userWithoutPassword.role.toLowerCase(),
        phoneNumber: userWithoutPassword.phoneNumber,
        avatarUrl: userWithoutPassword.avatarUrl
      }
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ message: 'Đã xảy ra lỗi khi đăng ký' });
  }
};

// Login
export const login = async (req: Request, res: Response) => {
  try {
    const { identifier, password } = req.body;

    // Find user by email or phone
    const user = await prisma.user.findFirst({
      where: {
        OR: [
          { email: identifier },
          { phoneNumber: identifier }
        ]
      }
    });

    if (!user) {
      return res.status(404).json({
        message: 'Tài khoản không tồn tại'
      });
    }

    // Check password
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({
        message: 'Email/Số điện thoại hoặc mật khẩu không đúng'
      });
    }

    // Check if user is active
    if (!user.isActive) {
      return res.status(403).json({
        message: 'Tài khoản đã bị vô hiệu hóa'
      });
    }

    // Generate token
    const token = jwt.sign(
      { userId: user.id, role: user.role },
      process.env.JWT_SECRET as string,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' } as jwt.SignOptions
    );

    // Remove password from response
    const { password: _, ...userWithoutPassword } = user;

    res.json({
      token,
      user: {
        id: userWithoutPassword.id,
        email: userWithoutPassword.email,
        name: userWithoutPassword.name,
        role: userWithoutPassword.role.toLowerCase(),
        phoneNumber: userWithoutPassword.phoneNumber,
        avatarUrl: userWithoutPassword.avatarUrl,
        loyaltyPoints: userWithoutPassword.loyaltyPoints,
        treesPlanted: userWithoutPassword.treesPlanted
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Đã xảy ra lỗi khi đăng nhập' });
  }
};

// Logout
export const logout = async (_req: Request, res: Response) => {
  // In a real app, you might want to blacklist the token
  res.json({ message: 'Đăng xuất thành công' });
};

// Get current user
export const getCurrentUser = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;

    const user = await prisma.user.findUnique({
      where: { id: userId }
    });

    if (!user) {
      return res.status(404).json({ message: 'Người dùng không tồn tại' });
    }

    const { password: _, ...userWithoutPassword } = user;

    res.json({
      id: userWithoutPassword.id,
      email: userWithoutPassword.email,
      name: userWithoutPassword.name,
      role: userWithoutPassword.role.toLowerCase(),
      phoneNumber: userWithoutPassword.phoneNumber,
      avatarUrl: userWithoutPassword.avatarUrl,
      loyaltyPoints: userWithoutPassword.loyaltyPoints,
      treesPlanted: userWithoutPassword.treesPlanted
    });
  } catch (error) {
    console.error('Get current user error:', error);
    res.status(500).json({ message: 'Đã xảy ra lỗi' });
  }
};

// Change Password
export const changePassword = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const { oldPassword, newPassword } = req.body;

    if (!oldPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Mật khẩu cũ và mật khẩu mới không được để trống'
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Mật khẩu mới phải có ít nhất 6 ký tự'
      });
    }

    // Find user
    const user = await prisma.user.findUnique({
      where: { id: userId }
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Người dùng không tồn tại'
      });
    }

    // Verify old password
    const isPasswordValid = await bcrypt.compare(oldPassword, user.password);
    if (!isPasswordValid) {
      return res.status(400).json({
        success: false,
        message: 'Mật khẩu cũ không chính xác'
      });
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 6);

    // Update password
    await prisma.user.update({
      where: { id: userId },
      data: { password: hashedPassword }
    });

    res.json({
      success: true,
      message: 'Đổi mật khẩu thành công'
    });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({
      success: false,
      message: 'Đã xảy ra lỗi khi đổi mật khẩu'
    });
  }
};
