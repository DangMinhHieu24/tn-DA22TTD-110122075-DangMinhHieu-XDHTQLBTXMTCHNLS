# TÀI LIỆU KỸ THUẬT DỰ ÁN ĐỒ ÁN TỐT NGHIỆP

> **Phiên bản**: 1.1 – Cập nhật ngày 21/06/2026 (bổ sung Supabase Realtime, Supabase PostgreSQL cloud hosting)
## Năng Lượng Sạch – Hệ thống Quản lý Bảo dưỡng Xe Điện Thông Minh

> **Mục đích tài liệu**: File này mô tả toàn bộ dự án đồ án tốt nghiệp một cách chính xác và chi tiết nhất, bao gồm kiến trúc, công nghệ, tính năng, và thiết kế hệ thống. Được tạo từ mã nguồn thực tế của dự án.

---

## 1. TỔNG QUAN DỰ ÁN

### 1.1 Tên dự án
**Năng Lượng Sạch** (`nanglungsach`) – Hệ thống quản lý bảo dưỡng xe điện thông minh (Electric Vehicle Maintenance Management System).

Tên thương mại trong giao diện: **Xanh EV**

### 1.2 Mô tả tổng quan
Đây là một hệ thống phần mềm di động và backend phục vụ cho trung tâm dịch vụ/garage bảo dưỡng xe điện. Hệ thống quản lý toàn bộ quy trình từ khi khách hàng đặt lịch hẹn, xe được tiếp nhận vào xưởng, kỹ thuật viên thực hiện sửa chữa, cho đến thanh toán và quản lý bảo hành. Ngoài ra còn tích hợp chatbot AI hỗ trợ khách hàng và kỹ thuật viên.

### 1.3 Đối tượng người dùng (3 vai trò)
| Vai trò | Tiếng Việt | Mô tả |
|---------|-----------|-------|
| `STAFF` | Nhân viên / Quản lý | Quản lý toàn bộ hoạt động: dashboard, tiếp nhận xe, phiếu sửa chữa, tồn kho, doanh thu, lịch hẹn |
| `TECHNICIAN` | Kỹ thuật viên | Xem danh sách công việc được giao, cập nhật trạng thái sửa chữa, tra cứu xe và phụ tùng |
| `CUSTOMER` | Khách hàng | Xem xe của mình, xem lịch sử sửa chữa, đặt lịch hẹn, xem bảo hành, chat với AI |

---

## 2. CÔNG NGHỆ SỬ DỤNG

### 2.1 Frontend – Mobile App
- **Framework**: Flutter (Dart) – phiên bản SDK `>=3.0.0 <4.0.0`
- **Kiến trúc**: Clean Architecture + Feature-First (Monorepo Packages)
- **State Management**: BLoC (flutter_bloc ^8.1.3) + Equatable ^2.0.5
- **Dependency Injection**: GetIt ^7.6.4 + Injectable ^2.3.2
- **File Storage / Auth Storage**: Supabase Flutter ^2.5.0 (dùng cho lưu ảnh xe, không phải auth chính)
- **QR Code**: mobile_scanner ^5.2.3 (quét QR), qr_flutter ^4.1.0 (tạo QR)
- **Image Picker**: image_picker ^1.1.2
- **Internationalization**: intl ^0.20.2, flutter_localizations (hỗ trợ tiếng Việt và tiếng Anh)
- **Font**: Roboto Variable (tự host trong assets)

### 2.2 Backend – REST API
- **Runtime**: Node.js với TypeScript ^5.3.3
- **Framework**: Express.js ^4.18.2
- **ORM**: Prisma ^5.7.0 (Prisma Client JS)
- **Database**: PostgreSQL
- **Authentication**: JWT (jsonwebtoken ^9.0.2) + bcryptjs ^2.4.3
- **AI Integration**: Google Generative AI (@google/generative-ai ^0.24.1) – sử dụng model `gemini-2.5-flash`
- **Security**: Helmet ^7.1.0, CORS ^2.8.5
- **Logging**: Morgan ^1.10.0
- **Validation**: express-validator ^7.0.1
- **Dev Tools**: nodemon ^3.0.2, ts-node ^10.9.2

### 2.3 Database
- **Loại**: PostgreSQL (quan hệ)
- **ORM**: Prisma với schema định nghĩa các bảng và quan hệ

### 2.4 Các dịch vụ bên ngoài
- **Supabase** (Project: `fvagqenqcsmoaaiuubvx`, region: AWS ap-southeast-2 – Singapore) – sử dụng **3 tính năng**:
  - **Supabase PostgreSQL**: Toàn bộ database chính của hệ thống được host trên Supabase cloud (kết nối qua Prisma ORM bằng connection pooler URL). Có thể chuyển sang local PostgreSQL bằng `.env.local` (dành cho dev nhanh hơn, nhưng sẽ mất Realtime).
  - **Supabase Storage**: Lưu trữ ảnh xe và ảnh phiếu sửa chữa trong bucket `vehicle-photos`. Ảnh được nén 70% quality, max 1920×1080px trước khi upload. Trả về Public URL lưu vào PostgreSQL.
  - **Supabase Realtime** (Postgres Changes via WebSocket): Lắng nghe thay đổi theo thời gian thực trên 4 bảng của một phiếu sửa chữa cụ thể (`work_orders`, `repair_items`, `work_order_photos`, `parts_used`). Khi có thay đổi → app tự refresh không cần bấm tay. **Lý do phải host DB trên Supabase**: Realtime dùng Postgres logical replication, chỉ hoạt động khi DB nằm trên Supabase.
- **Google Gemini AI**: Chatbot AI với model `gemini-2.5-flash` (Function Calling)

---

## 3. KIẾN TRÚC HỆ THỐNG

### 3.1 Tổng thể (High-Level Architecture)
```
┌──────────────────────────────────────────────────────────┐
│                  Flutter Mobile App                      │
│        (Android/iOS – 3 giao diện theo vai trò)          │
└───────────────┬──────────────────────────┬───────────────┘
                │ HTTP REST API             │ Supabase Realtime
                │ (JWT Bearer Token)        │ (WebSocket – Postgres Changes)
                │                          │
                ▼                          ▼
┌───────────────────────────┐  ┌──────────────────────────────────────┐
│  Node.js + Express        │  │         Supabase Cloud               │
│  Backend (TypeScript)     │  │   (Project: fvagqenqcsmoaaiuubvx)    │
│                           │  │   Region: AWS ap-southeast-2 (SG)    │
│  Routes → Controllers     │  │                                      │
│  → Prisma ORM             │  │  ┌─────────────┐  ┌───────────────┐ │
│  (auth, vehicles,         │  │  │  PostgreSQL │  │   Storage     │ │
│   work-orders,            ├──┼─▶│  Database   │  │  (vehicle-    │ │
│   inventory,              │  │  │  (chính)    │  │   photos)     │ │
│   appointments,           │  │  └──────┬──────┘  └───────────────┘ │
│   warranties, chat,       │  │         │                            │
│   AI Gemini)              │  │  ┌──────▼──────┐                    │
└──────────────┬────────────┘  │  │  Realtime   │ ← logical          │
               │               │  │  (WebSocket)│   replication      │
               ▼               │  └─────────────┘                    │
┌──────────────────────┐       └──────────────────────────────────────┘
│  Google Gemini AI    │
│  (gemini-2.5-flash)  │
│  Function Calling    │
└──────────────────────┘
```

### 3.2 Kiến trúc Flutter – Clean Architecture
Dự án Flutter sử dụng **Monorepo Packages** (nhiều package Dart trong cùng một repo), với cấu trúc **Clean Architecture** 3 lớp cho mỗi feature:

```
packages/
├── core/                    # Package chia sẻ: error handling, base classes, utils
├── design_system/           # Package UI: theme, colors, typography dùng chung
└── features/
    ├── auth/                # Feature: Đăng nhập / Đăng ký
    ├── admin/               # Feature: Giao diện Nhân viên/Quản lý
    ├── customer/            # Feature: Giao diện Khách hàng
    └── technician/          # Feature: Giao diện Kỹ thuật viên
```

