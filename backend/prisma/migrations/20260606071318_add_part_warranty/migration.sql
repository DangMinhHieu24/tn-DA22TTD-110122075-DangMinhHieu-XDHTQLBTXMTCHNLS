-- AlterTable
ALTER TABLE "inventory" ADD COLUMN     "warranty_days" INTEGER NOT NULL DEFAULT 0;

-- CreateTable
CREATE TABLE "part_warranties" (
    "id" TEXT NOT NULL,
    "part_used_id" TEXT NOT NULL,
    "part_id" TEXT NOT NULL,
    "work_order_id" TEXT NOT NULL,
    "vehicle_id" TEXT NOT NULL,
    "warranty_days" INTEGER NOT NULL,
    "start_date" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiry_date" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "part_warranties_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "part_warranties_part_used_id_key" ON "part_warranties"("part_used_id");

-- AddForeignKey
ALTER TABLE "part_warranties" ADD CONSTRAINT "part_warranties_part_used_id_fkey" FOREIGN KEY ("part_used_id") REFERENCES "parts_used"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "part_warranties" ADD CONSTRAINT "part_warranties_part_id_fkey" FOREIGN KEY ("part_id") REFERENCES "inventory"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "part_warranties" ADD CONSTRAINT "part_warranties_work_order_id_fkey" FOREIGN KEY ("work_order_id") REFERENCES "work_orders"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "part_warranties" ADD CONSTRAINT "part_warranties_vehicle_id_fkey" FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
