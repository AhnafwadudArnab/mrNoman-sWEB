# ElectroZoneBD Flutter App - cPanel Configuration Update

## ✅ Task 10: Update Flutter App Config

### Configuration Updated ✓

The Flutter app is now configured to connect to your cPanel backend:

**File Updated:** `lib/config/app_config.dart`

### What Changed

```dart
// BEFORE (Local development):
if (kIsWeb) {
  return 'http://localhost:8000'; // Local PHP server
}

// AFTER (cPanel production):
if (kIsWeb) {
  return 'https://electrozonebd.com'; // cPanel backend
}
```

---

## 🔧 Configuration Details

### API Base URL

```
Production: https://electrozonebd.com/api
Endpoints:
  ✅ https://electrozonebd.com/api/health
  ✅ https://electrozonebd.com/api/products
  ✅ https://electrozonebd.com/api/auth/login
  ✅ https://electrozonebd.com/api/cart
  ✅ https://electrozonebd.com/api/orders
```

### Build Modes

**Release Build (Production):**
```dart
kReleaseMode = true
→ Uses: https://electrozonebd.com
→ This is what users will see
```

**Debug Build (Development):**
```dart
kIsWeb = true
→ Uses: https://electrozonebd.com (now updated)
→ For local testing, you can change to: http://localhost:8000
```

---

## 🚀 Build & Deploy Flutter Web App

### Step 1: Build Flutter Web

```bash
# Navigate to project
cd c:\Wbsite fixing\electrocitybd_upto

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build for web (production)
flutter build web --release
```

This creates optimized build in: `build/web/`

### Step 2: Deploy to cPanel

**Option A: Upload web build to cPanel**

1. Go to cPanel File Manager
2. Navigate to: `/public_html/`
3. Delete old files (if any)
4. Upload contents of `build/web/` to `/public_html/`

**Directory structure should be:**
```
/public_html/
├── index.html
├── main.dart.js
├── assets/
├── canvaskit/
└── ... (all web build files)
```

**Option B: Keep separate Flutter and API**

1. API: `/public_html/api/` (already set up)
2. Flutter Web: `/public_html/` (deploy here)
3. Both share same domain: `https://electrozonebd.com`

### Step 3: Set File Permissions

```bash
# Via SSH/Terminal:
chmod -R 755 /home/asiment3/public_html/
chmod -R 644 /home/asiment3/public_html/*.html
chmod -R 644 /home/asiment3/public_html/*.js
```

### Step 4: Verify Deployment

Open browser and go to:
```
https://electrozonebd.com
```

You should see:
- ✅ ElectroZoneBD app loads
- ✅ Products display
- ✅ Navigation works
- ✅ API calls succeed

---

## 🧪 Testing Configuration

### Test 1: API Connection

In Flutter app, try:
1. Open home page → Should see products
2. Click on a product → Should load details
3. Try login → Should work with admin credentials

### Test 2: Login Test

```
Email: adminNoman@electrozonebd.com
Password: ElectroAdmin@2026
```

Should see:
- ✅ Login succeeds
- ✅ JWT token stored
- ✅ User profile loads
- ✅ Redirected to home

### Test 3: Admin Panel

After login as admin:
- ✅ Can access admin dashboard
- ✅ Can view orders
- ✅ Can manage products
- ✅ Can upload images

### Test 4: Cart & Checkout

- ✅ Add items to cart
- ✅ Cart persists (via SharedPreferences + backend sync)
- ✅ Checkout process works
- ✅ Order created in database

---

## 📋 Configuration Checklist

Before deploying:

- [ ] `app_config.dart` updated with cPanel URL
- [ ] Backend uploaded to cPanel (`/api` folder)
- [ ] Database imported to cPanel
- [ ] Composer installed on cPanel
- [ ] `.env` configured on cPanel
- [ ] API health endpoint works: `https://electrozonebd.com/api/health`
- [ ] Flutter app builds successfully: `flutter build web --release`
- [ ] Web build deployed to cPanel
- [ ] Can load app: `https://electrozonebd.com`
- [ ] Products display
- [ ] Login works
- [ ] API calls succeed

