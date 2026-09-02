# ElectroZoneBD Backend - cPanel Upload Guide

## 📋 Upload Instructions

### Method 1: Using FTP (Recommended for large files)

1. **Connect via FTP:**
   - Host: electrozonebd.com (or your FTP host)
   - Username: asiment3
   - Password: [Your FTP password]
   - Port: 21

2. **Navigate to:** `/home/asiment3/electrozonebd.com/`

3. **Upload backend folder contents:**
   - Create folder: `api`
   - Upload ALL files from backend/ into `api/` folder:
     ```
     ✅ .env
     ✅ .htaccess
     ✅ composer.json
     ✅ composer.lock
     ✅ config.php
     ✅ router.php
     ✅ Folders: api/, config/, controllers/, middleware/, models/, public/, services/, util/
     ⚠️  DO NOT upload: vendor/ (install via composer on cPanel)
     ⚠️  DO NOT upload: error.log, storage/ (will be created by system)
     ```

4. **File Permissions After Upload:**
   ```
   Folders:  755 (drwxr-xr-x)
   Files:    644 (-rw-r--r--)
   storage/: 777 (drwxrwxrwx)
   public/:  755 (drwxr-xr-x)
   ```

### Method 2: Using cPanel File Manager

1. Login to cPanel
2. File Manager → Navigate to `/public_html/api/`
3. Upload file manager → Choose files
4. Set permissions as above

---

## 🔧 Post-Upload Configuration (on cPanel)

### Step 1: Connect via SSH or cPanel Terminal

```bash
cd /home/asiment3/electrozonebd.com/api
```

### Step 2: Install Composer Dependencies

```bash
php -v  # Verify PHP 8.1 is available
composer install --no-dev --optimize-autoloader
```

If `composer` command not found, use:
```bash
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php --quiet
php composer.phar install --no-dev --optimize-autoloader
```

### Step 3: Set Correct Permissions

```bash
chmod 755 api
chmod 755 api/public
chmod 644 api/.env
chmod 755 api/storage
chmod 755 api/storage/uploads  # Create if not exists
mkdir -p api/storage/uploads
chmod 755 api/storage/uploads
```

### Step 4: Verify .htaccess is Active

Check if `mod_rewrite` is enabled:
```bash
# In cPanel: Home > Apache Modules > Search "rewrite"
```

If not enabled, contact hosting support to enable `mod_rewrite`.

---

## 📂 Directory Structure on cPanel

```
/home/asiment3/electrozonebd.com/
├── api/                      # Backend folder
│   ├── .env                  # Database credentials
│   ├── .htaccess            # URL rewriting
│   ├── config.php           # Configuration loader
│   ├── router.php           # API routes
│   ├── composer.json        # Dependencies
│   ├── composer.lock
│   ├── api/                 # API versioning (v1, v2)
│   ├── config/              # Config files
│   ├── controllers/         # Request handlers
│   ├── models/              # Database models
│   ├── services/            # Business logic
│   ├── middleware/          # Auth, CORS, etc.
│   ├── public/              # Entry point
│   │   ├── index.php       # API entry point
│   │   └── uploads/        # Uploaded images
│   ├── storage/             # Temp files, logs
│   └── vendor/              # Composer packages (after install)
```

---

## 🔗 API Endpoints After Deployment

```
Base URL: https://electrozonebd.com/api/

Examples:
✅ https://electrozonebd.com/api/auth/login
✅ https://electrozonebd.com/api/products
✅ https://electrozonebd.com/api/orders
✅ https://electrozonebd.com/api/cart
```

---

## ✅ Verification Checklist

After upload and configuration:

- [ ] `.env` file uploaded with correct credentials
- [ ] `composer install` completed successfully
- [ ] Permissions set correctly (755/644)
- [ ] `mod_rewrite` enabled in Apache
- [ ] Can access: `https://electrozonebd.com/api/health` (returns OK)
- [ ] Database connection working
- [ ] Admin login works in Flutter app

---

## 🆘 Troubleshooting

### "404 Not Found" on API endpoints
- ✅ Check `.htaccess` is in place
- ✅ Verify `mod_rewrite` is enabled
- ✅ Check folder permissions (755)

### "500 Internal Server Error"
- ✅ Check PHP error logs: `/home/asiment3/electrozonebd.com/api/storage/logs/`
- ✅ Verify `.env` database credentials are correct
- ✅ Ensure `vendor/` folder exists (run `composer install`)

### "Database connection failed"
- ✅ Verify database user `asiment3_zones` has all privileges
- ✅ Check `.env` DB_HOST is `localhost` (cPanel uses local sockets)
- ✅ Confirm database name: `asiment3_electrobd`

### PHP version issues
- ✅ cPanel must use PHP 8.1+
- ✅ Check via: `php -v` in terminal
- ✅ Select PHP version in cPanel: Home > PHP Selector

---

## 📞 Support

If issues occur, check:
1. cPanel error logs: `/home/asiment3/electrozonebd.com/api/storage/logs/`
2. Apache logs: Via cPanel > Raw Access Logs
3. PHP info: Create test file `<?php phpinfo(); ?>`

