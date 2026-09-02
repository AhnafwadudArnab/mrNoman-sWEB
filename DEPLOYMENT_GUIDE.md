# ElectroZoneBD - cPanel Deployment Guide

## 📦 Package Information
- **File:** `electrozonebd_full_deploy.zip` (38.24 MB)
- **Build Date:** May 5, 2026
- **Flutter Version:** Latest stable
- **PHP Version:** 7.4+ / 8.0+

---

## 🎯 What's Fixed in This Build

### ✅ Order Calculation Bug Fixed
**Issue:** Delivery charge (Inside/Outside Dhaka) was not being added to order total.
- **Before:** `total_amount` = product total - coupon discount (delivery charge ignored)
- **After:** `total_amount` = product total - coupon discount + delivery charge

**File Changed:** `backend/controllers/orderController.php` (lines 163-169)

Now when users select:
- **Inside Dhaka:** Product total + 60 TK = Order total
- **Outside Dhaka:** Product total + 120 TK = Order total

Both admin and user order pages will show the correct total amount.

---

## 📋 Pre-Deployment Checklist

### 1. Database Preparation
Run this SQL migration on your cPanel database:

```sql
-- Allow product_id to be NULL in order_items (for guest orders)
ALTER TABLE order_items MODIFY COLUMN product_id INT NULL;
```

**How to run:**
1. Go to cPanel → phpMyAdmin
2. Select database: `asiment1_electrobd`
3. Click "SQL" tab
4. Paste the above SQL
5. Click "Go"

### 2. Backend Dependencies
The zip includes `backend/vendor/` folder with all dependencies (PHPMailer, etc.).
**No composer install needed** - everything is pre-packaged.

### 3. Environment Configuration
The `.env` file is already configured for production:
- Database: `asiment1_electrobd`
- API URL: `https://electrozonebd.com`
- Debug: `false`
- SMTP: Gmail configured

---

## 🚀 Deployment Steps

### Step 1: Backup Current Site
1. Go to cPanel → File Manager
2. Navigate to `/home/asiment1/electrozonebd.com/`
3. Select all files → Compress → Download backup

### Step 2: Upload New Build
1. Go to cPanel → File Manager
2. Navigate to `/home/asiment1/electrozonebd.com/`
3. Click "Upload"
4. Upload `electrozonebd_full_deploy.zip`
5. Wait for upload to complete

### Step 3: Extract Files
1. Right-click on `electrozonebd_full_deploy.zip`
2. Click "Extract"
3. Extract to: `/home/asiment1/electrozonebd.com/`
4. Confirm overwrite when prompted
5. Delete the zip file after extraction

### Step 4: Verify File Structure
After extraction, your structure should be:

```
/home/asiment1/electrozonebd.com/
├── index.html              ← Flutter web (root)
├── main.dart.js
├── flutter.js
├── flutter_bootstrap.js
├── flutter_service_worker.js
├── .htaccess
├── manifest.json
├── favicon.png
├── assets/                 ← Flutter assets
│   ├── assets/
│   ├── fonts/
│   ├── packages/
│   └── shaders/
├── canvaskit/              ← Flutter renderer
├── icons/
└── backend/                ← PHP backend (or 'api/')
    ├── .env               ← Production config
    ├── .htaccess
    ├── config.php
    ├── router.php
    ├── api/
    ├── config/
    ├── controllers/       ← orderController.php (FIXED!)
    ├── models/
    ├── middleware/
    ├── services/
    ├── util/
    ├── vendor/            ← PHPMailer included
    ├── public/
    │   ├── index.php      ← Main entry point
    │   ├── .htaccess
    │   └── uploads/       ← Product images
    └── storage/
        └── logs/
```

**Note:** If your backend is in `/api/` instead of `/backend/`, rename the folder:
```bash
mv backend api
```

### Step 5: Set File Permissions
Run these commands in cPanel Terminal or SSH:

```bash
# Backend uploads folder (CRITICAL)
chmod 755 /home/asiment1/electrozonebd.com/backend/public/uploads/
chmod 644 /home/asiment1/electrozonebd.com/backend/public/uploads/*

# Backend logs folder
chmod 755 /home/asiment1/electrozonebd.com/backend/storage/logs/
chmod 644 /home/asiment1/electrozonebd.com/backend/storage/logs/*

# Protect .env file
chmod 600 /home/asiment1/electrozonebd.com/backend/.env

# Make sure .htaccess files are readable
chmod 644 /home/asiment1/electrozonebd.com/.htaccess
chmod 644 /home/asiment1/electrozonebd.com/backend/.htaccess
chmod 644 /home/asiment1/electrozonebd.com/backend/public/.htaccess
```

### Step 6: Verify .htaccess Configuration
Check that `/home/asiment1/electrozonebd.com/.htaccess` contains:

```apache
# Serve Flutter web app from root
DirectoryIndex index.html

<IfModule mod_rewrite.c>
    RewriteEngine On
    
    # Route /api requests to backend
    RewriteRule ^api/(.*)$ backend/public/index.php [L,QSA]
    
    # Serve Flutter web app for all other requests
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule ^ index.html [L]
</IfModule>
```

**If this file doesn't exist, create it manually.**

---

## ✅ Post-Deployment Testing

### 1. Test Backend Health
Open in browser:
```
https://electrozonebd.com/api/health
```

Expected response:
```json
{"status":"ok"}
```

