@echo off
echo ========================================
echo Starting Resume Backend and Flutter App
echo ========================================
echo.

echo [1/3] Checking Node backend...
cd resume-backend
start "Resume Backend" cmd /k "npm start"
timeout /t 3 /nobreak >nul

echo.
echo [2/3] Node backend started on http://localhost:3002
echo.

cd ..
echo [3/3] Starting Flutter app with fresh build...
echo.

flutter run -d chrome --web-browser-flag="--disable-web-security"

echo.
echo ========================================
echo Done! Check the browser.
echo ========================================
