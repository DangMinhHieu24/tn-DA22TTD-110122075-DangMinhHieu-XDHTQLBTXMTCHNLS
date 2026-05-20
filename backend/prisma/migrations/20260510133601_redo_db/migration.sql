/*
  Warnings:

  - You are about to drop the column `phoneNumber` on the `users` table. All the data in the column will be lost.
  - You are about to drop the column `currentKm` on the `vehicles` table. All the data in the column will be lost.
  - You are about to drop the column `licensePlate` on the `vehicles` table. All the data in the column will be lost.
  - You are about to drop the column `manufactureYear` on the `vehicles` table. All the data in the column will be lost.
  - You are about to drop the column `ownerId` on the `vehicles` table. All the data in the column will be lost.
  - You are about to drop the column `qrCode` on the `vehicles` table. All the data in the column will be lost.
  - You are about to drop the column `warrantyExpiry` on the `vehicles` table. All the data in the column will be lost.
  - You are about to drop the column `completedAt` on the `work_orders` table. All the data in the column will be lost.
  - You are about to drop the column `createdAt` on the `work_orders` table. All the data in the column will be lost.
  - You are about to drop the column `createdById` on the `work_orders` table. All the data in the column will be lost.
  - You are about to drop the column `technicianId` on the `work_orders` table. All the data in the column will be lost.
  - You are about to drop the column `vehicleId` on the `work_orders` table. All the data in the column will be lost.
  - You are about to drop the `work_order_services` table. If the table is not empty, all the data it contains will be lost.
  - A unique constraint covering the columns `[phone]` on the table `users` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[license_plate]` on the table `vehicles` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[qr_code]` on the table `vehicles` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `license_plate` to the `vehicles` table without a default value. This is not possible if the table is not empty.
  - Added the required column `owner_id` to the `vehicles` table without a default value. This is not possible if the table is not empty.
  - Added the required column `created_by_id` to the `work_orders` table without a default value. This is not possible if the table is not empty.
  - Added the required column `vehicle_id` to the `work_orders` table without a default value. This is not possible if the table is not empty.

*/
-- CreateEnum
CREATE TYPE "AppointmentStatus" AS ENUM ('PENDING', 'CONFIRMED', 'CANCELLED');

-- AlterEnum
ALTER TYPE "WorkOrderStatus" ADD VALUE 'PAID';

-- DropForeignKey
ALTER TABLE "vehicles" DROP CONSTRAINT "vehicles_ownerId_fkey";

-- DropForeignKey
ALTER TABLE "work_order_services" DROP CONSTRAINT "work_order_services_workOrderId_fkey";

-- DropForeignKey
ALTER TABLE "work_orders" DROP CONSTRAINT "work_orders_createdById_fkey";

-- DropForeignKey
ALTER TABLE "work_orders" DROP CONSTRAINT "work_orders_technicianId_fkey";

-- DropForeignKey
ALTER TABLE "work_orders" DROP CONSTRAINT "work_orders_vehicleId_fkey";

-- DropIndex
DROP INDEX "users_phoneNumber_key";

-- DropIndex
DROP INDEX "vehicles_licensePlate_key";

-- DropIndex
DROP INDEX "vehicles_qrCode_key";

-- AlterTable
ALTER TABLE "users" DROP COLUMN "phoneNumber",
ADD COLUMN     "loyalty_points" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "phone" TEXT;

-- AlterTable
ALTER TABLE "vehicles" DROP COLUMN "currentKm",
DROP COLUMN "licensePlate",
DROP COLUMN "manufactureYear",
DROP COLUMN "ownerId",
DROP COLUMN "qrCode",
DROP COLUMN "warrantyExpiry",
ADD COLUMN     "current_odometer" INTEGER,
ADD COLUMN     "license_plate" TEXT NOT NULL,
ADD COLUMN     "manufacturer_year" INTEGER,
ADD COLUMN     "owner_id" TEXT NOT NULL,
ADD COLUMN     "qr_code" TEXT,
ADD COLUMN     "warranty_expiry" TIMESTAMP(3);

