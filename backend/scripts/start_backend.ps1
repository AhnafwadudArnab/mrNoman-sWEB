param(
    [int]$Port = 8080
)

$ErrorActionPreference = 'Stop'

$php = 'C:\xampp\php\php.exe'
$backendRoot = Split-Path -Parent $PSScriptRoot
$docRoot = Join-Path $backendRoot 'public'
$router = Join-Path $backendRoot 'router.php'

if (-not (Test-Path $php)) {
    # Fallback: try plain 'php' from PATH
    $phpFallback = 'php'
    try {
        $version = & $phpFallback -v 2>$null
        if ($LASTEXITCODE -eq 0 -or $version) {
            $php = $phpFallback
        }
        else {
            Write-Error "PHP executable not found: $php"
            exit 1
        }
    }
    catch {
        Write-Error "PHP executable not found: $php"
        exit 1
    }
}

if (-not (Test-Path $docRoot)) {
    Write-Error "Backend public folder not found: $docRoot"
    exit 1
}

if (-not (Test-Path $router)) {
    Write-Error "Backend router not found: $router"
    exit 1
}

$existing = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty OwningProcess -Unique

foreach ($pid in $existing) {
    try {
        Stop-Process -Id $pid -Force -ErrorAction Stop
        Write-Host "Stopped stale process on port $Port (PID: $pid)"
    }
    catch {
        Write-Host "Could not stop PID ${pid}: $($_.Exception.Message)"
    }
}

Write-Host "Starting backend on http://127.0.0.1:$Port"
& $php -S "127.0.0.1:$Port" -t $docRoot $router
