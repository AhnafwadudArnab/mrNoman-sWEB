$phpCandidates = @(
    'C:\php\php.exe',
    'C:\xampp\php\php.exe'
)
$php = $phpCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $php) {
    # Fallback to PATH
    $php = 'php'
}

Write-Host "Using PHP: $php"
& $php (Join-Path $PSScriptRoot 'run_db_update.php')
