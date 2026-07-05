import { prisma } from '../prisma';

// Fuzzy string matching: checks if `target` appears in `text`
// allowing up to `maxDist` character edits (Levenshtein distance).
function fuzzyIncludes(text: string, target: string, maxDist = 2): boolean {
  if (text.includes(target)) return true;
  // Sliding window: check substrings of similar length
  const len = target.length;
  for (let i = 0; i <= text.length - len + maxDist; i++) {
    const window = text.substring(Math.max(0, i - maxDist), i + len + maxDist);
    if (levenshtein(window, target) <= maxDist) return true;
  }
  return false;
}

function levenshtein(a: string, b: string): number {
  const m = a.length, n = b.length;
  if (Math.abs(m - n) > 2) return 99;
  const dp: number[][] = Array.from({ length: m + 1 }, () => Array(n + 1).fill(0) as number[]);
  for (let i = 0; i <= m; i++) dp[i][0] = i;
  for (let j = 0; j <= n; j++) dp[0][j] = j;
  for (let i = 1; i <= m; i++) {
    for (let j = 1; j <= n; j++) {
      dp[i][j] = a[i - 1] === b[j - 1]
        ? dp[i - 1][j - 1]
        : 1 + Math.min(dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]);
    }
  }
  return dp[m][n];
}

