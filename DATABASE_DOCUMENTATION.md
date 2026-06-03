# Tài Liệu Database - Hệ Thống Năng Lượng Sạch

## Tổng Quan Database

**Hệ quản trị CSDL:** PostgreSQL 15+
**ORM:** Prisma 5.7.0
**Tổng số bảng:** 9 bảng
**Tổng số enums:** 6 enums
**Ngày cập nhật:** 25/05/2026

## Danh Sách Các Bảng

1. users - Quản lý người dùng
2. vehicles - Quản lý xe điện
3. work_orders - Phiếu sửa chữa
4. repair_items - Dịch vụ trong phiếu
5. work_order_photos - Ảnh phiếu sửa chữa
6. inventory - Kho phụ tùng
7. parts_used - Phụ tùng đã dùng
8. maintenance_logs - Nhật ký bảo trì
9. warranties - Thông tin bảo hành
10. appointments - Lịch hẹn

## Các Enums

### UserRole - Vai trò người dùng
- ADMIN: Quản trị viên, toàn quyền hệ thống
- TECHNICIAN: Kỹ thuật viên, xử lý phiếu sửa chữa
- CUSTOMER: Khách hàng, xem xe và lịch sử của mình

### WorkOrderStatus - Trạng thái phiếu
- PENDING: Chờ xử lý
- IN_PROGRESS: Đang thực hiện
- INSPECTION: Kiểm tra
- COMPLETED: Hoàn thành
- PAID: Đã thanh toán
- CANCELLED: Đã hủy

### WorkPriority - Mức độ ưu tiên
- NORMAL: Bình thường
- URGENT: Khẩn cấp

### ServiceType - Loại dịch vụ
- MAINTENANCE: Bảo dưỡng định kỳ
- BATTERY_CHECK: Kiểm tra pin/sạc
- BRAKES_TIRES: Phanh và lốp
- OTHER_REPAIR: Sửa chữa khác

### PhotoType - Loại ảnh
- INTAKE: Ảnh tiếp nhận
- AFTER_REPAIR: Ảnh sau sửa

### AppointmentStatus - Trạng thái lịch hẹn
- PENDING: Chờ xác nhận
- CONFIRMED: Đã xác nhận
- CANCELLED: Đã hủy

---

## BẢNG 1: USERS (users)

Lưu trữ thông tin người dùng trong hệ thống.

### Các Cột

**id** (String UUID, PRIMARY KEY)
- ID duy nhất tự động tạo
- Ví dụ: 550e8400-e29b-41d4-a716-446655440000

**email** (String, UNIQUE, NOT NULL)
- Email đăng nhập
- Ví dụ: nguyenvana@gmail.com

**phoneNumber** (String, UNIQUE, NULLABLE)
- Tên DB: phone
- Số điện thoại 10-11 số
- Ví dụ: 0901234567

**name** (String, NOT NULL)
- Họ và tên đầy đủ
- Ví dụ: Nguyễn Văn A

**password** (String, NOT NULL)
- Mật khẩu đã hash bằng bcrypt
- Ví dụ: $2a$10$N9qo8uLOickgx2ZMRZoMye...

**role** (UserRole, DEFAULT: CUSTOMER)
- Vai trò: ADMIN, TECHNICIAN, CUSTOMER

**loyaltyPoints** (Integer, DEFAULT: 0)
- Tên DB: loyalty_points
- Điểm tích lũy khách hàng
- Ví dụ: 150

**avatarUrl** (String, NULLABLE)
- URL ảnh đại diện

**isActive** (Boolean, DEFAULT: true)
- Tài khoản còn hoạt động không

**createdAt** (DateTime, DEFAULT: now())
- Ngày tạo tài khoản

**updatedAt** (DateTime, AUTO UPDATE)
- Ngày cập nhật cuối

### Quan Hệ
- ownedVehicles: Danh sách xe sở hữu (1-nhiều với Vehicle)
- assignedWorkOrders: Phiếu được phân công (1-nhiều với WorkOrder)
- createdWorkOrders: Phiếu đã tạo (1-nhiều với WorkOrder)
- appointments: Lịch hẹn (1-nhiều với Appointment)

### Business Rules
- Email hoặc phoneNumber phải có ít nhất 1
- Password hash với bcrypt 6-10 rounds
- Role mặc định là CUSTOMER khi đăng ký
- Loyalty points: +10 điểm mỗi 100,000đ chi tiêu

