import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('\n=== ALL APPOINTMENTS (all rows) ===');
  const appointments = await prisma.appointment.findMany({
    orderBy: { scheduledAt: 'asc' },
    include: {
      customer: { select: { name: true, email: true } },
    },
  });

  if (appointments.length === 0) {
    console.log('❌ No appointments found in database!');
  } else {
    console.log(`✅ Found ${appointments.length} appointment(s):`);
    appointments.forEach(a => {
      console.log({
        id: a.id,
        customer: a.customer?.name,
        customerId: a.customerId,
        scheduledAt_UTC: a.scheduledAt.toISOString(),
        scheduledAt_VN: a.scheduledAt.toLocaleString('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh' }),
        status: a.status,
        serviceType: a.serviceType,
      });
    });
  }

  // Test filter for today
  const today = '2026-06-07';
  const VN_OFFSET_MS = 7 * 60 * 60 * 1000;
  const [year, month, day] = today.split('-').map(Number);
  const startOfDayVN = new Date(Date.UTC(year, month - 1, day, 0, 0, 0, 0) - VN_OFFSET_MS);
  const endOfDayVN = new Date(Date.UTC(year, month - 1, day, 23, 59, 59, 999) - VN_OFFSET_MS);

  console.log('\n=== FILTER TEST for date=2026-06-07 (VN) ===');
  console.log('startOfDayVN (UTC):', startOfDayVN.toISOString());
  console.log('endOfDayVN   (UTC):', endOfDayVN.toISOString());

  const filtered = await prisma.appointment.findMany({
    where: {
      scheduledAt: { gte: startOfDayVN, lte: endOfDayVN },
    },
  });
  console.log('Appointments matching today filter:', filtered.length);

  // Also try wider range - all appointments in June 2026
  const juneStart = new Date('2026-06-01T00:00:00.000Z');
  const juneEnd = new Date('2026-06-30T23:59:59.999Z');
  const juneFiltered = await prisma.appointment.findMany({
    where: {
      scheduledAt: { gte: juneStart, lte: juneEnd },
    },
  });
  console.log('Appointments in June 2026 (UTC):', juneFiltered.length);

  await prisma.$disconnect();
}

main().catch(e => { console.error(e); process.exit(1); });
