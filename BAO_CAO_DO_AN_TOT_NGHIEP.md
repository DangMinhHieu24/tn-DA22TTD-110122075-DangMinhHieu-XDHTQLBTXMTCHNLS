# BÁO CÁO ĐỒ ÁN TỐT NGHIỆP
# HỆ THỐNG QUẢN LÝ BẢO DƯỠNG XE ĐIỆN THÔNG MINH - XANH EV

> **Tên dự án:** Xanh EV (Năng Lượng Sạch) - Hệ thống Quản lý Bảo dưỡng Xe Điện Thông Minh  
> **Phiên bản:** 1.0.0+1  
> **Ngày:** 2025  
> **Tài liệu này được tạo để hỗ trợ việc viết báo cáo đồ án tốt nghiệp**

---

## MỤC LỤC

1. [TỔNG QUAN DỰ ÁN](#1-tổng-quan-dự-án)
2. [PHÂN TÍCH YÊU CẦU HỆ THỐNG](#2-phân-tích-yêu-cầu-hệ-thống)
3. [KIẾN TRÚC HỆ THỐNG](#3-kiến-trúc-hệ-thống)
4. [CÔNG NGHỆ SỬ DỤNG](#4-công-nghệ-sử-dụng)
5. [THIẾT KẾ CƠ SỞ DỮ LIỆU](#5-thiết-kế-cơ-sở-dữ-liệu)
6. [CHỨC NĂNG CHI TIẾT THEO VAI TRÒ](#6-chức-năng-chi-tiết-theo-vai-trò)
7. [QUY TRÌNH NGHIỆP VỤ CHÍNH](#7-quy-trình-nghiệp-vụ-chính)
8. [TÍNH NĂNG ĐỔI MỚI & AI](#8-tính-năng-đổi-mới--ai)
9. [API & TÍCH HỢP](#9-api--tích-hợp)
10. [BẢO MẬT & PHÂN QUYỀN](#10-bảo-mật--phân-quyền)
11. [GIAO DIỆN NGƯỜI DÙNG](#11-giao-diện-người-dùng)
12. [KIỂM THỬ & ĐÁNH GIÁ](#12-kiểm-thử--đánh-giá)
13. [HƯỚNG PHÁT TRIỂN](#13-hướng-phát-triển)
14. [KẾT LUẬN](#14-kết-luận)

---

## 1. TỔNG QUAN DỰ ÁN

### 1.1. Bối cảnh và Động lực phát triển


Trong bối cảnh xu hướng phát triển bền vững và chuyển đổi sang năng lượng xanh, xe máy điện đang ngày càng phổ biến tại Việt Nam. Theo số liệu thống kê, thị trường xe điện Việt Nam tăng trưởng với tốc độ 40-50% mỗi năm. Tuy nhiên, ngành dịch vụ bảo dưỡng và sửa chữa xe điện vẫn còn nhiều hạn chế:

- **Quản lý thủ công:** Hầu hết các trung tâm dịch vụ vẫn sử dụng sổ sách, giấy tờ để quản lý thông tin xe, khách hàng, và lịch sử sửa chữa.
- **Thiếu minh bạch:** Khách hàng khó theo dõi tiến độ sửa chữa, không biết xe đang được xử lý đến đâu.
- **Quản lý bảo hành phức tạp:** Bảo hành xe và phụ tùng thường không được theo dõi chặt chẽ, dễ dẫn đến thất thoát và tranh chấp.
- **Không tận dụng công nghệ:** Các công nghệ mới như AI chatbot, Realtime updates, QR code chưa được ứng dụng.

**Xanh EV** ra đời nhằm giải quyết các vấn đề trên bằng cách số hóa toàn bộ quy trình quản lý bảo dưỡng xe điện, từ tiếp nhận xe, phân công công việc, theo dõi tiến độ, đến thanh toán và quản lý bảo hành.

### 1.2. Mục tiêu dự án

1. **Số hóa quy trình nghiệp vụ:** Chuyển đổi quy trình quản lý từ giấy tờ sang hệ thống điện tử.
2. **Tăng cường minh bạch:** Khách hàng có thể theo dõi xe của mình mọi lúc, mọi nơi.
3. **Tối ưu công việc:** Kỹ thuật viên và nhân viên quản lý làm việc hiệu quả hơn với dashboard, thống kê real-time.
4. **Ứng dụng AI:** Chatbot tự động tư vấn, đặt lịch hẹn, hỗ trợ kỹ thuật.
5. **Hệ thống Loyalty & Gamification:** Khuyến khích khách hàng trung thành và sử dụng xe xanh thông qua điểm thưởng, trồng cây ảo.

### 1.3. Phạm vi dự án


**Hệ thống bao gồm:**
- **Mobile App (Flutter):** Ứng dụng di động chạy trên Android và iOS với 3 giao diện riêng cho 3 vai trò người dùng.
- **Backend API (Node.js + Express):** REST API xử lý logic nghiệp vụ, kết nối database PostgreSQL.
- **Database (PostgreSQL on Supabase):** Lưu trữ toàn bộ dữ liệu người dùng, xe, phiếu sửa chữa, tồn kho, bảo hành.
- **AI Chatbot (Google Gemini 2.5 Flash):** Trợ lý ảo tư vấn và đặt lịch tự động cho khách hàng, hỗ trợ kỹ thuật cho KTV.
- **Realtime System (Supabase Realtime):** Cập nhật trạng thái phiếu sửa chữa real-time cho Staff và Technician.

**Đối tượng sử dụng:**
1. **STAFF (Nhân viên/Quản lý):** Quản lý toàn bộ hoạt động của cửa hàng.
2. **TECHNICIAN (Kỹ thuật viên):** Nhận và thực hiện công việc sửa chữa.
3. **CUSTOMER (Khách hàng):** Theo dõi xe, đặt lịch hẹn, xem bảo hành.

### 1.4. Đối tượng hưởng lợi

- **Chủ cửa hàng/Garage:** Quản lý dễ dàng, minh bạch, báo cáo doanh thu chính xác.
- **Kỹ thuật viên:** Xem công việc được giao rõ ràng, cập nhật tiến độ nhanh chóng.
- **Khách hàng:** Theo dõi xe mọi lúc, đặt lịch tiện lợi, được tích điểm và ưu đãi.

---

## 2. PHÂN TÍCH YÊU CẦU HỆ THỐNG

### 2.1. Yêu cầu chức năng

#### 2.1.1. Yêu cầu cho STAFF (Nhân viên/Quản lý)


**Dashboard & Thống kê:**
- Hiển thị tổng quan: Tổng số phiếu sửa chữa theo trạng thái (Pending, In Progress, Completed, Paid).
- Biểu đồ doanh thu 7 ngày gần nhất (Bar chart tự vẽ bằng CustomPaint).
- Danh sách phiếu sửa chữa chờ xử lý (Pending).
- Cảnh báo tồn kho phụ tùng dưới ngưỡng tối thiểu.
- Cảnh báo bảo hành sắp hết hạn (7 ngày trước khi hết hạn).

**Vehicle Intake (Tiếp nhận xe):**
- Quét QR Code hoặc nhập biển số xe để tra cứu.
- Nếu xe đã tồn tại: Hiển thị thông tin xe, chủ xe, lịch sử sửa chữa, trạng thái bảo hành.
- Nếu xe mới: Form nhập thông tin chủ xe (tên, số điện thoại), thông tin xe (loại xe, màu sắc, năm sản xuất).
- Chụp ảnh tình trạng xe khi tiếp nhận (trước sửa chữa).
- Nhập số KM hiện tại, ghi chú tình trạng xe.
- Chọn loại dịch vụ (Bảo dưỡng định kỳ, Kiểm tra pin/sạc, Phanh & Lốp, Sửa chữa khác).
- Nhập danh sách công việc cần thực hiện (mô tả dịch vụ, ước tính giá).
- Phân công kỹ thuật viên, ước tính thời gian hoàn thành.
- Tạo phiếu sửa chữa (Work Order) với mã phiếu tự động (WO-YYYYMMDD-XXXX).
- Nếu có lịch hẹn trước: Tự động liên kết phiếu với lịch hẹn.

**Quản lý phiếu sửa chữa (Work Order Management):**
- Xem danh sách tất cả phiếu sửa chữa (filter theo trạng thái, kỹ thuật viên, xe).
- Xem chi tiết phiếu: Thông tin xe, danh sách dịch vụ, phụ tùng đã sử dụng, ảnh, ghi chú, lịch sử cập nhật.
- Cập nhật trạng thái phiếu: PENDING → IN_PROGRESS → INSPECTION → COMPLETED → PAID.
- Phân công hoặc đổi kỹ thuật viên.
- Thêm/xóa dịch vụ trong phiếu.
- Thêm/xóa phụ tùng (từ tồn kho) vào phiếu.
- Thêm ảnh sau khi sửa chữa.

- Thanh toán phiếu: Nhập phương thức thanh toán (Tiền mặt/Thẻ/Chuyển khoản), áp dụng giảm giá từ điểm loyalty.
- Real-time updates: Trạng thái phiếu tự động cập nhật khi KTV đánh dấu hoàn thành dịch vụ.

**Quản lý lịch hẹn (Appointment Management):**
- Xem tất cả lịch hẹn (filter theo ngày, trạng thái).
- Xác nhận hoặc hủy lịch hẹn.
- Tạo phiếu sửa chữa trực tiếp từ lịch hẹn.

**Quản lý tồn kho (Inventory Management):**
- Xem danh sách phụ tùng (tên, số lượng, giá nhập, giá bán, thời hạn bảo hành).
- Thêm phụ tùng mới vào kho.
- Cập nhật số lượng, giá.
- Xóa phụ tùng.
- Cảnh báo phụ tùng dưới ngưỡng tối thiểu (min_threshold).

**Báo cáo doanh thu (Revenue Report):**
- Biểu đồ doanh thu theo ngày/tuần/tháng.
- Tổng doanh thu, số lượng phiếu đã thanh toán.
- Export báo cáo (nếu cần).

**Tra cứu đa chức năng (Radial Lookup Menu):**
- Tra cứu xe theo biển số.
- Tra cứu khách hàng theo tên/số điện thoại.
- Tra cứu kỹ thuật viên.
- Tra cứu hóa đơn/phiếu sửa chữa.


#### 2.1.2. Yêu cầu cho TECHNICIAN (Kỹ thuật viên)

**Dashboard cá nhân:**
- Hiển thị danh sách công việc được phân công (Work Orders assigned to me).
- Sắp xếp theo độ ưu tiên (Pending trước, In Progress sau).
- Hiển thị thông tin: Biển số xe, loại dịch vụ, thời gian hẹn, trạng thái.

**Chi tiết công việc:**
- Xem chi tiết phiếu sửa chữa: Thông tin xe, chủ xe, danh sách dịch vụ cần làm.
- Đánh dấu từng dịch vụ là "Hoàn thành" (isDone = true).
- Khi tất cả dịch vụ hoàn thành → tự động chuyển trạng thái phiếu sang INSPECTION hoặc COMPLETED.
- Thêm ghi chú về công việc.

**Tra cứu nhanh (Radial Lookup Menu):**
- Tra cứu xe theo biển số (xem lịch sử sửa chữa).
- Tra cứu phụ tùng trong kho.
- Tra cứu bảo hành.

**Chat AI hỗ trợ kỹ thuật:**
- Hỏi thông tin kỹ thuật về xe điện, phụ tùng.
- Tra cứu tồn kho phụ tùng qua chatbot.
- Tra cứu phiếu sửa chữa.

**Chat trực tiếp với khách hàng:**
- Gửi tin nhắn cho khách hàng để báo cáo tiến độ.
- Nhận tin nhắn từ khách hàng trong khi phiếu đang mở.

#### 2.1.3. Yêu cầu cho CUSTOMER (Khách hàng)

**Quản lý xe:**
- Xem danh sách xe của mình (biển số, loại xe, màu sắc, trạng thái bảo hành).
- Xem chi tiết xe: Thông tin, lịch sử sửa chữa (timeline), bảo hành.

**Lịch sử sửa chữa (Maintenance History):**
- Timeline hiển thị các lần sửa chữa (ngày, loại dịch vụ, tóm tắt công việc).
- Xem chi tiết từng lần sửa chữa: Danh sách dịch vụ, phụ tùng đã thay, tổng chi phí.

**Đặt lịch hẹn (Appointment Booking):**
- Chọn xe cần sửa chữa.
- Chọn loại dịch vụ (Bảo dưỡng, Kiểm tra pin, Phanh & Lốp, Khác).
- Chọn ngày và giờ hẹn.
- Nhập ghi chú (nếu có).
- Xác nhận đặt lịch.
- Hủy lịch hẹn (nếu chưa xác nhận).
- Xóa lịch sử lịch hẹn đã hủy/hoàn thành (soft delete).

**Quản lý bảo hành (Warranty Management):**
- Xem bảo hành tổng của xe (warranty_expiry).
- Xem bảo hành phụ tùng đã thay (part_warranty): Tên phụ tùng, ngày bắt đầu, ngày hết hạn, còn lại bao nhiêu ngày.
- Cảnh báo bảo hành sắp hết hạn.

**Hệ thống Loyalty Points:**
- Hiển thị số điểm tích lũy hiện tại.
- Lịch sử tích điểm (mỗi lần thanh toán).
- Quy đổi điểm để giảm giá khi sửa chữa lần sau (1000 điểm = 10.000đ giảm giá).

**Gamification - Trồng cây ảo (Eco-Friendly):**
- Hiển thị số cây ảo đã trồng (1 cây = 500 điểm).
- Khuyến khích khách hàng sử dụng xe xanh, bảo dưỡng định kỳ để trồng cây.

**Chat AI tư vấn:**
- Hỏi giá dịch vụ, thông tin kỹ thuật.
- Đặt lịch hẹn tự động qua chatbot (AI tự gợi ý, confirm).
- Xem giờ trống trong ngày.

**Chat trực tiếp với kỹ thuật viên:**
- Nhắn tin với KTV đang phụ trách xe của mình.
- Hỏi tiến độ sửa chữa.

### 2.2. Yêu cầu phi chức năng

**Hiệu năng:**
- Thời gian phản hồi API < 500ms cho các truy vấn thông thường.
- Hỗ trợ 100+ người dùng đồng thời.

**Bảo mật:**
- Mã hóa password bằng bcrypt (salt rounds = 10).
- Xác thực bằng JWT (token hết hạn sau 7 ngày).
- HTTPS cho tất cả API calls.
- Row Level Security (RLS) trên Supabase Storage.
- Phân quyền theo role (STAFF, TECHNICIAN, CUSTOMER).

**Khả năng mở rộng:**
- Kiến trúc modular (Feature-First Monorepo) dễ dàng thêm module mới.
- Database schema chuẩn, dễ migrate.
- API RESTful có thể tích hợp với hệ thống khác.

**Khả dụng (Availability):**
- Uptime 99% (phụ thuộc vào Supabase và hosting backend).
- Xử lý lỗi graceful, hiển thị thông báo rõ ràng cho người dùng.

**Khả năng bảo trì:**
- Code tuân thủ Effective Dart guidelines (Flutter).
- Code tuân thủ ESLint rules (TypeScript).
- Comment đầy đủ cho các hàm phức tạp.
- Clean Architecture giúp dễ test và maintain.

**Trải nghiệm người dùng (UX):**
- Giao diện Material Design 3, màu xanh chủ đạo (Eco theme).
- Responsive, hoạt động mượt mà trên các thiết bị.
- Hỗ trợ đa ngôn ngữ (Tiếng Việt và English).
- Thông báo real-time cho sự thay đổi trạng thái phiếu.

---

## 3. KIẾN TRÚC HỆ THỐNG

### 3.1. Kiến trúc tổng quan (High-Level Architecture)

Hệ thống Xanh EV được xây dựng theo mô hình **Client-Server** với kiến trúc **3-tier**:

```
┌─────────────────────────────────────────────────────────────┐
│         PRESENTATION LAYER (Client Tier)                    │
│                                                              │
│    Flutter Mobile App (Android/iOS)                         │
│    - Admin Interface (STAFF)                                │
│    - Technician Interface (TECHNICIAN)                      │
│    - Customer Interface (CUSTOMER)                          │
│                                                              │
└──────────────┬──────────────────────┬───────────────────────┘
               │ HTTP REST API         │ WebSocket (Supabase Realtime)
               │ (JWT Auth)            │
               ▼                       ▼
┌───────────────────────────────────────────────────────────┐
│         APPLICATION LAYER (Business Logic Tier)           │
│                                                            │
│    Node.js + Express.js Backend API                       │
│    - Controllers (Business logic)                         │
│    - Services (External integrations: Gemini AI)          │
│    - Middleware (Auth, Validation, Error handling)        │
│    - Prisma ORM (Database access layer)                   │
│                                                            │
└──────────────┬────────────────────────────────────────────┘
               │ SQL Queries
               ▼
┌───────────────────────────────────────────────────────────┐
│         DATA LAYER (Data Tier)                            │
│                                                            │
│    Supabase PostgreSQL Database                           │
│    - Users, Vehicles, Work Orders, Inventory              │
│    - Appointments, Warranties, Chat Messages              │
│                                                            │
│    Supabase Storage                                       │
│    - Vehicle photos, Work order photos                    │
│                                                            │
└───────────────────────────────────────────────────────────┘

External Services:
┌────────────────────┐
│  Google Gemini AI  │  ← Function Calling for Chatbot
└────────────────────┘
```


### 3.2. Kiến trúc Frontend (Flutter Clean Architecture)

Flutter app được tổ chức theo **Clean Architecture** kết hợp với **Feature-First Monorepo**:

```
lib/
├── main.dart                    # Entry point, Supabase init
└── core/
    ├── di/                      # Dependency Injection (GetIt + Injectable)
    ├── routes/                  # App routing (AppRouter)
    └── ...

packages/
├── core/                        # Shared utilities
│   ├── constants/               # API endpoints, colors, app constants
│   ├── error/                   # Error handling
│   ├── network/                 # HTTP client wrapper
│   ├── storage/                 # Local storage (SharedPreferences)
│   └── services/                # QR scanner, Image upload services
│
├── design_system/               # UI Components & Theme
│   ├── theme/                   # AppTheme, Colors, Typography
│   └── widgets/                 # Reusable widgets (buttons, cards, etc.)
│
└── features/
    ├── auth/                    # Authentication feature
    │   ├── data/                # Data layer
    │   │   ├── datasources/     # Remote API calls
    │   │   ├── models/          # Data models (JSON serialization)
    │   │   └── repositories/    # Repository implementations
    │   ├── domain/              # Business logic layer
    │   │   ├── entities/        # Domain entities
    │   │   ├── repositories/    # Repository interfaces
    │   │   └── usecases/        # Use cases
    │   ├── presentation/        # UI layer
    │   │   ├── bloc/            # BLoC (Business Logic Component)
    │   │   ├── pages/           # Pages/Screens
    │   │   └── widgets/         # Feature-specific widgets
    │   └── di/                  # Dependency Injection config
    │
    ├── admin/                   # Staff/Admin interface
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    │       ├── dashboard/       # Admin dashboard
    │       ├── vehicle_intake/  # Vehicle intake flow
    │       ├── work_order/      # Work order management
    │       ├── inventory/       # Inventory management
    │       ├── lookup/          # Radial lookup menu
    │       └── revenue/         # Revenue reports
    │
    ├── technician/              # Technician interface
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    │       ├── dashboard/       # Technician dashboard
    │       ├── work_detail/     # Work order detail
    │       ├── lookup/          # Lookup menu
    │       └── settings/        # Settings
    │
    └── customer/                # Customer interface
        ├── data/
        ├── domain/
        └── presentation/
            ├── vehicles/        # Vehicle list & details
            ├── appointments/    # Appointment booking
            ├── warranties/      # Warranty management
            ├── chat/            # AI chatbot & direct chat
            └── loyalty/         # Loyalty points & trees
```

**Ưu điểm của kiến trúc này:**
- **Separation of Concerns:** Tách biệt rõ ràng giữa UI, Business Logic, và Data.
- **Testability:** Dễ dàng viết unit test cho từng layer.
- **Scalability:** Thêm feature mới chỉ cần tạo package mới, không ảnh hưởng feature cũ.
- **Reusability:** Core và design_system được chia sẻ giữa các features.


### 3.3. Kiến trúc Backend (Layered Architecture)

Backend được xây dựng theo **Layered Architecture** với TypeScript:

```
backend/
├── src/
│   ├── server.ts                # Entry point (Express app setup)
│   │
│   ├── controllers/             # Request handlers
│   │   ├── auth.controller.ts
│   │   ├── vehicle.controller.ts
│   │   ├── work-order.controller.ts
│   │   ├── inventory.controller.ts
│   │   ├── appointment.controller.ts
│   │   ├── warranty.controller.ts
│   │   ├── chat.controller.ts
│   │   └── user.controller.ts
│   │
│   ├── middleware/              # Express middleware
│   │   ├── auth.middleware.ts   # JWT verification, role check
│   │   ├── validation.middleware.ts  # Input validation
│   │   └── error.middleware.ts  # Global error handler
│   │
│   ├── routes/                  # API routes
│   │   ├── auth.routes.ts       # POST /api/auth/login, /register
│   │   ├── vehicle.routes.ts    # GET/POST/PUT/DELETE /api/vehicles
│   │   ├── work-order.routes.ts # Work order CRUD & operations
│   │   ├── inventory.routes.ts
│   │   ├── appointment.routes.ts
│   │   ├── warranty.routes.ts
│   │   ├── chat.routes.ts       # Chat with AI & direct chat
│   │   └── user.routes.ts
│   │
│   └── services/
│       └── gemini.ts            # Google Gemini AI integration
│
├── prisma/
│   ├── schema.prisma            # Database schema definition
│   ├── migrations/              # Database migration files
│   └── seed.ts                  # Seed initial data
│
├── .env                         # Environment variables
└── package.json

```

**Luồng xử lý request:**
```
Client Request
    ↓
Express Router (routes/)
    ↓
Middleware (auth, validation)
    ↓
Controller (business logic)
    ↓
Prisma ORM (database queries)
    ↓
PostgreSQL Database
    ↓
Response to Client
```


### 3.4. Kiến trúc Database (PostgreSQL on Supabase)

Database được thiết kế theo mô hình **Relational Database** với các bảng được chuẩn hóa đến dạng 3NF (Third Normal Form):

**Core Tables:**
- `users`: Lưu thông tin người dùng (STAFF, TECHNICIAN, CUSTOMER).
- `vehicles`: Thông tin xe điện (biển số, loại xe, chủ xe, QR code).
- `work_orders`: Phiếu sửa chữa (trạng thái, xe, KTV phụ trách, tổng tiền).
- `work_order_services`: Các dịch vụ trong phiếu (loại dịch vụ, giá, trạng thái hoàn thành).
- `work_order_photos`: Ảnh phiếu sửa chữa (trước/sau).
- `inventory`: Tồn kho phụ tùng (tên, số lượng, giá, bảo hành).
- `parts_used`: Phụ tùng đã sử dụng trong phiếu.
- `part_warranties`: Bảo hành phụ tùng đã thay.
- `warranties`: Bảo hành tổng của xe.
- `appointments`: Lịch hẹn sửa chữa.
- `maintenance_logs`: Lịch sử bảo dưỡng.
- `chat_conversations`: Hội thoại chat.
- `chat_messages`: Tin nhắn chat.
- `notifications`: Thông báo.

**Quan hệ chính:**
```
users (1) ──────< (N) vehicles (owner_id)
users (1) ──────< (N) work_orders (technician_id, created_by_id)
vehicles (1) ───< (N) work_orders (vehicle_id)
work_orders (1) ─< (N) work_order_services (work_order_id)
work_orders (1) ─< (N) work_order_photos (work_order_id)
work_orders (1) ─< (N) parts_used (work_order_id)
inventory (1) ───< (N) parts_used (part_id)
parts_used (1) ──< (1) part_warranties (part_used_id)
vehicles (1) ────< (N) warranties (vehicle_id)
vehicles (1) ────< (N) maintenance_logs (vehicle_id)
users (1) ───────< (N) appointments (customer_id)
appointments (1) ─< (1) work_orders (appointment_id)
users (1) ───────< (N) chat_conversations (user_id)
chat_conversations (1) ─< (N) chat_messages (conversation_id)
```

---

## 4. CÔNG NGHỆ SỬ DỤNG

### 4.1. Frontend (Mobile App)

**Framework & Ngôn ngữ:**
- **Flutter 3.0+**: Framework cross-platform để xây dựng mobile app.
- **Dart**: Ngôn ngữ lập trình chính của Flutter.

**State Management:**
- **flutter_bloc (^8.1.3)**: Quản lý state theo pattern BLoC (Business Logic Component).
- **equatable (^2.0.5)**: So sánh đối tượng dễ dàng cho state.

**Dependency Injection:**
- **get_it (^7.6.4)**: Service locator để quản lý dependencies.
- **injectable (^2.3.2)**: Code generation cho GetIt.

**Backend & Auth:**
- **supabase_flutter (^2.5.0)**: Tích hợp Supabase (Auth, Storage, Realtime).

**QR Code & Image:**
- **mobile_scanner (^5.2.3)**: Quét QR code để nhận diện xe.
- **qr_flutter (^4.1.0)**: Tạo QR code.
- **image_picker (^1.1.2)**: Chụp/chọn ảnh từ camera/gallery.

**Localization:**
- **intl (^0.20.2)**: Định dạng ngày tháng, số tiền.
- **flutter_localizations**: Hỗ trợ đa ngôn ngữ (Tiếng Việt, English).

**Build Tools:**
- **build_runner (^2.4.6)**: Code generation.
- **flutter_launcher_icons (^0.14.3)**: Tạo app icon.
- **flutter_native_splash (^2.4.0)**: Tạo splash screen.

### 4.2. Backend (REST API)

**Runtime & Ngôn ngữ:**
- **Node.js 18+**: JavaScript runtime cho server.
- **TypeScript 5.3.3**: Ngôn ngữ type-safe cho JavaScript.

**Web Framework:**
- **Express.js (^4.18.2)**: Framework web phổ biến cho Node.js.

**Database:**
- **Prisma (^5.7.0)**: ORM hiện đại cho TypeScript.
- **@prisma/client (^5.7.0)**: Prisma client library.
- **PostgreSQL**: Database quan hệ (hosted on Supabase).

**Authentication & Security:**
- **jsonwebtoken (^9.0.2)**: Tạo và verify JWT tokens.
- **bcryptjs (^2.4.3)**: Hash passwords.
- **helmet (^7.1.0)**: Bảo vệ Express app với HTTP headers.
- **cors (^2.8.5)**: Cho phép CORS từ mobile app.

**Validation:**
- **express-validator (^7.0.1)**: Validate và sanitize input data.

**AI Integration:**
- **@google/generative-ai (^0.24.1)**: Google Gemini AI SDK.

**Development Tools:**
- **nodemon (^3.0.2)**: Auto-restart server khi code thay đổi.
- **ts-node (^10.9.2)**: Chạy TypeScript trực tiếp.
- **morgan (^1.10.0)**: HTTP request logger.

### 4.3. Infrastructure & Services

**Database & Storage:**
- **Supabase PostgreSQL**: Database cloud-hosted tại AWS Singapore (ap-southeast-2).
- **Supabase Storage**: Lưu trữ ảnh xe, ảnh phiếu sửa chữa (vehicle_photos bucket).
- **Supabase Realtime**: WebSocket để cập nhật real-time (Postgres Changes).

**AI Service:**
- **Google Gemini 2.5 Flash**: AI model cho chatbot với Function Calling.

**Version Control:**
- **Git**: Quản lý source code.

**Package Managers:**
- **pub (Flutter)**: Quản lý dependencies cho Flutter.
- **npm (Node.js)**: Quản lý dependencies cho backend.

---

## 5. THIẾT KẾ CƠ SỞ DỮ LIỆU

### 5.1. Database Schema Overview

Database gồm **14 bảng chính** được thiết kế để lưu trữ đầy đủ thông tin về người dùng, xe, phiếu sửa chữa, tồn kho, lịch hẹn, bảo hành, và chat.


### 5.2. Chi tiết các bảng

#### 5.2.1. Bảng `users` - Người dùng

**Mô tả:** Lưu trữ thông tin tất cả người dùng của hệ thống.

**Cấu trúc:**
| Cột | Kiểu dữ liệu | Mô tả |
|-----|-------------|-------|
| id | UUID (PK) | ID người dùng (tự động tạo) |
| email | String (Unique) | Email đăng nhập |
| phoneNumber | String (Unique, Nullable) | Số điện thoại |
| name | String | Họ tên |
| password | String | Password đã hash (bcrypt) |
| role | Enum (UserRole) | Vai trò: STAFF, TECHNICIAN, CUSTOMER |
| loyaltyPoints | Integer | Điểm tích lũy (mặc định 0) |
| treesPlanted | Integer | Số cây đã trồng (mặc định 0) |
| avatarUrl | String (Nullable) | Link ảnh đại diện |
| isActive | Boolean | Trạng thái hoạt động (mặc định true) |
| createdAt | DateTime | Ngày tạo |
| updatedAt | DateTime | Ngày cập nhật cuối |

**Quan hệ:**
- 1 User có nhiều Vehicles (owner_id)
- 1 User có nhiều Work Orders (assigned as technician)
- 1 User tạo nhiều Work Orders (created_by_id)
- 1 User có nhiều Appointments
- 1 User có nhiều Chat Conversations

**Indexes:**
- `email` (Unique)
- `phoneNumber` (Unique)
- `role` (để filter theo role)


#### 5.2.2. Bảng `vehicles` - Xe điện

**Mô tả:** Lưu thông tin các xe điện của khách hàng.

**Cấu trúc:**
| Cột | Kiểu dữ liệu | Mô tả |
|-----|-------------|-------|
| id | UUID (PK) | ID xe |
| licensePlate | String (Unique) | Biển số xe (VD: 29A-123.45) |
| brand | String (Nullable) | Hãng xe (VinFast, Yadea, Pega) |
| model | String | Model xe (VD: VinFast Klara S) |
| color | String (Nullable) | Màu sắc |
| imageUrl | String (Nullable) | Link ảnh xe |
| manufactureYear | Integer (Nullable) | Năm sản xuất |
| qrCode | String (Unique, Nullable) | Mã QR của xe |
| warrantyExpiry | DateTime (Nullable) | Ngày hết hạn bảo hành tổng |
| currentKm | Integer (Nullable) | Số KM hiện tại |
| ownerId | UUID (FK → users.id) | ID chủ xe |
| createdAt | DateTime | Ngày tạo |
| updatedAt | DateTime | Ngày cập nhật |

**Quan hệ:**
- 1 Vehicle thuộc về 1 User (owner)
- 1 Vehicle có nhiều Work Orders
- 1 Vehicle có nhiều Maintenance Logs
- 1 Vehicle có nhiều Warranties
- 1 Vehicle có nhiều Appointments

**Indexes:**
- `licensePlate` (Unique)
- `qrCode` (Unique)
- `ownerId` (Foreign Key)


#### 5.2.3. Bảng `work_orders` - Phiếu sửa chữa

**Mô tả:** Quản lý phiếu sửa chữa từ lúc tiếp nhận đến khi thanh toán.

**Cấu trúc:**
| Cột | Kiểu dữ liệu | Mô tả |
|-----|-------------|-------|
| id | UUID (PK) | ID phiếu |
| orderNumber | String (Unique) | Mã phiếu (WO-YYYYMMDD-XXXX) |
| vehicleId | UUID (FK → vehicles.id) | ID xe |
| appointmentId | UUID (FK → appointments.id, Nullable, Unique) | ID lịch hẹn (nếu có) |
| status | Enum (WorkOrderStatus) | Trạng thái phiếu |
| totalPrice | Float (Nullable) | Tổng tiền |
| technicianId | UUID (FK → users.id, Nullable) | ID KTV được giao |
| estimatedHours | Float (Nullable) | Ước tính thời gian (giờ) |
| scheduledTime | String (Nullable) | Thời gian hẹn (VD: "14:00") |
| notes | String (Nullable) | Ghi chú |
| createdById | UUID (FK → users.id) | ID người tạo phiếu (STAFF) |
| createdAt | DateTime | Ngày tạo |
| updatedAt | DateTime | Ngày cập nhật |
| completedAt | DateTime (Nullable) | Ngày hoàn thành |
| paymentMethod | Enum (PaymentMethod, Nullable) | CASH, CARD, TRANSFER |
| paidAt | DateTime (Nullable) | Ngày thanh toán |
| pointsRedeemed | Integer (Nullable) | Số điểm đã sử dụng để giảm giá |
| pointsDiscount | Float (Nullable) | Số tiền giảm từ điểm |

**Enum WorkOrderStatus:**
- `PENDING`: Chờ xử lý
- `IN_PROGRESS`: Đang thực hiện
- `INSPECTION`: Kiểm tra
- `COMPLETED`: Hoàn thành
- `PAID`: Đã thanh toán
- `CANCELLED`: Đã hủy

**Quan hệ:**
- 1 Work Order thuộc về 1 Vehicle
- 1 Work Order có thể liên kết với 1 Appointment
- 1 Work Order có nhiều Work Order Services (dịch vụ)
- 1 Work Order có nhiều Work Order Photos (ảnh)
- 1 Work Order có nhiều Parts Used (phụ tùng)
- 1 Work Order được giao cho 1 Technician
- 1 Work Order được tạo bởi 1 STAFF


#### 5.2.4. Bảng `work_order_services` (repair_items) - Dịch vụ trong phiếu

**Mô tả:** Các dịch vụ cụ thể trong mỗi phiếu sửa chữa.

**Cấu trúc:**
| Cột | Kiểu dữ liệu | Mô tả |
|-----|-------------|-------|
| id | UUID (PK) | ID dịch vụ |
| workOrderId | UUID (FK → work_orders.id) | ID phiếu |
| serviceType | Enum (ServiceType) | Loại dịch vụ |
| serviceName | String (Nullable) | Tên dịch vụ |
| description | String (Nullable) | Mô tả chi tiết |
| price | Float (Nullable) | Giá dịch vụ |
| isDone | Boolean | Đã hoàn thành? (mặc định false) |
| note | String (Nullable) | Ghi chú |
| approvalStatus | Enum (ApprovalStatus) | PENDING, APPROVED, REJECTED |
| createdAt | DateTime | Ngày tạo |

**Enum ServiceType:**
- `MAINTENANCE`: Bảo dưỡng định kỳ
- `BATTERY_CHECK`: Kiểm tra pin/sạc
- `BRAKES_TIRES`: Phanh & Lốp
- `OTHER_REPAIR`: Sửa chữa khác

#### 5.2.5. Bảng `work_order_photos` - Ảnh phiếu sửa chữa

**Mô tả:** Lưu ảnh trước và sau khi sửa chữa.

**Cấu trúc:**
| Cột | Kiểu dữ liệu | Mô tả |
|-----|-------------|-------|
| id | UUID (PK) | ID ảnh |
| workOrderId | UUID (FK → work_orders.id) | ID phiếu |
| photoUrl | String | URL ảnh (Supabase Storage) |
| photoType | Enum (PhotoType) | INTAKE, AFTER_REPAIR |
| description | String (Nullable) | Mô tả (VD: "Xước góc trước trái") |
| createdAt | DateTime | Ngày tạo |


#### 5.2.6. Bảng `inventory` - Tồn kho phụ tùng

**Mô tả:** Quản lý phụ tùng trong kho.

**Cấu trúc:**
| Cột | Kiểu dữ liệu | Mô tả |
|-----|-------------|-------|
| id | UUID (PK) | ID phụ tùng |
| partName | String | Tên phụ tùng |
| imageUrl | String (Nullable) | Link ảnh |
| quantity | Integer | Số lượng tồn kho (mặc định 0) |
| minThreshold | Integer | Ngưỡng tối thiểu (cảnh báo) |
| unitPrice | Float | Giá nhập |
| sellPrice | Float | Giá bán |
| warrantyDays | Integer | Số ngày bảo hành (mặc định 0) |

**Quan hệ:**
- 1 Inventory item có nhiều Parts Used

#### 5.2.7. Bảng `parts_used` - Phụ tùng đã sử dụng

**Mô tả:** Phụ tùng đã sử dụng trong phiếu sửa chữa.

**Cấu trúc:**
| Cột | Kiểu dữ liệu | Mô tả |
|-----|-------------|-------|
| id | UUID (PK) | ID |
| workOrderId | UUID (FK → work_orders.id) | ID phiếu |
| partId | UUID (FK → inventory.id) | ID phụ tùng |
| quantity | Integer | Số lượng đã dùng |
| unitPrice | Float | Giá tại thời điểm sử dụng |

**Quan hệ:**
- 1 Parts Used thuộc về 1 Work Order
- 1 Parts Used tham chiếu đến 1 Inventory item
- 1 Parts Used có thể có 1 Part Warranty


#### 5.2.8. Bảng `part_warranties` - Bảo hành phụ tùng

**Mô tả:** Bảo hành cho từng phụ tùng đã thay.

**Cấu trúc:**
| Cột | Kiểu dữ liệu | Mô tả |
|-----|-------------|-------|
| id | UUID (PK) | ID bảo hành |
| partUsedId | UUID (FK → parts_used.id, Unique) | ID phụ tùng đã dùng |
| partId | UUID (FK → inventory.id) | ID phụ tùng |
| workOrderId | UUID (FK → work_orders.id) | ID phiếu |
| vehicleId | UUID (FK → vehicles.id) | ID xe |
| warrantyDays | Integer | Số ngày bảo hành |
| startDate | DateTime | Ngày bắt đầu bảo hành |
| expiryDate | DateTime | Ngày hết hạn bảo hành |

**Logic:** Khi thêm phụ tùng vào phiếu, nếu phụ tùng có `warrantyDays > 0`, hệ thống tự động tạo bản ghi trong `part_warranties`.

#### 5.2.9. Bảng `warranties` - Bảo hành tổng

**Mô tả:** Bảo hành tổng của xe (do hãng cung cấp).

**Cấu trúc:**
| Cột | Kiểu dữ liệu | Mô tả |
|-----|-------------|-------|
| id | UUID (PK) | ID bảo hành |
| vehicleId | UUID (FK → vehicles.id) | ID xe |
| warrantyType | String | Loại bảo hành (VD: "Bảo hành chính hãng") |
| startDate | DateTime | Ngày bắt đầu |
| expiryDate | DateTime | Ngày hết hạn |
| terms | String (Nullable) | Điều khoản bảo hành |
| issuedBy | String (Nullable) | Đơn vị cấp bảo hành |