Mỗi feature package có cấu trúc Clean Architecture:
```
feature/lib/
├── data/
│   ├── datasources/
│   │   ├── remote/          # API calls (HTTP)
│   │   └── local/           # Local storage (SharedPreferences/token)
│   ├── models/              # Data Transfer Objects (DTO) từ JSON
│   └── repositories/        # Implementation của Repository
├── domain/
│   ├── entities/            # Pure Dart classes (business objects)
│   ├── repositories/        # Abstract Repository interfaces
│   └── usecases/            # Business logic use cases
├── di/                      # Dependency Injection setup
└── presentation/
    ├── bloc/                # BLoC: Events, States, Bloc class
    ├── pages/               # Screen/Page widgets
    └── widgets/             # Reusable UI components
```

### 3.3 Entry Point – Main App
File `lib/main.dart`:
- Khởi tạo Supabase
- Khởi tạo locale formatting cho tiếng Việt (`initializeDateFormatting('vi', null)`)
- Setup Dependency Injection (`configureDependencies()`)
- App được bọc trong `BlocProvider<AuthBloc>` để kiểm tra trạng thái đăng nhập
- `MaterialApp` với locale `vi`, hỗ trợ `GlobalMaterialLocalizations`, theme xanh lá (`AppTheme.lightTheme`)
- Route đầu tiên: Splash Screen (`/`)

### 3.4 Routing (lib/core/routes/app_router.dart)
| Route | Screen | Điều kiện truy cập |
|-------|--------|-------------------|
| `/` | `SplashScreen` | Public – kiểm tra auth rồi redirect |
| `/login` | `LoginPage` | Public |
| `/register` | `RegisterPage` | Public |
| `/admin/dashboard` | `AdminDashboardPage` | STAFF |
| `/admin/work-order-list` | `WorkOrderListPage` | STAFF |
| `/admin/vehicle-intake` | `VehicleIntakePage` | STAFF |
| `/admin/revenue-report` | `AdminRevenueReportPage` | STAFF |
| `/admin/lookup` | `AdminLookupPage` | STAFF |
| `/technician/dashboard` | `TechnicianDashboardPage` | TECHNICIAN |
| `/technician/work-list` | `TechnicianWorkListPage` | TECHNICIAN |
| `/technician/lookup` | `TechnicianLookupPage` | TECHNICIAN |
| `/customer/dashboard` | `MyVehiclesPage` | CUSTOMER |

**Splash Screen Logic**: Sau 1 giây, kiểm tra `authRepository.getCurrentUser()`. Nếu thành công → redirect theo role; nếu thất bại → `/login`.

---

## 4. CƠ SỞ DỮ LIỆU (DATABASE SCHEMA)

Database sử dụng PostgreSQL, quản lý qua Prisma ORM. Tất cả bảng được định nghĩa trong `backend/prisma/schema.prisma`.

### 4.1 Enums
```
UserRole:        STAFF | TECHNICIAN | CUSTOMER
PaymentMethod:   CASH | CARD | TRANSFER
WorkOrderStatus: PENDING | IN_PROGRESS | INSPECTION | COMPLETED | PAID | CANCELLED
ServiceType:     MAINTENANCE | BATTERY_CHECK | BRAKES_TIRES | OTHER_REPAIR
ApprovalStatus:  PENDING | APPROVED | REJECTED
PhotoType:       INTAKE | AFTER_REPAIR
AppointmentStatus: PENDING | CONFIRMED | CANCELLED | COMPLETED
```

### 4.2 Các bảng chính

#### Bảng `users`
| Trường | Kiểu | Mô tả |
|--------|------|-------|
| `id` | String (UUID) | Primary key |
| `email` | String (unique) | Email đăng nhập |
| `phone` | String? (unique) | Số điện thoại |
| `name` | String | Tên người dùng |
| `password` | String | Mật khẩu (bcrypt hash) |
| `role` | UserRole | Vai trò (mặc định: CUSTOMER) |
| `loyalty_points` | Int | Điểm tích lũy (mặc định: 0) |
| `trees_planted` | Int | Số cây trồng được (gamification xanh) |
| `avatarUrl` | String? | URL ảnh đại diện |
| `isActive` | Boolean | Trạng thái hoạt động |
| `createdAt` | DateTime | Thời điểm tạo |
| `updatedAt` | DateTime | Thời điểm cập nhật |

#### Bảng `vehicles`
| Trường | Kiểu | Mô tả |
|--------|------|-------|
| `id` | String (UUID) | Primary key |
| `license_plate` | String (unique) | Biển số xe (VD: 29A-123.45) |
| `brand` | String? | Hãng xe (VD: VinFast, Yadea, Pega) |
| `model` | String | Model xe (VD: VinFast Klara S) |
| `color` | String? | Màu xe |
| `image_url` | String? | URL ảnh xe |
| `manufacturer_year` | Int? | Năm sản xuất |
| `qr_code` | String? (unique) | Mã QR của xe (dùng để scan) |
| `warranty_expiry` | DateTime? | Ngày hết hạn bảo hành (tự cập nhật) |
| `current_odometer` | Int? | Số km hiện tại (cập nhật sau mỗi lần sửa) |
| `owner_id` | String (FK→users) | ID chủ xe |
| `createdAt` | DateTime | Thời điểm tạo |
| `updatedAt` | DateTime | Thời điểm cập nhật |

#### Bảng `work_orders` (Phiếu sửa chữa)
| Trường | Kiểu | Mô tả |
|--------|------|-------|
| `id` | String (UUID) | Primary key |
| `orderNumber` | String (unique) | Mã phiếu (VD: WO-2026-001, tự tạo) |
| `vehicle_id` | String (FK→vehicles) | ID xe |
| `appointment_id` | String? (FK→appointments, unique) | Liên kết với lịch hẹn nếu có |
| `status` | WorkOrderStatus | Trạng thái (mặc định: PENDING) |
| `total_price` | Float? | Tổng tiền (tính khi hoàn thành) |
| `notes` | String? | Ghi chú |
| `staff_id` | String? (FK→users) | ID kỹ thuật viên được phân công |
| `estimatedHours` | Float? | Ước tính thời gian (giờ) |
| `scheduledTime` | String? | Thời gian hẹn (ISO string) |
| `created_by_id` | String (FK→users) | ID người tạo phiếu |
| `created_at` | DateTime | Thời điểm tạo |
| `updatedAt` | DateTime | Thời điểm cập nhật |
| `completed_at` | DateTime? | Thời điểm hoàn thành |
| `payment_method` | PaymentMethod? | Hình thức thanh toán |
| `paid_at` | DateTime? | Thời điểm thanh toán |
| `points_redeemed` | Int? | Điểm loyalty đã dùng để giảm giá |
| `points_discount` | Float? | Số tiền giảm từ điểm loyalty |

#### Bảng `repair_items` (WorkOrderService – Dịch vụ trong phiếu)
| Trường | Kiểu | Mô tả |
|--------|------|-------|
| `id` | String (UUID) | Primary key |
| `order_id` | String (FK→work_orders) | ID phiếu sửa chữa |
| `serviceType` | ServiceType | Loại dịch vụ |
| `description` | String? | Mô tả chi tiết |
| `service_name` | String? | Tên dịch vụ |
| `price` | Float? | Giá dịch vụ |
| `is_done` | Boolean | Kỹ thuật viên đã hoàn thành chưa |
| `note` | String? | Ghi chú |
| `approval_status` | ApprovalStatus | Trạng thái phê duyệt |
| `createdAt` | DateTime | Thời điểm tạo |

#### Bảng `work_order_photos` (Ảnh phiếu sửa chữa)
| Trường | Kiểu | Mô tả |
|--------|------|-------|
| `id` | String (UUID) | Primary key |
| `workOrderId` | String (FK→work_orders) | ID phiếu |
| `photoUrl` | String | URL ảnh |
| `photoType` | PhotoType | Loại ảnh: INTAKE (lúc tiếp nhận) hoặc AFTER_REPAIR |
| `description` | String? | Mô tả (VD: "Xước góc trước bên trái") |
| `createdAt` | DateTime | Thời điểm tạo |