---

## BẢNG 2: VEHICLES (vehicles)

Lưu trữ thông tin xe điện của khách hàng.

### Các Cột

**id** (String UUID, PRIMARY KEY)
- ID duy nhất

**licensePlate** (String, UNIQUE, NOT NULL)
- Tên DB: license_plate
- Biển số xe theo chuẩn VN
- Ví dụ: 29A-123.45, 51F-678.90

**brand** (String, NULLABLE)
- Hãng xe
- Ví dụ: VinFast, Yadea, Pega

**model** (String, NOT NULL)
- Model xe
- Ví dụ: Klara S, VF e34, Xmen Plus

**color** (String, NULLABLE)
- Màu xe
- Ví dụ: Đỏ, Xanh dương, Trắng

**imageUrl** (String, NULLABLE)
- Tên DB: image_url
- URL ảnh xe

**manufactureYear** (Integer, NULLABLE)
- Tên DB: manufacturer_year
- Năm sản xuất
- Ví dụ: 2023, 2024

**qrCode** (String, UNIQUE, NULLABLE)
- Tên DB: qr_code
- Mã QR duy nhất của xe
- Ví dụ: QR-29A12345

**warrantyExpiry** (DateTime, NULLABLE)
- Tên DB: warranty_expiry
- Ngày hết hạn bảo hành

**currentKm** (Integer, NULLABLE)
- Tên DB: current_odometer
- Số km hiện tại
- Ví dụ: 5000, 12000

**ownerId** (String UUID, FOREIGN KEY, NOT NULL)
- Tên DB: owner_id
- ID chủ xe (User)

**createdAt** (DateTime, DEFAULT: now())
- Ngày thêm xe vào hệ thống

**updatedAt** (DateTime, AUTO UPDATE)
- Ngày cập nhật thông tin

### Quan Hệ
- owner: Chủ xe (nhiều-1 với User)
- workOrders: Phiếu sửa chữa (1-nhiều với WorkOrder)
- maintenanceLogs: Lịch sử bảo trì (1-nhiều với MaintenanceLog)
- warranties: Bảo hành (1-nhiều với Warranty)

### Business Rules
- Biển số xe phải unique
- QR code tự động generate: QR-{licensePlate}
- currentKm tự động cập nhật sau mỗi lần bảo trì
- Một khách hàng có thể có nhiều xe

---

## BẢNG 3: WORK_ORDERS (work_orders)

Phiếu sửa chữa/bảo trì xe - Bảng trung tâm của hệ thống.

### Các Cột

**id** (String UUID, PRIMARY KEY)
- ID duy nhất

**orderNumber** (String, UNIQUE, NOT NULL)
- Mã phiếu tự động tạo
- Format: WO-{YEAR}-{SEQUENCE}
- Ví dụ: WO-2026-001, WO-2026-002

**vehicleId** (String UUID, FOREIGN KEY, NOT NULL)
- Tên DB: vehicle_id
- ID xe được sửa

**status** (WorkOrderStatus, DEFAULT: PENDING)
- Trạng thái hiện tại
- Giá trị: PENDING, IN_PROGRESS, INSPECTION, COMPLETED, PAID, CANCELLED

**priority** (WorkPriority, DEFAULT: NORMAL)
- Mức độ ưu tiên
- Giá trị: NORMAL, URGENT

**totalPrice** (Float, NULLABLE)
- Tên DB: total_price
- Tổng tiền (VNĐ)
- Ví dụ: 1500000.0

**notes** (String, NULLABLE)
- Ghi chú thêm
- Ví dụ: Khách yêu cầu rửa xe

**technicianId** (String UUID, FOREIGN KEY, NULLABLE)
- Tên DB: staff_id
- ID kỹ thuật viên phụ trách

**estimatedHours** (Float, NULLABLE)
- Ước tính thời gian (giờ)
- Ví dụ: 2.5, 4.0

**scheduledTime** (String, NULLABLE)
- Giờ hẹn hoàn thành
- Ví dụ: 14:00, 09:30

**createdById** (String UUID, FOREIGN KEY, NOT NULL)
- Tên DB: created_by_id
- ID admin tạo phiếu

**createdAt** (DateTime, DEFAULT: now())
- Tên DB: created_at
- Ngày giờ tạo phiếu

