# 🚀 Hướng Dẫn Khởi Động Dự Án

## Mỗi lần mở code / demo cần làm theo thứ tự này:

---

## BƯỚC 1: Khởi động PostgreSQL (nếu chưa chạy)

PostgreSQL thường tự chạy cùng Windows. Kiểm tra bằng cách mở **Services**:
```
Windows + R → services.msc → tìm "postgresql-x64-18" → Start (nếu chưa chạy)
```

Hoặc dùng PowerShell (chạy với quyền Admin):
```powershell
Start-Service -Name "postgresql-x64-18"
```

---

## BƯỚC 2: Khởi động Backend API

Mở terminal, chạy:
```bash
cd D:\DoAn\Du_An\backend
npm run dev
```

✅ Thấy dòng này là OK:
```
🚀 Server running on http://localhost:3000
📱 Android Emulator: http://10.0.2.2:3000
```

---

## BƯỚC 3: Khởi động Prisma Studio (xem/quản lý database - tuỳ chọn)

Mở terminal mới, chạy:
```bash
cd D:\DoAn\Du_An\backend
npx prisma studio --port 5556 --browser none
```

✅ Mở trình duyệt vào: **http://localhost:5556**

> ⚠️ Prisma Studio sẽ tự tắt sau một lúc không dùng.  
> Nếu vào localhost:5556 thấy lỗi → chạy lại lệnh trên là được.

---

## BƯỚC 4: Khởi động Flutter App

Mở terminal mới, chạy:
```bash
cd D:\DoAn\Du_An
flutter run -d emulator-5554
```

Hoặc nhấn **F5** trong VS Code / Kiro.

---

## 📋 Tài khoản test

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@gmail.com | Admin123! |
| Technician | tech@gmail.com | Tech123! |
| Technician 2 | tech2@gmail.com | Tech123! |
| Customer | customer@gmail.com | Customer123! |

---

## 🔄 Chuyển đổi Database

### Dùng Local (nhanh, offline):
File `backend/.env`:
```
DATABASE_URL="postgresql://postgres:Dangminhhi3u%40113@localhost:5432/nanglungsach?schema=public"
```

### Dùng Supabase (có data thật, online):
File `backend/.env`:
```
DATABASE_URL="postgresql://postgres.fvagqenqcsmoaaiuubvx:Dangminhhi3u%40113@aws-1-ap-southeast-2.pooler.supabase.com:5432/postgres"
```

Sau khi đổi DATABASE_URL, restart backend (`Ctrl+C` rồi `npm run dev` lại).

---

## ⚠️ Lỗi thường gặp

### Backend lỗi "port 3000 already in use"
```powershell
# Kill process đang dùng port 3000
Get-Process | Where-Object {$_.ProcessName -like "node*"} | Stop-Process -Force
```

### Emulator offline
```powershell
# Restart ADB
& "C:\Users\dminh\AppData\Local\Android\Sdk\platform-tools\adb.exe" kill-server
& "C:\Users\dminh\AppData\Local\Android\Sdk\platform-tools\adb.exe" start-server
```

### Reset database local (xóa hết data, tạo lại)
```bash
cd D:\DoAn\Du_An\backend
npx prisma migrate reset
```
> ⚠️ Lệnh này xóa toàn bộ data!

---

## 📁 Cấu trúc quan trọng

```
D:\DoAn\Du_An\
├── backend/              ← Node.js + Prisma + PostgreSQL
│   ├── .env              ← Config database (local/supabase)
│   ├── prisma/           ← Schema & migrations
│   └── src/              ← Controllers, routes
├── lib/                  ← Flutter app root
│   ├── main.dart         ← Entry point
│   └── core/routes/      ← Navigation
└── packages/
    ├── core/             ← Shared utilities
    ├── design_system/    ← UI components
    └── features/
        ├── admin/        ← Admin feature
        ├── technician/   ← Technician feature
        ├── customer/     ← Customer feature
        └── auth/         ← Authentication
```
