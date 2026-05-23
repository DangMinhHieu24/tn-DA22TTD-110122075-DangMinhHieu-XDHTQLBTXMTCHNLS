-- CreateEnum
CREATE TYPE "PhotoType" AS ENUM ('INTAKE', 'AFTER_REPAIR');

-- AlterTable
ALTER TABLE "work_order_photos"
ADD COLUMN "photoType" "PhotoType" NOT NULL DEFAULT 'INTAKE';

-- Backfill existing rows
UPDATE "work_order_photos"
SET "photoType" = 'INTAKE'
WHERE "photoType" IS NULL;