### 2. Test Database Connection
Open in browser:
```
https://electrozonebd.com/api
```

Expected response:
```json
{
  "name": "electrozonebd",
  "version": "1.0.0",
  "endpoints": { ... }
}
```

### 3. Test Image Serving
Open in browser:
```
https://electrozonebd.com/api/public/uploads/img_69dde3a2797f86.73004709.jpg
```

Should display an image (not 404).

### 4. Test Frontend
Open in browser:
```
https://electrozonebd.com
```

Should load the Flutter web app.

### 5. Test Login
1. Go to https://electrozonebd.com
2. Click "Login"
3. Enter credentials
4. Should successfully log in

### 6. Test Order Placement (CRITICAL - NEW FIX)
1. Add products to cart
2. Go to checkout
3. Select "Inside Dhaka" or "Outside Dhaka"
4. Complete order
5. **Verify:** Order total = Product total + Delivery charge (60 or 120)
6. Check admin panel → Orders
7. **Verify:** Total amount shows correctly

### 7. Test Admin Panel
1. Login as admin
2. Go to Admin Dashboard
3. Check Orders page
4. **Verify:** All orders show correct totals (including delivery charge)

---

## 🔧 Troubleshooting

### Issue: 500 Internal Server Error
**Solution:**
1. Check PHP error log: `/home/asiment1/electrozonebd.com/backend/error.log`
2. Check cPanel error log: cPanel → Errors
3. Verify .htaccess syntax
4. Check file permissions

### Issue: Database Connection Failed
**Solution:**
1. Verify database credentials in `backend/.env`
2. Check database exists in cPanel → MySQL Databases
3. Verify user has permissions on database
4. Test connection with phpMyAdmin

### Issue: Images Not Loading
**Solution:**
1. Check uploads folder permissions: `chmod 755 backend/public/uploads/`
2. Verify .htaccess rewrite rules
3. Check image paths in database
4. Test direct image URL

### Issue: CORS Errors
**Solution:**
1. Check `backend/config/cors.php`
2. Verify `ALLOWED_ORIGINS` in `.env`
3. Add both www and non-www variants
4. Clear browser cache

### Issue: Orders Not Showing Correct Total
**Solution:**
1. Verify database migration was run (product_id nullable)
2. Check `backend/controllers/orderController.php` has delivery charge fix
3. Clear Flutter app cache
4. Test new order placement

---

## 📊 Monitoring & Maintenance

### Check Error Logs
```bash
tail -f /home/asiment1/electrozonebd.com/backend/error.log
tail -f /home/asiment1/electrozonebd.com/backend/storage/logs/$(date +%Y-%m-%d).log
```

### Database Backup
1. Go to cPanel → phpMyAdmin
2. Select `asiment1_electrobd`
3. Click "Export"
4. Choose "Quick" export
5. Download SQL file

**Schedule:** Weekly backups recommended

### Monitor Disk Space
```bash
du -sh /home/asiment1/electrozonebd.com/backend/public/uploads/
```

### Clean Old Logs
```bash
find /home/asiment1/electrozonebd.com/backend/storage/logs/ -name "*.log" -mtime +30 -delete
```

---

## 🔐 Security Checklist

- [x] `.env` file has 600 permissions (not readable by others)
- [x] `backend/.htaccess` blocks access to config files
- [x] `backend/public/.htaccess` blocks PHP execution in uploads
- [x] JWT secret is strong (64 characters)
- [x] Database password is strong
- [x] HTTPS is enabled (SSL certificate)
- [x] CORS is restricted to production domain
- [x] Debug mode is OFF (`APP_DEBUG=false`)
- [x] Error display is OFF (production mode)
- [x] Rate limiting is enabled
- [x] Input validation is active
- [x] SQL injection protection (prepared statements)
- [x] XSS protection headers enabled

---

## 📞 Support & Contact

**Developer:** Kiro AI Assistant  
**Deployment Date:** May 5, 2026  
**Version:** 1.0.0 (Order Fix Release)

**Important Files:**
- Backend fix: `backend/controllers/orderController.php`
- Database migration: `backend/sql/fix_order_items_nullable_product_id.sql`
- Environment config: `backend/.env`
- API entry point: `backend/public/index.php`

---

## ✨ What's Working

✅ User Authentication (Login/Register)  
✅ Admin Authentication  
✅ Product Catalog  
✅ Shopping Cart  
✅ Order Placement (Guest + Authenticated)  
✅ Order Management (Admin)  
✅ Order History (User)  
✅ **Delivery Charge Calculation (FIXED!)**  
✅ Coupon Discounts  
✅ Image Uploads  
✅ Product Search  
✅ Wishlist  
✅ Reviews & Ratings  
✅ Email Notifications  
✅ Payment Methods  
✅ Stock Management  
✅ Best Sellers Tracking  
✅ Trending Products  
✅ Flash Sales  
✅ Collections  
✅ Deals of the Day  

---

## 🎉 Deployment Complete!

Your ElectroZoneBD e-commerce platform is now live with the order calculation fix.

**Test the fix immediately:**
1. Place a test order with "Inside Dhaka" delivery
2. Verify total = products + 60 TK
3. Place another order with "Outside Dhaka"
4. Verify total = products + 120 TK
5. Check both orders in admin panel
6. Confirm totals are correct

**If everything works, you're all set! 🚀**