---

## 🔄 Configuration for Different Environments

### Local Development (Local PHP Server)

To test locally before deployment:

**Change `app_config.dart`:**
```dart
if (kIsWeb) {
  return 'http://localhost:8000'; // Local PHP server
}
```

**Then run locally:**
```bash
flutter run -d chrome
```

### Staging (Separate Server)

If you have staging environment:

```dart
if (kIsWeb) {
  return 'https://staging.electrozonebd.com';
}
```

### Production (cPanel)

Final production configuration (already set):

```dart
if (kIsWeb) {
  return 'https://electrozonebd.com';
}
```

---

## 🆘 Troubleshooting API Connection Issues

### Issue 1: "Failed to connect to API"

**Symptoms:**
```
Products not loading
Error: Connection refused
```

**Solutions:**
1. ✅ Verify backend is running on cPanel
2. ✅ Check `.env` file has correct credentials
3. ✅ Test API manually: `https://electrozonebd.com/api/health`
4. ✅ Check CORS headers in `.htaccess`

### Issue 2: "Login fails but registration works"

**Symptoms:**
```
Can create account but cannot login
```

**Solutions:**
1. ✅ Verify admin user imported: `adminNoman@electrozonebd.com`
2. ✅ Check password hashing in backend
3. ✅ Verify JWT token generation
4. ✅ Check token storage in SharedPreferences

### Issue 3: "Images not loading"

**Symptoms:**
```
Product images show broken image icon
```

**Solutions:**
1. ✅ Verify image paths in database
2. ✅ Check CORS headers allow image access
3. ✅ Verify upload folder permissions: `755`
4. ✅ Test image URL directly: `https://electrozonebd.com/api/uploads/image.jpg`

### Issue 4: "HTTPS Certificate Error"

**Symptoms:**
```
SSL/TLS error when connecting
```

**Solutions:**
1. ✅ Ensure SSL certificate is installed on cPanel
2. ✅ Force HTTPS in `.htaccess`:
   ```apache
   RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
   ```
3. ✅ Update Flutter config to use `https://`

---

## 📊 API Configuration Summary

```
Environment:      Production (cPanel)
Domain:           electrozonebd.com
API Base URL:     https://electrozonebd.com/api

Key Endpoints:
  Health:         https://electrozonebd.com/api/health
  Products:       https://electrozonebd.com/api/products
  Categories:     https://electrozonebd.com/api/categories
  Auth/Login:     https://electrozonebd.com/api/auth/login
  Cart:           https://electrozonebd.com/api/cart
  Orders:         https://electrozonebd.com/api/orders
  Wishlist:       https://electrozonebd.com/api/wishlist

Database:         asiment3_electrobd
DB Host:          localhost
DB User:          asiment3_zones

Admin Login:
  Email:          adminNoman@electrozonebd.com
  Password:       ElectroAdmin@2026
```

---

## 🎯 Next Steps

1. ✅ Flutter config updated (THIS STEP)
2. ⏭️  Build Flutter web: `flutter build web --release`
3. ⏭️  Deploy to cPanel: Upload `build/web/` contents
4. ⏭️  Test API endpoints from cPanel
5. ⏭️  Verify complete flow works
6. ⏭️  Setup payment gateway integration

---

## 📝 File Changes Summary

**Modified File:**
- `lib/config/app_config.dart`

**Changes Made:**
- Updated `baseUrl` for release builds to use cPanel
- Updated `baseUrl` for web debug builds to use cPanel
- Updated `baseUrl` for Android to use cPanel
- Kept iOS/macOS/Windows/Linux/Fuchsia pointing to cPanel

**Status:** ✅ Ready for production deployment

