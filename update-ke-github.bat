@echo off
title BalikinGo - Update ke GitHub
cd /d "%~dp0"

echo ========================================================
echo        BalikinGo - Sinkronisasi & Update ke GitHub
echo ========================================================
echo.

:: Pastikan git dapat dipanggil
where git >nul 2>&1
if errorlevel 1 (
    if exist "%LOCALAPPDATA%\GitHubDesktop\app-3.6.6\resources\app\git\cmd\git.exe" (
        set "PATH=%LOCALAPPDATA%\GitHubDesktop\app-3.6.6\resources\app\git\cmd;%PATH%"
    )
)

echo [1/3] Memeriksa perubahan file lokal...
git status --short
echo.

set MSG=
set /p MSG="Masukkan pesan update (tekan Enter untuk default): "
if "%MSG%"=="" (
    set MSG=Update aplikasi BalikinGo otomatis
)

echo.
echo [2/3] Menyiapkan file dan membuat commit...
git add -A
git commit -m "%MSG%"

echo.
echo [3/3] Mengunggah (Push) ke GitHub repository...
git push origin main

if errorlevel 0 (
    echo.
    echo ========================================================
    echo   BERHASIL! Semua file terbaru sudah terunggah ke GitHub.
    echo   Repository: https://github.com/saputrasip04/balikingo
    echo ========================================================
) else (
    echo.
    echo [PERINGATAN] Gagal melakukan push ke GitHub.
    echo Silakan periksa koneksi internet atau hak akses token Anda.
)

echo.
pause
