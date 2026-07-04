# Xanh EV - Hệ thống Quản lý Bảo dưỡng Xe Điện Thông Minh 🌿⚡

<div align="center">

![Version](https://img.shields.io/badge/version-1.0.0-green.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)
![Node.js](https://img.shields.io/badge/Node.js-18+-green.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

**Năng Lượng Sạch** - Giải pháp quản lý bảo dưỡng xe điện hiện đại với AI tích hợp

[Tính năng](#-tính-năng-chính) • [Công nghệ](#-công-nghệ-sử-dụng) • [Cài đặt](#-cài-đặt) • [Kiến trúc](#-kiến-trúc-hệ-thống) • [API](#-api-documentation)

</div>

---

## 📖 Tổng quan

**Xanh EV** (Năng Lượng Sạch) là hệ thống quản lý bảo dưỡng xe điện toàn diện, phục vụ cho các trung tâm dịch vụ/garage chuyên về xe điện. Hệ thống quản lý toàn bộ quy trình từ đặt lịch hẹn, tiếp nhận xe, sửa chữa, đến thanh toán và quản lý bảo hành.

### 🎯 Đối tượng người dùng

| Vai trò | Mô tả |
|---------|-------|
| 👔 **STAFF** (Nhân viên/Quản lý) | Quản lý toàn bộ hoạt động: dashboard, tiếp nhận xe, phiếu sửa chữa, tồn kho, doanh thu, lịch hẹn |
| 🔧 **TECHNICIAN** (Kỹ thuật viên) | Xem danh sách công việc được giao, cập nhật trạng thái sửa chữa, tra cứu xe và phụ tùng |
| 👤 **CUSTOMER** (Khách hàng) | Xem xe, lịch sử sửa chữa, đặt lịch hẹn, xem bảo hành, chat với AI |

---

## ✨ Tính năng chính

### 🏢 Dành cho Nhân viên (STAFF)

- **Dashboard thông minh**: Thống kê tổng quan, biểu đồ doanh thu 7 ngày, cảnh báo tồn kho và bảo hành
- **Vehicle Intake**: Quy trình tiếp nhận xe hoàn chỉnh với quét QR, chụp ảnh tình trạng xe, tạo phiếu sửa chữa
- **Quản lý phiếu sửa chữa**: Theo dõi trạng thái real-time, phân công kỹ thuật viên, quản lý phụ tùng và dịch vụ
- **Báo cáo doanh thu**: Biểu đồ chi tiết theo ngày/tuần/tháng
- **Quản lý tồn kho**: Cảnh báo phụ tùng dưới ngưỡng, quản lý giá nhập/bán
- **Tra cứu đa chức năng**: Radial Menu để tra cứu xe, khách hàng, kỹ thuật viên, hóa đơn

### 🔧 Dành cho Kỹ thuật viên (TECHNICIAN)

- **Dashboard cá nhân**: Danh sách công việc được phân công với độ ưu tiên
- **Cập nhật tiến độ**: Đánh dấu hoàn thành từng dịch vụ, cập nhật trạng thái phiếu
- **Tra cứu nhanh**: Tra cứu xe, phụ tùng, bảo hành qua Radial Menu
- **Chat AI hỗ trợ**: Trợ lý AI giúp tra cứu thông tin kỹ thuật

### 👤 Dành cho Khách hàng (CUSTOMER)

- **Quản lý xe**: Xem danh sách xe, lịch sử sửa chữa, thông tin bảo hành
- **Đặt lịch hẹn**: Đặt lịch bảo dưỡng, hủy lịch, xem trạng thái lịch hẹn
- **Theo dõi bảo hành**: Xem bảo hành tổng và bảo hành phụ tùng chi tiết
- **Hệ thống Loyalty**: Tích điểm mỗi lần sửa chữa, đổi điểm giảm giá
- **Gamification Eco-Friendly**: Trồng cây ảo để khuyến khích sử dụng xe xanh
- **Chat AI thông minh**: Đặt lịch, hỏi giá, tra cứu dịch vụ qua AI

### 🤖 AI & Automation

- **Chatbot AI**: Tích hợp Google Gemini 2.5 Flash với Function Calling
- **Realtime Updates**: Supabase Realtime cho cập nhật phiếu sửa chữa tự động
- **Auto Warranty Tracking**: Tự động tạo và cập nhật bảo hành phụ tùng
- **Loyalty Points**: Tính điểm và cây xanh tự động sau mỗi giao dịch

---

## 🛠 Công nghệ sử dụng

### Frontend (Mobile App)

```yaml
Framework: Flutter 3.0+
Architecture: Clean Architecture + Feature-First Monorepo
State Management: BLoC (flutter_bloc) + Equatable
Dependency Injection: GetIt + Injectable
Storage & Auth: Supabase Flutter
QR Code: mobile_scanner, qr_flutter
Image: image_picker
Localization: intl, flutter_localizations (Tiếng Việt + English)
```

### Backend (REST API)

```json
Runtime: Node.js + TypeScript 5.3.3
Framework: Express.js 4.18.2
ORM: Prisma 5.7.0
Database: PostgreSQL (Supabase Cloud)
Authentication: JWT + bcryptjs
AI: Google Generative AI (Gemini 2.5 Flash)
Security: Helmet, CORS
Validation: express-validator
```

### Infrastructure

```
Database: Supabase PostgreSQL (AWS ap-southeast-2 - Singapore)
Storage: Supabase Storage (vehicle photos bucket)
Realtime: Supabase Realtime (WebSocket, Postgres Changes)
AI Service: Google Gemini API (gemini-2.5-flash model)
```

---

## 🏗 Kiến trúc hệ thống

### High-Level Architecture

```
┌──────────────────────────────────────────────────────────┐
│              Flutter Mobile App (Android/iOS)            │
│         3 giao diện theo vai trò (STAFF/TECH/CUSTOMER)   │
└─────────────┬──────────────────────┬─────────────────────┘
              │ HTTP REST API         │ Supabase Realtime
              │ (JWT Bearer Token)    │ (WebSocket)
              ▼                       ▼
┌────────────────────┐    ┌──────────────────────────────┐
│  Node.js + Express │    │      Supabase Cloud          │
│  Backend API       │◄───┤   PostgreSQL + Storage       │
│  + Prisma ORM      │    │   + Realtime WebSocket       │
└────────┬───────────┘    └──────────────────────────────┘
         │
         ▼
┌─────────────────────┐
│  Google Gemini AI   │
│  (Function Calling) │
└─────────────────────┘
```

### Flutter Clean Architecture (Feature-First)

```
packages/
├── core/                  # Shared: error handling, base classes, utils
├── design_system/         # UI: theme, colors, typography
└── features/
    ├── auth/              # Authentication
    ├── admin/             # Staff interface
    ├── customer/          # Customer interface
    └── technician/        # Technician interface

Mỗi feature package:
├── data/                  # Data layer (API, models, repositories)
├── domain/                # Business logic (entities, use cases)
├── presentation/          # UI layer (BLoC, pages, widgets)
└── di/                    # Dependency injection
```

---

## 🚀 Cài đặt

### Yêu cầu hệ thống

- **Flutter SDK**: >= 3.0.0 < 4.0.0
- **Node.js**: >= 18.0.0
- **PostgreSQL**: 14+ (hoặc sử dụng Supabase Cloud)
- **Git**: Latest version

### 1. Clone repository

```bash
git clone https://github.com/your-repo/nanglungsach.git
cd nanglungsach
```

### 2. Cấu hình Backend

```bash
cd backend

# Cài đặt dependencies
npm install

# Tạo file .env từ template
cp .env.example .env
```

#### Cấu hình file `.env`:

```env
# Database (Supabase PostgreSQL)
DATABASE_URL="postgresql://postgres:[PASSWORD]@db.[PROJECT_ID].supabase.co:5432/postgres?pgbouncer=true"
DIRECT_URL="postgresql://postgres:[PASSWORD]@db.[PROJECT_ID].supabase.co:5432/postgres"

# JWT Secret
JWT_SECRET="your-super-secret-jwt-key-change-this-in-production"

# Supabase
SUPABASE_URL="https://[PROJECT_ID].supabase.co"
SUPABASE_KEY="your-supabase-anon-key"

# Google Gemini AI
GEMINI_API_KEY="your-google-gemini-api-key"

# Server
PORT=3000
NODE_ENV=development
```

#### Chạy migrations và seed database:

```bash
# Generate Prisma Client
npm run prisma:generate

# Run migrations
npm run prisma:migrate

# Seed initial data (optional)
npm run prisma:seed

# Start development server
npm run dev
```

Backend sẽ chạy tại `http://localhost:3000`

### 3. Cấu hình Flutter App

```bash
cd ..  # Quay về root directory

# Cài đặt dependencies
flutter pub get

# Generate dependency injection code
flutter pub run build_runner build --delete-conflicting-outputs
```

#### Cấu hình Supabase trong app:

Mở file `lib/main.dart` và cập nhật:

```dart
await Supabase.initialize(
  url: 'https://[YOUR_PROJECT_ID].supabase.co',
  anonKey: 'your-supabase-anon-key',
);
```

#### Cấu hình API endpoint:

Mở file `packages/core/lib/constants/app_constants.dart`:

```dart
class AppConstants {
  static const String baseUrl = 'http://YOUR_IP:3000'; // Thay YOUR_IP
}
```

**Lưu ý**: Với Android emulator dùng `10.0.2.2`, iOS simulator dùng `localhost`, device thật dùng IP máy tính.

### 4. Chạy ứng dụng

```bash
# Kiểm tra devices
flutter devices

# Chạy trên device/emulator
flutter run

# Hoặc chạy với hot reload
flutter run --debug
```

### 5. Build APK (Production)

```bash
# Build APK release
flutter build apk --release

# Build APK split theo ABI (file nhỏ hơn)
flutter build apk --split-per-abi

# File APK sẽ nằm trong: build/app/outputs/flutter-apk/
```

---

## 📊 Database Schema

### Các bảng chính

```
users              - Người dùng (STAFF/TECHNICIAN/CUSTOMER)
vehicles           - Xe điện
work_orders        - Phiếu sửa chữa
repair_items       - Dịch vụ trong phiếu
work_order_photos  - Ảnh phiếu sửa chữa
inventory          - Tồn kho phụ tùng
parts_used         - Phụ tùng đã sử dụng
part_warranties    - Bảo hành phụ tùng
warranties         - Bảo hành tổng
appointments       - Lịch hẹn
maintenance_logs   - Lịch sử bảo dưỡng
chat_conversations - Cuộc trò chuyện AI
chat_messages      - Tin nhắn chat
```

### Quan hệ database

```
users 1─────∞ vehicles (owner_id)
users 1─────∞ work_orders (created_by_id, staff_id)
vehicles 1──∞ work_orders (vehicle_id)
work_orders 1─∞ repair_items (order_id)
work_orders 1─∞ work_order_photos (workOrderId)
work_orders 1─∞ parts_used (order_id)
inventory 1───∞ parts_used (part_id)
parts_used 1──1 part_warranties (part_used_id)
vehicles 1────∞ warranties (vehicle_id)
```

Xem chi tiết schema tại: `backend/prisma/schema.prisma`

---

## 🔌 API Documentation

### Base URL

```
http://localhost:3000/api
```

### Authentication

Tất cả endpoints (trừ `/auth/register` và `/auth/login`) yêu cầu JWT token:

```http
Authorization: Bearer <your_jwt_token>
```

### Main Endpoints

#### Authentication

```http
POST   /auth/register          # Đăng ký tài khoản mới
POST   /auth/login             # Đăng nhập (email/phone + password)
POST   /auth/logout            # Đăng xuất
GET    /auth/me                # Lấy thông tin user hiện tại
```

#### Users

```http
GET    /users                  # Danh sách users (filter by role)
GET    /users/:id              # Chi tiết user
PUT    /users/:id              # Cập nhật user
DELETE /users/:id              # Xóa user (STAFF only)
GET    /users/technicians      # Danh sách kỹ thuật viên
```

#### Vehicles

```http
GET    /vehicles               # Danh sách xe (search: licensePlate, model, brand)
GET    /vehicles/:id           # Chi tiết xe + lịch sử
GET    /vehicles/plate/:plate  # Tra cứu xe theo biển số
POST   /vehicles               # Tạo xe mới (STAFF only)
PUT    /vehicles/:id           # Cập nhật xe
DELETE /vehicles/:id           # Xóa xe (STAFF only)
GET    /vehicles/:id/maintenance-logs  # Lịch sử bảo dưỡng
```

#### Work Orders (Phiếu sửa chữa)

```http
GET    /work-orders                    # Danh sách phiếu (filter: status, technicianId, vehicleId)
GET    /work-orders/:id                # Chi tiết phiếu đầy đủ
POST   /work-orders                    # Tạo phiếu mới (Vehicle Intake)
PATCH  /work-orders/:id/status         # Cập nhật trạng thái
PATCH  /work-orders/:id/assign         # Phân công KTV
PATCH  /work-orders/:id/parts          # Thêm phụ tùng
POST   /work-orders/:id/services       # Thêm dịch vụ
PATCH  /work-orders/:id/services/:sid  # Cập nhật dịch vụ (isDone)
POST   /work-orders/:id/photos         # Thêm ảnh
DELETE /work-orders/:id/photos/:pid    # Xóa ảnh
PATCH  /work-orders/:id/payment        # Thanh toán
GET    /work-orders/dashboard-stats    # Thống kê dashboard (STAFF)
GET    /work-orders/revenue-report     # Báo cáo doanh thu (STAFF)
```

#### Inventory (Tồn kho)

```http
GET    /inventory              # Danh sách phụ tùng
GET    /inventory/:id          # Chi tiết phụ tùng
POST   /inventory              # Tạo phụ tùng mới (STAFF)
PUT    /inventory/:id          # Cập nhật (STAFF)
DELETE /inventory/:id          # Xóa (STAFF)
```

#### Appointments (Lịch hẹn)

```http
GET    /appointments            # Tất cả lịch hẹn (STAFF, filter: date, status)
GET    /appointments/my         # Lịch hẹn của tôi (CUSTOMER)
POST   /appointments            # Tạo lịch hẹn
PATCH  /appointments/:id/cancel # Hủy lịch hẹn
DELETE /appointments/:id        # Xóa lịch hẹn (STAFF)
DELETE /appointments/my/history # Xóa lịch sử (soft delete)
```

#### Warranties (Bảo hành)

```http
GET    /warranties             # Tất cả bảo hành (STAFF, filter: status, expiringSoon)
GET    /warranties/:id         # Chi tiết bảo hành
POST   /warranties             # Tạo bảo hành (STAFF)
PUT    /warranties/:id         # Cập nhật (STAFF)
DELETE /warranties/:id         # Xóa (STAFF)
GET    /vehicles/:id/warranties # Bảo hành của xe (cả warranty + part_warranty)
```

#### Chat AI

```http
POST   /chat/message           # Gửi tin nhắn, nhận phản hồi AI
GET    /chat/history           # Lịch sử hội thoại
```

### Status Codes

```
200 OK                  - Thành công
201 Created             - Tạo mới thành công
400 Bad Request         - Dữ liệu không hợp lệ
401 Unauthorized        - Chưa đăng nhập hoặc token hết hạn
403 Forbidden           - Không có quyền truy cập
404 Not Found           - Không tìm thấy
500 Internal Error      - Lỗi server
```

Xem API documentation chi tiết tại: `project_documentation.md`

---

## 🔐 Bảo mật

- **JWT Authentication**: Token hết hạn sau 7 ngày
- **Password Hashing**: bcryptjs với salt rounds = 10
- **CORS**: Cấu hình CORS cho mobile app
- **Helmet**: HTTP headers security
- **Input Validation**: express-validator cho tất cả endpoints
- **Role-based Access Control**: Kiểm tra role trên mỗi route
- **Supabase RLS**: Row Level Security cho storage

---

## 🎨 Design System

### Colors

```dart
Primary: #006E2F (Xanh lá đậm - Eco theme)
Secondary: #FFA726 (Cam nhạt)
Background: #F5F5F5 (Xám nhạt)
Card: #FFFFFF (Trắng)
Success: #4CAF50
Warning: #FFC107
Error: #F44336
```

### Typography

```dart
Font Family: Roboto Variable (self-hosted)
Headline: 24-28px, Bold
Title: 20px, SemiBold
Body: 16px, Regular
Caption: 14px, Regular
```

### Components

- Custom AppBar với gradient
- Bottom Navigation Bar (3-4 tabs)
- Draggable Floating Action Button
- Radial Menu (Tra cứu)
- Timeline Component (Lịch sử sửa chữa)
- Custom Charts (Bar chart canvas tự vẽ)

---

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run widget tests
flutter test test/widget_test.dart

# Run integration tests
flutter test integration_test/
```

---

## 📦 Build & Deploy

### Build APK

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release --split-per-abi

# Output: build/app/outputs/flutter-apk/
```

### Build iOS (cần macOS + Xcode)

```bash
flutter build ios --release
```

### Deploy Backend

```bash
cd backend

# Build TypeScript
npm run build

# Start production server
npm start

# Hoặc sử dụng PM2
pm2 start dist/server.js --name nanglungsach-api
```

**Khuyến nghị**: Deploy backend lên Railway, Render, hoặc DigitalOcean.

---

## 📱 Screenshots

### Staff Interface
- Dashboard với thống kê và biểu đồ
- Vehicle Intake với QR scanner
- Quản lý phiếu sửa chữa real-time
- Báo cáo doanh thu chi tiết

### Technician Interface
- Danh sách công việc cá nhân
- Cập nhật tiến độ từng dịch vụ
- Chat AI hỗ trợ kỹ thuật
- Tra cứu xe và phụ tùng nhanh

### Customer Interface
- Danh sách xe với trạng thái bảo hành
- Lịch sử sửa chữa timeline
- Đặt lịch hẹn đơn giản
- Chat AI đặt lịch tự động
- Hệ thống loyalty points và trồng cây

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Coding Standards

- **Flutter**: Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- **TypeScript**: Use ESLint rules defined in project
- **Commit messages**: Use conventional commits format
- **Code review**: All PRs require at least 1 approval

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Authors

**Đồ Án Tốt Nghiệp** - Năng Lượng Sạch Development Team

---

## 🙏 Acknowledgments

- Flutter & Dart team for amazing framework
- Supabase for backend infrastructure
- Google Gemini for AI capabilities
- Prisma for excellent ORM
- Open source community

---

## 📞 Support

Nếu bạn gặp vấn đề hoặc có câu hỏi:

- 📧 Email: support@nanglungsach.com
- 🐛 Issues: [GitHub Issues](https://github.com/your-repo/nanglungsach/issues)
- 📖 Documentation: [Full Documentation](./project_documentation.md)

---

<div align="center">

**Made with ❤️ for a greener future 🌿**

⭐ Star this repo if you find it helpful!

</div>
