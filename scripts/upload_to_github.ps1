# KPSS 2026 - GitHub Otomatik Yükleme Scripti
# Bu script github_data klasöründeki değişiklikleri otomatik olarak GitHub'a yükler
#
# KULLANIM:
# 1. İlk kez: .\upload_to_github.ps1 -Setup
# 2. Sonraki: .\upload_to_github.ps1 -Message "Flashcard güncelleme"
# 3. Hızlı:   .\upload_to_github.ps1 (varsayılan mesajla)

param(
    [switch]$Setup,
    [string]$Message = "İçerik güncelleme"
)

$ErrorActionPreference = "Stop"
$RepoUrl = "https://github.com/mertcanasdf/kpss-data.git"
$DataFolder = Join-Path $PSScriptRoot "..\github_data"
$TempRepo = Join-Path $env:TEMP "kpss-data-temp"

function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) { Write-Output $args }
    $host.UI.RawUI.ForegroundColor = $fc
}

# Git kurulu mu kontrol et
function Test-GitInstalled {
    try {
        git --version | Out-Null
        return $true
    } catch {
        return $false
    }
}

# İlk kurulum
if ($Setup) {
    Write-ColorOutput Green "🔧 GitHub kurulumu başlatılıyor..."
    
    if (-not (Test-GitInstalled)) {
        Write-ColorOutput Red "❌ Git kurulu değil! https://git-scm.com/download/win adresinden indirin."
        exit 1
    }
    
    # Git kullanıcı bilgilerini ayarla
    $name = Read-Host "GitHub kullanıcı adınız"
    $email = Read-Host "GitHub email adresiniz"
    
    git config --global user.name $name
    git config --global user.email $email
    
    Write-ColorOutput Green "✅ Git yapılandırıldı: $name <$email>"
    Write-ColorOutput Yellow "⚠️ GitHub'a push yaparken kullanıcı adı ve token girmeniz gerekecek."
    Write-ColorOutput Yellow "   Token oluşturmak için: https://github.com/settings/tokens"
    exit 0
}

# Ana yükleme işlemi
Write-ColorOutput Cyan "📦 GitHub'a yükleme başlatılıyor..."

if (-not (Test-GitInstalled)) {
    Write-ColorOutput Red "❌ Git kurulu değil!"
    exit 1
}

if (-not (Test-Path $DataFolder)) {
    Write-ColorOutput Red "❌ github_data klasörü bulunamadı: $DataFolder"
    exit 1
}

# Temp klasörünü temizle
if (Test-Path $TempRepo) {
    Remove-Item -Recurse -Force $TempRepo
}

try {
    # 1. Repo'yu klonla
    Write-ColorOutput Yellow "⬇️ Repo klonlanıyor..."
    git clone $RepoUrl $TempRepo 2>&1 | Out-Null
    
    # 2. Eski dosyaları sil (README hariç)
    Write-ColorOutput Yellow "🗑️ Eski dosyalar temizleniyor..."
    Get-ChildItem $TempRepo -Exclude ".git", "README.md" | Remove-Item -Recurse -Force
    
    # 3. Yeni dosyaları kopyala
    Write-ColorOutput Yellow "📁 Yeni dosyalar kopyalanıyor..."
    Get-ChildItem $DataFolder | Copy-Item -Destination $TempRepo -Recurse -Force
    
    # 4. Git add, commit, push
    Write-ColorOutput Yellow "📤 GitHub'a yükleniyor..."
    Push-Location $TempRepo
    
    git add -A
    $status = git status --porcelain
    
    if ($status) {
        git commit -m $Message
        git push origin main
        Write-ColorOutput Green "✅ Başarıyla yüklendi: $Message"
    } else {
        Write-ColorOutput Yellow "ℹ️ Değişiklik yok, yükleme yapılmadı."
    }
    
    Pop-Location
    
} catch {
    Write-ColorOutput Red "❌ Hata: $_"
    exit 1
} finally {
    # Temizlik
    if (Test-Path $TempRepo) {
        Remove-Item -Recurse -Force $TempRepo -ErrorAction SilentlyContinue
    }
}

Write-ColorOutput Cyan "🎉 İşlem tamamlandı!"