**updatedAt** (DateTime, AUTO UPDATE)
- Ngày giờ cập nhật cuối

**completedAt** (DateTime, NULLABLE)
- Tên DB: completed_at
- Ngày giờ hoàn thành

### Quan Hệ
- vehicle: Xe được sửa (nhiều-1 với Vehicle)
- technician: Kỹ thuật viên (nhiều-1 với User)
- createdBy: Admin tạo phiếu (nhiều-1 với User)
- services: Dịch vụ (1-nhiều với WorkOrderService)
- photos: Ảnh (1-nhiều với WorkOrderPhoto)
- partsUsed: Phụ tùng (1-nhiều với PartsUsed)
- maintenanceLog: Nhật ký (1-1 với MaintenanceLog)

### Business Rules
- orderNumber format: WO-{YEAR}-{SEQUENCE}
- totalPrice = SUM(services.price) + SUM(partsUsed.quantity × unitPrice)
- completedAt tự động set khi status = COMPLETED
- Chỉ Admin tạo và phân công phiếu
- Technician chỉ xem phiếu của mình

---

## BẢNG 4: REPAIR_ITEMS (repair_items)

Danh sách dịch vụ/công việc trong một phiếu sửa chữa.

### Các Cột

**id** (String UUID, PRIMARY KEY)
- ID duy nhất

**workOrderId** (String UUID, FOREIGN KEY, NOT NULL)
- Tên DB: order_id
- ID phiếu chứa dịch vụ này

**serviceType** (ServiceType, NOT NULL)
- Loại dịch vụ
- Giá trị: MAINTENANCE, BATTERY_CHECK, BRAKES_TIRES, OTHER_REPAIR

**description** (String, NULLABLE)
- Mô tả chi tiết công việc
- Ví dụ: Thay dầu phanh, kiểm tra đèn

**serviceName** (String, NULLABLE)
- Tên DB: service_name
- Tên dịch vụ tùy chỉnh
- Ví dụ: Bảo dưỡng 5000km

**price** (Float, NULLABLE)
- Giá dịch vụ (VNĐ)
- Ví dụ: 300000.0

**isDone** (Boolean, DEFAULT: false)
- Tên DB: is_done
- Đã hoàn thành chưa (checkbox)

**note** (String, NULLABLE)
- Ghi chú của technician
- Ví dụ: Đã thay mới

**createdAt** (DateTime, DEFAULT: now())
- Ngày thêm dịch vụ

### Quan Hệ
- workOrder: Phiếu chứa dịch vụ (nhiều-1 với WorkOrder)

### Business Rules
- Một phiếu có thể có nhiều dịch vụ
- isDone = true khi technician tick checkbox
- Khi xóa WorkOrder, tất cả services cũng bị xóa (CASCADE)
- Price có thể null nếu dịch vụ miễn phí

---

## BẢNG 5: WORK_ORDER_PHOTOS (work_order_photos)

Lưu trữ ảnh chụp trong quá trình tiếp nhận và sửa chữa.

### Các Cột

**id** (String UUID, PRIMARY KEY)
- ID duy nhất

**workOrderId** (String UUID, FOREIGN KEY, NOT NULL)
- ID phiếu

**photoUrl** (String, NOT NULL)
- URL ảnh trên cloud storage
- Ví dụ: https://supabase.../photos/abc.jpg

**photoType** (PhotoType, DEFAULT: INTAKE)
- Loại ảnh
- Giá trị: INTAKE, AFTER_REPAIR

**description** (String, NULLABLE)
- Mô tả ảnh
- Ví dụ: Xước góc trước bên trái

**createdAt** (DateTime, DEFAULT: now())
- Ngày giờ chụp

### Quan Hệ
- workOrder: Phiếu chứa ảnh (nhiều-1 với WorkOrder)

### Business Rules
- INTAKE: Chụp khi tiếp nhận xe (Admin)
- AFTER_REPAIR: Chụp sau khi sửa xong (Technician)
- Lưu trên Supabase Storage
- Khi xóa WorkOrder, tất cả photos cũng bị xóa (CASCADE)

---

## BẢNG 6: INVENTORY (inventory)

Quản lý kho phụ tùng.

### Các Cột

**id** (String UUID, PRIMARY KEY)
- ID duy nhất

