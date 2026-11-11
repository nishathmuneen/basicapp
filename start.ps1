$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$distIndex = Join-Path $root "frontend\dist\index.html"

if (-not (Test-Path $distIndex)) {
    Write-Host "Building frontend..."
    Push-Location (Join-Path $root "frontend")
    npm run build
    Pop-Location
}

Write-Host "Starting My Health Tracker at http://127.0.0.1:8000"
Push-Location (Join-Path $root "backend")
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
Pop-Location