-- AlterTable
ALTER TABLE "work_orders" DROP COLUMN "completedAt",
DROP COLUMN "createdAt",
DROP COLUMN "createdById",
DROP COLUMN "technicianId",
DROP COLUMN "vehicleId",
ADD COLUMN     "completed_at" TIMESTAMP(3),
ADD COLUMN     "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "created_by_id" TEXT NOT NULL,
ADD COLUMN     "staff_id" TEXT,
ADD COLUMN     "total_price" DOUBLE PRECISION,
ADD COLUMN     "vehicle_id" TEXT NOT NULL;

-- DropTable
DROP TABLE "work_order_services";

-- CreateTable
CREATE TABLE "repair_items" (
    "id" TEXT NOT NULL,
    "order_id" TEXT NOT NULL,
    "serviceType" "ServiceType" NOT NULL,
    "description" TEXT,
    "service_name" TEXT,
    "price" DOUBLE PRECISION,
    "is_done" BOOLEAN NOT NULL DEFAULT false,
    "note" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "repair_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "inventory" (
    "id" TEXT NOT NULL,
    "part_name" TEXT NOT NULL,
    "quantity" INTEGER NOT NULL DEFAULT 0,
    "min_threshold" INTEGER NOT NULL,
    "unit_price" DOUBLE PRECISION NOT NULL,
    "sell_price" DOUBLE PRECISION NOT NULL,

    CONSTRAINT "inventory_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "parts_used" (
    "id" TEXT NOT NULL,
    "order_id" TEXT NOT NULL,
    "part_id" TEXT NOT NULL,
    "quantity" INTEGER NOT NULL,
    "unit_price" DOUBLE PRECISION NOT NULL,

    CONSTRAINT "parts_used_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "appointments" (
    "id" TEXT NOT NULL,
    "customer_id" TEXT NOT NULL,
    "scheduled_at" TIMESTAMP(3) NOT NULL,
    "service_type" TEXT,
    "notes" TEXT,
    "status" "AppointmentStatus" NOT NULL DEFAULT 'PENDING',

    CONSTRAINT "appointments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "maintenance_logs" (
    "id" TEXT NOT NULL,
    "vehicle_id" TEXT NOT NULL,
    "odometer_km" INTEGER NOT NULL,
    "service_type" TEXT,
    "next_service_km" INTEGER,
    "next_service_date" TIMESTAMP(3),

    CONSTRAINT "maintenance_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "warranties" (
    "id" TEXT NOT NULL,
    "vehicle_id" TEXT NOT NULL,
    "warranty_type" TEXT NOT NULL,
    "start_date" TIMESTAMP(3) NOT NULL,
    "expiry_date" TIMESTAMP(3) NOT NULL,
    "terms" TEXT,
    "issued_by" TEXT,

    CONSTRAINT "warranties_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_phone_key" ON "users"("phone");

-- CreateIndex
CREATE UNIQUE INDEX "vehicles_license_plate_key" ON "vehicles"("license_plate");

-- CreateIndex
CREATE UNIQUE INDEX "vehicles_qr_code_key" ON "vehicles"("qr_code");

-- AddForeignKey
ALTER TABLE "vehicles" ADD CONSTRAINT "vehicles_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "work_orders" ADD CONSTRAINT "work_orders_vehicle_id_fkey" FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "work_orders" ADD CONSTRAINT "work_orders_staff_id_fkey" FOREIGN KEY ("staff_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "work_orders" ADD CONSTRAINT "work_orders_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "repair_items" ADD CONSTRAINT "repair_items_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "work_orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "parts_used" ADD CONSTRAINT "parts_used_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "work_orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "parts_used" ADD CONSTRAINT "parts_used_part_id_fkey" FOREIGN KEY ("part_id") REFERENCES "inventory"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "appointments" ADD CONSTRAINT "appointments_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "maintenance_logs" ADD CONSTRAINT "maintenance_logs_vehicle_id_fkey" FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "warranties" ADD CONSTRAINT "warranties_vehicle_id_fkey" FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
