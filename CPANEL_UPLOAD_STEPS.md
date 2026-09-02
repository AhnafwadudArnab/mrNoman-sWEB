# ElectroZoneBD Backend Upload to cPanel - Step by Step

## 📦 Option 1: Upload via cPanel File Manager (Easiest)

### Step 1: Login to cPanel
```
URL: https://electrozonebd.com:2083
Username: asiment3
Password: [Your cPanel password]
```

### Step 2: Access File Manager
1. Click **File Manager** in cPanel
2. Navigate to: `/home/asiment3/public_html/`
3. You should see: `index.html` or `index.php`

### Step 3: Create 'api' Folder
1. Right-click in empty space
2. Select **Create New Folder**
3. Name it: `api`
4. Click **Create**

### Step 4: Navigate into 'api' Folder
1. Double-click the `api` folder to enter it

### Step 5: Upload Backend Files

**Upload Method:**
1. Click **Upload** button (top menu)
2. Choose files from your computer:

**Files to upload (in this order):**
```
From: c:\Wbsite fixing\electrocitybd_upto\backend\

Upload these files:
  1. .env
  2. .htaccess
  3. config.php
  4. router.php
  5. composer.json
  6. composer.lock
```

**Folders to upload (drag & drop):**
```
  1. api/
  2. config/
  3. controllers/
  4. middleware/
  5. models/
  6. public/
  7. services/
  8. util/
  9. sql/
```

### Step 6: Set File Permissions

After upload completes:

**For .env file:**
1. Right-click `.env`
2. Select **Change Permissions**
3. Set to: `644` (rw-r--r--)
4. Click **Change**

**For folders:**
1. Right-click each folder
2. Select **Change Permissions**
3. Set to: `755` (rwxr-xr-x)
4. Check **Recursive** checkbox
5. Click **Change**

---

## 🔧 Option 2: Upload via FTP (For Large Files)

### FTP Credentials
```
Host: electrozonebd.com (or ftp.electrozonebd.com)
Username: asiment3
Password: [Your FTP password]
Port: 21
```

### FTP Steps

1. **Download FTP Client:**
   - FileZilla (free) - https://filezilla-project.org/
   - WinSCP (free)
   - Cyberduck (free)

2. **Connect to Server:**
   ```
   Host: electrozonebd.com
   Username: asiment3
   Password: [Your FTP password]
   Port: 21
   ```

3. **Navigate to:**
   ```
   Remote: /home/asiment3/public_html/
   ```

4. **Create 'api' folder** (in remote server)
5. **Double-click 'api'** to enter
6. **Drag & drop backend files:**
   ```
   From Local Computer: c:\Wbsite fixing\electrocitybd_upto\backend\
   To Remote: /home/asiment3/public_html/api/
   
   Files: .env, .htaccess, config.php, router.php, composer.json, composer.lock
   Folders: api/, config/, controllers/, middleware/, models/, public/, services/, util/, sql/
   ```

7. **Right-click on files → File Permissions:**
   ```
   .env = 644
   Folders = 755
   ```

---

## ✅ After Upload: Verify in cPanel

1. Go back to cPanel
2. File Manager → `/public_html/api/`
3. You should see:
   ```
   ✅ .env
   ✅ .htaccess
   ✅ config.php
   ✅ router.php
   ✅ composer.json
   ✅ composer.lock
   ✅ api/ (folder)
   ✅ config/ (folder)
   ✅ controllers/ (folder)
   ✅ middleware/ (folder)
   ✅ models/ (folder)
   ✅ public/ (folder)
   ✅ services/ (folder)
   ✅ util/ (folder)
   ```

---

## 🖥️ Next: Install Composer Dependencies

After upload, you need to run composer on cPanel:

### Via cPanel Terminal

1. Go to: **cPanel → Terminal** (or Advanced → Terminal)
2. Run these commands:

```bash
# Navigate to api folder
cd /home/asiment3/public_html/api

# Verify PHP version
php -v
# Should show: PHP 8.1 or higher

# Install dependencies
composer install --no-dev --optimize-autoloader

# If composer command not found, use:
# php -r "copy('https://getcomposer.org/installer', 'composer-setup.php'); php('composer-setup.php'); unlink('composer-setup.php');"
# php composer.phar install --no-dev --optimize-autoloader
```

3. Wait for composer to finish (5-10 minutes)

### Create Storage Folders

```bash
# Create upload directory
mkdir -p /home/asiment3/public_html/api/storage/uploads
mkdir -p /home/asiment3/public_html/api/storage/logs

# Set permissions
chmod 755 /home/asiment3/public_html/api/storage
chmod 755 /home/asiment3/public_html/api/storage/uploads
chmod 755 /home/asiment3/public_html/api/storage/logs
```

---

## 🧪 Test API Connection

After composer install:

1. Open browser and go to:
   ```
   https://electrozonebd.com/api/health
   ```

2. You should see:
   ```json
   {
     "status": "ok",
     "message": "API is running"
   }
   ```

If you see error, check:
- ✅ `.env` file exists
- ✅ Database credentials correct
- ✅ `mod_rewrite` enabled
- ✅ PHP 8.1 selected in cPanel

---

## 📝 Checklist

After completing upload:

- [ ] All files uploaded to `/home/asiment3/public_html/api/`
- [ ] Permissions set: files 644, folders 755
- [ ] `.env` file contains correct database credentials
- [ ] Composer installed successfully (vendor/ folder exists)
- [ ] Storage folders created (uploads/, logs/)
- [ ] Can access: https://electrozonebd.com/api/health
- [ ] API returns OK response

---

## 🆘 Troubleshooting

### "404 Not Found" Error
```
Problem: API endpoint not found
Solution:
  1. Check .htaccess is in /api/ folder
  2. Verify mod_rewrite enabled: Home > Apache Modules
  3. Restart Apache (if possible) or contact support
```

### "500 Internal Server Error"
```
Problem: Server error
Solution:
  1. Check error logs: /home/asiment3/public_html/api/storage/logs/
  2. Verify .env database credentials
  3. Ensure vendor/ folder exists
  4. Check PHP version: php -v (should be 8.1+)
```

### "Cannot Connect to Database"
```
Problem: Database connection failed
Solution:
  1. Verify .env has correct credentials:
     - DB_HOST=localhost (NOT hostname)
     - DB_NAME=asiment3_electrobd
     - DB_USER=asiment3_zones
     - DB_PASSWORD=i~B5+W#2nJ2-_X2q
  2. Test database user in phpMyAdmin
  3. Check MariaDB is running
```

---

## Next Steps After Upload

1. ✅ Upload backend files (THIS STEP)
2. ⏭️ Import database schema (electrobd_structure.sql, electrobd_data.sql)
3. ⏭️ Test API endpoints
4. ⏭️ Update Flutter app config
5. ⏭️ Deploy Flutter web

