import { GoogleGenerativeAI, SchemaType } from '@google/generative-ai';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || '');

const customerModel = genAI.getGenerativeModel({
  model: 'gemini-2.5-flash',
  systemInstruction: `Bạn là trợ lý ảo của Xanh EV - trung tâm dịch vụ xe điện.
Bạn có thể trả lời câu hỏi về dịch vụ, báo giá, bảo dưỡng, chính sách.
Khi khách hàng muốn đặt lịch hoặc hỏi thông tin các xe của chính họ, hãy dùng công cụ để:
1. Lấy danh sách xe của chính khách hàng đang trò chuyện (không cần biển số)
2. Tra cứu xe khác (cần biển số)
3. Xem dịch vụ có sẵn
4. Xem khung giờ trống
5. Đặt lịch hẹn

Luôn trả lời bằng tiếng Việt, thân thiện, lịch sự.`,
  tools: [
    {
      functionDeclarations: [
        {
          name: 'getMyVehicles',
          description: 'Lấy danh sách các xe của chính người dùng (khách hàng) đang trò chuyện',
          parameters: {
            type: SchemaType.OBJECT,
            properties: {},
            required: [],
          },
        },
        {
          name: 'lookupVehicle',
          description: 'Tra cứu thông tin xe theo biển số',
          parameters: {
            type: SchemaType.OBJECT,
            properties: {
              licensePlate: { type: SchemaType.STRING, description: 'Biển số xe (VD: 59A-12345)' },
            },
            required: ['licensePlate'],
          },
        },
        {
          name: 'getServiceTypes',
          description: 'Lấy danh sách dịch vụ có sẵn',
          parameters: {
            type: SchemaType.OBJECT,
            properties: {},
            required: [],
          },
        },
        {
          name: 'getAvailableSlots',
          description: 'Xem khung giờ trống trong ngày',
          parameters: {
            type: SchemaType.OBJECT,
            properties: {
              date: { type: SchemaType.STRING, description: 'Ngày cần xem (YYYY-MM-DD)' },
            },
            required: ['date'],
          },
        },
        {
          name: 'createAppointment',
          description: 'Đặt lịch hẹn sửa chữa',
          parameters: {
            type: SchemaType.OBJECT,
            properties: {
              vehicleId: { type: SchemaType.STRING, description: 'ID xe' },
              serviceType: { type: SchemaType.STRING, description: 'Loại dịch vụ' },
              date: { type: SchemaType.STRING, description: 'Ngày hẹn (YYYY-MM-DD)' },
              time: { type: SchemaType.STRING, description: 'Giờ hẹn (HH:mm)' },
              notes: { type: SchemaType.STRING, description: 'Ghi chú thêm' },
            },
            required: ['vehicleId', 'serviceType', 'date', 'time'],
          },
        },
      ],
    },
  ],
});

const technicianModel = genAI.getGenerativeModel({
  model: 'gemini-2.5-flash',
  systemInstruction: `Bạn là trợ lý kỹ thuật viên (KTV) của Xanh EV.
Bạn giúp KTV tra cứu thông tin xe, phụ tùng, và phiếu sửa chữa.
Bạn có các công cụ:
1. Tra cứu xe theo biển số
2. Kiểm tra tồn kho phụ tùng
3. Tra cứu phiếu sửa chữa

Luôn trả lời bằng tiếng Việt, ngắn gọn, chính xác.`,
  tools: [
    {
      functionDeclarations: [
        {
          name: 'lookupVehicle',
          description: 'Tra cứu thông tin xe theo biển số',
          parameters: {
            type: SchemaType.OBJECT,
            properties: {
              licensePlate: { type: SchemaType.STRING, description: 'Biển số xe (VD: 59A-12345)' },
            },
            required: ['licensePlate'],
          },
        },
        {
          name: 'checkInventory',
          description: 'Kiểm tra tồn kho phụ tùng theo tên',
          parameters: {
            type: SchemaType.OBJECT,
            properties: {
              query: { type: SchemaType.STRING, description: 'Tên phụ tùng cần tìm' },
            },
            required: ['query'],
          },
        },
        {
          name: 'searchWorkOrders',
          description: 'Tra cứu phiếu sửa chữa theo biển số hoặc tên khách hàng',
          parameters: {
            type: SchemaType.OBJECT,
            properties: {
              query: { type: SchemaType.STRING, description: 'Biển số hoặc tên khách hàng' },
            },
            required: ['query'],
          },
        },
      ],
    },
  ],
});

export async function processChatMessage(
  userId: string,
  message: string,
  conversationId?: string,
  role?: string,
): Promise<{ reply: string; conversationId: string }> {
  let conv = conversationId
    ? await prisma.chatConversation.findUnique({ where: { id: conversationId } })
    : null;

  if (!conv) {
    conv = await prisma.chatConversation.create({
      data: { userId },
    });
  }

  await prisma.chatMessage.create({
    data: {
      conversationId: conv.id,
      role: 'user',
      content: message,
    },
  });

  const history = await prisma.chatMessage.findMany({
    where: { conversationId: conv.id },
    orderBy: { createdAt: 'asc' },
    take: 20,
  });

  const activeModel = role === 'technician' ? technicianModel : customerModel;

  const chat = activeModel.startChat({
    history: history.slice(0, -1).map((m) => ({
      role: m.role === 'user' ? 'user' : 'model',
      parts: [{ text: m.content }],
    })),
  });

  let result = await chat.sendMessage(message);
  let reply = '';
  let loopCount = 0;

  while (loopCount < 5) {
    const fns = result.response.functionCalls();

    if (fns && fns.length > 0) {
      const fn = fns[0];
      const fnResult = await executeFunction(fn.name, fn.args as Record<string, any>, userId);

      result = await chat.sendMessage([
        {
          functionResponse: {
            name: fn.name,
            response: fnResult,
          },
        },
      ]);
      loopCount++;
    } else {
      reply = result.response.text();
      break;
    }
  }

  await prisma.chatMessage.create({
    data: {
      conversationId: conv.id,
      role: 'bot',
      content: reply,
    },
  });

  return { reply, conversationId: conv.id };
}

