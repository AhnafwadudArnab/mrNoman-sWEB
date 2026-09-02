# Category ID Mapping Fix - Empty Filters Issue

## Root Cause
The filter sections were empty because the Flutter pages were requesting products with **incorrect category IDs**.

## Database Schema (Correct Mapping)
```
categoryId 1 → "Home Appliances"
categoryId 2 → "Kitchen Appliances"
categoryId 3 → "Personal Care"
categoryId 4 → "Fans & Coolers"
categoryId 5 → "Lighting"
categoryId 6 → "Electronics"
... etc
```

## Issues Found & Fixed

### 1. KitchenAppliances.dart ❌ → ✅
**Was:** `categoryId: 1` (fetches "Home Appliances" instead)
**Now:** `categoryId: 2` (correctly fetches "Kitchen Appliances")

### 2. PersonalCareLifestyle.dart ❌ → ✅
**Was:** `categoryId: 2` (fetches "Kitchen Appliances" instead)
**Now:** `categoryId: 3` (correctly fetches "Personal Care")

### 3. HomeComfortUtils.dart ❌ → ✅
**Was:** `categoryId: 3` with category: 'Home Utility' (wrong category name)
**Now:** `categoryId: 1` with category: 'Home Appliances' (correct)

## Why This Caused Empty Filters

1. **Wrong Category → No Products**: When categoryId was incorrect, the API returned products from the wrong category or none at all
2. **No Products → No Brands**: The `_brandOptions` getter extracts unique brand_name values from products
3. **No Products → Empty Filter**: If `_products` list is empty, `_brandOptions` returns empty list
4. **Empty Options → Hidden Filter Section**: The filter UI shows nothing when options list is empty

## Data Flow

```
Flutter Page
   ↓
ApiService.getProducts(categoryId: X)
   ↓
API Endpoint: /products?category_id=X
   ↓
Database Query: SELECT ... FROM products WHERE category_id = X
   ↓
Returns Products with brand_name (from LEFT JOIN brands)
   ↓
_getUniqueBrands() extracts unique brand_name values
   ↓
Filter displays brand options
```

## Additional Note: Brand Data
Even with correct categoryId, filters will remain empty if products lack `brand_id` assignments in the database. To verify and fix:

```sql
-- Check if products have brands assigned
SELECT COUNT(*) FROM products WHERE category_id = 1 AND brand_id IS NULL;

-- If count > 0, assign brands (example):
UPDATE products SET brand_id = 1 WHERE category_id = 1 AND brand_id IS NULL;
```

## Verification Steps
1. Rerun the Flutter app
2. Navigate to each category page
3. Check if brand and category filters now populate with options
4. Test filter functionality - filters should now work correctly

## Files Modified
- `lib/Front-end/All Pages/Categories All/SideCatePages/KitchenAppliances.dart`
- `lib/Front-end/All Pages/Categories All/SideCatePages/PersonalCareLifestyle.dart`
- `lib/Front-end/All Pages/Categories All/SideCatePages/HomeComfortUtils.dart`

## Status
✅ **Fixed** - Category ID mappings corrected to match database schema
