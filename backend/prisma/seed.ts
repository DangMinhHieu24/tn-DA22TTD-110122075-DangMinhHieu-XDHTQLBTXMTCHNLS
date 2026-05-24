import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding database...');

  // Clear old work orders and vehicles so seed is deterministic
  await prisma.maintenanceLog.deleteMany();
  await prisma.warranty.deleteMany();
  await prisma.partsUsed.deleteMany();
  await prisma.inventory.deleteMany();
  await prisma.workOrder.deleteMany();
  await prisma.vehicle.deleteMany();
  await prisma.appointment.deleteMany();

  // Create admin user
  const adminPassword = await bcrypt.hash('admin123', 10);
  const admin = await prisma.user.upsert({
    where: { email: 'admin@gmail.com' },
    update: {},
    create: {
      email: 'admin@gmail.com',
      name: 'Admin User',
      password: adminPassword,
      role: 'ADMIN',
      phoneNumber: '0901234567'
    }
  });
  console.log('✅ Admin user created:', admin.email);

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
      },
      {
        partName: 'BMS 60V 30A',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/1/19/PCB_Macro_2.jpg',
        quantity: 14,
        minThreshold: 3,
        unitPrice: 450000,
        sellPrice: 650000,
      },
      {
        partName: 'Sạc 60V 5A',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/6/6a/Power_adapter.jpg',
        quantity: 16,
        minThreshold: 4,
        unitPrice: 520000,
        sellPrice: 720000,
      },
      {
        partName: 'Động cơ hub 1500W',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/4d/Hub_motor.jpg',
        quantity: 6,
        minThreshold: 1,
        unitPrice: 2800000,
        sellPrice: 3500000,
      },
      {
        partName: 'Bộ điều khiển 60V 35A',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/46/Motor_controller.jpg',
        quantity: 9,
        minThreshold: 2,
        unitPrice: 900000,
        sellPrice: 1200000,
      },
      {
        partName: 'Tay ga điện (Hall)',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/2/23/Throttle.jpg',
        quantity: 25,
        minThreshold: 6,
        unitPrice: 90000,
        sellPrice: 150000,
      },
      {
        partName: 'Má phanh trước (đĩa)',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/2/29/Disc_brake_pads.jpg',
        quantity: 30,
        minThreshold: 6,
        unitPrice: 120000,
        sellPrice: 180000,
      },
      {
        partName: 'Đĩa phanh trước 220mm',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/6/67/Brake_disc.jpg',
        quantity: 12,
        minThreshold: 3,
        unitPrice: 180000,
        sellPrice: 260000,
      },
      {
        partName: 'Lốp không săm 90/90-12',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/2/2d/Tire_2000px.jpg',
        quantity: 18,
        minThreshold: 4,
        unitPrice: 650000,
        sellPrice: 900000,
      },
      {
        partName: 'Cảm biến phanh (cut-off)',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/8/87/Brake_lever.jpg',
        quantity: 20,
        minThreshold: 5,
        unitPrice: 60000,
        sellPrice: 120000,
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

  // Create work orders
  const workOrder1 = await prisma.workOrder.create({
    data: {
      orderNumber: 'WO-2026-001',
      vehicleId: vehicle1.id,
      status: 'PENDING',
      priority: 'URGENT',
      notes: 'Khách báo xe sụt pin nhanh khi tăng tốc mạnh. Cần kiểm tra pack pin và cập nhật cấu hình BMS.',
      technicianId: technician1.id,
      estimatedHours: 2.5,
      createdById: admin.id,
      services: {
        create: [
          { serviceType: 'BATTERY_CHECK', description: 'Kiểm tra pack pin và BMS' },
          { serviceType: 'OTHER_REPAIR', description: 'Cập nhật cấu hình BMS' }
        ]
      },
      photos: {
        create: [
          {
            photoUrl: 'https://upload.wikimedia.org/wikipedia/commons/3/3b/ZEV_2700_electric_motor_scooter.jpg',
            photoType: 'INTAKE',
            description: 'Anh xe khi nhan xe',
          },
          {
            photoUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/41/EVScooterAtVancouver.jpg',
            photoType: 'INTAKE',
            description: 'Anh xe mat ben trai',
          },
          {
            photoUrl: 'https://upload.wikimedia.org/wikipedia/commons/d/db/Horwin_CR6_Black_Edition.jpg',
            photoType: 'AFTER_REPAIR',
            description: 'Anh xe sau khi kiem tra xong',
          },
          {
            photoUrl: 'https://upload.wikimedia.org/wikipedia/commons/2/2f/Motor_scooter_in_an_auto_shop.jpg',
            photoType: 'AFTER_REPAIR',
            description: 'Anh xe mat ben phai',
          },
        ],
      },
      partsUsed: {
        create: [
          {
            partId: bms.id,
            quantity: 1,
            unitPrice: bms.sellPrice,
          },
        ],
      },
    }
  });
  console.log('✅ Work Order 1 created:', workOrder1.orderNumber);

  const workOrder2 = await prisma.workOrder.create({
    data: {
      orderNumber: 'WO-2026-002',
      vehicleId: vehicle2.id,
      status: 'INSPECTION',
      priority: 'NORMAL',
      notes: 'Bảo dưỡng mốc 10.000km. Thay má phanh trước, kiểm tra áp suất lốp và kiểm tra sạc.',
      technicianId: technician1.id,
      estimatedHours: 1.5,
      scheduledTime: '14:00',
      createdById: admin.id,
      services: {
        create: [
          { serviceType: 'MAINTENANCE', description: 'Bảo dưỡng định kỳ 10.000km' },
          { serviceType: 'BRAKES_TIRES', description: 'Thay má phanh trước' }
        ]
      },
      photos: {
        create: [
          {
            photoUrl: 'https://upload.wikimedia.org/wikipedia/commons/d/db/Horwin_CR6_Black_Edition.jpg',
            photoType: 'INTAKE',
            description: 'Anh xe khi nhan xe',
          },
          {
            photoUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/41/EVScooterAtVancouver.jpg',
            photoType: 'AFTER_REPAIR',
            description: 'Anh xe canh sau',
          },
        ],
      },
      partsUsed: {
        create: [
          {
            partId: brakePad.id,
            quantity: 1,
            unitPrice: brakePad.sellPrice,
          },
          {
            partId: charger.id,
            quantity: 1,
            unitPrice: charger.sellPrice,
          },
        ],
      },
    }
  });
  console.log('✅ Work Order 2 created:', workOrder2.orderNumber);

  const workOrder3 = await prisma.workOrder.create({
    data: {
      orderNumber: 'WO-2026-003',
      vehicleId: vehicle3.id,
      status: 'IN_PROGRESS',
      priority: 'NORMAL',
      notes: 'Thay lốp không săm, kiểm tra và căn chỉnh đĩa phanh. Khách đang đợi tại sảnh.',
      technicianId: technician2.id,
      estimatedHours: 1.0,
      createdById: admin.id,
      services: {
        create: [
          { serviceType: 'BRAKES_TIRES', description: 'Thay lốp không săm 90/90-12' }
        ]
      },
      photos: {
        create: [
          {
            photoUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/41/EVScooterAtVancouver.jpg',
            photoType: 'INTAKE',
            description: 'Anh xe khi nhan xe',
          },
          {
            photoUrl: 'https://upload.wikimedia.org/wikipedia/commons/3/3b/ZEV_2700_electric_motor_scooter.jpg',
            photoType: 'AFTER_REPAIR',
            description: 'Anh xe canh truoc',
          },
        ],
      },
      partsUsed: {
        create: [
          {
            partId: tire.id,
            quantity: 1,
            unitPrice: tire.sellPrice,
          },
          {
            partId: brakeDisc.id,
            quantity: 1,
            unitPrice: brakeDisc.sellPrice,
          },
        ],
      },
    }
  });
  console.log('✅ Work Order 3 created:', workOrder3.orderNumber);

  const maintenanceLogs = await prisma.maintenanceLog.createMany({
    data: [
      {
        vehicleId: vehicle1.id,
        odometerKm: 3800,
        serviceType: 'MAINTENANCE',
        serviceSummary: 'Bảo dưỡng định kỳ 5.000km',
        notes: 'Kiểm tra tổng quát, siết lại đầu cos pin, vệ sinh dàn điện.',
        performedAt: new Date('2025-03-12T08:30:00.000Z'),
        nextServiceKm: 5800,
      },
      {
        vehicleId: vehicle1.id,
        odometerKm: 4950,
        serviceType: 'BATTERY_CHECK',
        serviceSummary: 'Kiểm tra pack pin và BMS',
        notes: 'Đã hiệu chỉnh cấu hình BMS và kiểm tra dung lượng pin.',
        performedAt: new Date('2025-05-10T09:00:00.000Z'),
        nextServiceKm: 5950,
      },
      {
        vehicleId: vehicle2.id,
        odometerKm: 9800,
        serviceType: 'BRAKES_TIRES',
        serviceSummary: 'Thay má phanh trước, kiểm tra lốp',
        notes: 'Thay má phanh trước và kiểm tra áp suất lốp.',
        performedAt: new Date('2025-06-18T10:15:00.000Z'),
        nextServiceKm: 10800,
      },
      {
        vehicleId: vehicle3.id,
        odometerKm: 14500,
        serviceType: 'OTHER_REPAIR',
        serviceSummary: 'Căn chỉnh đĩa phanh, kiểm tra lốp',
        notes: 'Cân chỉnh lại hệ thống phanh và thay lốp không săm.',
        performedAt: new Date('2025-07-22T13:45:00.000Z'),
        nextServiceKm: 15500,
      },
    ],
  });
  console.log('✅ Maintenance logs created:', maintenanceLogs.count);

  console.log('🎉 Seeding completed!');
}

main()
  .catch((e) => {
    console.error('❌ Seeding error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
