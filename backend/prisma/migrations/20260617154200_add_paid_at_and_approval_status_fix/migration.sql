-- AlterEnum
ALTER TYPE "AppointmentStatus" ADD VALUE 'COMPLETED';

-- AlterTable
ALTER TABLE "work_orders" ADD COLUMN "appointment_id" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "work_orders_appointment_id_key" ON "work_orders"("appointment_id");

-- AddForeignKey
ALTER TABLE "work_orders" ADD CONSTRAINT "work_orders_appointment_id_fkey" FOREIGN KEY ("appointment_id") REFERENCES "appointments"("id") ON DELETE SET NULL ON UPDATE CASCADE;