#### Bảng `inventory` (Tồn kho phụ tùng)
| Trường | Kiểu | Mô tả |
|--------|------|-------|
| `id` | String (UUID) | Primary key |
| `part_name` | String | Tên phụ tùng |
| `image_url` | String? | Ảnh phụ tùng |
| `quantity` | Int | Số lượng tồn kho (mặc định: 0) |
| `min_threshold` | Int | Ngưỡng tồn kho tối thiểu (cảnh báo khi dưới ngưỡng) |
| `unit_price` | Float | Giá nhập |
| `sell_price` | Float | Giá bán |
| `warranty_days` | Int | Số ngày bảo hành phụ tùng (mặc định: 0) |

#### Bảng `parts_used` (Phụ tùng đã dùng trong phiếu)
| Trường | Kiểu | Mô tả |
|--------|------|-------|
| `id` | String (UUID) | Primary key |
| `order_id` | String (FK→work_orders) | ID phiếu sửa chữa |
| `part_id` | String (FK→inventory) | ID phụ tùng |
| `quantity` | Int | Số lượng sử dụng |
| `unit_price` | Float | Giá tại thời điểm sử dụng |

#### Bảng `part_warranties` (Bảo hành phụ tùng từng lần sửa)
| Trường | Kiểu | Mô tả |
|--------|------|-------|
| `id` | String (UUID) | Primary key |
| `part_used_id` | String (FK→parts_used, unique) | ID phụ tùng đã dùng |
| `part_id` | String (FK→inventory) | ID phụ tùng |
| `work_order_id` | String (FK→work_orders) | ID phiếu sửa chữa |
| `vehicle_id` | String (FK→vehicles) | ID xe |
| `warranty_days` | Int | Số ngày bảo hành |
| `start_date` | DateTime | Ngày bắt đầu bảo hành (= ngày hoàn thành phiếu) |
| `expiry_date` | DateTime | Ngày hết hạn bảo hành |

**Lưu ý**: Bảo hành phụ tùng được tự động tạo khi phiếu sửa chữa chuyển sang trạng thái `COMPLETED`. Ngày hết hạn bảo hành của xe (`vehicles.warranty_expiry`) cũng được tự động cập nhật theo ngày hết hạn muộn nhất trong tất cả bảo hành phụ tùng.

#### Bảng `appointments` (Lịch hẹn)
| Trường | Kiểu | Mô tả |
|--------|------|-------|
| `id` | String (UUID) | Primary key |
| `customer_id` | String (FK→users) | ID khách hàng |
| `vehicle_id` | String? (FK→vehicles) | ID xe (nếu biết) |
| `scheduled_at` | DateTime | Thời điểm hẹn |
| `service_type` | String? | Loại dịch vụ |
| `notes` | String? | Ghi chú |
| `status` | AppointmentStatus | Trạng thái (mặc định: PENDING) |
| `deleted_at` | DateTime? | Soft delete (xóa mềm lịch sử) |

**Lưu ý**: Khi tạo phiếu sửa chữa (`WorkOrder`) từ lịch hẹn, lịch hẹn đó tự động chuyển sang `COMPLETED`.

#### Bảng `maintenance_logs` (Lịch sử bảo dưỡng)
| Trường | Kiểu | Mô tả |
|--------|------|-------|
| `id` | String (UUID) | Primary key |
| `vehicle_id` | String (FK→vehicles) | ID xe |
| `work_order_id` | String? (FK→work_orders, unique) | ID phiếu sửa chữa tương ứng |
| `odometer_km` | Int | Số km odometer tại thời điểm bảo dưỡng |
| `service_type` | String? | Loại dịch vụ |
| `service_summary` | String? | Tóm tắt các dịch vụ đã thực hiện |
| `next_service_km` | Int? | Km kế tiếp cần bảo dưỡng |
| `next_service_date` | DateTime? | Ngày kế tiếp bảo dưỡng |
| `notes` | String? | Ghi chú |
| `performed_at` | DateTime | Ngày thực hiện |

**Lưu ý**: `MaintenanceLog` được tự động tạo/cập nhật (upsert) khi phiếu sửa chữa chuyển sang `COMPLETED`.

#### Bảng `chat_conversations` và `chat_messages`
- `chat_conversations`: Lưu mỗi cuộc trò chuyện của người dùng với AI (1 user có thể có nhiều conversations)
- `chat_messages`: Lưu từng tin nhắn (role: `user` hoặc `bot`)

#### Bảng `warranties` (Bảo hành tổng hợp xe – do STAFF tạo thủ công)
| Trường | Kiểu | Mô tả |
|--------|------|-------|
| `id` | String (UUID) | Primary key |
| `vehicle_id` | String (FK→vehicles) | ID xe |
| `warrantyType` | String | Loại bảo hành (VD: "Bảo hành động cơ", "Bảo hành pin") |
| `start_date` | DateTime | Ngày bắt đầu |
| `expiry_date` | DateTime | Ngày hết hạn |
| `terms` | String? | Điều khoản bảo hành |
| `issued_by` | String? | Đơn vị cấp bảo hành |

---

## 5. BACKEND API ENDPOINTS

### 5.1 Authentication (`/api/auth`)
| Method | Endpoint | Auth | Mô tả |
|--------|----------|------|-------|
| POST | `/api/auth/register` | Public | Đăng ký tài khoản mới (mặc định role=CUSTOMER) |
| POST | `/api/auth/login` | Public | Đăng nhập bằng email hoặc số điện thoại + password |
| POST | `/api/auth/logout` | JWT | Đăng xuất |
| GET | `/api/auth/me` | JWT | Lấy thông tin người dùng hiện tại |

**Login Request Body**: `{ identifier: string, password: string }` (identifier là email hoặc phone)  
**Login Response**: `{ token: string, user: { id, email, name, role, phoneNumber, avatarUrl, loyaltyPoints, treesPlanted } }`  
**JWT**: Payload là `{ userId, role }`, thời hạn 7 ngày

### 5.2 Users (`/api/users`)
| Method | Endpoint | Auth | Mô tả |
|--------|----------|------|-------|
| GET | `/api/users` | JWT | Lấy danh sách người dùng (có thể lọc theo role) |
| GET | `/api/users/:id` | JWT | Lấy thông tin người dùng theo ID |
| PUT | `/api/users/:id` | JWT | Cập nhật thông tin người dùng |
| DELETE | `/api/users/:id` | JWT (STAFF) | Xóa người dùng |
| GET | `/api/users/technicians` | JWT | Lấy danh sách kỹ thuật viên |

### 5.3 Vehicles (`/api/vehicles`)
| Method | Endpoint | Auth | Mô tả |
|--------|----------|------|-------|
| GET | `/api/vehicles` | JWT | Lấy danh sách xe (CUSTOMER: chỉ xe của mình; STAFF/TECH: tất cả; có search theo biển số/model/brand) |
| GET | `/api/vehicles/:id` | JWT | Lấy chi tiết xe kèm lịch sử phiếu sửa chữa |
| GET | `/api/vehicles/plate/:licensePlate` | JWT | Tra cứu xe theo biển số |
| GET | `/api/vehicles/:id/maintenance-logs` | JWT | Lấy lịch sử bảo dưỡng của xe |
| POST | `/api/vehicles` | JWT (STAFF) | Tạo xe mới |
| PUT | `/api/vehicles/:id` | JWT | Cập nhật thông tin xe (odometer không được giảm) |
| DELETE | `/api/vehicles/:id` | JWT (STAFF) | Xóa xe |

**Permission**: CUSTOMER chỉ xem xe của mình, STAFF/TECHNICIAN xem tất cả.

### 5.4 Work Orders – Phiếu Sửa Chữa (`/api/work-orders`)
Đây là module trung tâm và phức tạp nhất của hệ thống.

