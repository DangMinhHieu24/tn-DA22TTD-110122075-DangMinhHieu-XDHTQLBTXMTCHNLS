@echo off
echo Starting Backend and Flutter App...
echo.

REM Start backend in new window
start "Backend Server" cmd /k "cd backend && npm run dev"

REM Wait 3 seconds for backend to start
timeout /t 3 /nobreak

REM Start Flutter app
echo Starting Flutter app...
flutter run

pause
