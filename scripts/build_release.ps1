# ═══════════════════════════════════════════════════════════════════════════
# KPSS ASISTAN - SECURE RELEASE BUILD SCRIPT
# ═══════════════════════════════════════════════════════════════════════════
# Bu script güvenli release build oluşturur:
# - Code Obfuscation (kod gizleme)
# - Split Debug Info (debug bilgisi ayırma)
# - Minify & Shrink (küçültme)
# - APK ve App Bundle oluşturma
# ═══════════════════════════════════════════════════════════════════════════

$ErrorActionPreference = "Stop"
$symbolsDir = "build/symbols"

Write-Host "🔒 KPSS ASISTAN - Secure Release Build" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray

# Symbols klasörünü oluştur
if (-not (Test-Path $symbolsDir)) {
    New-Item -ItemType Directory -Path $symbolsDir -Force | Out-Null
}

# 1. Flutter clean
Write-Host "`n📦 Cleaning previous builds..." -ForegroundColor Yellow
flutter clean

# 2. Get dependencies
Write-Host "`n📦 Getting dependencies..." -ForegroundColor Yellow
flutter pub get

# 3. Run tests
Write-Host "`n🧪 Running tests..." -ForegroundColor Yellow
flutter test --no-pub
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Tests failed! Aborting build." -ForegroundColor Red
    exit 1
}

# 4. Analyze code
Write-Host "`n🔍 Analyzing code..." -ForegroundColor Yellow
flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Analysis failed! Aborting build." -ForegroundColor Red
    exit 1
}

# 5. Build APK with obfuscation
Write-Host "`n🔐 Building APK with obfuscation..." -ForegroundColor Green
flutter build apk --release --obfuscate --split-debug-info=$symbolsDir/apk --split-per-abi

# 6. Build App Bundle with obfuscation
Write-Host "`n🔐 Building App Bundle with obfuscation..." -ForegroundColor Green
flutter build appbundle --release --obfuscate --split-debug-info=$symbolsDir/aab

# 7. Show results
Write-Host "`n═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host "✅ BUILD COMPLETED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Gray

Write-Host "`n📁 Output Files:" -ForegroundColor Cyan

# APK files
$apkDir = "build/app/outputs/flutter-apk"
if (Test-Path $apkDir) {
    Get-ChildItem $apkDir -Filter "*.apk" | ForEach-Object {
        $size = [math]::Round($_.Length / 1MB, 2)
        Write-Host "   APK: $($_.Name) - $size MB" -ForegroundColor White
    }
}

# AAB file
$aabDir = "build/app/outputs/bundle/release"
if (Test-Path $aabDir) {
    Get-ChildItem $aabDir -Filter "*.aab" | ForEach-Object {
        $size = [math]::Round($_.Length / 1MB, 2)
        Write-Host "   AAB: $($_.Name) - $size MB" -ForegroundColor White
    }
}

Write-Host "`n📁 Symbol Files (BACKUP THESE!):" -ForegroundColor Yellow
Write-Host "   $symbolsDir/apk" -ForegroundColor White
Write-Host "   $symbolsDir/aab" -ForegroundColor White

Write-Host "`n⚠️  IMPORTANT: Backup symbol files for crash report de-obfuscation!" -ForegroundColor Yellow
Write-Host ""
