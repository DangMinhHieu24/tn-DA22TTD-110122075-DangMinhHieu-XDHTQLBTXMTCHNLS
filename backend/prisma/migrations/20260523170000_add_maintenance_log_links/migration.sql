-- Add maintenance log linkage and richer history fields
ALTER TABLE "maintenance_logs" ADD COLUMN "work_order_id" TEXT;
ALTER TABLE "maintenance_logs" ADD COLUMN "service_summary" TEXT;
ALTER TABLE "maintenance_logs" ADD COLUMN "notes" TEXT;
ALTER TABLE "maintenance_logs" ADD COLUMN "performed_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

CREATE UNIQUE INDEX "maintenance_logs_work_order_id_key" ON "maintenance_logs"("work_order_id");
CREATE INDEX "maintenance_logs_vehicle_id_performed_at_idx" ON "maintenance_logs"("vehicle_id", "performed_at");

ALTER TABLE "maintenance_logs"
ADD CONSTRAINT "maintenance_logs_work_order_id_fkey"
FOREIGN KEY ("work_order_id") REFERENCES "work_orders"("id") ON DELETE SET NULL ON UPDATE CASCADE;