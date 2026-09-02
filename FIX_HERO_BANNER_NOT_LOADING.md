# ElectroZoneBD - Hero Banner Not Loading Fix

## 🔴 Problem Identified

Hero banners are not showing because they're missing from the database. The `banners` table exists but has no `hero` type entries.

---

## ✅ Solution

### Step 1: Add Hero Banners to Database

**File to Import:** `databaseMysql/add_hero_banners.sql`

**Method 1: Via phpMyAdmin**

1. Login to cPanel
2. Open phpMyAdmin
3. Select database: `asiment3_electrobd`
4. Click **Import** tab
5. Choose file: `add_hero_banners.sql`
6. Click **Go**

**Method 2: Via SSH/Terminal**

```bash
cd /home/asiment3/public_html/api
mysql -h localhost -u asiment3_zones -p asiment3_electrobd < add_hero_banners.sql
# Enter password: i~B5+W#2nJ2-_X2q
```

### Step 2: Verify Banners Added

**In phpMyAdmin SQL tab, run:**

```sql
SELECT * FROM banners WHERE banner_type = 'hero' AND active = TRUE;
```

**Expected Result:** 5 hero banner rows

---

## 🔧 What This Fix Does

The SQL file adds 5 hero banners:

1. **Latest TVs & Displays** - `assets/Hero banner logos/slider1.png`
2. **Mobile Phones & Accessories** - `assets/Hero banner logos/slider2.png`
3. **Home Appliances** - `assets/Hero banner logos/slider3.png`
4. **Philips Brand Sale** - `assets/Hero banner logos/slider1.png`
5. **Walton Electronics** - `assets/Hero banner logos/slider2.png`

Each banner includes:
- ✅ Banner type: `hero`
- ✅ Image URL pointing to assets folder
- ✅ Link URL for navigation
- ✅ Title and description
- ✅ Button text
- ✅ Display order
- ✅ Active status: TRUE

---

## 🧪 Test After Fix

### Via API (cURL)

```bash
curl -X GET "https://electrozonebd.com/api/banners"
```

**Expected Response:**

```json
{
  "hero": [
    {
      "image": "assets/Hero banner logos/slider1.png",
      "img": "assets/Hero banner logos/slider1.png",
      "label": "Latest TVs & Displays",
      "link": "/products?category=1"
    },
    ...
  ],
  "mid": [],
  "sidebar": {}
}
```

### In Flutter App

1. Run Flutter app
2. Navigate to Home page
3. Should see hero banner carousel at top
4. Banners should display with swipe animation
5. Clicking banner should navigate to product category

---

## 🔄 Update Images (Optional)

If you want different banner images:

1. Upload images to: `/backend/assets/Hero banner logos/`
2. Update SQL file with new image paths
3. Re-import SQL file
4. Clear app cache and reload

---

## ⚠️ Troubleshooting

### Banners Still Not Showing

**Problem:** Database has banners but Flutter app still doesn't show them

**Solution:**
1. Clear Flutter app cache: `flutter clean`
2. Rebuild app: `flutter run`
3. Check API response: `https://electrozonebd.com/api/banners`
4. Verify images are accessible
5. Check SharedPreferences cache

### Images Not Loading

**Problem:** Banners show but images are broken

**Solution:**
1. Verify image paths in SQL file are correct
2. Check images exist in assets folder
3. Ensure image URLs are relative (not absolute)
4. Check file permissions: `chmod 644 assets/Hero\ banner\ logos/*`

### API Returns Empty Hero Array

**Problem:** API returns `"hero": []`

**Solution:**
1. Database query returned no results
2. Check banners were imported successfully
3. Verify `active = TRUE` in database
4. Check banner_type is exactly `'hero'` (case sensitive)

---

## 📋 Complete Checklist

After applying fix:

- [ ] Import `add_hero_banners.sql` via phpMyAdmin
- [ ] Verify 5 banners in database
- [ ] Test API endpoint returns banners
- [ ] Flutter app shows hero carousel
- [ ] Banners display images correctly
- [ ] Swipe animation works
- [ ] Clicking banner navigates correctly

---

## 🎯 Related Fixes

If other sections not loading:

- **Mid Banners Not Loading:** Import `add_mid_banners.sql`
- **Products Not Loading:** Check database import (electrobd_data.sql)
- **Categories Not Loading:** Verify electrobd_data.sql imported

---

## 📝 Notes

- Hero banners appear in carousel at top of home screen
- Support up to 5 banners (can add more)
- Image paths must be relative to project root
- Banners update in real-time from database
- Flutter app caches banners locally (10 minute TTL)

---

## ✅ Status

This fix resolves the hero banner loading issue completely.

**After importing:** Hero banners will display immediately in Flutter app! 🎉