| Method | Endpoint | Auth | Mô tả |
|--------|----------|------|-------|
| GET | `/api/work-orders` | JWT | Lấy danh sách phiếu (có filter: status, technicianId, vehicleId, search, sortBy) |
| GET | `/api/work-orders/:id` | JWT | Lấy chi tiết phiếu (kèm xe, chủ xe, KTV, dịch vụ, ảnh, phụ tùng) |
| POST | `/api/work-orders` | JWT (STAFF) | Tạo phiếu sửa chữa mới (Vehicle Intake) |
| PATCH | `/api/work-orders/:id/status` | JWT | Cập nhật trạng thái phiếu |
| PATCH | `/api/work-orders/:id/assign` | JWT (STAFF) | Phân công kỹ thuật viên |
| PATCH | `/api/work-orders/:id/parts` | JWT | Thêm phụ tùng vào phiếu |
| POST | `/api/work-orders/:id/services` | JWT | Thêm dịch vụ vào phiếu |
| PATCH | `/api/work-orders/:id/services/:serviceId` | JWT | Cập nhật trạng thái dịch vụ (isDone) |
| PATCH | `/api/work-orders/:id/services/:serviceId/approval` | JWT | Phê duyệt/từ chối dịch vụ |
| POST | `/api/work-orders/:id/photos` | JWT | Thêm ảnh vào phiếu |
| DELETE | `/api/work-orders/:id/photos/:photoId` | JWT | Xóa ảnh |
| PATCH | `/api/work-orders/:id/payment` | JWT (STAFF) | Cập nhật thông tin thanh toán |
| GET | `/api/work-orders/dashboard-stats` | JWT (STAFF) | Lấy thống kê dashboard |
| GET | `/api/work-orders/revenue-report` | JWT (STAFF) | Lấy báo cáo doanh thu |

**Quy trình tạo phiếu (POST /api/work-orders)**:
- Tự động tạo `orderNumber` dạng `WO-{năm}-{số thứ tự 3 chữ số}` (VD: `WO-2026-001`)
- Kiểm tra tồn kho trước khi dùng phụ tùng, tự động trừ số lượng
- Cập nhật `currentKm` cho xe nếu được cung cấp (odometer không được giảm)
- Nếu tạo từ lịch hẹn (`appointmentId`), tự động cập nhật lịch hẹn sang `COMPLETED`

**Logic khi chuyển trạng thái sang COMPLETED**:
1. Tính `totalPrice` = tổng tiền phụ tùng + tổng tiền dịch vụ
2. Tự động tạo/cập nhật `MaintenanceLog` với odometer hiện tại
3. Tự động tạo `PartWarranty` cho từng phụ tùng có `warrantyDays > 0`
4. Cập nhật `vehicles.warranty_expiry` theo ngày hết hạn bảo hành muộn nhất
5. Tính điểm loyalty: 1 điểm / 20.000 VNĐ (`floor(totalPrice / 20000)`)
6. Tính số cây trồng: 1 cây cơ bản + 1 cây / 500.000 VNĐ (`1 + floor(totalPrice / 500000)`)

**Logic Loyalty Points**:
- Điểm tích lũy: 1 điểm = 20.000 VNĐ doanh thu
- Điểm đổi thưởng: Khách hàng có thể dùng điểm để giảm tiền khi thanh toán (lưu vào `pointsRedeemed` và `pointsDiscount`)
- Gamification: Mỗi lần sửa xe điện tương đương trồng thêm cây (eco-friendly concept)

### 5.5 Inventory – Tồn Kho (`/api/inventory`)
| Method | Endpoint | Auth | Mô tả |
|--------|----------|------|-------|
| GET | `/api/inventory` | JWT | Lấy danh sách phụ tùng (có filter theo quantity threshold) |
| GET | `/api/inventory/:id` | JWT | Lấy chi tiết phụ tùng |
| POST | `/api/inventory` | JWT (STAFF) | Tạo phụ tùng mới |
| PUT | `/api/inventory/:id` | JWT (STAFF) | Cập nhật phụ tùng |
| DELETE | `/api/inventory/:id` | JWT (STAFF) | Xóa phụ tùng |

### 5.6 Appointments – Lịch Hẹn (`/api/appointments`)
| Method | Endpoint | Auth | Mô tả |
|--------|----------|------|-------|
| GET | `/api/appointments` | JWT (STAFF) | Lấy tất cả lịch hẹn (có filter date, dateFrom, dateTo, status) |
| GET | `/api/appointments/my` | JWT (CUSTOMER) | Lấy lịch hẹn của customer hiện tại |
| POST | `/api/appointments` | JWT | Tạo lịch hẹn mới |
| PATCH | `/api/appointments/:id/cancel` | JWT | Hủy lịch hẹn (chỉ owner) |
| DELETE | `/api/appointments/:id` | JWT (STAFF) | Xóa lịch hẹn |
| DELETE | `/api/appointments/my/history` | JWT | Customer xóa lịch sử lịch hẹn đã hủy/hoàn thành (soft delete) |

**Lưu ý về timezone**: API sử dụng offset UTC+7 (múi giờ Việt Nam) khi lọc theo ngày.

### 5.7 Warranties – Bảo Hành (`/api/warranties`)
| Method | Endpoint | Auth | Mô tả |
|--------|----------|------|-------|
| GET | `/api/warranties` | JWT (STAFF) | Lấy tất cả bảo hành (filter: status, expiringSoon) |
| GET | `/api/warranties/:id` | JWT | Lấy chi tiết bảo hành |
| POST | `/api/warranties` | JWT (STAFF) | Tạo bảo hành mới cho xe |
| PUT | `/api/warranties/:id` | JWT (STAFF) | Cập nhật bảo hành |
| DELETE | `/api/warranties/:id` | JWT (STAFF) | Xóa bảo hành |
| GET | `/api/vehicles/:vehicleId/warranties` | JWT | Lấy bảo hành của xe cụ thể (cả warranty tổng và part_warranty) |

**Trạng thái bảo hành tính toán phía backend**:
- `ACTIVE`: Còn > 30 ngày
- `EXPIRING_SOON`: Còn ≤ 30 ngày
- `EXPIRED`: Đã hết hạn (< 0 ngày)

### 5.8 Chat AI (`/api/chat`)
| Method | Endpoint | Auth | Mô tả |
|--------|----------|------|-------|
| POST | `/api/chat/message` | JWT | Gửi tin nhắn đến AI, nhận phản hồi |
| GET | `/api/chat/history` | JWT | Lấy lịch sử hội thoại |

**Cơ chế AI**:
- Sử dụng Google Gemini API với model `gemini-2.5-flash`
- **2 mô hình AI khác nhau theo role**:
  - `customerModel`: Dành cho CUSTOMER – có thể xem xe của mình, tra cứu xe khác, xem dịch vụ, xem khung giờ trống, **đặt lịch hẹn**
  - `technicianModel`: Dành cho TECHNICIAN – có thể tra cứu xe, kiểm tra tồn kho phụ tùng, tra cứu phiếu sửa chữa
- Sử dụng **Function Calling** (Tool Use) để AI tự động gọi các hàm truy vấn database:
  - `getMyVehicles`: Lấy xe của user đang chat
  - `lookupVehicle(licensePlate)`: Tra cứu xe theo biển số
  - `getServiceTypes`: Lấy danh sách dịch vụ và giá
  - `getAvailableSlots(date)`: Xem slot trống trong ngày
  - `createAppointment(vehicleId, serviceType, date, time, notes)`: Đặt lịch
  - `checkInventory(query)`: Tìm phụ tùng trong kho
  - `searchWorkOrders(query)`: Tìm phiếu sửa chữa
- Lưu lịch sử hội thoại vào database (lấy tối đa 20 tin nhắn gần nhất làm context)
- Tối đa 5 vòng lặp function calling cho mỗi tin nhắn
- Ngôn ngữ: Tiếng Việt, phong cách thân thiện, lịch sự

---

## 6. TÍNH NĂNG CHI TIẾT THEO VAI TRÒ

