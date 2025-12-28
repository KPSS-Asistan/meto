@echo off
chcp 65001 >nul
echo.
echo ========================================
echo   KPSS 2026 - GitHub Yükleme
echo ========================================
echo.

cd /d "%~dp0"

if "%1"=="" (
    powershell -ExecutionPolicy Bypass -File "upload_to_github.ps1" -Message "İçerik güncelleme"
) else if "%1"=="setup" (
    powershell -ExecutionPolicy Bypass -File "upload_to_github.ps1" -Setup
) else (
    powershell -ExecutionPolicy Bypass -File "upload_to_github.ps1" -Message "%*"
)

echo.
pause
