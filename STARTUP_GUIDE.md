# 🚀 Hướng Dẫn Khởi Động Dự Án

## Mỗi lần mở code / demo cần làm theo thứ tự này:

---

## BƯỚC 1: Khởi động Backend API

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

> Database tự kết nối Supabase cloud - **không cần bật PostgreSQL local**.

---

## BƯỚC 2: Chạy Flutter App

Mở terminal mới, chạy:
```bash
cd D:\DoAn\Du_An
flutter run
```

Hoặc nhấn **F5** trong VS Code / Kiro.

---

## BƯỚC 3: Prisma Studio (tuỳ chọn - xem/sửa data)

```bash
cd D:\DoAn\Du_An\backend
npx prisma studio --port 5556 --browser none
```

✅ Mở trình duyệt: **http://localhost:5556**

> ⚠️ Prisma Studio tự tắt sau một lúc. Chạy lại lệnh trên nếu mất kết nối.

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

### Dùng Supabase cloud (mặc định - demo/bảo vệ):
File `backend/.env`:
```
DATABASE_URL="postgresql://postgres.fvagqenqcsmoaaiuubvx:Dangminhhi3u%40113@aws-1-ap-southeast-2.pooler.supabase.com:5432/postgres"
```

### Dùng Local (dev nhanh hơn, offline):
File `backend/.env`:
```
DATABASE_URL="postgresql://postgres:Dangminhhi3u%40113@localhost:5432/nanglungsach?schema=public"
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
