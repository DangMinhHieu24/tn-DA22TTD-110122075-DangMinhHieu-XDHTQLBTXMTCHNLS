/*
  Warnings:

  - You are about to drop the column `warrantyStatus` on the `vehicles` table. All the data in the column will be lost.
  - A unique constraint covering the columns `[qrCode]` on the table `vehicles` will be added. If there are existing duplicate values, this will fail.

*/
-- AlterTable
ALTER TABLE "vehicles" DROP COLUMN "warrantyStatus",
ADD COLUMN     "brand" TEXT,
ADD COLUMN     "manufactureYear" INTEGER,
ADD COLUMN     "qrCode" TEXT,
ADD COLUMN     "warrantyExpiry" TIMESTAMP(3);

-- CreateIndex
CREATE UNIQUE INDEX "vehicles_qrCode_key" ON "vehicles"("qrCode");
