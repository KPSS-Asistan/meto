@echo off
chcp 65001 >nul
cd /d "%~dp0\..\github_data"

echo.
echo ========================================
echo   KPSS 2026 - Hızlı GitHub Yükleme
echo ========================================
echo.

:: Git repo olarak başlat (ilk seferde)
if not exist ".git" (
    echo İlk kurulum yapılıyor...
    git init
    git remote add origin https://github.com/mertcanasdf/kpss-data.git
    git branch -M main
)

:: Değişiklikleri ekle ve yükle
git add -A
git commit -m "İçerik güncelleme - %date% %time%"
git push -u origin main

echo.
echo ✅ Yükleme tamamlandı!
pause
