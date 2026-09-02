-- ═══════════════════════════════════════════════════════════════
-- COMPLETE FIX: Image URLs + Flash Sale Products + Deals
-- Run in phpMyAdmin → asiment1_electrobd → SQL tab
-- ═══════════════════════════════════════════════════════════════

-- ── 1. Fix broken image URLs ──────────────────────────────────

UPDATE products SET image_url = 'assets/trends/mini_cooker.jpg'       WHERE product_id = 53;
UPDATE products SET image_url = 'assets/trends/minihand.jpg'          WHERE product_id = 59;
UPDATE products SET image_url = 'assets/trends/chargerfan.jpg'        WHERE product_id = 60;
UPDATE products SET image_url = 'assets/trends/mini2cokker.jpg'       WHERE product_id = 61;
UPDATE products SET image_url = 'assets/trends/miyoko.jpg'            WHERE product_id = 1;
UPDATE products SET image_url = 'assets/trends/miyoko.jpg'            WHERE product_id = 2;
UPDATE products SET image_url = 'assets/trends/miyoko.jpg'            WHERE product_id = 3;
UPDATE products SET image_url = 'assets/trends/tele_sett.jpg'         WHERE product_id = 4;
UPDATE products SET image_url = 'assets/trends/kennede.jpg'           WHERE product_id = 5;
UPDATE products SET image_url = 'assets/trends/blender.jpg'           WHERE product_id = 6;
UPDATE products SET image_url = 'assets/trends/noha_hot_king.jpg'     WHERE product_id = 7;
UPDATE products SET image_url = 'assets/trends/av_sandwich_maker.jpg' WHERE product_id = 8;
UPDATE products SET image_url = 'assets/trends/miyoko_25l_oven.jpg'   WHERE product_id = 9;
UPDATE products SET image_url = 'assets/BestSale/2912.jpg'            WHERE product_id IN (28,29,30,31,32,33,34,35,36);

-- Fix uploaded images that are missing from server (products 120, 121)
UPDATE products SET image_url = 'assets/placeholder.png'              WHERE product_id IN (120, 121) AND image_url LIKE '/api/public/uploads/%';

-- ── 2. Flash Sale products (flash_sale_id = 2) ────────────────

DELETE FROM flash_sale_products WHERE flash_sale_id = 2;

INSERT INTO flash_sale_products (flash_sale_id, product_id, flash_price, display_order)
SELECT 2, p.product_id, ROUND(p.price * 0.85, 0), ROW_NUMBER() OVER (ORDER BY p.product_id)
FROM products p
WHERE p.product_id IN (50,51,52,53,54,55,56,57,58,59,60,61)
  AND p.stock_quantity > 0;

-- ── 3. Deals of the Day ───────────────────────────────────────

DELETE FROM deals_of_the_day WHERE product_id IN (1,2,3,4,5,6,7,8,9);

INSERT INTO deals_of_the_day (product_id, deal_price, start_date, end_date)
SELECT 
    p.product_id,
    ROUND(p.price * 0.80, 0),
    NOW(),
    DATE_ADD(NOW(), INTERVAL 30 DAY)
FROM products p
WHERE p.product_id IN (1,2,3,4,5,6,7,8,9);
