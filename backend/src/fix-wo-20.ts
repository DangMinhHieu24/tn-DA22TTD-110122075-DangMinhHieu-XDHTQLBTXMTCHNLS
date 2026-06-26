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

  if (!wo) {
    console.log('Work order not found');
    return;
  }

  console.log('Original Work Order:', {
    totalPrice: wo.totalPrice,
    parts: wo.partsUsed.map(p => ({ name: p.part.partName, price: p.unitPrice }))
  });

  // Update partsUsed unitPrice to their part's sellPrice
  for (const pu of wo.partsUsed) {
    await prisma.partsUsed.update({
      where: { id: pu.id },
      data: {
        unitPrice: pu.part.sellPrice
      }
    });
  }

  // Fetch updated parts
  const updatedParts = await prisma.partsUsed.findMany({
    where: { workOrderId: wo.id }
  });

  const servicesSum = wo.services.reduce((s, sv) => s + (sv.price ?? 0), 0);
  const partsSum = updatedParts.reduce((s, p) => s + (p.quantity * p.unitPrice), 0);
  const newTotal = servicesSum + partsSum;

  // Update workOrder totalPrice
  await prisma.workOrder.update({
    where: { id: wo.id },
    data: {
      totalPrice: newTotal
    }
  });

  console.log('Updated Work Order to have actual prices for testing warranty:', {
    totalPrice: newTotal,
    servicesSum,
    partsSum
  });
}

main().catch(console.error).finally(() => prisma.$disconnect());
