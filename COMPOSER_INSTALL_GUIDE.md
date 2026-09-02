# ElectroZoneBD Backend - Composer Installation on cPanel

## 📋 Overview

After uploading backend files to cPanel, you need to install PHP dependencies using Composer.

**What is Composer?**
- PHP package manager (like npm for Node.js)
- Installs all required PHP libraries listed in `composer.json`
- Creates `vendor/` folder with all dependencies

**Why Install on cPanel?**
- Don't upload `vendor/` folder (too large ~100+ MB)
- Install fresh on cPanel server after upload
- Ensures compatibility with server PHP version (8.1)

---

## 🚀 Method 1: Via cPanel Terminal (Recommended)

### Step 1: Access cPanel Terminal

1. Login to cPanel: `https://electrozonebd.com:2083`
2. Search for **"Terminal"** in cPanel
3. Click on **Terminal**
4. A command-line window will open

### Step 2: Navigate to API Folder

```bash
cd /home/asiment3/public_html/api
```

### Step 3: Verify PHP Version

```bash
php -v
```

You should see:
```
PHP 8.1.x (or higher)
```

If you see PHP 7.x, contact hosting support to select PHP 8.1 version.

### Step 4: Install Composer

**If composer command exists:**
```bash
composer install --no-dev --optimize-autoloader
```

**If composer command not found, download it:**
```bash
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php --quiet
php composer.phar install --no-dev --optimize-autoloader
rm composer-setup.php
```

### Step 5: Wait for Installation

Installation will take 5-15 minutes depending on:
- Server speed
- Number of packages (40+)
- Internet connection

You'll see output like:
```
Loading composer repositories with package information
Updating dependencies
  - Downloading ...
  - Installing ...
Generating optimized autoload files
```

After completion, you should see:
```
✓ Installation successful
```

### Step 6: Verify Installation

```bash
ls -la
```

You should see a new folder: `vendor/`

---

## 🚀 Method 2: Via File Manager (If Terminal Not Available)

### Step 1: Download Composer Installer

On your local machine:
1. Download: https://getcomposer.org/download/
2. Save as: `composer.phar`

### Step 2: Upload Composer

1. Via FTP, upload `composer.phar` to: `/home/asiment3/public_html/api/`
2. Via cPanel File Manager, upload to same location

### Step 3: Execute via Web Browser

1. Create a file: `run_composer.php` in `/home/asiment3/public_html/api/`

```php
<?php
shell_exec('cd /home/asiment3/public_html/api && php composer.phar install --no-dev --optimize-autoloader');
echo "Composer install started. Check back in 5-10 minutes.";
?>
```

2. Access via browser: `https://electrozonebd.com/api/run_composer.php`
3. Wait for 5-15 minutes
4. Check if `vendor/` folder was created
5. **Delete `run_composer.php` after completion** (security risk)

---

## 📦 What Gets Installed

After composer install, your `vendor/` folder will contain:

```
vendor/
├── autoload.php              # Autoloader (included in code)
├── composer/                 # Composer metadata
├── doctrine/                 # Database ORM
├── firebase/                 # JWT authentication
├── guzzlehttp/              # HTTP client
├── monolog/                 # Logging
├── phpmailer/               # Email sending
├── symfony/                 # Framework components
├── psr/                     # PHP standards
└── ... (40+ other packages)
```

---

## ✅ Post-Installation: Create Storage Folders

After composer install, create upload directories:

### Via Terminal:

```bash
# Create directories
mkdir -p /home/asiment3/public_html/api/storage/uploads
mkdir -p /home/asiment3/public_html/api/storage/logs
mkdir -p /home/asiment3/public_html/api/storage/temp

# Set permissions
chmod 755 /home/asiment3/public_html/api/storage
chmod 755 /home/asiment3/public_html/api/storage/uploads
chmod 755 /home/asiment3/public_html/api/storage/logs
chmod 755 /home/asiment3/public_html/api/storage/temp

# Verify
ls -la /home/asiment3/public_html/api/storage/
```

