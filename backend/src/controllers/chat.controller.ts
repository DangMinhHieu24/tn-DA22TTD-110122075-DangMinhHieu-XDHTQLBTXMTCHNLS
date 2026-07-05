import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { processChatMessage } from '../services/gemini';

const prisma = new PrismaClient();

const OPEN_CHAT_STATUSES = ['PENDING', 'IN_PROGRESS', 'INSPECTION', 'COMPLETED'] as const;
const DIRECT_CHAT_ROLES = ['customer', 'technician'] as const;

async function getOpenWorkOrderByConversation(conversationId: string, userId: string, role: string) {
  const conversation = await prisma.chatConversation.findUnique({
    where: { id: conversationId },
    select: { userId: true },
  });

  if (!conversation) {
    return null;
  }

  return prisma.workOrder.findFirst({
    where: {
      vehicle: { ownerId: conversation.userId },
      status: { in: [...OPEN_CHAT_STATUSES] },
      ...(role.toLowerCase() === 'technician' ? { technicianId: userId } : {}),
    },
    include: {
      technician: true,
    },
  });
}

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

// Get or create direct conversation for a customer
export const getDirectConversation = async (req: Request, res: Response) => {
  try {
    const authUser = (req as any).user;
    const targetUserId = (req.query.customerId as string) || authUser.userId;
    
    // Prefer the conversation that already contains direct customer/technician messages.
    let conv = await prisma.chatConversation.findFirst({
      where: {
        userId: targetUserId,
        messages: {
          some: {
            role: { in: [...DIRECT_CHAT_ROLES] },
          },
        },
      },
      orderBy: { updatedAt: 'desc' },
      include: {
        messages: {
          where: { role: { in: [...DIRECT_CHAT_ROLES] } },
          orderBy: { createdAt: 'asc' },
        }
      }
    });

    if (!conv) {
      conv = await prisma.chatConversation.create({
        data: { userId: targetUserId },
        include: {
          messages: {
            where: { role: { in: [...DIRECT_CHAT_ROLES] } },
            orderBy: { createdAt: 'asc' },
          }
        }
      });
    }

    // Find the technician currently assigned to this customer's vehicle
    const activeWorkOrder = await prisma.workOrder.findFirst({
      where: {
        vehicle: { ownerId: targetUserId },
        status: { in: [...OPEN_CHAT_STATUSES] }
      },
      include: {
        technician: true
      }
    });

    res.json({
      success: true,
      data: {
        conversationId: conv.id,
        messages: conv.messages,
        technician: activeWorkOrder?.technician ? {
          id: activeWorkOrder.technician.id,
          name: activeWorkOrder.technician.name,
          phoneNumber: activeWorkOrder.technician.phoneNumber,
          avatarUrl: activeWorkOrder.technician.avatarUrl
        } : null
      }
    });
  } catch (error) {
    console.error('Get direct conversation error:', error);
    res.status(500).json({ success: false, message: 'Lỗi lấy hội thoại trực tiếp' });
  }
};

// Send a message in direct conversation
export const sendDirectMessage = async (req: Request, res: Response) => {
  try {
    const authUser = (req as any).user;
    const { content, conversationId } = req.body;

    if (!content || !content.trim()) {
      return res.status(400).json({ success: false, message: 'Nội dung không được để trống' });
    }

    const openWorkOrder = await getOpenWorkOrderByConversation(
      conversationId,
      authUser.userId,
      authUser.role,
    );

    if (!openWorkOrder) {
      return res.status(403).json({
        success: false,
        message: 'Kênh chat đã đóng vì phiếu sửa chữa đã thanh toán hoặc không còn hoạt động',
      });
    }

    // Get sender's name
    const sender = await prisma.user.findUnique({
      where: { id: authUser.userId }
    });
    const senderName = sender?.name || 'Người dùng';

    // Package as JSON to support sender meta without schema changes
    const payload = JSON.stringify({
      senderId: authUser.userId,
      senderName,
      text: content.trim()
    });

    const msg = await prisma.chatMessage.create({
      data: {
        conversationId,
        role: authUser.role.toLowerCase(), // 'customer' or 'technician'
        content: payload
      }
    });

    // Update conversation updatedAt
    await prisma.chatConversation.update({
      where: { id: conversationId },
      data: { updatedAt: new Date() }
    });

    res.json({ success: true, data: msg });
  } catch (error) {
    console.error('Send direct message error:', error);
    res.status(500).json({ success: false, message: 'Lỗi gửi tin nhắn trực tiếp' });
  }
};

// Get conversations list for a technician
export const getTechConversations = async (req: Request, res: Response) => {
  try {
    const authUser = (req as any).user;

    // Find all active work orders for this technician to identify the customers
    const workOrders = await prisma.workOrder.findMany({
      where: {
        technicianId: authUser.userId,
        status: { in: [...OPEN_CHAT_STATUSES] }
      },
      include: {
        vehicle: {
          include: {
            owner: true
          }
        }
      }
    });

    const customerIds = Array.from(new Set(workOrders.map(wo => wo.vehicle.ownerId)));

    // Fetch the conversations for these customers
    const conversations = await prisma.chatConversation.findMany({
      where: {
        userId: { in: customerIds },
        messages: {
          some: {
            role: { in: [...DIRECT_CHAT_ROLES] },
          },
        },
      },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            avatarUrl: true,
            phoneNumber: true
          }
        },
        messages: {
          where: { role: { in: [...DIRECT_CHAT_ROLES] } },
          orderBy: { createdAt: 'desc' },
          take: 1
        }
      },
      orderBy: { updatedAt: 'desc' }
    });

    res.json({ success: true, data: conversations });
  } catch (error) {
    console.error('Get tech conversations error:', error);
    res.status(500).json({ success: false, message: 'Lỗi lấy danh sách hội thoại của KTV' });
  }
};

// Get direct messages history
export const getDirectHistory = async (req: Request, res: Response) => {
  try {
    const { conversationId } = req.params;

    const messages = await prisma.chatMessage.findMany({
      where: {
        conversationId,
        role: { in: [...DIRECT_CHAT_ROLES] },
      },
      orderBy: { createdAt: 'asc' }
    });

    res.json({ success: true, data: messages });
  } catch (error) {
    console.error('Get direct history error:', error);
    res.status(500).json({ success: false, message: 'Lỗi lấy lịch sử tin nhắn trực tiếp' });
  }
};