**partName** (String, NOT NULL)
- Tên DB: part_name
- Tên phụ tùng
- Ví dụ: Lốp xe 16 inch, Phanh đĩa trước

**imageUrl** (String, NULLABLE)
- Tên DB: image_url
- URL ảnh phụ tùng

**quantity** (Integer, DEFAULT: 0)
- Số lượng tồn kho
- Ví dụ: 20, 5, 0

**minThreshold** (Integer, NOT NULL)
- Tên DB: min_threshold
- Ngưỡng cảnh báo hết hàng
- Ví dụ: 5, 10

**unitPrice** (Float, NOT NULL)
- Tên DB: unit_price
- Giá nhập (VNĐ)
- Ví dụ: 500000.0

**sellPrice** (Float, NOT NULL)
- Tên DB: sell_price
- Giá bán (VNĐ)
- Ví dụ: 700000.0

### Quan Hệ
- partsUsed: Lịch sử sử dụng (1-nhiều với PartsUsed)

### Business Rules
- Cảnh báo khi quantity < minThreshold
- Tự động trừ quantity khi thêm vào PartsUsed
- sellPrice thường > unitPrice (có lãi)
- Admin có thể điều chỉnh quantity thủ công

---

## BẢNG 7: PARTS_USED (parts_used)

Ghi nhận phụ tùng đã sử dụng trong phiếu sửa chữa.

### Các Cột

**id** (String UUID, PRIMARY KEY)
- ID duy nhất

**workOrderId** (String UUID, FOREIGN KEY, NOT NULL)
- Tên DB: order_id
- ID phiếu sử dụng

**partId** (String UUID, FOREIGN KEY, NOT NULL)
- Tên DB: part_id
- ID phụ tùng

**quantity** (Integer, NOT NULL)
- Số lượng đã dùng
- Ví dụ: 2, 4, 1

**unitPrice** (Float, NOT NULL)
- Tên DB: unit_price
- Giá tại thời điểm dùng (VNĐ)
- Ví dụ: 700000.0

### Quan Hệ
- workOrder: Phiếu sử dụng (nhiều-1 với WorkOrder)
- part: Phụ tùng được dùng (nhiều-1 với Inventory)

### Business Rules
- unitPrice lưu giá tại thời điểm sử dụng
- Tự động trừ Inventory.quantity khi tạo record
- Tổng tiền = quantity × unitPrice
- Khi xóa WorkOrder, tất cả partsUsed cũng bị xóa (CASCADE)

---

## BẢNG 8: MAINTENANCE_LOGS (maintenance_logs)

Nhật ký bảo trì đầy đủ của xe.

### Các Cột

**id** (String UUID, PRIMARY KEY)
- ID duy nhất

**vehicleId** (String UUID, FOREIGN KEY, NOT NULL)
- Tên DB: vehicle_id
- ID xe

**workOrderId** (String UUID, UNIQUE, FOREIGN KEY, NULLABLE)
- Tên DB: work_order_id
- ID phiếu (nếu có)

**odometerKm** (Integer, NOT NULL)
- Tên DB: odometer_km
- Số km khi bảo trì
- Ví dụ: 5000, 8000

**serviceType** (String, NULLABLE)
- Tên DB: service_type
- Loại dịch vụ chính
- Ví dụ: MAINTENANCE, BATTERY_CHECK

**serviceSummary** (String, NULLABLE)
- Tên DB: service_summary
- Tóm tắt công việc đã làm
- Ví dụ: Bảo dưỡng định kỳ, thay lốp

**nextServiceKm** (Integer, NULLABLE)
- Tên DB: next_service_km
- Km bảo dưỡng tiếp theo
- Ví dụ: 8000, 11000

**nextServiceDate** (DateTime, NULLABLE)
- Tên DB: next_service_date
- Ngày bảo dưỡng tiếp theo

**notes** (String, NULLABLE)
- Ghi chú thêm

**performedAt** (DateTime, DEFAULT: now())
- Tên DB: performed_at
- Ngày thực hiện bảo trì

### Quan Hệ
- vehicle: Xe được bảo trì (nhiều-1 với Vehicle)
- workOrder: Phiếu tạo ra log (1-1 với WorkOrder)

### Business Rules
- Tự động tạo khi WorkOrder chuyển sang COMPLETED
- Service summary tự động tạo từ danh sách services
- nextServiceKm = odometerKm + 3000 (cho MAINTENANCE)
- nextServiceDate = performedAt + 3 months
- Tự động cập nhật Vehicle.currentKm

