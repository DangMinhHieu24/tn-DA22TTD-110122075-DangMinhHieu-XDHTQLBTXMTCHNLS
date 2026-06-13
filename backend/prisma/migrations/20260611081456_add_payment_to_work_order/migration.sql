-- CreateEnum
CREATE TYPE "PaymentMethod" AS ENUM ('CASH', 'CARD', 'TRANSFER');

-- AlterTable
ALTER TABLE "work_orders" ADD COLUMN     "paid_at" TIMESTAMP(3),
ADD COLUMN     "payment_method" "PaymentMethod";
