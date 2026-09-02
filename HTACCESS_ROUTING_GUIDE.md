# ElectroZoneBD Backend - .htaccess URL Routing Configuration

## 📋 Overview

The `.htaccess` file is critical for API routing on cPanel. It:
- ✅ Enables URL rewriting (mod_rewrite)
- ✅ Routes API requests to `public/index.php`
- ✅ Protects sensitive files (`.env`, `config.php`)
- ✅ Enables CORS for image uploads
- ✅ Handles gzip compression
- ✅ Sets PHP memory limits

---

## ✅ Task 9: Verify .htaccess is Correctly Configured

### Already Done ✓

The `.htaccess` file in your backend folder is **already properly configured**:

```
Location: /home/asiment3/public_html/api/.htaccess
Size: ~3 KB
Status: ✅ Ready for cPanel
```

### What's Already in .htaccess:

```apache
<IfModule mod_rewrite.c>
    RewriteEngine On
    Options -Indexes
    
    # Block sensitive files
    RewriteRule "(^|/)\." - [F]
    <FilesMatch "^(config\.php|\.env|composer\.json|composer\.lock|router\.php)$">
        Require all denied
    </FilesMatch>
    
    # Handle Authorization Header (for JWT)
    RewriteCond %{HTTP:Authorization} .
    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
    
    # Serve uploaded images
    RewriteCond %{REQUEST_URI} ^/api/uploads/(.+)$
    RewriteCond %{DOCUMENT_ROOT}/api/public/uploads/%1 -f
    RewriteRule ^uploads/(.+)$ public/uploads/$1 [L]
    
    # Allow existing files
    RewriteCond %{REQUEST_FILENAME} -f
    RewriteRule ^ - [L]
    
    # Allow existing directories
    RewriteCond %{REQUEST_FILENAME} -d
    RewriteRule ^ - [L]
    
    # Route everything to public/index.php
    RewriteRule ^ public/index.php [L]
</IfModule>
```

---

## 🔧 What You Need to Do on cPanel

### Step 1: Verify .htaccess is Uploaded

1. Go to cPanel File Manager
2. Navigate to: `/public_html/api/`
3. Check if `.htaccess` file exists
4. If not visible, enable "Show Hidden Files":
   - Settings → Show Hidden Files (toggle ON)

### Step 2: Check File Permissions

1. Right-click `.htaccess`
2. Select **Change Permissions**
3. Set to: `644` (rw-r--r--)
4. Click **Change**

### Step 3: Verify mod_rewrite is Enabled

1. In cPanel, search for **"Apache Modules"**
2. Look for: `mod_rewrite`
3. Should be **checked/enabled**

If NOT enabled:
- Contact hosting support to enable `mod_rewrite`
- Some shared hosts have it disabled by default

### Step 4: Test mod_rewrite Status

Create a test file: `test_rewrite.php`

```php
<?php
if (extension_loaded('mod_rewrite')) {
    echo "✓ mod_rewrite is ENABLED";
} else {
    echo "✗ mod_rewrite is DISABLED - Contact support";
}
?>
```

1. Upload to: `/public_html/api/test_rewrite.php`
2. Access: `https://electrozonebd.com/api/test_rewrite.php`
3. Delete after testing

---

## 🧪 Test API Routing

After uploading and configuring .htaccess:

### Test 1: Health Check Endpoint

```
GET https://electrozonebd.com/api/health
```

Expected response:
```json
{
  "status": "ok",
  "message": "API is running"
}
```

### Test 2: List Products

```
GET https://electrozonebd.com/api/products
```

Expected response:
```json
[
  {
    "product_id": 1,
    "product_name": "Product Name",
    "price": 9999,
    ...
  },
  ...
]
```

### Test 3: API with Query Parameter

```
GET https://electrozonebd.com/api/products?limit=5
```

Should return 5 products.

### Test 4: Login Endpoint

```
POST https://electrozonebd.com/api/auth/login
Content-Type: application/json

{
  "email": "adminNoman@electrozonebd.com",
  "password": "ElectroAdmin@2026"
}
```

Expected response:
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {...}
}
```

---

## 🔐 Security Features in .htaccess

### 1. Block Hidden Files
```apache
RewriteRule "(^|/)\." - [F]
```
Blocks: `.env`, `.git`, `.htaccess` access

### 2. Block Sensitive Files
```apache
<FilesMatch "^(config\.php|\.env|composer\.json|router\.php)$">
    Require all denied
</FilesMatch>
```
Prevents direct access to configuration files

### 3. JWT Authorization Header
```apache
RewriteCond %{HTTP:Authorization} .
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
```
Allows JWT tokens in Authorization header (required for auth)

### 4. CORS Headers for Images
```apache
<IfModule mod_headers.c>
    <FilesMatch "\.(jpg|jpeg|png|webp|gif|svg)$">
        Header always set Access-Control-Allow-Origin "*"
        Header always set Access-Control-Allow-Methods "GET, OPTIONS"
    </FilesMatch>
