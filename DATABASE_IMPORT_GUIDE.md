# ElectroZoneBD Database Import to cPanel - Step by Step

## 📋 Overview

You need to import 3 SQL files in this exact order:

1. **electrobd_structure.sql** - Database structure (tables, procedures)
2. **electrobd_data.sql** - All product, category, and sample data
3. **admin_users.sql** - Admin login credentials

**Database Name:** `asiment3_electrobd`

---

## 🚀 Step 1: Access phpMyAdmin

### Method 1: Via cPanel
1. Login to cPanel: `https://electrozonebd.com:2083`
2. Click **phpMyAdmin** (usually in Database section)
3. You'll be logged in automatically

### Method 2: Direct URL
```
https://electrozonebd.com/cpanel (check with your host)
or
https://[your-server-ip]/phpmyadmin
```

---

## 📊 Step 2: Import Database Structure (FIRST)

### Part A: Select Database

1. In phpMyAdmin left panel, click on database: **`asiment3_electrobd`**
2. You should see "Database: asiment3_electrobd" at the top

### Part B: Import SQL File

1. Click **Import** tab (top menu bar)
2. Under "Import method" → Select **From text file**
3. Click **Choose File**
4. Navigate to: `c:\Wbsite fixing\electrocitybd_upto\databaseMysql\`
5. Select: **`electrobd_structure.sql`**
6. Click **Open**

### Part C: Import Settings

Make sure these are set:
```
Character set of the file: utf8mb4
Format: SQL
```

### Part D: Execute Import

1. Click **Go** button (bottom right)
2. Wait for import to complete (should say "Import successful")
3. You should see tables created:
   - users
   - products
   - categories
   - brands
   - cart
   - orders
   - etc.

---

## 📦 Step 3: Import Database Data (SECOND)

### Repeat same process:

1. Make sure **`asiment3_electrobd`** database is selected
2. Click **Import** tab
3. Choose File: **`electrobd_data.sql`**
4. Click **Go**
5. Wait for completion (importing products, categories, brands, etc.)

This will populate:
- ✅ Products (100+)
- ✅ Categories (10)
- ✅ Brands (40+)
- ✅ Collections
- ✅ Banners
- ✅ Deals of the Day
- ✅ Flash Sales
- ✅ Sample data

---

## 🔐 Step 4: Import Admin Users (THIRD)

### Final import:

1. Make sure **`asiment3_electrobd`** database is selected
2. Click **Import** tab
3. Choose File: **`admin_users.sql`**
4. Click **Go**
5. Wait for completion

This will add admin users:
```
Admin 1: adminNoman@electrozonebd.com / ElectroAdmin@2026
Admin 2: superadmin_roz@electrozonebd.com / ZoneAdmin@2026
Admin 3: superadmin@ez.com / ZoneAdmin@2078
```

---

## ✅ Step 5: Verify Import Success

### In phpMyAdmin:

1. Click on database: **`asiment3_electrobd`**
2. You should see all tables:

**Tables Overview:**
```
✅ users                      (users table)
✅ products                   (products with prices, images, stock)
✅ categories                 (product categories)
✅ brands                     (brand information)
✅ cart                       (shopping cart items)
✅ orders                     (order history)
✅ order_items               (items in orders)
✅ wishlist                   (user wishlists)
✅ deals_of_the_day          (daily deals)
✅ flash_sales               (flash sale promotions)
✅ banners                   (promotional banners)
✅ collections               (product collections)
✅ ratings                   (product ratings)
✅ reviews                   (product reviews)
✅ coupons                   (discount codes)
✅ payment_methods           (payment gateways)
... and more
```

### Quick Verification Queries:

In phpMyAdmin, click **SQL** tab and run:

```sql
-- Check user count
SELECT COUNT(*) as total_users FROM users;
-- Should return: 3 (including 3 admins)

-- Check product count
SELECT COUNT(*) as total_products FROM products;
-- Should return: 100+

-- Check admin login
SELECT email, role FROM users WHERE role='admin';
-- Should show 3 admin users
```

---

## 🧪 Test Database Connection

### From Flutter App (Later)

After deploying backend to cPanel, test:

```
GET https://electrozonebd.com/api/products
```

Should return JSON with product list.

---

## 🆘 Troubleshooting

### Import Error: "Access Denied"
```
Problem: Cannot import SQL file
Solution:
  1. Verify user asiment3_zones has all privileges
  2. Try importing smaller file first
  3. Contact hosting support
```

### Import Error: "Syntax Error"
```
Problem: SQL syntax error in file
Solution:
  1. File may be corrupted
  2. Try re-downloading from project
  3. Verify UTF-8 encoding
```

### Tables Not Showing
```
Problem: Database appears empty after import
Solution:
  1. Refresh browser: F5
  2. Select database again from left panel
  3. Check import messages for errors
```

### Admin Login Not Working
```
Problem: Cannot login with admin credentials
Solution:
  1. Verify admin_users.sql was imported
  2. Check users table has email and password_hash
  3. Try resetting password through API
```

---

## 📊 After Import: Database Stats

You should have:

```
Tables:        20+
Users:         3+ (admins)
Products:      100+
Categories:    10
Brands:        40+
Orders:        0 (will be created by users)
Cart items:    0 (will be created by users)
Collections:   5+
Banners:       10+
Flash sales:   3+
Coupons:       5+
```

---

## ✨ Final Checklist

After importing all 3 SQL files:

- [ ] Logged into phpMyAdmin with cPanel credentials
- [ ] Database selected: asiment3_electrobd
- [ ] Imported electrobd_structure.sql successfully
- [ ] Imported electrobd_data.sql successfully
- [ ] Imported admin_users.sql successfully
- [ ] All tables visible in phpMyAdmin
- [ ] Can see products, categories, brands
- [ ] Admin users visible in users table
- [ ] No error messages in import logs

---

## 🎯 Next Steps

After database import:

1. ✅ Import database (THIS STEP)
2. ⏭️ Verify backend upload to cPanel
3. ⏭️ Run composer install on cPanel
4. ⏭️ Test API endpoints
5. ⏭️ Update Flutter app config
6. ⏭️ Deploy Flutter web