### 6.1 Giao diện STAFF (Nhân viên/Quản lý) – `packages/features/admin`

#### 6.1.1 Dashboard (`AdminDashboardPage`)
Màn hình chính với 4 tab navigation:
1. **Home** (Dashboard tổng quan)
2. **Tra cứu** (Lookup)
3. **Tiếp nhận** (Vehicle Intake)
4. **Profile** (Hồ sơ)

Nội dung Home Dashboard:
- **Quick Stats Grid**: 3 thẻ thống kê:
  - Số xe đang sửa (`vehiclesInService`)
  - Số xe hoàn thành hôm nay (`completedToday`)
  - Doanh thu hôm nay (VND, format `1.500.000 VND`)
- **Biểu đồ doanh thu 7 ngày**: Bar chart tùy chỉnh (custom canvas, không dùng thư viện bên ngoài), hiển thị doanh thu từng ngày trong 7 ngày gần nhất (trục Y: đơn vị triệu, VD: "2tr"), click vào bar để xem tooltip giá trị cụ thể
- **Quick Shortcuts**: Các nút tắt đến các trang chính
- **Alerts Section**: Cảnh báo tồn kho thấp (phụ tùng dưới ngưỡng tối thiểu), cảnh báo bảo hành sắp hết hạn
- **Technicians Section**: Danh sách kỹ thuật viên và trạng thái

#### 6.1.2 Vehicle Intake – Tiếp nhận xe (`VehicleIntakePage`)
**Đây là màn hình phức tạp nhất (~84KB) trong toàn bộ ứng dụng**, xử lý toàn bộ quy trình tiếp nhận xe:

**Bước 1 – Tra cứu xe**:
- Tìm xe bằng biển số (nhập tay hoặc quét QR code bằng `mobile_scanner`)
- Hiển thị thông tin xe: biển số, model, màu, odometer, chủ xe
- Tùy chọn tạo xe mới nếu chưa có trong hệ thống

**Bước 2 – Tạo phiếu sửa chữa**:
- Chọn các dịch vụ cần thực hiện (checkbox theo loại: Bảo dưỡng định kỳ, Kiểm tra pin, Phanh & Lốp, Sửa chữa khác)
- Thêm mô tả chi tiết cho từng dịch vụ
- Phân công kỹ thuật viên
- Nhập odometer hiện tại
- Ghi chú
- Chụp/upload ảnh tình trạng xe lúc tiếp nhận (`image_picker` + Supabase Storage)
- Xem trước và tạo phiếu

**Reception Hub** (`ReceptionHubPage`): Trang tổng hợp lịch hẹn ngày hôm nay, hiển thị theo timeline, cho phép tạo phiếu từ lịch hẹn sẵn có.

#### 6.1.3 Danh sách phiếu sửa chữa (`WorkOrderListPage`)
- Tab theo trạng thái: Chờ xử lý, Đang thực hiện, Kiểm tra, Hoàn thành, Đã thanh toán, Đã hủy
- Tìm kiếm theo biển số, mã phiếu, tên khách hàng
- Mỗi phiếu hiển thị: mã phiếu, xe, KTV, dịch vụ, trạng thái, thời gian

#### 6.1.4 Chi tiết phiếu sửa chữa (`WorkOrderDetailPage`)
- Xem toàn bộ thông tin phiếu
- Cập nhật trạng thái (kéo dropdown)
- Phân công/thay đổi KTV
- Thêm/xóa dịch vụ
- Quản lý phụ tùng sử dụng
- Xem ảnh trước/sau sửa
- Thanh toán: chọn phương thức (Tiền mặt/Thẻ/Chuyển khoản), áp dụng điểm loyalty
- Xem thông tin chủ xe: điểm loyalty, số cây đã trồng

#### 6.1.5 Báo cáo doanh thu (`AdminRevenueReportPage`)
- Biểu đồ doanh thu theo ngày/tuần/tháng (~78KB)
- Tổng doanh thu, số phiếu, doanh thu trung bình
- Lọc theo khoảng thời gian

#### 6.1.6 Tra cứu (`AdminLookupPage`)
Giao diện tra cứu đa chức năng với "Radial Menu" (menu tròn xòe ra):
- Tra cứu xe theo biển số → xem lịch sử, bảo hành, thông tin chủ xe
- Tra cứu khách hàng
- Tra cứu kỹ thuật viên
- Tra cứu hóa đơn/phiếu sửa chữa

#### 6.1.7 Quản lý tồn kho (`InventoryPage`)
- Danh sách phụ tùng với số lượng tồn kho
- Cảnh báo phụ tùng dưới ngưỡng tối thiểu
- Thêm/sửa/xóa phụ tùng

#### 6.1.8 Cảnh báo (`AdminAlertsPage`)
- Danh sách cảnh báo: tồn kho thấp, bảo hành sắp hết hạn

### 6.2 Giao diện TECHNICIAN (Kỹ thuật viên) – `packages/features/technician`

#### 6.2.1 Dashboard (`TechnicianDashboardPage`)
- Chào mừng kỹ thuật viên
- Thống kê cá nhân: số công việc hoàn thành, đang làm
- Danh sách công việc được phân công (được làm nổi bật những việc ưu tiên)
- Draggable FAB (nút nổi có thể kéo thả) để truy cập nhanh

#### 6.2.2 Danh sách công việc (`TechnicianWorkListPage`)
- Lọc phiếu theo trạng thái
- Xem chi tiết từng phiếu công việc

#### 6.2.3 Chi tiết công việc (`WorkDetailPage`)
- Xem chi tiết phiếu sửa chữa được phân công
- Tick hoàn thành từng dịch vụ (`isDone = true`)
- Cập nhật trạng thái phiếu (chuyển từ IN_PROGRESS sang INSPECTION, COMPLETED)

#### 6.2.4 Tra cứu (`TechnicianLookupPage`)
Radial Menu cho kỹ thuật viên:
- Tra cứu xe theo biển số
- Kiểm tra tồn kho phụ tùng
- Tra cứu danh sách xe (`VehicleListPage`, `VehicleResultPage`)
- Tra cứu phiếu sửa chữa
- Xem bảo hành xe

#### 6.2.5 Thống kê cá nhân (`TechStatsPage`)
- Số liệu thống kê cá nhân của kỹ thuật viên

#### 6.2.6 Chat AI (`TechChatFloatingBubble`)
- Nút chat nổi trên màn hình (draggable)
- Chat với AI để tra cứu xe, phụ tùng, phiếu sửa chữa

#### 6.2.7 Settings (`SettingsPage`)
- Cài đặt ứng dụng, đăng xuất

### 6.3 Giao diện CUSTOMER (Khách hàng) – `packages/features/customer`

#### 6.3.1 Danh sách xe (`MyVehiclesPage`)
- Màn hình chính với Bottom Navigation Bar:
  1. Xe của tôi
  2. Lịch hẹn
  3. Chat AI
  4. Tài khoản
- Hiển thị danh sách xe của khách hàng với thông tin cơ bản
- Card xe: ảnh, biển số, model, odometer, trạng thái bảo hành

#### 6.3.2 Chi tiết xe (`VehicleDetailPage`)
Màn hình lớn (~55KB):
- Thông tin chi tiết xe
- Lịch sử sửa chữa (timeline)
- Thông tin bảo hành
- Nút đặt lịch hẹn nhanh

#### 6.3.3 Chi tiết phiếu sửa chữa – góc nhìn khách hàng (`CustomerWorkOrderDetailPage`)
Màn hình lớn (~61KB):
- Xem chi tiết phiếu sửa chữa của xe mình
- Xem từng dịch vụ và trạng thái thực hiện
- Xem ảnh trước/sau
- Xem phụ tùng đã thay
- Thông tin thanh toán
- Thông tin bảo hành phụ tùng

#### 6.3.4 Bảo hành (`CustomerWarrantyPage`)
- Xem danh sách bảo hành của xe
- Phân loại: bảo hành tổng (do garage cấp), bảo hành phụ tùng (tự động từ phiếu sửa chữa)
- Trạng thái: Còn hạn / Sắp hết hạn / Đã hết hạn

