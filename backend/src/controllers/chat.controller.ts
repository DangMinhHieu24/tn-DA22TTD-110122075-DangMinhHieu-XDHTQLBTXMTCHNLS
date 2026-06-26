import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { processChatMessage } from '../services/gemini';

const prisma = new PrismaClient();

export const sendMessage = async (req: Request, res: Response) => {
  try {
    const authUser = (req as any).user;
    const { content, conversationId, role } = req.body;

    if (!content || !content.trim()) {
      return res.status(400).json({ success: false, message: 'Nội dung tin nhắn không được để trống' });
    }

    const result = await processChatMessage(authUser.userId, content.trim(), conversationId, role);

    res.json({ success: true, data: result });
  } catch (error) {
    console.error('Chat error:', error);
    res.status(500).json({ success: false, message: 'Lỗi xử lý tin nhắn', error: (error as Error).message });
  }
};

export const getHistory = async (req: Request, res: Response) => {
  try {
    const authUser = (req as any).user;
    const conversations = await prisma.chatConversation.findMany({
      where: { userId: authUser.userId },
      include: {
        messages: {
          orderBy: { createdAt: 'asc' },
          take: 50,
        },
      },
      orderBy: { updatedAt: 'desc' },
      take: 10,
    });

    res.json({ success: true, data: conversations });
  } catch (error) {
    console.error('Chat history error:', error);
    res.status(500).json({ success: false, message: 'Lỗi lấy lịch sử chat' });
  }
};

export const clearHistory = async (req: Request, res: Response) => {
  try {
    const authUser = (req as any).user;
    await prisma.chatConversation.deleteMany({
      where: { userId: authUser.userId },
    });
    res.json({ success: true, message: 'Đã xoá lịch sử chat' });
  } catch (error) {
    console.error('Clear chat error:', error);
    res.status(500).json({ success: false, message: 'Lỗi xoá lịch sử chat' });
  }
};

export const getConversation = async (req: Request, res: Response) => {
  try {
    const authUser = (req as any).user;
    const { id } = req.params;
    const conv = await prisma.chatConversation.findFirst({
      where: { id, userId: authUser.userId },
      include: {
        messages: { orderBy: { createdAt: 'asc' } },
      },
    });

    if (!conv) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy hội thoại' });
    }

    res.json({ success: true, data: conv });
  } catch (error) {
    console.error('Get conversation error:', error);
    res.status(500).json({ success: false, message: 'Lỗi lấy hội thoại' });
  }
};
