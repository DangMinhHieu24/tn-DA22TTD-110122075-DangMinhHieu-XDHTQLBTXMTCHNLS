import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  const wo = await prisma.workOrder.findFirst({
    where: { orderNumber: 'WO-2026-020' },
    include: {
      services: true,
      partsUsed: {
        include: {
          part: true
        }
      }
    }
  });
  console.log(JSON.stringify(wo, null, 2));
}

main().catch(console.error).finally(() => prisma.$disconnect());
