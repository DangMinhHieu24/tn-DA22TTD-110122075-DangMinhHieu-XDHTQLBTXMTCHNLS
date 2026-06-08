import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  // All 4 appointments have scheduledAt that was stored wrong (server treated local datetime string as UTC)
  // The user was in VN (UTC+7), so the actual intended VN times are 7 hours AHEAD of what's stored
  // Example: stored "2026-06-08T00:00:00Z" should be "2026-06-07T17:00:00Z" (= 00:00 VN time)
  // Actually wait - if user picked 7:00 VN on 8/6, Flutter sent "2026-06-08T07:00:00.000" 
  // Node.js on UTC machine → stored as 2026-06-08T07:00:00Z
  // But the user INTENDED 2026-06-08T07:00:00+07:00 = 2026-06-08T00:00:00Z
  //
  // So stored = intended_UTC + 7h → we need to subtract 7h

  console.log('=== BEFORE FIX ===');
  const before = await prisma.appointment.findMany({ orderBy: { scheduledAt: 'asc' } });
  before.forEach(a => console.log(a.id.substring(0,8), a.scheduledAt.toISOString(), '=', a.scheduledAt.toLocaleString('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh' }), 'VN'));

  // Fix: subtract 7 hours from each appointment's scheduledAt
  const VN_OFFSET_MS = 7 * 60 * 60 * 1000;
  for (const a of before) {
    const corrected = new Date(a.scheduledAt.getTime() - VN_OFFSET_MS);
    await prisma.appointment.update({
      where: { id: a.id },
      data: { scheduledAt: corrected },
    });
    console.log(`Fixed ${a.id.substring(0,8)}: ${a.scheduledAt.toISOString()} → ${corrected.toISOString()} (${corrected.toLocaleString('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh' })} VN)`);
  }

  console.log('\n=== AFTER FIX ===');
  const after = await prisma.appointment.findMany({ orderBy: { scheduledAt: 'asc' } });
  after.forEach(a => console.log(a.id.substring(0,8), a.scheduledAt.toISOString(), '=', a.scheduledAt.toLocaleString('vi-VN', { timeZone: 'Asia/Ho_Chi_Minh' }), 'VN'));

  await prisma.$disconnect();
}

main().catch(e => { console.error(e); process.exit(1); });