#### 6.3.5 Lịch hẹn (`AppointmentsPage`, `CreateAppointmentPage`)
- Xem danh sách lịch hẹn
- Tạo lịch hẹn mới: chọn xe, loại dịch vụ, ngày giờ, ghi chú
- Hủy lịch hẹn (PENDING/CONFIRMED → CANCELLED)
- Xóa lịch sử lịch hẹn đã hủy/hoàn thành

#### 6.3.6 Chat AI (`ChatFloatingBubble`)
- Nút chat nổi (draggable)
- Chat để hỏi về dịch vụ, giá, đặt lịch, xem xe
- AI tự động đặt lịch hẹn theo yêu cầu

#### 6.3.7 Tài khoản (`CustomerAccountPage`)
- Thông tin cá nhân
- Điểm loyalty tích lũy
- Số cây đã trồng (eco gamification)
- Đăng xuất

---

## 7. PHÂN QUYỀN (AUTHORIZATION)

### 7.1 JWT Authentication
- Token được gửi qua header: `Authorization: Bearer <token>`
- Middleware `authenticate` kiểm tra token trên tất cả route cần auth
- Payload token: `{ userId: string, role: string }`
- Hết hạn: 7 ngày (configurable qua `JWT_EXPIRES_IN`)

### 7.2 Role-Based Access Control (RBAC)
```
CUSTOMER:
  - Chỉ xem xe của chính mình
  - Chỉ xem phiếu sửa chữa của xe mình
  - Chỉ xem/hủy lịch hẹn của mình
  - Chỉ xem bảo hành xe của mình
  - Tạo lịch hẹn mới

TECHNICIAN:
  - Xem tất cả xe, phiếu sửa chữa
  - Cập nhật trạng thái dịch vụ (isDone) trong phiếu được phân công
  - Cập nhật trạng thái phiếu sửa chữa
  - Tra cứu tồn kho
  
STAFF:
  - Toàn quyền tất cả resource
  - Tạo/xóa xe, tạo phiếu sửa chữa
  - Quản lý tồn kho, bảo hành
  - Xem dashboard và báo cáo doanh thu
  - Quản lý lịch hẹn
  - Phân công kỹ thuật viên
```

---

## 8. LUỒNG NGHIỆP VỤ CHÍNH (BUSINESS FLOWS)

### 8.1 Luồng tiếp nhận xe và xử lý phiếu sửa chữa
```
1. STAFF mở app → vào tab "Tiếp nhận xe"
2. Quét QR code hoặc nhập biển số xe
3. Hệ thống tìm xe (GET /api/vehicles/plate/:plate)
   - Nếu có xe: hiển thị thông tin
   - Nếu không có: tạo xe mới
4. STAFF chọn dịch vụ cần làm, phân công KTV, nhập odometer, chụp ảnh
5. Tạo phiếu (POST /api/work-orders)
   - Tự tạo orderNumber: WO-2026-001
   - Trừ phụ tùng từ kho nếu có
   - Status: PENDING
6. KTV nhận thông báo về công việc mới
7. KTV mở app → Dashboard → xem phiếu được phân công
8. KTV bắt đầu làm: PENDING → IN_PROGRESS
9. KTV tick từng dịch vụ hoàn thành (isDone = true)
10. KTV kết thúc: IN_PROGRESS → INSPECTION (kiểm tra lại)
11. STAFF kiểm tra → COMPLETED
    - Tự tính totalPrice
    - Tạo MaintenanceLog
    - Tạo PartWarranty cho phụ tùng có bảo hành
    - Cập nhật warranty_expiry của xe
    - Cộng điểm loyalty và cây trồng cho khách hàng
12. STAFF thanh toán: COMPLETED → PAID
    - Chọn phương thức thanh toán
    - Áp dụng điểm loyalty (nếu khách muốn)
```

### 8.2 Luồng đặt lịch hẹn (qua app hoặc AI)
```
Qua App:
1. CUSTOMER vào tab "Lịch hẹn" → "Tạo lịch hẹn"
2. Chọn xe, loại dịch vụ, ngày giờ, ghi chú
3. POST /api/appointments → Status: PENDING

Qua AI Chat:
1. CUSTOMER mở chat với AI
2. "Tôi muốn đặt lịch bảo dưỡng xe 59A-12345 vào ngày 25/6/2026"
3. AI gọi getMyVehicles() để xác nhận xe
4. AI gọi getAvailableSlots(date) để xem slot trống
5. AI gọi createAppointment(...) → tạo lịch hẹn
6. AI phản hồi xác nhận thành công

Xử lý lịch hẹn:
7. STAFF xem lịch hẹn trong Reception Hub
8. STAFF tạo phiếu từ lịch hẹn → lịch hẹn chuyển COMPLETED
```

### 8.3 Luồng quản lý bảo hành
```
Bảo hành tổng (thủ công):
- STAFF tạo warranty mới cho xe (VD: "Bảo hành động cơ 2 năm")
- POST /api/warranties

Bảo hành phụ tùng (tự động):
- Khi phiếu COMPLETED, mỗi phụ tùng có warrantyDays > 0 → tạo PartWarranty
- Ngày bắt đầu = ngày hoàn thành phiếu
- Ngày hết hạn = ngày bắt đầu + warrantyDays

Xem bảo hành:
- CUSTOMER: CustomerWarrantyPage → GET /api/vehicles/:id/warranties
- Backend tính daysRemaining và trạng thái: ACTIVE / EXPIRING_SOON / EXPIRED
```

---

## 9. CẤU TRÚC THƯ MỤC ĐẦY ĐỦ