</IfModule>
```
Allows images to be served to Flutter app from different domain

### 5. Gzip Compression
```apache
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/html text/xml text/css
    AddOutputFilterByType DEFLATE application/json application/javascript
</IfModule>
```
Reduces API response size (faster for Flutter app)

### 6. Browser Caching
```apache
<IfModule mod_expires.c>
    ExpiresByType image/jpg "access plus 1 month"
    ExpiresByType text/css "access plus 1 week"
    ExpiresByType application/javascript "access plus 1 week"
</IfModule>
```
Reduces server load for static files

---

## 🆘 Troubleshooting .htaccess Issues

### Issue 1: "404 Not Found" on API endpoints

**Symptoms:**
```
https://electrozonebd.com/api/products → 404 Not Found
```

**Solutions:**
1. ✅ Verify `.htaccess` is in `/api/` folder
2. ✅ Check file permissions: 644
3. ✅ Verify `mod_rewrite` is enabled (check Apache Modules)
4. ✅ Check `.htaccess` syntax: http://htaccess.madewithlove.com/

**Test:**
```bash
# Via SSH
cd /home/asiment3/public_html/api
cat .htaccess | head -20
# Should show RewriteEngine configuration
```

### Issue 2: "500 Internal Server Error"

**Symptoms:**
```
API returns: 500 Internal Server Error
```

**Solutions:**
1. ✅ Check PHP error logs: `storage/logs/error.log`
2. ✅ Verify `.htaccess` syntax is correct
3. ✅ Check PHP version (must be 8.1+)
4. ✅ Verify database connection in `.env`

**Test:**
```bash
# Check for .htaccess errors
apachectl configtest  # May require sudo
```

### Issue 3: "Authorization Header Not Working"

**Symptoms:**
```
Login works, but subsequent requests fail
Authorization header ignored
```

**Solutions:**
1. ✅ Verify `.htaccess` has JWT header line:
   ```apache
   RewriteCond %{HTTP:Authorization} .
   RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
   ```
2. ✅ Check if hosting provider supports custom headers
3. ✅ Contact support to enable `mod_setenvif`

### Issue 4: "Images Not Loading (CORS Error)"

**Symptoms:**
```
Uploaded images show CORS error in browser console
```

**Solutions:**
1. ✅ Verify CORS headers in `.htaccess`:
   ```apache
   Header always set Access-Control-Allow-Origin "*"
   ```
2. ✅ Check `mod_headers` module is enabled
3. ✅ Verify images are in: `public/uploads/`
4. ✅ Check image file permissions: 644

---

## 📋 .htaccess Verification Checklist

After uploading to cPanel:

- [ ] `.htaccess` file exists in `/api/` folder
- [ ] File permissions set to 644 (rw-r--r--)
- [ ] `mod_rewrite` enabled in Apache Modules
- [ ] `.htaccess` syntax is valid
- [ ] API health endpoint works: `https://electrozonebd.com/api/health`
- [ ] Products endpoint works: `https://electrozonebd.com/api/products`
- [ ] Login endpoint works: `POST /auth/login`
- [ ] Uploaded images accessible
- [ ] No 404 errors on API calls
- [ ] No 500 errors on API calls
- [ ] JWT authorization working
- [ ] Gzip compression enabled

---

## 🔗 Complete API Routing Flow

```
User Request:
  ↓
https://electrozonebd.com/api/products
  ↓
Apache receives request
  ↓
.htaccess mod_rewrite processes:
  1. Check if .env/.git/config.php → Block (403)
  2. Check if Authorization header → Pass to PHP
  3. Check if file exists → Serve directly
  4. Check if directory exists → Serve directly
  5. Otherwise → Route to public/index.php
  ↓
public/index.php (entry point)
  ↓
router.php processes URL
  ↓
Route to correct controller
  ↓
Controller queries database
  ↓
Return JSON response
  ↓
.htaccess adds CORS headers
  ↓
.htaccess compresses with gzip
  ↓
Response sent to Flutter app
```

---

## 📞 If Still Having Issues

1. **Check error logs:**
   ```
   cPanel → Error Logs → Look for API errors
   SSH: tail -100 /home/asiment3/electrozonebd.com/api/storage/logs/error.log
   ```

2. **Test with curl:**
   ```bash
   curl -v https://electrozonebd.com/api/health
   # Check response headers and status
   ```

3. **Verify Apache config:**
   ```bash
   apachectl configtest  # Should say "Syntax OK"
   ```

4. **Contact Hosting Support with:**
   - cPanel username: asiment3
   - Domain: electrozonebd.com
   - Issue: API endpoints returning 404
   - Confirm: mod_rewrite enabled, .htaccess present

---

## 🎯 Task 9 Status

✅ **COMPLETED**

Your `.htaccess` file is already properly configured and ready for cPanel deployment. No changes needed - just verify after uploading to cPanel.

Next: Task 10 - Update Flutter app config

