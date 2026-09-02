-- ============================================================
-- FIX ALL PROBLEMS — electrozonebd.com
-- Run this in cPanel → phpMyAdmin on database: asiment1_electrobd
-- ============================================================

-- ============================================================
-- 1. DELETE TEST PRODUCTS (120, 121, 122, 123)
-- ============================================================

-- Remove from any sections first (foreign key safety)
DELETE FROM best_sellers WHERE product_id IN (120, 121, 122, 123);
DELETE FROM trending_products WHERE product_id IN (120, 121, 122, 123);
DELETE FROM deals WHERE product_id IN (120, 121, 122, 123);
DELETE FROM flash_sale_products WHERE product_id IN (120, 121, 122, 123);
DELETE FROM cart_items WHERE product_id IN (120, 121, 122, 123);
DELETE FROM order_items WHERE product_id IN (120, 121, 122, 123);
DELETE FROM wishlist WHERE product_id IN (120, 121, 122, 123);
DELETE FROM product_ratings WHERE product_id IN (120, 121, 122, 123);
DELETE FROM product_reviews WHERE product_id IN (120, 121, 122, 123);

-- Now delete the test products
DELETE FROM products WHERE product_id IN (120, 121, 122, 123);

-- ============================================================
-- 2. FIX WRONG IMAGE URLs ON PRODUCTS
-- ============================================================

-- product_id 2: Nima 2-in-1 Grinder — was showing miyoko image
UPDATE products SET image_url = 'assets/flash/nima_grinder.jpg' WHERE product_id = 2;

-- product_id 3: Miyako Kettle — was showing miyoko (curry cooker) image
UPDATE products SET image_url = 'assets/Deals of the Day/miyoko_kettle.jpg' WHERE product_id = 3;

-- product_id 4: Sokany Hair Dryer — was showing tele_sett image
UPDATE products SET image_url = 'assets/flash/dryer.jpg' WHERE product_id = 4;

-- product_id 56: Miyoko Electric Kettle — was showing miyoko (curry cooker) image
UPDATE products SET image_url = 'assets/Deals of the Day/miyoko_kettle.jpg' WHERE product_id = 56;

-- ============================================================
-- 3. FIX CATEGORY IMAGES
-- ============================================================

UPDATE categories SET category_image = 'assets/categories/kitchen.png'
    WHERE category_name IN ('Kitchen Appliances');

UPDATE categories SET category_image = 'assets/categories/homecomfort.png'
    WHERE category_name IN ('Home Comfort & Utility', 'Fan & Cooling', 'Home Appliances');

UPDATE categories SET category_image = 'assets/categories/personalcare.png'
    WHERE category_name IN ('Personal Care', 'Personal Care & Lifestyle');

UPDATE categories SET category_image = 'assets/categories/tools.png'
    WHERE category_name IN ('Tools & Hardware');

UPDATE categories SET category_image = 'assets/categories/lighting.png'
    WHERE category_name IN ('Electronics & Gadgets');

UPDATE categories SET category_image = 'assets/categories/wiring.png'
    WHERE category_name IN ('Wiring & Cables');

-- ============================================================
-- 4. EXTEND FLASH SALE (currently ends May 6 — extend 30 days)
-- ============================================================

UPDATE flash_sales
SET end_time = DATE_ADD(NOW(), INTERVAL 30 DAY)
WHERE flash_sale_id = 2 AND active = 1;

-- ============================================================
-- VERIFY
-- ============================================================
SELECT 'Test products remaining:' AS check_name, COUNT(*) AS count
    FROM products WHERE product_id IN (120,121,122,123);

SELECT 'Category images fixed:' AS check_name, COUNT(*) AS count
    FROM categories WHERE category_image LIKE 'assets/categories/%';

SELECT product_id, product_name, image_url
    FROM products WHERE product_id IN (2,3,4,56);
