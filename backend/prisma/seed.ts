// @ts-nocheck
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

const roundMoney = (value: number) => Math.round(value / 1000) * 1000;

const buildPhotos = (label: string, index: number) => {
  const photos = [
    'https://upload.wikimedia.org/wikipedia/commons/4/41/EVScooterAtVancouver.jpg',
    'https://upload.wikimedia.org/wikipedia/commons/3/3b/ZEV_2700_electric_motor_scooter.jpg',
    'https://upload.wikimedia.org/wikipedia/commons/d/db/Horwin_CR6_Black_Edition.jpg',
    'https://upload.wikimedia.org/wikipedia/commons/2/2f/Motor_scooter_in_an_auto_shop.jpg',
  ];

  return [
    {
      photoUrl: photos[index % photos.length],
      photoType: 'INTAKE',
      description: `Ảnh tiếp nhận - ${label}`,
    },
    {
      photoUrl: photos[(index + 1) % photos.length],
      photoType: 'AFTER_REPAIR',
      description: `Ảnh hoàn tất - ${label}`,
    },
  ];
};
async function main() {
  console.log('🌱 Seeding database...');

  // Clear old data so seed is deterministic
  await prisma.maintenanceLog.deleteMany();
  await prisma.warranty.deleteMany();
  await prisma.partsUsed.deleteMany();
  await prisma.inventory.deleteMany();
  await prisma.workOrder.deleteMany();
  await prisma.vehicle.deleteMany();
  await prisma.appointment.deleteMany();
  await prisma.user.deleteMany();

  // Create admin user
  const adminPassword = await bcrypt.hash('staff123', 10);
  const admin = await prisma.user.upsert({
    where: { email: 'staff' },
    update: {},
    create: {
      email: 'staff',
      name: 'Nhân viên',
      password: adminPassword,
      role: 'STAFF',
      phoneNumber: '0901234567'
    }
  });
  console.log('✅ Staff user created:', admin.email);

  // Create technician users
  const techPassword = await bcrypt.hash('tech123', 10);
  const technician1 = await prisma.user.upsert({
    where: { email: 'tech@gmail.com' },
    update: {},
    create: {
      email: 'tech@gmail.com',
      name: 'Trần Văn Bình',
      password: techPassword,
      role: 'TECHNICIAN',
      phoneNumber: '0907654321'
    }
  });
  console.log('✅ Technician 1 created:', technician1.email);

  const technician2 = await prisma.user.upsert({
    where: { email: 'tech2@gmail.com' },
    update: {},
    create: {
      email: 'tech2@gmail.com',
      name: 'Lê Quang Cường',
      password: techPassword,
      role: 'TECHNICIAN',
      phoneNumber: '0907654322'
    }
  });
  console.log('✅ Technician 2 created:', technician2.email);

  // Create customer users
  const customerPassword = await bcrypt.hash('customer123', 10);
  const customer1 = await prisma.user.upsert({
    where: { email: 'customer@gmail.com' },
    update: {},
    create: {
      email: 'customer@gmail.com',
      name: 'Nguyễn Văn A',
      password: customerPassword,
      role: 'CUSTOMER',
      phoneNumber: '0909876543'
    }
  });
  console.log('✅ Customer 1 created:', customer1.email);

  const customer2 = await prisma.user.upsert({
    where: { email: 'customer2@gmail.com' },
    update: {},
    create: {
      email: 'customer2@gmail.com',
      name: 'Trần Văn B',
      password: customerPassword,
      role: 'CUSTOMER',
      phoneNumber: '0909876544'
    }
  });
  console.log('✅ Customer 2 created:', customer2.email);

  const customer3 = await prisma.user.upsert({
    where: { email: 'customer3@gmail.com' },
    update: {},
    create: {
      email: 'customer3@gmail.com',
      name: 'Lê Thị C',
      password: customerPassword,
      role: 'CUSTOMER',
      phoneNumber: '0909876545'
    }
  });
  console.log('✅ Customer 3 created:', customer3.email);

  // Create vehicles
  const vehicle1 = await prisma.vehicle.create({
    data: {
      licensePlate: '29A-123.45',
      model: 'VinFast Klara S',
      color: 'Trắng ngọc trai',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/41/EVScooterAtVancouver.jpg',
      warrantyExpiry: new Date('2025-12-31T23:59:59.000Z'),
      currentKm: 5000,
      ownerId: customer1.id
    }
  });
  console.log('✅ Vehicle 1 created:', vehicle1.licensePlate);

  const vehicle2 = await prisma.vehicle.create({
    data: {
      licensePlate: '30G-789.01',
      model: 'VinFast Feliz S',
      color: 'Đỏ',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/3/3b/ZEV_2700_electric_motor_scooter.jpg',
      warrantyExpiry: new Date('2025-12-31T23:59:59.000Z'),
      currentKm: 10000,
      ownerId: customer2.id
    }
  });
  console.log('✅ Vehicle 2 created:', vehicle2.licensePlate);

  const vehicle3 = await prisma.vehicle.create({
    data: {
      licensePlate: '51H-456.78',
      model: 'Dat Bike Weaver 200',
      color: 'Xanh dương',
      imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/d/db/Horwin_CR6_Black_Edition.jpg',
      warrantyExpiry: null,
      currentKm: 15000,
      ownerId: customer3.id
    }
  });
  console.log('✅ Vehicle 3 created:', vehicle3.licensePlate);

  // Create inventory parts
  const inventoryItems = await prisma.inventory.createMany({
    data: [
      {
        partName: 'Pin Li-ion 60V 20Ah (pack)',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/6/6f/18650_cell.jpg',
        quantity: 10,
        minThreshold: 2,
        unitPrice: 4200000,
        sellPrice: 5200000,
        warrantyDays: 365,
      },
      {
        partName: 'BMS 60V 30A',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/1/19/PCB_Macro_2.jpg',
        quantity: 14,
        minThreshold: 3,
        unitPrice: 450000,
        sellPrice: 650000,
        warrantyDays: 180,
      },
      {
        partName: 'Sạc 60V 5A',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/6/6a/Power_adapter.jpg',
        quantity: 16,
        minThreshold: 4,
        unitPrice: 520000,
        sellPrice: 720000,
        warrantyDays: 180,
      },
      {
        partName: 'Động cơ hub 1500W',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/4d/Hub_motor.jpg',
        quantity: 6,
        minThreshold: 1,
        unitPrice: 2800000,
        sellPrice: 3500000,
        warrantyDays: 365,
      },
      {
        partName: 'Bộ điều khiển 60V 35A',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/46/Motor_controller.jpg',
        quantity: 9,
        minThreshold: 2,
        unitPrice: 900000,
        sellPrice: 1200000,
        warrantyDays: 180,
      },
      {
        partName: 'Tay ga điện (Hall)',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/2/23/Throttle.jpg',
        quantity: 25,
        minThreshold: 6,
        unitPrice: 90000,
        sellPrice: 150000,
        warrantyDays: 90,
      },
      {
        partName: 'Má phanh trước (đĩa)',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/2/29/Disc_brake_pads.jpg',
        quantity: 30,
        minThreshold: 6,
        unitPrice: 120000,
        sellPrice: 180000,
        warrantyDays: 90,
      },
      {
        partName: 'Đĩa phanh trước 220mm',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/6/67/Brake_disc.jpg',
        quantity: 12,
        minThreshold: 3,
        unitPrice: 180000,
        sellPrice: 260000,
        warrantyDays: 90,
      },
      {
        partName: 'Lốp không săm 90/90-12',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/2/2d/Tire_2000px.jpg',
        quantity: 18,
        minThreshold: 4,
        unitPrice: 650000,
        sellPrice: 900000,
        warrantyDays: 180,
      },
      {
        partName: 'Cảm biến phanh (cut-off)',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/8/87/Brake_lever.jpg',
        quantity: 20,
        minThreshold: 5,
        unitPrice: 60000,
        sellPrice: 120000,
        warrantyDays: 90,
      },
    ],
  });
  console.log('✅ Inventory items created:', inventoryItems.count);

  const seededParts = await prisma.inventory.findMany({
    where: {
      partName: {
        in: [
          'Pin Li-ion 60V 20Ah (pack)',
          'BMS 60V 30A',
          'Sạc 60V 5A',
          'Bộ điều khiển 60V 35A',
          'Tay ga điện (Hall)',
          'Cảm biến phanh (cut-off)',
          'Má phanh trước (đĩa)',
          'Đĩa phanh trước 220mm',
          'Lốp không săm 90/90-12',
        ],
      },
    },
  });
  const partByName = new Map(seededParts.map((part) => [part.partName, part]));
  const brakePad = partByName.get('Má phanh trước (đĩa)')!;
  const brakeDisc = partByName.get('Đĩa phanh trước 220mm')!;
  const tire = partByName.get('Lốp không săm 90/90-12')!;
  const batteryPack = partByName.get('Pin Li-ion 60V 20Ah (pack)')!;
  const bms = partByName.get('BMS 60V 30A')!;
  const charger = partByName.get('Sạc 60V 5A')!;
  const controller = partByName.get('Bộ điều khiển 60V 35A')!;
  const throttle = partByName.get('Tay ga điện (Hall)')!;
  const brakeSensor = partByName.get('Cảm biến phanh (cut-off)')!;

  // Map vehicles to their owners
  const ownerByVehicle = new Map([
    [vehicle1.id, customer1],
    [vehicle2.id, customer2],
    [vehicle3.id, customer3],
  ]);

  // ─────────────────────────────────────────────────────────────
  // Generate realistic completed work orders from today going back
  // ─────────────────────────────────────────────────────────────
  const now = new Date();
  const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const totalCompletedOrders = 30; // 30 completed orders spread over ~60 days

  // Generate completion dates going back from yesterday, spread over 60 days
  const completedDates: Date[] = [];
  const past60Days = 60;
  for (let i = 0; i < totalCompletedOrders; i++) {
    const dayOffset = past60Days - Math.round((past60Days * i) / (totalCompletedOrders - 1));
    const date = new Date(todayStart);
    date.setDate(date.getDate() - dayOffset);
    const hours = [8, 9, 10, 11, 13, 14, 15, 16][i % 8];
    const minutes = [0, 15, 30, 45, 10, 25, 40, 50][i % 8];
    date.setHours(hours, minutes, 0, 0);
    completedDates.push(date);
  }

  const vehicles = [vehicle1, vehicle2, vehicle3];
  const techs = [technician1, technician2];
  const serviceTypes = ['MAINTENANCE', 'BATTERY_CHECK', 'BRAKES_TIRES', 'OTHER_REPAIR'];
  const basePrices = [150000, 170000, 200000, 220000, 250000, 300000];

  // Realistic service scenarios
  const serviceScenarios = [
    { type: 'MAINTENANCE', name: 'Bảo dưỡng định kỳ 5.000km', parts: [], techNote: 'Đã thay dầu nhớt, vệ sinh lọc gió, kiểm tra hệ thống phanh và đèn. Xe hoạt động ổn định.' },
    { type: 'BATTERY_CHECK', name: 'Kiểm tra pin & BMS', parts: [], techNote: 'Đã kiểm tra pin, BMS hoạt động bình thường, điện áp các cell đạt chuẩn, sạc đầy 100%.' },
    { type: 'BRAKES_TIRES', name: 'Thay má phanh trước', parts: ['brakePad'], techNote: 'Đã thay má phanh trước mới, vệ sinh đĩa phanh, kiểm tra dầu phanh. Phanh ăn tốt.' },
    { type: 'BRAKES_TIRES', name: 'Thay lốp không săm', parts: ['tire'], techNote: 'Đã thay lốp không săm mới, cân chỉnh áp suất 2.2 kg/cm², kiểm tra van và vành.' },
    { type: 'BRAKES_TIRES', name: 'Thay má phanh + đĩa phanh', parts: ['brakePad', 'brakeDisc'], techNote: 'Đã thay má phanh và đĩa phanh trước mới, căn chỉnh kẹp phanh, kiểm tra dầu.' },
    { type: 'OTHER_REPAIR', name: 'Thay pin Li-ion 60V', parts: ['batteryPack'], techNote: 'Đã thay pin Li-ion 60V 20Ah mới, kiểm tra BMS tương thích, sạc thử đạt 100%.' },
    { type: 'OTHER_REPAIR', name: 'Thay BMS 60V 30A', parts: ['bms'], techNote: 'Đã thay BMS 60V 30A mới, cân bằng cell, kiểm tra dòng sạc/xả bình thường.' },
    { type: 'MAINTENANCE', name: 'Bảo dưỡng + kiểm tra sạc', parts: ['charger'], techNote: 'Đã bảo dưỡng định kỳ, thay sạc mới 60V 5A, kiểm tra dòng sạc đạt chuẩn.' },
    { type: 'BATTERY_CHECK', name: 'Kiểm tra pin + thay BMS', parts: ['bms'], techNote: 'Đã thay BMS mới, kiểm tra pin vẫn còn tốt, sạc đầy và xả kiểm tra.' },
    { type: 'OTHER_REPAIR', name: 'Thay bộ điều khiển 60V', parts: ['controller'], techNote: 'Đã thay bộ điều khiển 60V 35A mới, lập trình lại thông số, chạy thử xe ổn định.' },
    { type: 'OTHER_REPAIR', name: 'Sửa chữa hệ thống phanh', parts: ['brakePad', 'brakeSensor'], techNote: 'Đã thay má phanh và cảm biến phanh mới, kiểm tra công tắc cut-off hoạt động tốt.' },
    { type: 'BRAKES_TIRES', name: 'Thay lốp + má phanh', parts: ['tire', 'brakePad'], techNote: 'Đã thay lốp sau mới và má phanh trước, kiểm tra hệ thống phanh an toàn.' },
    { type: 'OTHER_REPAIR', name: 'Thay tay ga điện', parts: ['throttle'], techNote: 'Đã thay tay ga điện (Hall) mới, hiệu chuẩn tín hiệu, chạy thử xe êm và nhạy.' },
    { type: 'MAINTENANCE', name: 'Bảo dưỡng tổng quát', parts: [], techNote: 'Đã kiểm tra toàn bộ xe: pin, động cơ, phanh, lốp, đèn. Xe đạt tiêu chuẩn vận hành.' },
    { type: 'OTHER_REPAIR', name: 'Thay pin + BMS + sạc', parts: ['batteryPack', 'bms', 'charger'], techNote: 'Đã thay pin Li-ion mới kèm BMS và sạc, kiểm tra lần cuối tất cả thông số, xe vận hành tốt.' },
    { type: 'BRAKES_TIRES', name: 'Thay đĩa phanh + lốp', parts: ['brakeDisc', 'tire'], techNote: 'Đã thay đĩa phanh trước và lốp sau mới, kiểm tra độ mòn và áp suất đạt chuẩn.' },
  ];

  const partMap: Record<string, any> = {
    brakePad, brakeDisc, tire, batteryPack, bms, charger, controller, throttle, brakeSensor,
  };

  let orderIndex = 1;

  for (let i = 0; i < completedDates.length; i++) {
    const completedAt = completedDates[i];
    const vehicle = vehicles[i % vehicles.length];
    const tech = techs[i % techs.length];
    const scenario = serviceScenarios[i % serviceScenarios.length];
    const svcType = scenario.type;
    const svcName = scenario.name;
    const servicePrice = basePrices[i % basePrices.length];

    // Appointment 1-3 days before the work order
    const appointmentDate = new Date(completedAt);
    appointmentDate.setDate(appointmentDate.getDate() - (1 + (i % 3)));
    appointmentDate.setHours([9, 10, 11, 14, 15, 16][i % 6], [0, 30][i % 2], 0, 0);

    // Work order created at check-in time (morning of completion day)
    const createdAt = new Date(completedAt);
    createdAt.setHours(createdAt.getHours() - 2 - (i % 3));

    // Appointment notes based on service
    const appointmentNotes = svcType === 'MAINTENANCE'
      ? `${svcName} - Xe chạy ${(vehicle.currentKm ?? 5000) + i * 120}km`
      : svcType === 'BATTERY_CHECK'
        ? `${svcName} - Pin yếu, sạc không đầy`
        : svcType === 'BRAKES_TIRES'
          ? `${svcName} - Phanh kêu, lốp mòn`
          : `${svcName} - Xe có tiếng lạ, cần kiểm tra`;

    // Create appointment (past, so CONFIRMED)
    const owner = ownerByVehicle.get(vehicle.id)!;
    await prisma.appointment.create({
      data: {
        customerId: owner.id,
        vehicleId: vehicle.id,
        scheduledAt: appointmentDate,
        serviceType: svcType,
        notes: appointmentNotes,
        status: 'CONFIRMED',
      },
    });

    // Parts selection based on scenario
    const partsUsedList: any[] = [];
    for (const partKey of scenario.parts) {
      const part = partMap[partKey];
      if (part) {
        partsUsedList.push({ partId: part.id, quantity: 1, unitPrice: part.sellPrice });
      }
    }

    const partsTotal = partsUsedList.reduce((s, p) => s + (p.quantity * p.unitPrice), 0);
    const totalPrice = roundMoney(partsTotal + servicePrice);
    const estimatedHours = 1 + (i % 4) * 0.5;
    const expectedHour = (createdAt.getHours() + Math.ceil(estimatedHours)) % 24;

    // Determine status: 80% PAID, 20% COMPLETED
    const isPaid = i % 5 !== 0; // 80% paid
    const status = isPaid ? 'PAID' : 'COMPLETED';
    const paidAt = isPaid ? new Date(completedAt.getTime() + (30 + (i % 4) * 15) * 60 * 1000) : null; // paid 30-75 min after completion

    const workOrder = await prisma.workOrder.create({
      data: {
        orderNumber: `WO-${new Date().getFullYear()}-${String(orderIndex).padStart(3, '0')}`,
        vehicleId: vehicle.id,
        status,
        notes: scenario.techNote,
        technicianId: tech.id,
        estimatedHours,
        scheduledTime: `${expectedHour}:00`,
        totalPrice,
        createdAt,
        completedAt,
        paidAt,
        createdById: admin.id,
        services: {
          create: [
            {
              serviceType: svcType,
              serviceName: svcName,
              description: svcName,
              price: servicePrice,
              isDone: true,
              approvalStatus: 'APPROVED',
            },
          ],
        },
        photos: { create: buildPhotos(svcName, i) },
        partsUsed: { create: partsUsedList.map((p) => ({ partId: p.partId, quantity: p.quantity, unitPrice: p.unitPrice })) },
      },
    });

    // bump vehicle km
    const kmIncrease = 80 + (i % 5) * 40;
    await prisma.vehicle.update({
      where: { id: vehicle.id },
      data: { currentKm: { increment: kmIncrease } },
    });

    await prisma.maintenanceLog.create({
      data: {
        vehicleId: vehicle.id,
        workOrderId: workOrder.id,
        odometerKm: (vehicle.currentKm ?? 5000) + kmIncrease,
        serviceType: svcType,
        serviceSummary: svcName,
        notes: `Seed: ${svcName} - ${vehicle.licensePlate}`,
        performedAt: completedAt,
        nextServiceKm: (vehicle.currentKm ?? 5000) + kmIncrease + 800,
      },
    });

    // Create PartWarranty records for parts with warranty
    const createdPartsUsed = await prisma.partsUsed.findMany({
      where: { workOrderId: workOrder.id },
      include: { part: { select: { warrantyDays: true } } },
    });
    for (const pu of createdPartsUsed) {
      if (pu.part.warrantyDays > 0) {
        const expiryDate = new Date(completedAt.getTime() + pu.part.warrantyDays * 24 * 60 * 60 * 1000);
        await prisma.partWarranty.create({
          data: {
            partUsedId: pu.id,
            partId: pu.partId,
            workOrderId: workOrder.id,
            vehicleId: vehicle.id,
            warrantyDays: pu.part.warrantyDays,
            startDate: completedAt,
            expiryDate,
          },
        });
      }
    }

    // Update vehicle warranty expiry to the latest expiry date among all part warranties
    const maxExpiry = await prisma.partWarranty.aggregate({
      where: { vehicleId: vehicle.id },
      _max: { expiryDate: true },
    });
    if (maxExpiry._max.expiryDate) {
      await prisma.vehicle.update({
        where: { id: vehicle.id },
        data: { warrantyExpiry: maxExpiry._max.expiryDate },
      });
    }

    // Loyalty: 1 tree per order + 1 per 500k, points = floor(totalPrice / 2000)
    const pointsToAward = Math.floor(totalPrice / 2000);
    const extraTrees = Math.floor(totalPrice / 500000);
    if (pointsToAward > 0) {
      await prisma.user.update({
        where: { id: owner.id },
        data: {
          loyaltyPoints: { increment: pointsToAward },
          treesPlanted: { increment: 1 + extraTrees },
        },
      });
    }

    orderIndex += 1;
    console.log(`✅ #${orderIndex - 1}: ${workOrder.orderNumber} — ${svcName} (${status})`);
  }

  // ─────────────────────────────────────────────────────────────
  // Active orders — created today (PENDING / IN_PROGRESS / INSPECTION)
  // ─────────────────────────────────────────────────────────────
  const activeStatuses = ['PENDING', 'INSPECTION', 'IN_PROGRESS', 'PENDING', 'INSPECTION', 'IN_PROGRESS'];
  const techActive = [technician1, technician2, technician1, technician2, technician1, technician2];
  for (let j = 0; j < 6; j++) {
    const vehicle = vehicles[j % vehicles.length];
    const tech = techActive[j];
    const status = activeStatuses[j];
    const svcType = serviceTypes[j % serviceTypes.length];
    const svcName = svcType === 'MAINTENANCE' ? 'Bảo dưỡng định kỳ' : svcType === 'BATTERY_CHECK' ? 'Kiểm tra pin/BMS' : svcType === 'BRAKES_TIRES' ? 'Thay phanh & lốp' : 'Sửa chữa khác';
    const createdAt = new Date();

    // Create appointment for today/tomorrow
    const aptDate = new Date(todayStart);
    aptDate.setDate(aptDate.getDate() + j);
    aptDate.setHours(9 + j, 0, 0, 0);

    const owner = ownerByVehicle.get(vehicle.id)!;
    await prisma.appointment.create({
      data: {
        customerId: owner.id,
        vehicleId: vehicle.id,
        scheduledAt: aptDate,
        serviceType: svcType,
        notes: `${svcName} - Lịch hẹn online`,
        status: j < 2 ? 'CONFIRMED' : 'PENDING',
      },
    });

    const workOrder = await prisma.workOrder.create({
      data: {
        orderNumber: `WO-${new Date().getFullYear()}-${String(orderIndex).padStart(3, '0')}`,
        vehicleId: vehicle.id,
        status,
        notes: `${svcName} - ${vehicle.licensePlate}`,
        technicianId: tech.id,
        estimatedHours: 1.5,
        createdAt,
        createdById: admin.id,
        services: { create: [{ serviceType: svcType, serviceName: svcName, description: svcName, price: basePrices[j % basePrices.length], approvalStatus: 'APPROVED' }] },
      },
    });

    orderIndex += 1;
    console.log(`✅ #${orderIndex - 1}: ${workOrder.orderNumber} — ${svcName} (${status})`);
  }

  console.log('🎉 Seeding completed!');

}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