```
Du_An/
├── lib/                          # Flutter app entry point
│   ├── main.dart                 # Entry point: Supabase init, DI, MaterialApp
│   └── core/
│       ├── di/
│       │   └── injection.dart    # GetIt + Injectable configuration
│       └── routes/
│           └── app_router.dart   # Route definitions + SplashScreen
│
├── packages/
│   ├── core/                     # Shared utilities package
│   │   └── lib/
│   │       ├── core.dart
│   │       ├── src/
│   │       │   ├── error/        # Failure classes (abstract Error types)
│   │       │   ├── models/       # Base model classes
│   │       │   ├── usecase/      # Abstract UseCase class
│   │       │   ├── utils/        # Utility functions
│   │       │   └── widgets/      # Shared widgets
│   │       └── services/
│   │
│   ├── design_system/            # UI Theme package
│   │   └── lib/
│   │       └── design_system.dart  # AppTheme, colors, typography
│   │
│   └── features/
│       ├── auth/                 # Authentication feature
│       │   └── lib/
│       │       ├── auth.dart
│       │       ├── data/
│       │       │   ├── datasources/remote/auth_remote_datasource.dart
│       │       │   ├── datasources/local/auth_local_datasource.dart  # Token storage
│       │       │   ├── interceptors/auth_interceptor.dart
│       │       │   ├── models/user_model.dart
│       │       │   ├── models/auth_response_model.dart
│       │       │   └── repositories/auth_repository_impl.dart
│       │       ├── di/auth_di.dart
│       │       ├── domain/
│       │       │   ├── entities/user.dart           # { id, email, name, role, phone, avatar, loyaltyPoints, treesPlanted }
│       │       │   ├── repositories/auth_repository.dart
│       │       │   └── usecases/                    # login, register, logout, getCurrentUser
│       │       └── presentation/
│       │           ├── bloc/auth_bloc.dart          # AuthCheckRequested → AuthAuthenticated/Unauthenticated
│       │           ├── login/                       # LoginPage, LoginBloc
│       │           ├── register/                    # RegisterPage, RegisterBloc
│       │           └── widgets/                     # LogoutButton, UserAvatar
│       │
│       ├── admin/                # Staff/Admin feature
│       │   └── lib/
│       │       ├── admin.dart
│       │       ├── data/
│       │       │   ├── datasources/remote/          # dashboard, vehicle, work_order, appointment, revenue datasources
│       │       │   ├── models/                      # AdminAppointmentModel, DashboardStatsModel, VehicleModel, WorkOrderModel, TechnicianModel
│       │       │   └── repositories/               # VehicleIntakeRepository (tổng hợp nhiều datasource)
│       │       ├── di/admin_di.dart
│       │       ├── domain/
│       │       │   ├── entities/                    # AdminAppointment, DashboardStats, LookupCategory, LookupResult, RevenueReport
│       │       │   ├── repositories/               # DashboardRepository, AdminAppointmentRepository, RevenueReportRepository
│       │       │   └── usecases/                   # GetDashboardStats, GetRevenueReport, GetUpcomingAppointments, SearchLookup, DeleteAppointment
│       │       └── presentation/
│       │           ├── dashboard/
│       │           │   ├── bloc/                   # DashboardBloc, RevenueReportBloc
│       │           │   ├── pages/                  # AdminDashboardPage, WorkOrderListPage, WorkOrderDetailPage, AdminRevenueReportPage, InventoryPage, AdminAlertsPage
│       │           │   └── widgets/                # StatCard, ShortcutButton, AlertItem, TechnicianItem, BottomNavItem
│       │           ├── vehicle_intake/
│       │           │   ├── bloc/                   # VehicleIntakeBloc, AdminAppointmentBloc
│       │           │   ├── pages/                  # VehicleIntakePage (84KB!), ReceptionHubPage (39KB)
│       │           │   └── widgets/                # ServiceCheckbox
│       │           ├── lookup/
│       │           │   ├── bloc/                   # LookupBloc
│       │           │   ├── pages/                  # AdminLookupPage, VehicleLookupPage, CustomerLookupPage, InvoiceLookupPage
│       │           │   └── widgets/                # RadialLookupMenu, VehicleSearchResultCard, CustomerDetailSheet, TechnicianDetailSheet, InvoiceDetailSheet
│       │           └── warranty/
│       │               └── pages/admin_vehicle_warranty_page.dart
│       │
│       ├── customer/             # Customer feature
│       │   └── lib/
│       │       ├── customer.dart
│       │       ├── data/
│       │       │   ├── datasources/remote/         # vehicle, work_order, appointment datasources
│       │       │   ├── models/                     # CustomerVehicleModel, CustomerWorkOrderModel, CustomerAppointmentModel
│       │       │   └── repositories/customer_repository_impl.dart
│       │       ├── di/customer_di.dart
│       │       ├── domain/
│       │       │   ├── entities/                   # CustomerVehicle, CustomerWorkOrder, CustomerAppointment, CustomerMaintenanceLog
│       │       │   ├── repositories/customer_repository.dart
│       │       │   └── usecases/                   # GetCustomerVehicles, GetVehicleWorkOrders, GetMyAppointments, CreateAppointment, CancelAppointment
│       │       └── presentation/
│       │           ├── vehicles/
│       │           │   ├── bloc/                   # CustomerVehicleBloc, CustomerWorkOrderBloc
│       │           │   ├── pages/                  # MyVehiclesPage, VehicleDetailPage (55KB), CustomerWorkOrderDetailPage (61KB)
│       │           │   └── widgets/                # CustomerVehicleCard, CustomerAppBar, CustomerBottomNav, CustomerWorkOrderCard
│       │           ├── warranties/
│       │           │   └── pages/customer_warranty_page.dart
│       │           ├── account/
│       │           │   └── pages/customer_account_page.dart
│       │           ├── appointments/
│       │           │   ├── bloc/appointment_bloc.dart
│       │           │   ├── pages/                  # AppointmentsPage, CreateAppointmentPage
│       │           │   └── widgets/appointment_card.dart
│       │           └── chat/
│       │               ├── bloc/                   # ChatBloc, ChatEvent, ChatState
│       │               └── widgets/chat_floating_bubble.dart
│       │
│       └── technician/           # Technician feature
│           └── lib/
│               ├── technician.dart
│               ├── data/
│               │   ├── datasources/remote/         # work_remote, tech_lookup_remote
│               │   ├── datasources/local/work_local_datasource.dart
│               │   ├── models/                     # WorkItemModel, VehicleDetailModel, InventoryPartModel
│               │   └── repositories/               # WorkRepositoryImpl, TechLookupRepositoryImpl
│               ├── di/technician_di.dart
│               ├── domain/
│               │   ├── entities/                   # WorkItem, VehicleDetail, InventoryPart, TechLookupCategory, WorkItemService
│               │   ├── repositories/               # WorkRepository, TechLookupRepository
│               │   └── usecases/                   # GetWorkItems, UpdateWorkStatus, SearchVehicleByPlate, GetVehicleWarranties, GetAllVehicles, GetInventoryParts, SearchWorkOrders
│               └── presentation/
│                   ├── dashboard/
│                   │   ├── bloc/                   # TechDashboardBloc
│                   │   ├── pages/                  # TechnicianDashboardPage, TechnicianWorkListPage
│                   │   └── widgets/                # DashboardHeader, GreetingSection, StatsCard, WorkCard, DraggableFAB, DashboardBottomNav
│                   ├── work_detail/
│                   │   └── pages/work_detail_page.dart
│                   ├── settings/
│                   │   └── pages/settings_page.dart
│                   ├── lookup/
│                   │   ├── bloc/                   # VehicleDetailBloc, VehicleListBloc, PartsLookupBloc
│                   │   ├── pages/                  # TechnicianLookupPage, VehicleResultPage, VehicleListPage, PartsLookupPage, TechStatsPage
│                   │   └── widgets/                # TechnicianRadialMenu
│                   └── chat/
│                       ├── bloc/                   # TechChatBloc, TechChatEvent, TechChatState
│                       └── widgets/tech_chat_floating_bubble.dart
│
├── backend/
│   ├── src/
│   │   ├── server.ts             # Express app setup, middleware, routes registration
│   │   ├── controllers/
│   │   │   ├── auth.controller.ts
│   │   │   ├── user.controller.ts
│   │   │   ├── vehicle.controller.ts
│   │   │   ├── work-order.controller.ts  # Phức tạp nhất (1529 dòng, 45KB)
│   │   │   ├── inventory.controller.ts
│   │   │   ├── appointment.controller.ts
│   │   │   ├── warranty.controller.ts
│   │   │   └── chat.controller.ts
│   │   ├── routes/               # Route definitions (auth, user, vehicle, work-order, inventory, appointment, warranty, chat)
│   │   ├── middleware/
│   │   │   ├── auth.middleware.ts       # JWT authenticate + requireRole
│   │   │   ├── error.middleware.ts      # Global error handler
│   │   │   └── validation.middleware.ts # express-validator middleware
│   │   └── services/
│   │       └── gemini.ts         # Google Gemini AI integration (358 dòng)
│   └── prisma/
│       ├── schema.prisma         # Database schema (304 dòng)
│       ├── seed.ts               # Seed data (23KB – tạo dữ liệu mẫu)
│       └── migrations/          # Prisma migrations
│
├── assets/
│   └── fonts/
│       └── Roboto-Variable.ttf  # Font chữ
│
├── pubspec.yaml                  # Flutter dependencies (root app)
├── start-dev.bat                 # Script khởi động dev environment (Windows)
└── UX/                           # Thư mục thiết kế UX (mockup HTML/CSS)
```

---

## 10. CẤU HÌNH MÔI TRƯỜNG

### 10.1 Backend – Biến môi trường

Dự án có **2 chế độ database** có thể chuyển đổi:

**`.env` (đang dùng – Supabase cloud):**
```bash
# Database – Supabase PostgreSQL (production/demo)
# Kết nối qua Supabase connection pooler (AWS ap-southeast-2)
DATABASE_URL="postgresql://postgres.<project-id>:<password>@aws-1-ap-southeast-2.pooler.supabase.com:5432/postgres"

# JWT
JWT_SECRET="your-super-secret-jwt-key"
JWT_EXPIRES_IN="7d"

# Server
PORT=3000
NODE_ENV="development"

# CORS
ALLOWED_ORIGINS="http://localhost:*,http://127.0.0.1:*"

# Google Gemini AI
GEMINI_API_KEY="your-gemini-api-key"
```

