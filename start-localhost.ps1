# KPSS admin panel (Node dashboard). Default: http://localhost:3456
$port     = 3456
$url      = "http://localhost:$port"
$toolsDir = Join-Path $PSScriptRoot 'tools'

# Check if already running
$existing = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "Dashboard zaten calisiyor: $url" -ForegroundColor Green
    Start-Process $url
    exit
}

# Install deps if needed
if (-not (Test-Path (Join-Path $toolsDir 'node_modules'))) {
    Write-Host "npm install..." -ForegroundColor Yellow
    Push-Location $toolsDir
    npm install
    Pop-Location
}

# Find node.exe
$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
$nodePath = if ($nodeCmd) { $nodeCmd.Source } else { $null }
if (-not $nodePath) { $nodePath = "C:\Program Files\nodejs\node.exe" }
if (-not (Test-Path $nodePath)) { Write-Host "node.exe bulunamadi!" -ForegroundColor Red; exit 1 }

# Start node as a detached process (survives PowerShell closing)
Write-Host "Dashboard baslatiliyor..." -ForegroundColor Cyan
Start-Process $nodePath -ArgumentList "dashboard/server/server.js" `
    -WorkingDirectory $toolsDir `
    -WindowStyle Hidden

# Wait for server to be ready (max 10s)
$ready = $false
for ($i = 0; $i -lt 20; $i++) {
    Start-Sleep -Milliseconds 500
    $conn = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
    if ($conn) { $ready = $true; break }
}

if ($ready) {
    Write-Host "Dashboard hazir: $url" -ForegroundColor Green
    Start-Process $url
    Write-Host "Durdurmak icin: taskkill /f /im node.exe" -ForegroundColor Gray
} else {
    Write-Host "Sunucu baslatılamadı." -ForegroundColor Red
}
