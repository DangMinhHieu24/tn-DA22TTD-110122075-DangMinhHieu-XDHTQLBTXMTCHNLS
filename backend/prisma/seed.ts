import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding database...');

  // Clear old work orders and vehicles so seed is deterministic
  await prisma.partsUsed.deleteMany();
  await prisma.inventory.deleteMany();
  await prisma.workOrder.deleteMany();
  await prisma.vehicle.deleteMany();

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
        partName: 'Má phanh trước',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/2/29/Disc_brake_pads.jpg',
        quantity: 25,
        minThreshold: 5,
        unitPrice: 120000,
        sellPrice: 180000,
      },
      {
        partName: 'Lốp sau Michelin City Grip 2',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/2/2d/Tire_2000px.jpg',
        quantity: 12,
        minThreshold: 3,
        unitPrice: 850000,
        sellPrice: 1150000,
      },
      {
        partName: 'Sên xích tải',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/1/1c/Roller_chain.jpg',
        quantity: 30,
        minThreshold: 6,
        unitPrice: 90000,
        sellPrice: 140000,
      },
      {
        partName: 'Bộ pin cell (module)',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/6/6f/18650_cell.jpg',
        quantity: 8,
        minThreshold: 2,
        unitPrice: 650000,
        sellPrice: 900000,
      },
      {
        partName: 'Lọc gió',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/3/3e/Air_filter_closeup.jpg',
        quantity: 18,
        minThreshold: 4,
        unitPrice: 70000,
        sellPrice: 120000,
      },
    ],
  });
  console.log('✅ Inventory items created:', inventoryItems.count);

  const seededParts = await prisma.inventory.findMany({
    where: {
      partName: {
        in: [
          'Má phanh trước',
          'Lốp sau Michelin City Grip 2',
          'Sên xích tải',
          'Bộ pin cell (module)',
          'Lọc gió',
        ],
      },
    },
  });
  const partByName = new Map(seededParts.map((part) => [part.partName, part]));
  const brakePad = partByName.get('Má phanh trước')!;
  const rearTire = partByName.get('Lốp sau Michelin City Grip 2')!;
  const chainKit = partByName.get('Sên xích tải')!;
  const batteryModule = partByName.get('Bộ pin cell (module)')!;
  const airFilter = partByName.get('Lọc gió')!;

  // Create work orders
  const workOrder1 = await prisma.workOrder.create({
    data: {
      orderNumber: 'WO-2026-001',
      vehicleId: vehicle1.id,
      status: 'PENDING',
      priority: 'URGENT',
      notes: 'Khách báo xe sụt pin nhanh khi tăng tốc mạnh. Cần kiểm tra cell pin số 4 và cập nhật phần mềm BMS bản mới nhất.',
      technicianId: technician1.id,
      estimatedHours: 2.5,
      createdById: admin.id,
      services: {
        create: [
          { serviceType: 'BATTERY_CHECK', description: 'Kiểm tra cell pin số 4' },
          { serviceType: 'OTHER_REPAIR', description: 'Cập nhật phần mềm BMS' }
        ]
      },
      photos: {
        create: [
          {
            photoUrl: 'https://upload.wikimedia.org/wikipedia/commons/3/3b/ZEV_2700_electric_motor_scooter.jpg',
            description: 'Anh xe khi nhan xe',
          },
          {
            photoUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/41/EVScooterAtVancouver.jpg',
            description: 'Anh xe mat ben trai',
          },
          {
            photoUrl: 'https://upload.wikimedia.org/wikipedia/commons/d/db/Horwin_CR6_Black_Edition.jpg',
            description: 'Anh xe mat ben phai',
          },
        ],
      },
      partsUsed: {
        create: [
          {
            partId: batteryModule.id,
            quantity: 1,
            unitPrice: batteryModule.sellPrice,
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
      status: 'PENDING',
      priority: 'NORMAL',
      notes: 'Bảo dưỡng mốc 10.000km. Thay má phanh trước, kiểm tra áp suất lốp và tra dầu xích.',
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
            description: 'Anh xe khi nhan xe',
          },
          {
            photoUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/41/EVScooterAtVancouver.jpg',
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
            partId: airFilter.id,
            quantity: 1,
            unitPrice: airFilter.sellPrice,
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
      notes: 'Thay lốp sau Michelin City Grip 2, căn chỉnh lại xích tải. Khách đang đợi tại sảnh.',
      technicianId: technician2.id,
      estimatedHours: 1.0,
      createdById: admin.id,
      services: {
        create: [
          { serviceType: 'BRAKES_TIRES', description: 'Thay lốp sau Michelin City Grip 2' }
        ]
      },
      photos: {
        create: [
          {
            photoUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/41/EVScooterAtVancouver.jpg',
            description: 'Anh xe khi nhan xe',
          },
          {
            photoUrl: 'https://upload.wikimedia.org/wikipedia/commons/3/3b/ZEV_2700_electric_motor_scooter.jpg',
            description: 'Anh xe canh truoc',
          },
        ],
      },
      partsUsed: {
        create: [
          {
            partId: rearTire.id,
            quantity: 1,
            unitPrice: rearTire.sellPrice,
          },
          {
            partId: chainKit.id,
            quantity: 1,
            unitPrice: chainKit.sellPrice,
          },
        ],
      },
    }
  });
  console.log('✅ Work Order 3 created:', workOrder3.orderNumber);

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