**`.env.local` (tùy chọn – Local PostgreSQL, nhanh hơn nhưng mất Realtime):**
```bash
DATABASE_URL="postgresql://postgres:postgres123@localhost:5432/nanglungsach?schema=public"
```

> **Lưu ý quan trọng**: Phải dùng Supabase PostgreSQL (`.env`) thì mới có **Supabase Realtime** hoạt động, vì Realtime dựa vào Postgres logical replication chỉ khả dụng trên Supabase. Nếu dùng local PG thì tính năng cập nhật real-time phiếu sửa chữa sẽ không hoạt động.

### 10.2 Flutter – Cấu hình Supabase
Hardcode trong `lib/main.dart`:
```
Supabase URL: https://fvagqenqcsmoaaiuubvx.supabase.co
Supabase Anon Key: [JWT key]
```

### 10.3 API Base URL trong Flutter
- Android Emulator: `http://10.0.2.2:3000`
- iOS Simulator / Physical Device (qua LAN): `http://<IP-máy-tính>:3000`
- Backend lắng nghe trên `0.0.0.0:3000`

---

## 11. KHỞI ĐỘNG DỰ ÁN (Development Setup)

### 11.1 Backend
```bash
cd backend
npm install
npx prisma migrate dev   # Chạy migrations
npx prisma db seed       # Seed dữ liệu mẫu
npm run dev              # Khởi động server (nodemon + ts-node, port 3000)
```

### 11.2 Flutter App
```bash
# Từ thư mục gốc
flutter pub get
cd packages/core && flutter pub get
cd packages/design_system && flutter pub get
cd packages/features/auth && flutter pub get
cd packages/features/admin && flutter pub get
cd packages/features/customer && flutter pub get
cd packages/features/technician && flutter pub get

# Chạy code generation cho Injectable
flutter pub run build_runner build

# Chạy app
flutter run
```

### 11.3 Script tự động (Windows)
File `start-dev.bat` tự động khởi động cả backend và flutter.

---

## 12. ĐIỂM ĐẶC BIỆT / TÍNH NĂNG NỔI BẬT

### 12.1 QR Code Integration
- Mỗi xe có mã QR duy nhất (`vehicle.qrCode`)
- STAFF có thể quét QR bằng camera để tra cứu xe ngay lập tức
- Sử dụng `mobile_scanner` package

### 12.2 Gamification – Eco Theme
- Chủ đề xe điện (Electric Vehicle) gắn với ý tưởng "xanh – bảo vệ môi trường"
- Khi khách hàng hoàn thành dịch vụ → cộng "số cây trồng được"
- Hiển thị số cây trồng trên tài khoản khách hàng để khuyến khích sử dụng xe điện

### 12.3 Loyalty Points System
- Tích điểm: cứ 20.000 VNĐ chi tiêu = 1 điểm
- Đổi điểm: dùng điểm giảm giá khi thanh toán
- Thông tin điểm hiển thị trên phiếu sửa chữa (cho STAFF thấy điểm của khách)

### 12.4 Tự động hóa bảo hành
- Không cần nhập tay bảo hành phụ tùng – hệ thống tự tạo khi phiếu COMPLETED
- Tự cập nhật ngày hết hạn bảo hành của xe theo bảo hành phụ tùng mới nhất

### 12.5 Real-time Revenue Dashboard
- Biểu đồ 7 ngày doanh thu được xây dựng hoàn toàn bằng Flutter custom painting (không dùng chart library)
- Dữ liệu live từ API hoặc fallback dữ liệu demo khi chưa load xong

### 12.6 AI Chatbot với Function Calling
- AI không chỉ trả lời câu hỏi mà còn **thực hiện hành động** (đặt lịch, tra cứu database)
- Sử dụng Gemini 2.5 Flash với Function Calling (Tool Use)
- Lịch sử hội thoại được lưu vào database, mỗi cuộc trò chuyện có context riêng

### 12.7 Phân tách giao diện rõ ràng theo role
- Một app Flutter duy nhất nhưng hiển thị 3 giao diện hoàn toàn khác nhau
- Sau khi login, app tự động redirect đến dashboard phù hợp theo role
- Middleware kiểm tra permission ở cả frontend (route guard) và backend (JWT + role check)

### 12.8 Kiến trúc Monorepo với Clean Architecture
- Các feature được tách thành package riêng biệt → dễ maintain, test riêng lẻ
- Áp dụng Clean Architecture triệt để: Domain không phụ thuộc vào Data hay Presentation
- Dependency Injection bằng GetIt + Injectable

---

## 13. THÔNG TIN KỸ THUẬT BỔ SUNG

### 13.1 Màu sắc chủ đạo (Design System)
- Primary (xanh lá chính): `#006E2F` / `#15803D` / `#22C55E`
- Background: `#F7F9FB`
- Surface: `#FFFFFF`
- Secondary (xanh dương): `#0058BE` / `#2170E4`
- Error/Warning: `#9E4036` / `#FF8B7C`
- On Surface Variant: `#3D4A3D`

### 13.2 App Theme
- Material Design 3
- Gradient nền: `F0FDF4` (green-50) → `E0F2FE` (blue-50) trên Splash Screen
- Font: Roboto Variable
- `debugShowCheckedModeBanner: false`

### 13.3 Localization
- Ngôn ngữ mặc định: `vi` (tiếng Việt)
- Hỗ trợ: `vi`, `en`
- Sử dụng `GlobalMaterialLocalizations`, `GlobalWidgetsLocalizations`, `GlobalCupertinoLocalizations`

### 13.4 Security
- Password: bcryptjs, 6 rounds (development), khuyến nghị 10+ cho production
- JWT: RS256 secret, thời hạn 7 ngày
- Helmet.js: bảo vệ HTTP headers
- CORS: configured whitelist từ environment variable
- Token không được lưu ở backend (stateless JWT), không có blacklist token mechanism (đơn giản hóa)

### 13.5 Seed Data
File `backend/prisma/seed.ts` (23KB) tạo dữ liệu mẫu bao gồm:
- Tài khoản STAFF, TECHNICIAN, CUSTOMER mẫu
- Xe điện mẫu (VinFast, Yadea, Pega, v.v.)
- Phụ tùng tồn kho mẫu
- Phiếu sửa chữa mẫu ở các trạng thái khác nhau
- Lịch hẹn mẫu

---

## 14. CÁC ĐIỂM CẦN LƯU Ý KHI VIẾT BÁO CÁO

1. **Tên dự án**: "Năng Lượng Sạch" – hệ thống quản lý bảo dưỡng xe điện
2. **Platform**: Mobile App (Android/iOS) sử dụng Flutter
3. **Kiến trúc**: Client-Server (Mobile App + REST API Backend)
4. **Database**: Relational Database (PostgreSQL) với Prisma ORM
5. **Công nghệ nổi bật**: Flutter BLoC, Clean Architecture, JWT Auth, Prisma ORM, Google Gemini AI, QR Code, Supabase Storage
6. **3 actor chính**: Staff (nhân viên/quản lý), Technician (kỹ thuật viên), Customer (khách hàng)
7. **Module chính**: Authentication, Vehicle Management, Work Order Management, Inventory Management, Appointment Management, Warranty Management, Revenue Reporting, AI Chatbot
8. **Tính năng AI**: Chatbot Gemini 2.5 Flash với Function Calling cho phép đặt lịch tự động và tra cứu thông tin
9. **Business Logic phức tạp**: Tự động tính điểm loyalty, tự động tạo bảo hành phụ tùng, tự động cập nhật MaintenanceLog, kiểm soát odometer không giảm
10. **Gamification**: Hệ thống điểm tích lũy và "cây xanh" gắn với triết lý xe điện bảo vệ môi trường

---

*Tài liệu này được tổng hợp từ mã nguồn thực tế của dự án vào ngày 21/06/2026. Tất cả thông tin đều phản ánh đúng trạng thái hiện tại của dự án.*
