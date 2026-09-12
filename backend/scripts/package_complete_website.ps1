# Complete cPanel Website Packaging Script
# Target extraction directory: /home/asiment3/electrozonebd.com

$staging = "c:\Website-fixing\scratch_complete_website"
$zipOut = "c:\Website-fixing\electrozonebd_complete_website.zip"
$webBuild = "c:\Website-fixing\build\web"

Write-Host "Checking if Flutter Web build is ready..."
if (-not (Test-Path "$webBuild\index.html")) {
    Write-Error "Flutter web build not found at $webBuild! Please wait for build to complete."
    exit 1
}

Write-Host "Cleaning old staging and zip..."
if (Test-Path $staging) { Remove-Item -Recurse -Force $staging }
if (Test-Path $zipOut) { Remove-Item -Force $zipOut }

New-Item -ItemType Directory -Path $staging | Out-Null

# 1. Copy Flutter Web build files to root of staging
Write-Host "1. Copying Flutter Web frontend files to root..."
Copy-Item -Recurse -Force "$webBuild\*" $staging

# 2. Prepare API directory
$apiDir = "$staging\api"
New-Item -ItemType Directory -Path $apiDir | Out-Null

Write-Host "2. Copying backend files to /api..."
$folders = @("api", "config", "controllers", "middleware", "models", "public", "services", "util", "vendor")
foreach ($f in $folders) {
    $src = "c:\Website-fixing\backend\$f"
    if (Test-Path $src) {
        Copy-Item -Recurse -Force $src "$apiDir\$f"
    }
}

# Ensure uploads folder exists
$uploadsDir = "$apiDir\public\uploads"
if (-not (Test-Path $uploadsDir)) {
    New-Item -ItemType Directory -Path $uploadsDir | Out-Null
}

# Backend root files
Copy-Item "c:\Website-fixing\backend\.htaccess" "$apiDir\.htaccess"
Copy-Item "c:\Website-fixing\backend\config.php" "$apiDir\config.php"
Copy-Item "c:\Website-fixing\backend\index.php" "$apiDir\index.php"
Copy-Item "c:\Website-fixing\backend\.env.production" "$apiDir\.env"

# 3. Create identical /backend folder to prevent any legacy route breaks
Write-Host "3. Mirroring to /backend for dual-compatibility..."
Copy-Item -Recurse -Force $apiDir "$staging\backend"

# 4. Master Root .htaccess
Write-Host "4. Writing master root .htaccess..."
$rootHtaccess = @'
Options -MultiViews
RewriteEngine On

# Force HTTPS
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]

# Redirect www to non-www
RewriteCond %{HTTP_HOST} ^www\.(.+)$ [NC]
RewriteRule ^ https://%1%{REQUEST_URI} [R=301,L]

# Serve uploaded images directly
RewriteCond %{REQUEST_URI} ^/api/public/uploads/(.+)$
RewriteRule ^api/public/uploads/(.+)$ api/public/uploads/$1 [L]

RewriteCond %{REQUEST_URI} ^/api/uploads/(.+)$
RewriteRule ^api/uploads/(.+)$ api/public/uploads/$1 [L]

RewriteCond %{REQUEST_URI} ^/uploads/(.+)$
RewriteRule ^uploads/(.+)$ api/public/uploads/$1 [L]

# Route /api/* requests to api/public/index.php
RewriteCond %{REQUEST_URI} ^/api(/.*)?$ [NC]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^api(/.*)?$ api/public/index.php [L,QSA]

# Route /backend/* requests to backend/public/index.php
RewriteCond %{REQUEST_URI} ^/backend(/.*)?$ [NC]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^backend(/.*)?$ backend/public/index.php [L,QSA]

# Fix asset image paths if needed
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^assets/(?!assets/)(.+\.(jpg|jpeg|png|gif|webp|svg|ico))$ assets/assets/$1 [L,NC]

# Serve static assets directly
RewriteRule \.(jpg|jpeg|png|gif|webp|svg|ico|woff|woff2|ttf|otf|wasm|js|css|json)$ - [L,NC]

# Handle Flutter web SPA routing — send all other requests to index.html
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^ index.html [L]

# MIME types for Flutter web
<IfModule mod_mime.c>
  AddType application/wasm .wasm
  AddType application/javascript .js .mjs
  AddType application/manifest+json .json
</IfModule>

# Cache static assets
<IfModule mod_expires.c>
  ExpiresActive On
  ExpiresByType text/html                 "access plus 0 seconds"
  ExpiresByType application/javascript    "access plus 1 year"
  ExpiresByType text/css                  "access plus 1 year"
  ExpiresByType image/png                 "access plus 1 year"
  ExpiresByType image/jpg                 "access plus 1 year"
  ExpiresByType image/jpeg                "access plus 1 year"
  ExpiresByType image/webp                "access plus 1 year"
  ExpiresByType font/woff2                "access plus 1 year"
  ExpiresByType application/wasm          "access plus 1 year"
</IfModule>

# Gzip compression
<IfModule mod_deflate.c>
  AddOutputFilterByType DEFLATE text/html text/plain text/css
  AddOutputFilterByType DEFLATE application/javascript application/json
  AddOutputFilterByType DEFLATE application/wasm
  AddOutputFilterByType DEFLATE font/woff2
</IfModule>

# Security headers
<IfModule mod_headers.c>
  Header always set X-Content-Type-Options "nosniff"
  Header always set X-Frame-Options "SAMEORIGIN"
  Header always set X-XSS-Protection "1; mode=block"
</IfModule>
'@

Set-Content -Path "$staging\.htaccess" -Value $rootHtaccess -Encoding UTF8

# 5. Compress into single master zip
Write-Host "5. Creating master zip package: $zipOut ..."
$ProgressPreference = 'SilentlyContinue'
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($staging, $zipOut, [System.IO.Compression.CompressionLevel]::Optimal, $false)

# Clean staging
Remove-Item -Recurse -Force $staging

$sizeMB = (Get-Item $zipOut).Length / 1MB
Write-Host "================================================="
Write-Host " SUCCESS: $zipOut created!"
Write-Host " Package size: $([math]::Round($sizeMB, 2)) MB"
Write-Host " Ready for direct extraction into /home/asiment3/electrozonebd.com"
Write-Host "================================================="
