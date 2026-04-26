# KPSS admin panel - durdur
$port = 3456

$conn = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
if (-not $conn) {
    Write-Host "Dashboard zaten calismıyor." -ForegroundColor Yellow
    exit
}

$procId = $conn.OwningProcess
Stop-Process -Id $procId -Force
Write-Host "Dashboard durduruldu (PID $procId)." -ForegroundColor Green
