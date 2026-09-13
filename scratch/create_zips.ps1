$ProgressPreference = 'SilentlyContinue'

$rootDir = "c:\Website-fixing"
$tempDir = Join-Path $rootDir "scratch\temp_updated_files"
$updatesZip = Join-Path $rootDir "electrozonebd_updated_files_only.zip"
$completeZip = Join-Path $rootDir "electrozonebd_complete_updated_website.zip"

# Clean previous temp
if (Test-Path $tempDir) { Remove-Item -Path $tempDir -Recurse -Force }
if (Test-Path $updatesZip) { Remove-Item -Path $updatesZip -Force }
if (Test-Path $completeZip) { Remove-Item -Path $completeZip -Force }

New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# List of updated files
$updatedFiles = @(
    "assets/payments/rocket.png",
    "assets/payments/upay.png",
    "backend/api/auth/Admin/admin-login.php",
    "backend/api/auth/login.php",
    "backend/api/auth/admin_login.php",
    "backend/api/deals_timer.php",
    "backend/public/index.php",
    "lib/front_end/Admin_Panel/A_deals.dart",
    "lib/front_end/Admin_Panel/A_delivery_settings.dart",
    "lib/front_end/Admin_Panel/A_orders.dart",
    "lib/front_end/Admin_Panel/A_promotions.dart",
    "lib/front_end/Admin_Panel/admin_scaffold.dart",
    "lib/front_end/All_Pages/CART/Track_ur_orders.dart",
    "lib/front_end/Dimensions/responsive_dimensions.dart",
    "lib/front_end/utils/api_service.dart",
    "lib/front_end/widgets/SearchRes.dart",
    "lib/front_end/widgets/Sections/mid_banner_row.dart",
    "lib/front_end/widgets/footer.dart",
    "lib/front_end/widgets/header.dart"
)

Write-Host "Copying updated files preserving directory structure..."
foreach ($relPath in $updatedFiles) {
    $src = Join-Path $rootDir $relPath
    if (Test-Path $src) {
        $dest = Join-Path $tempDir $relPath
        $destDir = Split-Path -Path $dest -Parent
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        Copy-Item -Path $src -Destination $dest -Force
        Write-Host " [OK] $relPath"
    } else {
        Write-Host " [MISSING] $relPath"
    }
}

# 1. Create updates-only zip
Write-Host "Creating $updatesZip ..."
$tempItems = Get-ChildItem -Path $tempDir
Compress-Archive -Path ($tempItems.FullName) -DestinationPath $updatesZip -Force
$uSize = [math]::Round(((Get-Item $updatesZip).Length / 1KB), 2)
Write-Host "Created electrozonebd_updated_files_only.zip ($uSize KB)"

# Clean temp directory
Remove-Item -Path $tempDir -Recurse -Force

# 2. Create complete updated project zip
Write-Host "Creating $completeZip ..."
$excludeNames = @(
    '.git',
    '.dart_tool',
    '.idea',
    '.vscode',
    'build',
    'scratch',
    'electrozonebd_complete_website.zip',
    'backend_cpanel.zip',
    'electrozonebd_updated_fixed.zip',
    'electrozonebd_updated_all_fixed.zip',
    'electrozonebd_updated_files_only.zip',
    'electrozonebd_complete_updated_website.zip'
)

$fullItems = Get-ChildItem -Path $rootDir | Where-Object {
    $excludeNames -notcontains $_.Name
}

Compress-Archive -Path ($fullItems.FullName) -DestinationPath $completeZip -Force
$cSize = [math]::Round(((Get-Item $completeZip).Length / 1MB), 2)
Write-Host "Created electrozonebd_complete_updated_website.zip ($cSize MB)"

Write-Host "ALL ZIPS CREATED SUCCESSFULLY!"