async function handleLoyaltyQuery(userId: string, message: string): Promise<string | null> {
  const normalizedMsg = removeAccents(message.toLowerCase().trim());

  const keywords = [
    'diem thuong', 'diem', 'cay xanh', 'trong cay',
    'tich diem', 'loyalty', 'phan thuong', 'uu dai',
    'diem tich luy', 'so diem', 'so cay',
  ];

  const isMatch = keywords.some((kw) => normalizedMsg.includes(kw));
  if (!isMatch) return null;

  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { loyaltyPoints: true, treesPlanted: true, name: true },
  });

  if (!user) {
    return 'Không tìm thấy thông tin tài khoản. Vui lòng thử lại.';
  }

  return 'Thông tin tài khoản của bạn:\n\n'
    + `🌳 **Cây xanh đã trồng:** ${user.treesPlanted} cây\n`
    + `⭐ **Điểm thưởng:** ${user.loyaltyPoints} điểm\n\n`
    + 'Cứ mỗi 500.000đ giá trị đơn sửa chữa, Xanh EV sẽ trồng thêm 1 cây xanh thay bạn trên khắp Việt Nam. 🌱\n'
    + 'Điểm thưởng có thể dùng để giảm giá cho lần sửa chữa tiếp theo.';
}

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
    // Reuse the most recent conversation of this customer to maintain chat history
    conv = await prisma.chatConversation.findFirst({
      where: { userId },
      orderBy: { updatedAt: 'desc' },
    });
  }

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

  // Touch conversation timestamp to keep it active
  await prisma.chatConversation.update({
    where: { id: conv.id },
    data: { updatedAt: new Date() },
  });

  if (role !== 'technician') {
    // Rule-based: loyalty & green tree queries
    const loyaltyReply = await handleLoyaltyQuery(userId, message);
    if (loyaltyReply) {
      await prisma.chatMessage.create({
        data: {
          conversationId: conv.id,
          role: 'bot',
          content: loyaltyReply,
        },
      });
      await prisma.chatConversation.update({
        where: { id: conv.id },
        data: { updatedAt: new Date() },
      });
      return { reply: loyaltyReply, conversationId: conv.id };
    }

    const bookingReply = await handleRuleBasedBooking(userId, message, conv.id);
    if (bookingReply) {
      await prisma.chatMessage.create({
        data: {
          conversationId: conv.id,
          role: 'bot',
          content: bookingReply,
        },
      });
      await prisma.chatConversation.update({
        where: { id: conv.id },
        data: { updatedAt: new Date() },
      });
      return { reply: bookingReply, conversationId: conv.id };
    }
  }

  if (role === 'technician') {
    const reply = await processNvidiaChatMessage(userId, message, conv.id);
    return { reply, conversationId: conv.id };
  }

  // Customer: use NVIDIA API with customer-specific prompt & tools
  const customerSystemPrompt = `Bạn là trợ lý ảo của Xanh EV - trung tâm dịch vụ xe điện.
Bạn có thể trả lời câu hỏi về dịch vụ, báo giá, bảo dưỡng, chính sách.

Thông tin cửa hàng:
- Tên: Xanh EV Repair - Chi nhánh Trà Vinh
- Địa chỉ: 123 Nguyễn Thị Minh Khai, P.7, TP. Trà Vinh
- Số điện thoại: 0976 985 305
- Giờ mở cửa: 7:00 - 19:00 tất cả các ngày trong tuần

CHƯƠNG TRÌNH TÍCH ĐIỂM & CÂY XANH:
- Mỗi đơn sửa chữa: +1 cây xanh. Cứ 500.000đ: thêm 1 cây.
- Điểm thưởng: 20.000đ = 1 điểm. 50 điểm = 50.000đ giảm giá.
- Gọi getLoyaltyInfo để tra cứu.

═══════════════════════════════════════════
QUY TRÌNH ĐẶT LỊCH (BẮT BUỘC THỰC HIỆN THEO THỨ TỰ)
═══════════════════════════════════════════

Khi khách hàng muốn ĐẶT LỊCH / ĐẶT HẸN / BẢO DƯỠNG / SỬA XE (dù viết sai chính tả cũng phải nhận diện), BẠN PHẢI:

BƯỚC 1 - Lấy danh sách xe:
→ Gọi getMyVehicles() ngay lập tức.
→ Trả lời: "Danh sách xe của bạn:" + liệt kê các xe (biển số, hãng, model).
→ Hỏi: "Vui lòng chọn xe cần sửa chữa (gõ số thứ tự hoặc biển số)."

BƯỚC 2 - Chọn dịch vụ:
→ Khi khách chọn xe, gọi getServiceTypes() để lấy danh sách dịch vụ.
→ Trả lời: "Các dịch vụ có sẵn:" + liệt kê kèm giá.
→ Hỏi: "Vui lòng chọn dịch vụ (gõ số hoặc tên dịch vụ)."

BƯỚC 3 - Chọn thời gian:
→ Khi khách chọn dịch vụ, hỏi ngày mong muốn.
→ Gọi getAvailableSlots(date: "YYYY-MM-DD") để xem khung giờ trống.
→ Trả lời: "Khung giờ trống ngày YYYY-MM-DD:" + liệt kê.
→ Hỏi: "Vui lòng chọn khung giờ."

BƯỚC 4 - Xác nhận & tạo lịch:
→ Khi khách chọn giờ, TẤT CẢ THÔNG TIN ĐÃ ĐỦ.
→ Gọi createAppointment(vehicleId: "...", serviceType: "...", date: "YYYY-MM-DD", time: "HH:mm").
→ Trả lời xác nhận: "Đặt lịch thành công! Chi tiết: [Xe] - [Dịch vụ] - [Ngày giờ]"

LƯU Ý QUAN TRỌNG:
- KHÔNG được tự trả lời thông tin chung chung khi khách muốn đặt lịch.
- KHÔNG được hỏi "bạn muốn biết thêm gì" khi chưa hoàn tất đặt lịch.
- Nếu khách viết sai chính tả (vd: "dat lidsh", "bao duong dinh ky", "sua chua") → vẫn PHẢI nhận diện là ĐẶT LỊCH và gọi getMyVehicles().
- Sau khi hoàn tất đặt lịch, mới hỏi "Bạn cần hỗ trợ gì thêm không?".

Luôn trả lời bằng tiếng Việt, thân thiện, lịch sự.`;

  const customerTools = [
    {
      type: 'function',
      function: {
        name: 'getMyVehicles',
        description: 'Lấy danh sách xe của khách hàng đang trò chuyện. Gọi NGAY KHI khách muốn đặt lịch.',
        parameters: {
          type: 'object',
          properties: {},
          required: [],
        },
      },
    },
    {
      type: 'function',
      function: {
        name: 'getServiceTypes',
        description: 'Lấy danh sách dịch vụ có sẵn kèm giá. Gọi SAU KHI khách đã chọn xe.',
        parameters: {
          type: 'object',
          properties: {},
          required: [],
        },
      },
    },
    {
      type: 'function',
      function: {
        name: 'getAvailableSlots',
        description: 'Xem khung giờ trống trong ngày. Gọi SAU KHI khách chọn dịch vụ và ngày.',
        parameters: {
          type: 'object',
          properties: {
            date: { type: 'string', description: 'Ngày cần xem (YYYY-MM-DD)' },
          },
          required: ['date'],
        },
      },
    },
    {
      type: 'function',
      function: {
        name: 'createAppointment',
        description: 'Tạo lịch hẹn. Gọi KHI ĐỦ thông tin: xe, dịch vụ, ngày, giờ.',
        parameters: {
          type: 'object',
          properties: {
            vehicleId: { type: 'string', description: 'ID xe (lấy từ kết quả getMyVehicles)' },
            serviceType: { type: 'string', description: 'Tên dịch vụ (lấy từ kết quả getServiceTypes)' },
            date: { type: 'string', description: 'Ngày hẹn (YYYY-MM-DD)' },
            time: { type: 'string', description: 'Giờ hẹn (HH:mm)' },
            notes: { type: 'string', description: 'Ghi chú thêm (không bắt buộc)' },
          },
          required: ['vehicleId', 'serviceType', 'date', 'time'],
        },
      },
    },
    {
      type: 'function',
      function: {
        name: 'getLoyaltyInfo',
        description: 'Tra cứu điểm thưởng và số cây xanh của khách hàng. Gọi KHI khách hỏi về điểm thưởng, cây xanh, ưu đãi.',
        parameters: {
          type: 'object',
          properties: {},
          required: [],
        },
      },
    },
    {
      type: 'function',
      function: {
        name: 'lookupVehicle',
        description: 'Tra cứu thông tin xe theo biển số. Gọi KHI khách muốn tra cứu xe không phải của họ.',
        parameters: {
          type: 'object',
          properties: {
            licensePlate: { type: 'string', description: 'Biển số xe (VD: 59A-12345)' },
          },
          required: ['licensePlate'],
        },
      },
    },
  ];

  const reply = await processNvidiaChatMessage(userId, message, conv.id, customerSystemPrompt, customerTools);
  return { reply, conversationId: conv.id };
}

