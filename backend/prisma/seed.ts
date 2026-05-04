import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding database...');

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
      warrantyStatus: true,
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
      warrantyStatus: true,
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
      warrantyStatus: false,
      currentKm: 15000,
      ownerId: customer3.id
    }
  });
  console.log('✅ Vehicle 3 created:', vehicle3.licensePlate);

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
      }
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
      }
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
      }
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
