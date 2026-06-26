import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  const wos = await prisma.workOrder.findMany({
    include: {
      services: true,
      partsUsed: true
    }
  });
  console.log(wos.map(w => ({
    orderNumber: w.orderNumber,
    status: w.status,
    totalPrice: w.totalPrice,
    servicesCount: w.services.length,
    servicesSum: w.services.reduce((s, sv) => s + (sv.price ?? 0), 0),
    partsCount: w.partsUsed.length,
    partsSum: w.partsUsed.reduce((s, p) => s + (p.quantity * p.unitPrice), 0)
  })));
}

main().catch(console.error).finally(() => prisma.$disconnect());