---

## BẢNG 9: WARRANTIES (warranties)

Quản lý thông tin bảo hành của xe.

### Các Cột

**id** (String UUID, PRIMARY KEY)
- ID duy nhất

**vehicleId** (String UUID, FOREIGN KEY, NOT NULL)
- Tên DB: vehicle_id
- ID xe

**warrantyType** (String, NOT NULL)
- Tên DB: warranty_type
- Loại bảo hành
- Ví dụ: Pin, Động cơ, Khung xe

**startDate** (DateTime, NOT NULL)
- Tên DB: start_date
- Ngày bắt đầu bảo hành

**expiryDate** (DateTime, NOT NULL)
- Tên DB: expiry_date
- Ngày hết hạn bảo hành

**terms** (String, NULLABLE)
- Điều khoản bảo hành
- Ví dụ: Bảo hành 2 năm hoặc 20,000km

**issuedBy** (String, NULLABLE)
- Tên DB: issued_by
- Đơn vị cấp bảo hành
- Ví dụ: VinFast, Yadea Vietnam

### Quan Hệ
- vehicle: Xe được bảo hành (nhiều-1 với Vehicle)

### Business Rules
- Một xe có thể có nhiều loại bảo hành
- Pin: 2-3 năm
- Động cơ: 2 năm
- Khung xe: 5 năm
- Cảnh báo 30 ngày trước khi hết hạn

---

## BẢNG 10: APPOINTMENTS (appointments)

Quản lý lịch hẹn bảo trì của khách hàng.

### Các Cột

**id** (String UUID, PRIMARY KEY)
- ID duy nhất

**customerId** (String UUID, FOREIGN KEY, NOT NULL)
- Tên DB: customer_id
- ID khách hàng

**scheduledAt** (DateTime, NOT NULL)
- Tên DB: scheduled_at
- Ngày giờ hẹn

**serviceType** (String, NULLABLE)
- Tên DB: service_type
- Loại dịch vụ muốn làm
- Ví dụ: Bảo dưỡng định kỳ

**notes** (String, NULLABLE)
- Ghi chú từ khách
- Ví dụ: Xe có tiếng kêu lạ ở phanh

**status** (AppointmentStatus, DEFAULT: PENDING)
- Trạng thái lịch hẹn
- Giá trị: PENDING, CONFIRMED, CANCELLED

### Quan Hệ
- customer: Khách hàng đặt lịch (nhiều-1 với User)

### Business Rules
- Customer tạo appointment → status = PENDING
- Admin xác nhận → status = CONFIRMED
- Gửi email/SMS khi CONFIRMED
- Nhắc nhở 1 ngày trước scheduledAt

---

## Quan Hệ Giữa Các Bảng

### Sơ Đồ Quan Hệ Chính

User (CUSTOMER) → Vehicle → WorkOrder
User (TECHNICIAN) → WorkOrder (assigned)
User (ADMIN) → WorkOrder (created)

WorkOrder → WorkOrderService (1-nhiều)
WorkOrder → WorkOrderPhoto (1-nhiều)
WorkOrder → PartsUsed (1-nhiều)
WorkOrder → MaintenanceLog (1-1)

PartsUsed → Inventory (nhiều-1)

Vehicle → MaintenanceLog (1-nhiều)
Vehicle → Warranty (1-nhiều)

User (CUSTOMER) → Appointment (1-nhiều)

### Cascade Behaviors

Khi xóa WorkOrder:
- WorkOrderService: CASCADE (xóa tất cả)
- WorkOrderPhoto: CASCADE (xóa tất cả)
- PartsUsed: CASCADE (xóa tất cả)
- MaintenanceLog: SET NULL (giữ log, set workOrderId = null)

Khi xóa Vehicle:
- WorkOrder: RESTRICT (không thể xóa nếu còn phiếu)

Khi xóa User:
- Vehicle: RESTRICT (không thể xóa nếu còn xe)

---

## Queries Thường Dùng

### 1. Lấy phiếu của kỹ thuật viên

SELECT wo.*, v.licensePlate, v.brand, v.model
FROM work_orders wo
JOIN vehicles v ON wo.vehicle_id = v.id
WHERE wo.staff_id = 'technician-id'
AND wo.status IN ('PENDING', 'IN_PROGRESS')
ORDER BY wo.priority DESC, wo.created_at ASC;

