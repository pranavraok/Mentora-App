# PowerShell script to start backend and Flutter
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting Resume Backend and Flutter App" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/3] Starting Node backend..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd 'resume-backend'; npm start"
Start-Sleep -Seconds 3

Write-Host ""
Write-Host "[2/3] Node backend started on http://localhost:3002" -ForegroundColor Green
Write-Host ""

Write-Host "[3/3] Starting Flutter app with fresh build..." -ForegroundColor Yellow
Write-Host ""

flutter run -d chrome --web-browser-flag="--disable-web-security"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Done! Check the browser." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
