# Build cPanel Backend Zip
$staging = "c:\Website-fixing\scratch_backend_staging"
$zipOut = "c:\Website-fixing\backend_cpanel.zip"

if (Test-Path $staging) {
    Remove-Item -Recurse -Force $staging
}
if (Test-Path $zipOut) {
    Remove-Item -Force $zipOut
}

New-Item -ItemType Directory -Path $staging | Out-Null

# Copy folders
$folders = @("api", "config", "controllers", "middleware", "models", "public", "services", "util", "vendor")
foreach ($f in $folders) {
    $src = "c:\Website-fixing\backend\$f"
    if (Test-Path $src) {
        Copy-Item -Recurse -Force $src "$staging\$f"
    }
}

# Ensure uploads folder exists in public
$uploadsDir = "$staging\public\uploads"
if (-not (Test-Path $uploadsDir)) {
    New-Item -ItemType Directory -Path $uploadsDir | Out-Null
}

# Copy files
Copy-Item "c:\Website-fixing\backend\.htaccess" "$staging\.htaccess"
Copy-Item "c:\Website-fixing\backend\config.php" "$staging\config.php"
if (Test-Path "c:\Website-fixing\backend\composer.json") {
    Copy-Item "c:\Website-fixing\backend\composer.json" "$staging\composer.json"
}

# Use production env as .env in the package
Copy-Item "c:\Website-fixing\backend\.env.production" "$staging\.env"

# Compress archive
Write-Host "Compressing to $zipOut..."
Compress-Archive -Path "$staging\*" -DestinationPath $zipOut -Force

# Clean staging
Remove-Item -Recurse -Force $staging

$len = (Get-Item $zipOut).Length
Write-Host "SUCCESS: Built $zipOut ($len bytes)"