### 2. Tính doanh thu hôm nay

SELECT SUM(total_price) as revenue_today
FROM work_orders
WHERE DATE(completed_at) = CURRENT_DATE
AND status = 'COMPLETED';

### 3. Lịch sử bảo trì của xe

SELECT ml.*, wo.orderNumber
FROM maintenance_logs ml
LEFT JOIN work_orders wo ON ml.work_order_id = wo.id
WHERE ml.vehicle_id = 'vehicle-id'
ORDER BY ml.performed_at DESC;

### 4. Phụ tùng sắp hết hàng

SELECT *
FROM inventory
WHERE quantity < min_threshold
ORDER BY quantity ASC;

### 5. Xe sắp hết bảo hành

SELECT v.*, w.warrantyType, w.expiryDate
FROM vehicles v
JOIN warranties w ON v.id = w.vehicle_id
WHERE w.expiry_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
ORDER BY w.expiry_date ASC;

---

## Indexes Quan Trọng

### Users
- PRIMARY KEY (id)
- UNIQUE INDEX (email)
- UNIQUE INDEX (phone)
- INDEX (role)

### Vehicles
- PRIMARY KEY (id)
- UNIQUE INDEX (license_plate)
- UNIQUE INDEX (qr_code)
- FOREIGN KEY (owner_id)
- INDEX (owner_id)

### Work Orders
- PRIMARY KEY (id)
- UNIQUE INDEX (orderNumber)
- FOREIGN KEY (vehicle_id)
- FOREIGN KEY (staff_id)
- FOREIGN KEY (created_by_id)
- INDEX (status)
- INDEX (staff_id)
- INDEX (created_at DESC)

### Maintenance Logs
- PRIMARY KEY (id)
- UNIQUE INDEX (work_order_id)
- FOREIGN KEY (vehicle_id)
- INDEX (vehicle_id, performed_at DESC)

### Inventory
- PRIMARY KEY (id)
- INDEX (quantity)

---

## Security & Permissions

### Row Level Security

**User Table:**
- Users chỉ xem được thông tin của mình
- Admin xem được tất cả

**Vehicle Table:**
- Customer chỉ xem xe của mình
- Technician xem xe trong phiếu được phân công
- Admin xem tất cả

**WorkOrder Table:**
- Customer xem phiếu của xe mình
- Technician xem phiếu được phân công
- Admin xem tất cả

**Inventory Table:**
- Chỉ Admin và Technician xem được
- Customer không có quyền

---

## Migration Commands

### Generate Prisma Client
npx prisma generate

### Run Migrations
npx prisma migrate dev --name init

### Seed Database
npx prisma db seed

### Reset Database (WARNING: deletes all data)
npx prisma migrate reset

---

## Sample Data

### Admin User
Email: admin@nanglungsach.com
Phone: 0901234567
Name: Admin Hệ Thống
Password: admin123
Role: ADMIN

### Technician User
Email: kythuat1@nanglungsach.com
Phone: 0902345678
Name: Trần Văn Kỹ Thuật
Password: tech123
Role: TECHNICIAN

### Customer User
Email: khach1@gmail.com
Phone: 0903456789
Name: Nguyễn Văn Khách
Password: customer123
Role: CUSTOMER

---

## Best Practices

### Naming Conventions
- Tables: snake_case, số nhiều (users, work_orders)
- Columns: snake_case (license_plate, created_at)
- Enums: UPPER_CASE (PENDING, IN_PROGRESS)

### Data Integrity
- Luôn dùng FOREIGN KEY constraints
- Dùng UNIQUE cho dữ liệu không được trùng
- Dùng NOT NULL cho trường bắt buộc

### Timestamps
- Mọi bảng đều có createdAt và updatedAt
- Dùng DateTime với timezone (UTC)

### Soft Delete
- Dùng isActive thay vì xóa hẳn
- Giữ lại dữ liệu để audit

### UUID vs Auto Increment
- Dùng UUID cho security
- Không lộ số lượng records

---

Tài liệu này được tạo tự động từ Prisma Schema.
Ngày cập nhật: 25/05/2026
Phiên bản: 1.0.0
Tác giả: Năng Lượng Sạch Development Team
