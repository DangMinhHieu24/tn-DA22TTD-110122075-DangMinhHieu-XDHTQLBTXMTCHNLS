-- CreateEnum
CREATE TYPE "ApprovalStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');

-- AlterTable
ALTER TABLE "repair_items" ADD COLUMN "approval_status" "ApprovalStatus" NOT NULL DEFAULT 'PENDING';