async function executeFunction(name: string, args: Record<string, any>, userId: string): Promise<Record<string, any>> {
  switch (name) {
    case 'getMyVehicles': {
      const vehicles = await prisma.vehicle.findMany({
        where: { ownerId: userId },
      });
      if (vehicles.length === 0) {
        return { found: false, message: 'Người dùng hiện chưa có xe nào đăng ký trên hệ thống.' };
      }
      return {
        found: true,
        vehicles: vehicles.map((v) => ({
          id: v.id,
          licensePlate: v.licensePlate,
          brand: v.brand,
          model: v.model,
          color: v.color,
        })),
      };
    }

    case 'lookupVehicle': {
      const vehicle = await prisma.vehicle.findUnique({
        where: { licensePlate: args.licensePlate },
        include: { owner: { select: { name: true, phoneNumber: true } } },
      });
      if (!vehicle) return { found: false, message: 'Không tìm thấy xe với biển số này' };
      return {
        found: true,
        id: vehicle.id,
        licensePlate: vehicle.licensePlate,
        brand: vehicle.brand,
        model: vehicle.model,
        color: vehicle.color,
        ownerName: vehicle.owner.name,
        ownerPhone: vehicle.owner.phoneNumber,
      };
    }

    case 'getServiceTypes': {
      return {
        services: [
          { type: 'MAINTENANCE', name: 'Bảo dưỡng định kỳ', price: '200.000đ - 500.000đ' },
          { type: 'BATTERY_CHECK', name: 'Kiểm tra pin/sạc', price: '100.000đ - 300.000đ' },
          { type: 'BRAKES_TIRES', name: 'Phanh & Lốp', price: '150.000đ - 400.000đ' },
          { type: 'OTHER_REPAIR', name: 'Sửa chữa khác', price: 'Tuỳ mức độ' },
        ],
      };
    }

    case 'getAvailableSlots': {
      const date = new Date(args.date + 'T00:00:00');
      const endOfDay = new Date(date.getTime() + 86400000);

      const existing = await prisma.appointment.findMany({
        where: {
          scheduledAt: { gte: date, lt: endOfDay },
          status: { in: ['PENDING', 'CONFIRMED'] },
        },
        select: { scheduledAt: true },
      });

      const bookedTimes = new Set(existing.map((a) => {
        const h = a.scheduledAt.getHours();
        const m = a.scheduledAt.getMinutes();
        return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}`;
      }));

      const allSlots = [
        '07:00', '08:00', '09:00', '10:00', '11:00',
        '13:00', '14:00', '15:00', '16:00', '17:00',
      ];

      const available = allSlots.filter((s) => !bookedTimes.has(s));
      return { date: args.date, availableSlots: available };
    }

    case 'createAppointment': {
      const vehicle = await prisma.vehicle.findUnique({ where: { id: args.vehicleId } });
      if (!vehicle) return { success: false, message: 'Không tìm thấy xe' };

      const scheduledAt = new Date(`${args.date}T${args.time}:00`);
      const appointment = await prisma.appointment.create({
        data: {
          customerId: vehicle.ownerId,
          vehicleId: args.vehicleId,
          scheduledAt,
          serviceType: args.serviceType,
          notes: args.notes || null,
          status: 'PENDING',
        },
      });

      return {
        success: true,
        id: appointment.id,
        date: args.date,
        time: args.time,
        serviceType: args.serviceType,
        status: 'PENDING',
      };
    }

    case 'checkInventory': {
      const parts = await prisma.inventory.findMany({
        where: {
          partName: { contains: args.query, mode: 'insensitive' },
        },
        select: { partName: true, quantity: true, unitPrice: true },
        take: 10,
      });
      if (parts.length === 0) return { found: false, message: 'Không tìm thấy phụ tùng phù hợp' };
      return { found: true, parts: parts.map((p: { partName: string; quantity: number; unitPrice: number }) => ({ name: p.partName, stock: p.quantity, price: p.unitPrice })) };
    }

    case 'searchWorkOrders': {
      const workOrders = await prisma.workOrder.findMany({
        where: {
          OR: [
            { vehicle: { licensePlate: { contains: args.query, mode: 'insensitive' } } },
            { vehicle: { owner: { name: { contains: args.query, mode: 'insensitive' } } } },
          ],
        },
        select: {
          id: true,
          status: true,
          createdAt: true,
          vehicle: { select: { licensePlate: true, model: true } },
        },
        take: 10,
        orderBy: { createdAt: 'desc' },
      });
      if (workOrders.length === 0) return { found: false, message: 'Không tìm thấy phiếu sửa chữa phù hợp' };
      return {
        found: true,
        workOrders: workOrders.map(w => ({
          id: w.id,
          licensePlate: w.vehicle.licensePlate,
          model: w.vehicle.model,
          status: w.status,
          createdAt: w.createdAt,
        })),
      };
    }

    default:
      return { error: `Unknown function: ${name}` };
  }
}
