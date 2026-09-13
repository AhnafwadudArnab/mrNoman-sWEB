$zipusDir = "c:\Website-fixing\zipus"

if (-not (Test-Path $zipusDir)) {
    New-Item -ItemType Directory -Path $zipusDir | Out-Null
}

$oldZips = @(
    "backend_cpanel.zip",
    "electrozonebd_complete_updated_website.zip",
    "electrozonebd_updated_files_only.zip",
    "electrozonebd_updated_fixed.zip"
)

foreach ($name in $oldZips) {
    $fullPath = Join-Path "c:\Website-fixing" $name
    if (Test-Path $fullPath) {
        Move-Item -Path $fullPath -Destination $zipusDir -Force
        Write-Host "Moved $name to zipus/"
    }
}