async function processNvidiaChatMessage(
  userId: string,
  message: string,
  conversationId: string,
  systemPrompt?: string,
  customTools?: any[],
): Promise<string> {
  const history = await prisma.chatMessage.findMany({
    where: { conversationId },
    orderBy: { createdAt: 'asc' },
    take: 20,
  });

  const messages: any[] = history.map((m) => ({
    role: m.role === 'user' ? 'user' : 'assistant',
    content: m.content,
  }));

  // Add system instruction
  const effectivePrompt = systemPrompt || `Bạn là trợ lý kỹ thuật viên (KTV) của Xanh EV.
Bạn giúp KTV tra cứu thông tin xe, phụ tùng, và phiếu sửa chữa.

Thông tin cửa hàng:
- Tên: Xanh EV Repair - Chi nhánh Trà Vinh
- Địa chỉ: 123 Nguyễn Thị Minh Khai, P.7, TP. Trà Vinh
- Số điện thoại: 0976 985 305
- Giờ mở cửa: 7:00 - 19:00 tất cả các ngày trong tuần

Bạn BẮT BUỘC phải sử dụng các công cụ (tools) được cung cấp để tra cứu thông tin thực tế từ cơ sở dữ liệu:
1. Tra cứu xe theo biển số (lookupVehicle)
2. Kiểm tra tồn kho phụ tùng theo tên (checkInventory)
3. Tra cứu phiếu sửa chữa (searchWorkOrders)

Chỉ trả lời dựa trên kết quả trả về của công cụ. Không được tự bịa ra dữ liệu hoặc mô tả cấu trúc dữ liệu JSON. Luôn trả lời bằng tiếng Việt, ngắn gọn, chính xác.`;

  messages.unshift({
    role: 'system',
    content: effectivePrompt,
  });

  const effectiveTools = customTools || [
    {
      type: 'function',
      function: {
        name: 'lookupVehicle',
        description: 'Tra cứu thông tin xe theo biển số',
        parameters: {
          type: 'object',
          properties: {
            licensePlate: { type: 'string', description: 'Biển số xe (VD: 59A-12345)' },
          },
          required: ['licensePlate'],
        },
      },
    },
    {
      type: 'function',
      function: {
        name: 'checkInventory',
        description: 'Kiểm tra tồn kho phụ tùng theo tên',
        parameters: {
          type: 'object',
          properties: {
            query: { type: 'string', description: 'Tên phụ tùng cần tìm' },
          },
          required: ['query'],
        },
      },
    },
    {
      type: 'function',
      function: {
        name: 'searchWorkOrders',
        description: 'Tra cứu phiếu sửa chữa theo biển số hoặc tên khách hàng',
        parameters: {
          type: 'object',
          properties: {
            query: { type: 'string', description: 'Biển số hoặc tên khách hàng' },
          },
          required: ['query'],
        },
      },
    },
  ];

  const apiKey = process.env.NVIDIA_API_KEY || '';
  const apiUrl = `${process.env.NVIDIA_API_URL || 'https://integrate.api.nvidia.com/v1'}/chat/completions`;
  const model = process.env.NVIDIA_MODEL || 'meta/llama-3.1-8b-instruct';

  let loopCount = 0;
  let finalReply = '';

  while (loopCount < 5) {
    const response = await fetch(apiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model,
        messages,
        tools: effectiveTools,
        tool_choice: 'auto',
        temperature: 0.2,
        max_tokens: 1024,
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Nvidia API error: ${response.status} - ${errorText}`);
    }

    const data = await response.json() as any;
    const choice = data.choices?.[0];
    if (!choice) {
      throw new Error('Nvidia API returned empty choices');
    }

    const assistantMessage = choice.message;
    const toolCalls = assistantMessage.tool_calls;

    if (toolCalls && toolCalls.length > 0) {
      // Push the assistant message (with tool calls) to local history context
      messages.push(assistantMessage);

      // Execute each function call and push results
      for (const tc of toolCalls) {
        let args = {};
        try {
          args = typeof tc.function.arguments === 'string'
            ? JSON.parse(tc.function.arguments)
            : tc.function.arguments;
        } catch (e) {
          console.error('Failed to parse tool arguments:', tc.function.arguments);
        }

        const fnResult = await executeFunction(tc.function.name, args, userId);

        messages.push({
          role: 'tool',
          tool_call_id: tc.id,
          name: tc.function.name,
          content: JSON.stringify(fnResult),
        });
      }
      loopCount++;
    } else {
      finalReply = assistantMessage.content || '';
      break;
    }
  }

  // Save the final response as bot message
  await prisma.chatMessage.create({
    data: {
      conversationId,
      role: 'bot',
      content: finalReply,
    },
  });

  return finalReply;
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

    case 'getLoyaltyInfo': {
      const user = await prisma.user.findUnique({
        where: { id: userId },
        select: { loyaltyPoints: true, treesPlanted: true, name: true },
      });
      if (!user) {
        return { found: false, message: 'Không tìm thấy thông tin người dùng.' };
      }
      return {
        found: true,
        name: user.name,
        points: user.loyaltyPoints,
        trees: user.treesPlanted,
        message: `Bạn ${user.name} đang có ${user.loyaltyPoints} điểm thưởng và đã trồng được ${user.treesPlanted} cây xanh thông qua các đơn sửa chữa tại Xanh EV. 🌱`,
      };
    }

    default:
      return { error: `Unknown function: ${name}` };
  }
}

export function removeAccents(str: string): string {
  return str
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/đ/g, 'd')
    .replace(/Đ/g, 'D');
}

export async function handleRuleBasedBooking(
  userId: string,
  message: string,
  conversationId: string,
): Promise<string | null> {
  const normalizedMsg = message.toLowerCase().trim();
  const noAccentMsg = removeAccents(normalizedMsg);

  // 1. Get history to check if we are in an active booking flow
  const history = await prisma.chatMessage.findMany({
    where: { conversationId },
    orderBy: { createdAt: 'desc' },
    take: 10,
  });

  console.log('--- handleRuleBasedBooking ---');
  console.log('message:', message);
  console.log('normalizedMsg:', normalizedMsg);
  console.log('noAccentMsg:', noAccentMsg);
  console.log('history count:', history.length);
  console.log('history roles & content:', history.map(h => `${h.role}: ${h.content.substring(0, 35)}...`).join(' | '));

  // Check if they want to cancel/reset booking
  if (noAccentMsg === 'huy' || noAccentMsg === 'thoat' || noAccentMsg.includes('huy dat lich')) {
    const isCurrentlyBooking = history.some(m => m.role === 'bot' && m.content.includes('Chọn xe cần sửa chữa') || m.content.includes('Chọn loại dịch vụ') || m.content.includes('Chọn thời gian đặt lịch'));
    if (isCurrentlyBooking) {
      return 'Dạ, mình đã hủy luồng đặt lịch hẹn. Tôi có thể giải đáp thông tin gì khác cho bạn không ạ?';
    }
  }

  // 2. Determine if the user is triggering a new booking flow
  // Fuzzy match: cho phép sai 2-3 ký tự cho các keyword quan trọng
  const hasBookingIntent = fuzzyIncludes(noAccentMsg, 'dat lich', 3)
    || fuzzyIncludes(noAccentMsg, 'hen lich', 3)
    || fuzzyIncludes(noAccentMsg, 'dat hen', 3)
    || fuzzyIncludes(noAccentMsg, 'book lich', 3)
    || noAccentMsg.includes('bao duong xe')
    || noAccentMsg.includes('sua xe')
    || noAccentMsg.includes('bao tri xe')
    || fuzzyIncludes(noAccentMsg, 'dat cho', 3);

  // Find the last bot message
  const lastBotMessage = history.find(m => m.role === 'bot');

  // Check if we are in the middle of a booking flow
  let isBookingFlow = false;
  let currentStep = '';

  if (lastBotMessage) {
    const content = lastBotMessage.content;
    if (content.includes('Chọn xe cần sửa chữa')) {
      isBookingFlow = true;
      currentStep = 'SELECT_VEHICLE';
    } else if (content.includes('Chọn loại dịch vụ')) {
      isBookingFlow = true;
      currentStep = 'SELECT_SERVICE';
    } else if (content.includes('Chọn thời gian đặt lịch')) {
      isBookingFlow = true;
      currentStep = 'SELECT_DATETIME';
    }
  }

  // If not in a booking flow and not a trigger, let Gemini handle it
  if (!isBookingFlow && !hasBookingIntent) {
  return null;
}

  // If it's a trigger, start the flow (Step 1)
  if (hasBookingIntent && !isBookingFlow) {
    const vehicles = await prisma.vehicle.findMany({
      where: { ownerId: userId },
    });

    if (vehicles.length === 0) {
      return 'Bạn chưa có xe máy điện nào đăng ký trên hệ thống. Vui lòng đăng ký xe mới trong ứng dụng hoặc mang xe đến trực tiếp cửa hàng để được hỗ trợ đăng ký nhé.';
    }

    let reply = 'Chào bạn! Mình sẽ hỗ trợ bạn đặt lịch hẹn dịch vụ tại Xanh EV nhé. ✨\n\n👉 **Chọn xe cần sửa chữa**\n';
    reply += 'Vui lòng chọn chiếc xe máy điện cần bảo dưỡng hoặc sửa chữa dưới đây:\n';
    
    const optionsStr = vehicles.map(v => `${v.brand || 'Xe'} ${v.model} (${v.color || ''}) - Biển số: ${v.licensePlate}`).join(' | ');
    reply += `<!-- Options: ${optionsStr} -->`;
    return reply;
  }

  // Process next step in the flow
  if (isBookingFlow) {
    const vehicles = await prisma.vehicle.findMany({
      where: { ownerId: userId },
    });

    if (currentStep === 'SELECT_VEHICLE') {
      let selectedVehicle = null;

      const parsedIdx = parseInt(noAccentMsg);
      if (!isNaN(parsedIdx) && parsedIdx >= 1 && parsedIdx <= vehicles.length) {
        selectedVehicle = vehicles[parsedIdx - 1];
      } else {
        selectedVehicle = vehicles.find(v => 
          noAccentMsg.replace(/[^a-z0-9]/g, '').includes(v.licensePlate.toLowerCase().replace(/[^a-z0-9]/g, '')) ||
          v.licensePlate.toLowerCase().replace(/[^a-z0-9]/g, '').includes(noAccentMsg.replace(/[^a-z0-9]/g, ''))
        );
      }

      if (!selectedVehicle) {
        let reply = 'Dạ, lựa chọn không khớp với danh sách xe. Vui lòng chọn xe của bạn dưới đây nha:\n';
        const optionsStr = vehicles.map(v => `${v.brand || 'Xe'} ${v.model} - ${v.licensePlate}`).join(' | ');
        reply += `<!-- Options: ${optionsStr} -->`;
        return reply;
      }

      let reply = `Dạ, mình đã ghi nhận xe cần đặt lịch: **${selectedVehicle.brand || ''} ${selectedVehicle.model} - Biển số [${selectedVehicle.licensePlate}]** <!-- ID: ${selectedVehicle.id} -->.\n\n`;
      reply += '👉 **Chọn loại dịch vụ**\n';
      reply += 'Bạn muốn thực hiện dịch vụ nào cho chiếc xe này ạ? Vui lòng chọn các gợi ý bên dưới:\n';
      
      const optionsStr = 'Bảo dưỡng định kỳ | Sửa chữa chung | Kiểm tra pin & sạc | Dịch vụ sửa chữa khác';
      reply += `<!-- Options: ${optionsStr} -->`;
      return reply;
    }

    if (currentStep === 'SELECT_SERVICE') {
      const idMatch = lastBotMessage!.content.match(/ID:\s*([a-f0-9\-]+)/i);
      if (!idMatch) {
        return 'Có lỗi xảy ra trong quá trình xử lý lịch hẹn. Vui lòng gõ "đặt lịch" để bắt đầu lại.';
      }
      const vehicleId = idMatch[1];
      const vehicle = vehicles.find(v => v.id === vehicleId);
      if (!vehicle) {
        return 'Không tìm thấy thông tin xe đã chọn. Vui lòng gõ "đặt lịch" để bắt đầu lại.';
      }

      let serviceType = '';
      if (noAccentMsg === '1' || noAccentMsg.includes('bao duong')) {
        serviceType = 'Bảo dưỡng định kỳ';
      } else if (noAccentMsg === '2' || noAccentMsg.includes('sua chua') || noAccentMsg.includes('sua xe')) {
        serviceType = 'Sửa chữa chung';
      } else if (noAccentMsg === '3' || noAccentMsg.includes('pin') || noAccentMsg.includes('sac')) {
        serviceType = 'Kiểm tra pin & sạc';
      } else if (noAccentMsg === '4' || noAccentMsg.includes('khac')) {
        serviceType = 'Khác';
      }

      if (!serviceType) {
        let reply = 'Lựa chọn dịch vụ chưa đúng. Vui lòng chọn loại dịch vụ bạn mong muốn:\n';
        const optionsStr = 'Bảo dưỡng định kỳ | Sửa chữa chung | Kiểm tra pin & sạc | Dịch vụ sửa chữa khác';
        reply += `<!-- Options: ${optionsStr} -->`;
        return reply;
      }

      let reply = `Đã ghi nhận dịch vụ: **${serviceType}** cho xe **${vehicle.brand || ''} ${vehicle.model}** <!-- ID: ${vehicle.id} --> <!-- Service: ${serviceType} -->.\n\n`;
      reply += '👉 **Chọn thời gian đặt lịch**\n';
      reply += 'Bạn vui lòng chọn nhanh khung giờ hoặc nhập thời gian mong muốn mang xe đến (Ví dụ: "mai lúc 14:00"):\n';
      
      const optionsStr = 'Hôm nay lúc 15:00 | Mai lúc 09:00 | Mai lúc 14:30 | Chọn ngày & giờ khác... | Hủy đặt lịch';
      reply += `<!-- Options: ${optionsStr} -->`;
      return reply;
    }

    if (currentStep === 'SELECT_DATETIME') {
      const idMatch = lastBotMessage!.content.match(/ID:\s*([a-f0-9\-]+)/i);
      const serviceMatch = lastBotMessage!.content.match(/Service:\s*(.*?)\s*-->/i);

      if (!idMatch || !serviceMatch) {
        return 'Có lỗi xảy ra trong quá trình xử lý lịch hẹn. Vui lòng gõ "đặt lịch" để bắt đầu lại.';
      }

      const vehicleId = idMatch[1];
      const serviceType = serviceMatch[1].trim();
      const vehicle = vehicles.find(v => v.id === vehicleId);

      if (!vehicle) {
        return 'Không tìm thấy thông tin xe đã chọn. Vui lòng gõ "đặt lịch" để bắt đầu lại.';
      }

      const parsedDate = parseDateTime(normalizedMsg);

      if (!parsedDate) {
        let reply = 'Dạ, mình chưa nhận diện được thời gian bạn nhập. Vui lòng chọn hoặc nhập lại theo mẫu (Ví dụ: "mai lúc 9h30"):\n';
        const optionsStr = 'Hôm nay lúc 15:00 | Mai lúc 09:00 | Mai lúc 14:30 | Chọn ngày & giờ khác... | Hủy đặt lịch';
        reply += `<!-- Options: ${optionsStr} -->`;
        return reply;
      }

      const hours = parsedDate.getHours();
      if (hours < 7 || hours >= 19) {
        let reply = `Khung giờ ${hours.toString().padStart(2, '0')}:${parsedDate.getMinutes().toString().padStart(2, '0')} nằm ngoài giờ mở cửa của cửa hàng (7:00 - 19:00).\nVui lòng chọn hoặc nhập lại khung giờ khác:\n`;
        const optionsStr = 'Hôm nay lúc 15:00 | Mai lúc 09:00 | Mai lúc 14:30 | Chọn ngày & giờ khác... | Hủy đặt lịch';
        reply += `<!-- Options: ${optionsStr} -->`;
        return reply;
      }

      const scheduledAt = parsedDate;
      await prisma.appointment.create({
        data: {
          customerId: userId,
          vehicleId: vehicleId,
          scheduledAt,
          serviceType: serviceType,
          status: 'PENDING',
          notes: 'Đặt lịch tự động qua Chatbot',
        },
      });

      const day = scheduledAt.getDate().toString().padStart(2, '0');
      const month = (scheduledAt.getMonth() + 1).toString().padStart(2, '0');
      const timeStr = `${scheduledAt.getHours().toString().padStart(2, '0')}:${scheduledAt.getMinutes().toString().padStart(2, '0')}`;
      
      let reply = '🎉 **Đặt lịch hẹn thành công rồi ạ!** 🎉\n\n';
      reply += `• **Xe sửa chữa:** ${vehicle.brand || ''} ${vehicle.model} - **${vehicle.licensePlate}**\n`;
      reply += `• **Dịch vụ đăng ký:** ${serviceType}\n`;
      reply += `• **Thời gian hẹn:** ${timeStr} ngày ${day}/${month}/${scheduledAt.getFullYear()}\n`;
      reply += '• **Trạng thái:** Chờ xác nhận ⏳\n\n';
      reply += 'Cửa hàng Xanh EV đã ghi nhận lịch hẹn của bạn và rất hân hạnh được đón tiếp bạn!';
      return reply;
    }
  }

  return null;
}

function parseDateTime(input: string): Date | null {
  const now = new Date();
  const str = input.toLowerCase().trim();
  const noAccentStr = removeAccents(str);

  let baseDate = new Date();
  
  if (noAccentStr.includes('mai')) {
    baseDate.setDate(now.getDate() + 1);
  } else if (noAccentStr.includes('mot') || noAccentStr.includes('ngay kia')) {
    baseDate.setDate(now.getDate() + 2);
  } else if (noAccentStr.includes('hom nay')) {
    baseDate.setDate(now.getDate());
  }

  const timeRegex = /(\d{1,2})[h:](\d{2})/;
  const timeMatch = noAccentStr.match(timeRegex);
  let hours = -1;
  let minutes = -1;
  if (timeMatch) {
    hours = parseInt(timeMatch[1]);
    minutes = parseInt(timeMatch[2]);
  } else {
    const hourRegex = /(\d{1,2})\s*(?:gio|h)/;
    const hourMatch = noAccentStr.match(hourRegex);
    if (hourMatch) {
      hours = parseInt(hourMatch[1]);
      minutes = 0;
    }
  }

  if (hours === -1) return null;

  const dateRegex = /(\d{1,2})[\/\-](\d{1,2})/;
  const dateMatch = noAccentStr.match(dateRegex);

  if (dateMatch) {
    const day = parseInt(dateMatch[1]);
    const month = parseInt(dateMatch[2]) - 1;
    const year = now.getFullYear();
    const parsedDate = new Date(year, month, day, hours, minutes);
    
    if (parsedDate.getTime() < now.getTime() - 24 * 3600 * 1000) {
      parsedDate.setFullYear(year + 1);
    }
    return parsedDate;
  } else if (noAccentStr.includes('mai') || noAccentStr.includes('mot') || noAccentStr.includes('ngay kia') || noAccentStr.includes('hom nay')) {
    const parsedDate = new Date(baseDate.getFullYear(), baseDate.getMonth(), baseDate.getDate(), hours, minutes);
    return parsedDate;
  }

  return null;
}
