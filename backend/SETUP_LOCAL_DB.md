# Setup Local PostgreSQL Database

## Tại sao dùng Local PostgreSQL?
- **Nhanh hơn 5-10 lần** so với Supabase (không qua internet)
- **Miễn phí hoàn toàn**, không giới hạn
- **Offline development** - Không cần internet

## Cài đặt PostgreSQL trên Windows

### Cách 1: PostgreSQL Installer (Khuyên dùng)

1. **Download PostgreSQL 15**
   - Truy cập: https://www.postgresql.org/download/windows/
   - Download "Windows x86-64" installer

2. **Cài đặt**
   - Chạy file `.exe` vừa download
   - Next → Next
   - Chọn password cho user `postgres`: `postgres123`
   - Port: `5432` (mặc định)
   - Locale: `Default locale`
   - Finish

3. **Kiểm tra cài đặt**
   ```bash
   psql --version
   ```
   Nếu thấy version → Thành công!

### Cách 2: Docker (Nếu đã có Docker)

```bash
docker run --name postgres-dev -e POSTGRES_PASSWORD=postgres123 -p 5432:5432 -d postgres:15
```

## Setup Database

### 1. Tạo database
```bash
# Mở Command Prompt hoặc PowerShell
psql -U postgres

# Trong psql shell:
CREATE DATABASE nanglungsach;
\q
```

### 2. Update .env file
```bash
# Copy .env.local thành .env
cp .env.local .env
```

Hoặc thủ công: Copy nội dung `.env.local` vào `.env`

### 3. Chạy migrations
```bash
cd backend
npx prisma migrate dev
npx prisma db seed
```

### 4. Start backend
```bash
npm run dev
```

## So sánh tốc độ

| Database | Login Time | Query Time |
|----------|-----------|------------|
| Supabase | 2-3s | 200-500ms |
| Local PostgreSQL | 0.3-0.5s | 10-50ms |

## Chuyển đổi giữa Local và Supabase

### Dùng Local (Development)
```bash
# .env
DATABASE_URL="postgresql://postgres:postgres123@localhost:5432/nanglungsach?schema=public"
```

### Dùng Supabase (Production/Testing)
```bash
# .env
DATABASE_URL="postgresql://postgres.xxx:xxx@aws-0-ap-southeast-1.pooler.supabase.com:6543/postgres?pgbouncer=true"
```

## Troubleshooting

### Lỗi: "password authentication failed"
- Kiểm tra password trong DATABASE_URL
- Mặc định: `postgres123`

### Lỗi: "database does not exist"
```bash
psql -U postgres
CREATE DATABASE nanglungsach;
```

### Lỗi: "connection refused"
- Kiểm tra PostgreSQL service đang chạy
- Windows: Services → PostgreSQL → Start

### Reset database
```bash
npx prisma migrate reset
npx prisma db seed
```