### Via File Manager:

1. Navigate to: `/public_html/api/storage/`
2. Right-click → Create New Folder
3. Create: `uploads`, `logs`, `temp`
4. Right-click each → Change Permissions → 755

---

## 🧪 Test Installation

### Step 1: Check vendor Folder

Via Terminal:
```bash
ls -la /home/asiment3/public_html/api/vendor/
# Should list 40+ packages
```

Via File Manager:
1. Navigate to `/public_html/api/`
2. Should see `vendor/` folder

### Step 2: Test API Health Endpoint

Open browser and go to:
```
https://electrozonebd.com/api/health
```

You should see:
```json
{
  "status": "ok",
  "message": "API is running"
}
```

If you get error:
- Check `.env` file has correct database credentials
- Verify database import completed
- Check error logs in `storage/logs/`

### Step 3: Test Product Endpoint

```
https://electrozonebd.com/api/products
```

You should see JSON with products list.

---

## 🆘 Troubleshooting

### Error: "composer: command not found"

**Solution:**
```bash
# Download composer
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php'); php('composer-setup.php'); unlink('composer-setup.php');"

# Run with php
php composer.phar install --no-dev --optimize-autoloader
```

### Error: "PHP version 7.x required, 8.x provided"

**Solution:**
1. Go to cPanel → PHP Selector
2. Select PHP 8.1 or higher
3. Click Set as Default
4. Run composer install again

### Error: "Could not connect to database"

**Solution:**
1. Check `.env` file:
   ```bash
   cat /home/asiment3/public_html/api/.env
   ```
2. Verify database credentials:
   - DB_NAME: asiment3_electrobd
   - DB_USER: asiment3_zones
   - DB_PASSWORD: i~B5+W#2nJ2-_X2q
   - DB_HOST: localhost

3. Test database connection:
   ```bash
   mysql -h localhost -u asiment3_zones -p asiment3_electrobd
   # Enter password: i~B5+W#2nJ2-_X2q
   # If connected, type: quit
   ```

### Error: "vendor/ folder very large / disk quota exceeded"

**Solution:**
1. Use `--no-dev` flag (already in guide)
2. Use `--optimize-autoloader` (already in guide)
3. Remove unnecessary packages from composer.json
4. Contact hosting support to increase disk quota

### Installation Hangs/Takes Too Long

**Solution:**
1. May be normal (10-15 minutes is typical)
2. Check terminal for activity
3. If completely stuck, try again
4. Contact hosting support if persistent issues

---

## 📋 Verification Checklist

After composer install:

- [ ] Logged into cPanel Terminal
- [ ] Navigated to: /home/asiment3/public_html/api
- [ ] Verified PHP version: 8.1 or higher
- [ ] Ran: composer install --no-dev --optimize-autoloader
- [ ] Installation completed successfully
- [ ] vendor/ folder exists
- [ ] Created storage/uploads folder
- [ ] Created storage/logs folder
- [ ] Created storage/temp folder
- [ ] Set permissions: 755 for folders, 644 for files
- [ ] Tested: https://electrozonebd.com/api/health (returns OK)
- [ ] Tested: https://electrozonebd.com/api/products (returns products)

---

## 📊 What's Installed

Key packages installed by composer:

```
✅ firebase/jwt                 - JWT token authentication
✅ guzzlehttp/guzzle           - HTTP requests
✅ phpmailer/phpmailer         - Email sending
✅ doctrine/dbal               - Database abstraction
✅ monolog/monolog             - Logging
✅ symfony/http-foundation     - HTTP support
✅ symfony/routing             - URL routing
✅ psr/log                     - Logging standard
✅ psr/http-message            - HTTP standard
✅ ... 30+ other packages
```

---

## 🎯 Next Steps

After composer install:

1. ✅ Composer installed (THIS STEP)
2. ⏭️  Verify .htaccess routing
3. ⏭️  Test API endpoints from local machine
4. ⏭️  Update Flutter app config
5. ⏭️  Deploy Flutter web app
6. ⏭️  Test complete flow

