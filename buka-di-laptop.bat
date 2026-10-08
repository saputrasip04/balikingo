@echo off
title BalikinGo - Buka di Desktop
cd /d "%~dp0"

:: Cek apakah server BalikinGo sudah aktif di port 8088
powershell -NoProfile -Command "try { (Invoke-WebRequest -Uri 'http://localhost:8088/api/network-info' -UseBasicParsing -TimeoutSec 1).StatusCode } catch { exit 1 }" >nul 2>&1
if errorlevel 1 (
    echo Memulai server BalikinGo...
    start /min powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0serve.ps1"
    timeout /t 2 /nobreak >nul
)

:: Buka di peramban bawaan laptop
echo Membuka BalikinGo di browser...
start http://localhost:8088/

