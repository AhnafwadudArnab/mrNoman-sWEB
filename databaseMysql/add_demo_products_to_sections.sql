-- ============================================
-- ADD DEMO PRODUCTS TO ALL SECTIONS
-- ============================================
-- This script adds demo products and assigns them to various sections
-- like Flash Sale, Best Selling, Trending, Deals, Tech Parts
-- Database: asiment3_electrobd (ELECTROCITYBD)
-- Date: 2026-09-03

USE asiment3_electrobd;

-- First, ensure categories and brands exist
INSERT IGNORE INTO `categories` (`category_name`, `category_image`) VALUES
('Electronics', 'assets/categories/electronics.jpg'),
('Kitchen Appliances', 'assets/categories/kitchen.jpg'),
('Power Tools', 'assets/categories/power-tools.jpg'),
('Home Appliances', 'assets/categories/home.jpg');

INSERT IGNORE INTO `brands` (`brand_name`, `brand_logo`) VALUES
('Miyoko', 'assets/brands/miyoko.jpg'),
('Nima', 'assets/brands/nima.jpg'),
('DeWalt', 'assets/brands/dewalt.jpg'),
('Philips', 'assets/brands/philips.jpg'),
('Samsung', 'assets/brands/samsung.jpg'),
('LG', 'assets/brands/lg.jpg'),
('Prestige', 'assets/brands/prestige.jpg'),
('Cosori', 'assets/brands/cosori.jpg'),
('Black+Decker', 'assets/brands/blackanddecker.jpg');

-- Get category IDs
SET @kitchen_cat = (SELECT category_id FROM categories WHERE category_name = 'Kitchen Appliances' LIMIT 1);
SET @tools_cat = (SELECT category_id FROM categories WHERE category_name = 'Power Tools' LIMIT 1);
SET @home_cat = (SELECT category_id FROM categories WHERE category_name = 'Home Appliances' LIMIT 1);

-- Get brand IDs
SET @miyoko_brand = (SELECT brand_id FROM brands WHERE brand_name = 'Miyoko' LIMIT 1);
SET @nima_brand = (SELECT brand_id FROM brands WHERE brand_name = 'Nima' LIMIT 1);
SET @dewalt_brand = (SELECT brand_id FROM brands WHERE brand_name = 'DeWalt' LIMIT 1);
SET @philips_brand = (SELECT brand_id FROM brands WHERE brand_name = 'Philips' LIMIT 1);
SET @samsung_brand = (SELECT brand_id FROM brands WHERE brand_name = 'Samsung' LIMIT 1);
SET @lg_brand = (SELECT brand_id FROM brands WHERE brand_name = 'LG' LIMIT 1);
SET @prestige_brand = (SELECT brand_id FROM brands WHERE brand_name = 'Prestige' LIMIT 1);
SET @cosori_brand = (SELECT brand_id FROM brands WHERE brand_name = 'Cosori' LIMIT 1);
SET @bd_brand = (SELECT brand_id FROM brands WHERE brand_name = 'Black+Decker' LIMIT 1);

-- ============================================
-- FLASH SALE PRODUCTS
-- ============================================
INSERT IGNORE INTO `products` (`category_id`, `brand_id`, `product_name`, `description`, `price`, `stock_quantity`, `image_url`) VALUES
(@kitchen_cat, @miyoko_brand, 'Electric Kettle 1.5L', 'High-quality electric kettle with auto shutoff feature', 2500.00, 15, 'assets/flash/miyoko_kettle.jpg'),
(@kitchen_cat, @nima_brand, 'Hand Mixer 200W', 'Powerful hand mixer with 5 speed settings', 1800.00, 20, 'assets/flash/handmixxer.jpg'),
(@kitchen_cat, @nima_brand, 'Coffee Grinder Burr', 'Professional burr grinder with multiple settings', 1500.00, 12, 'assets/flash/nima_grinder.jpg'),
(@kitchen_cat, @prestige_brand, 'Pressure Cooker 5L', 'Premium pressure cooker with safety valves', 3200.00, 10, 'assets/flash/pressure_cooker.jpg'),
(@kitchen_cat, @cosori_brand, 'Air Fryer 4.7L', 'Digital air fryer with temperature control', 5500.00, 8, 'assets/flash/air_fryer.jpg'),
(@kitchen_cat, @philips_brand, 'Blender 600W', 'Powerful blender with smoothie mode', 2200.00, 18, 'assets/flash/blender.jpg'),
(@kitchen_cat, @bd_brand, '2-Slice Toaster', 'Adjustable heat 2-slice toaster with crumb tray', 1200.00, 25, 'assets/flash/toaster.jpg'),
(@home_cat, @samsung_brand, 'Microwave 28L', '28L digital microwave oven with 900W power', 8500.00, 5, 'assets/flash/microwave.jpg'),
(@tools_cat, @dewalt_brand, 'Cordless Power Drill', '18V cordless drill with hammer mode and battery', 4500.00, 7, 'assets/flash/power_drill.jpg'),
(@home_cat, @lg_brand, 'Washing Machine 6.5kg', '6.5kg inverter technology washing machine', 25000.00, 3, 'assets/flash/washing_machine.jpg');

-- Get Flash Sale IDs
SET @flash_sale_id = (SELECT COALESCE(MAX(flash_sale_id), 0) + 1 FROM flash_sales);

-- Create flash sale event if it doesn't exist
INSERT IGNORE INTO `flash_sales` (`title`, `start_time`, `end_time`, `active`) VALUES
('Weekend Flash Sale', DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_ADD(NOW(), INTERVAL 7 DAY), 1);

SET @flash_sale_id = (SELECT flash_sale_id FROM flash_sales WHERE active = 1 ORDER BY end_time DESC LIMIT 1);

-- Add products to flash sale
INSERT IGNORE INTO `flash_sale_products` (`flash_sale_id`, `product_id`, `flash_price`, `display_order`) 
SELECT @flash_sale_id, p.product_id, p.price * 0.85, ROW_NUMBER() OVER (ORDER BY p.product_id)
FROM products p 
WHERE p.product_name IN (
  'Electric Kettle 1.5L', 'Hand Mixer 200W', 'Coffee Grinder Burr', 
  'Pressure Cooker 5L', 'Air Fryer 4.7L', 'Blender 600W', 
  '2-Slice Toaster', 'Microwave 28L', 'Cordless Power Drill', 'Washing Machine 6.5kg'
);

-- ============================================
-- BEST SELLING PRODUCTS
-- ============================================
INSERT IGNORE INTO `products` (`category_id`, `brand_id`, `product_name`, `description`, `price`, `stock_quantity`, `image_url`) VALUES
(@kitchen_cat, @miyoko_brand, 'Stainless Steel Kettle', 'Durable stainless steel kettle with auto shutoff', 2000.00, 30, 'assets/bestselling/kettle.jpg'),
(@kitchen_cat, @philips_brand, 'Food Processor 800W', 'Multi-function food processor with multiple attachments', 3500.00, 14, 'assets/bestselling/processor.jpg'),
(@home_cat, @samsung_brand, 'Smart Rice Cooker', 'Smart rice cooker with multiple cooking modes', 4200.00, 16, 'assets/bestselling/rice_cooker.jpg'),
(@kitchen_cat, @prestige_brand, 'Frying Pan Set', 'Non-stick frying pan set with heat-resistant handles', 1500.00, 22, 'assets/bestselling/pan_set.jpg'),
(@home_cat, @lg_brand, 'Vacuum Cleaner', 'Powerful vacuum cleaner with HEPA filter', 5800.00, 9, 'assets/bestselling/vacuum.jpg');

-- ============================================
-- TRENDING PRODUCTS
-- ============================================
INSERT IGNORE INTO `products` (`category_id`, `brand_id`, `product_name`, `description`, `price`, `stock_quantity`, `image_url`) VALUES
(@kitchen_cat, @cosori_brand, 'Digital Air Fryer Oven', 'Large digital air fryer with convection heating', 6500.00, 6, 'assets/trends/air_fryer_oven.jpg'),
(@home_cat, @samsung_brand, 'Smart Washing Machine', 'WiFi-enabled washing machine with app control', 35000.00, 2, 'assets/trends/smart_washer.jpg'),
(@kitchen_cat, @nima_brand, 'Portable Juicer', 'Cordless portable juicer for fresh juice', 1800.00, 19, 'assets/trends/portable_juicer.jpg'),
(@tools_cat, @dewalt_brand, 'Impact Drill 20V', 'Professional impact drill with 20V battery', 6200.00, 5, 'assets/trends/impact_drill.jpg'),
(@home_cat, @lg_brand, 'Smart AC Unit', 'Smart air conditioner with WiFi control', 45000.00, 1, 'assets/trends/smart_ac.jpg');

-- ============================================
-- DEALS OF THE DAY PRODUCTS
-- ============================================
INSERT IGNORE INTO `products` (`category_id`, `brand_id`, `product_name`, `description`, `price`, `stock_quantity`, `image_url`) VALUES
(@kitchen_cat, @bd_brand, 'Toaster Oven', 'Compact toaster oven for baking and toasting', 3800.00, 11, 'assets/deals/toaster_oven.jpg'),
(@kitchen_cat, @philips_brand, 'Electric Grill', 'Smokeless electric grill for indoor cooking', 4500.00, 8, 'assets/deals/grill.jpg'),
(@home_cat, @prestige_brand, 'Water Heater 25L', '25L water heater with temperature control', 12000.00, 4, 'assets/deals/water_heater.jpg'),
(@kitchen_cat, @miyoko_brand, 'Tea Maker Kettle', 'Electric kettle with temperature settings', 2300.00, 26, 'assets/deals/tea_maker.jpg'),
(@home_cat, @lg_brand, 'Ceiling Fan Premium', 'Premium ceiling fan with 5-speed control', 3200.00, 17, 'assets/deals/ceiling_fan.jpg');

-- ============================================
-- TECH PARTS & ACCESSORIES
-- ============================================
INSERT IGNORE INTO `products` (`category_id`, `brand_id`, `product_name`, `description`, `price`, `stock_quantity`, `image_url`) VALUES
(@tools_cat, @dewalt_brand, 'Drill Bit Set 100pcs', 'Complete drill bit set with 100 pieces', 1200.00, 40, 'assets/techparts/drill_bits.jpg'),
(@tools_cat, @dewalt_brand, 'Saw Blade Pack', 'Professional saw blades for circular saw', 800.00, 35, 'assets/techparts/saw_blades.jpg'),
(@home_cat, @samsung_brand, 'Air Filter Replacement', 'Replacement air filter for air purifiers', 500.00, 50, 'assets/techparts/air_filter.jpg'),
(@kitchen_cat, @philips_brand, 'Mixer Jar Set', 'Replacement jar set for mixers', 600.00, 28, 'assets/techparts/mixer_jar.jpg'),
(@kitchen_cat, @miyoko_brand, 'Kettle Element', 'Replacement heating element for kettles', 400.00, 45, 'assets/techparts/kettle_element.jpg');

-- ============================================
-- FEATURED PRODUCTS (all categories)
-- ============================================
-- Update best sellers to be featured
UPDATE products 
SET stock_quantity = stock_quantity + 5 
WHERE product_name IN ('Stainless Steel Kettle', 'Food Processor 800W', 'Smart Rice Cooker', 'Frying Pan Set', 'Vacuum Cleaner')
LIMIT 5;

-- ============================================
-- ADD PRODUCT SPECIFICATIONS
-- ============================================
INSERT IGNORE INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`, `display_order`) 
SELECT p.product_id, 'Warranty', '1 Year', 1 FROM products p 
WHERE p.product_name IN ('Electric Kettle 1.5L', 'Hand Mixer 200W', 'Microwave 28L', 'Washing Machine 6.5kg');

INSERT IGNORE INTO `product_specifications` (`product_id`, `spec_key`, `spec_value`, `display_order`) 
SELECT p.product_id, 'Power', 
CASE 
  WHEN p.product_name = 'Hand Mixer 200W' THEN '200W'
  WHEN p.product_name = 'Blender 600W' THEN '600W'
  WHEN p.product_name = 'Food Processor 800W' THEN '800W'
  WHEN p.product_name = 'Electric Grill' THEN '1500W'
  ELSE 'Variable'
END, 2 FROM products p 
WHERE p.product_name IN ('Hand Mixer 200W', 'Blender 600W', 'Food Processor 800W', 'Electric Grill');

-- ============================================
-- ADD TO BEST SELLERS
-- ============================================
INSERT IGNORE INTO `best_sellers` (`product_id`, `sales_count`, `display_order`)
SELECT p.product_id, 50 + FLOOR(RAND()*100), ROW_NUMBER() OVER (ORDER BY p.product_id)
FROM products p
WHERE p.product_name IN (
  'Stainless Steel Kettle', 'Food Processor 800W', 'Smart Rice Cooker', 
  'Frying Pan Set', 'Vacuum Cleaner', 'Electric Kettle 1.5L', 'Hand Mixer 200W'
);

-- ============================================
-- ADD TO TRENDING PRODUCTS
-- ============================================
INSERT IGNORE INTO `trending_products` (`product_id`, `trending_score`, `display_order`)
SELECT p.product_id, 80 + FLOOR(RAND()*20), ROW_NUMBER() OVER (ORDER BY p.product_id)
FROM products p
WHERE p.product_name IN (
  'Digital Air Fryer Oven', 'Smart Washing Machine', 'Portable Juicer',
  'Impact Drill 20V', 'Smart AC Unit', 'Air Fryer 4.7L'
);

-- ============================================
-- ADD TO DEALS OF THE DAY
-- ============================================
INSERT IGNORE INTO `deals_of_the_day` (`product_id`, `deal_price`, `end_date`)
SELECT p.product_id, ROUND(p.price * 0.80, 2), DATE_ADD(NOW(), INTERVAL 7 DAY)
FROM products p
WHERE p.product_name IN (
  'Toaster Oven', 'Electric Grill', 'Water Heater 25L', 
  'Tea Maker Kettle', 'Ceiling Fan Premium', 'Microwave 28L'
);

-- ============================================
-- ADD TO TECH PARTS
-- ============================================
INSERT IGNORE INTO `tech_part_products` (`product_id`, `display_order`)
SELECT p.product_id, ROW_NUMBER() OVER (ORDER BY p.product_id)
FROM products p
WHERE p.product_name IN (
  'Drill Bit Set 100pcs', 'Saw Blade Pack', 'Air Filter Replacement',
  'Mixer Jar Set', 'Kettle Element'
);

-- ============================================
-- UPDATE PRODUCT RATINGS
-- ============================================
INSERT IGNORE INTO `product_ratings` (`product_id`, `rating_avg`, `review_count`)
SELECT p.product_id, 4.5, 50 FROM products p
WHERE p.stock_quantity > 0
ON DUPLICATE KEY UPDATE rating_avg = 4.5, review_count = review_count + 10;

-- ============================================
-- UPDATE STOCK THRESHOLDS
-- ============================================
UPDATE products 
SET min_stock_threshold = 5, max_stock_threshold = 100
WHERE product_name IN (
  'Electric Kettle 1.5L', 'Hand Mixer 200W', 'Coffee Grinder Burr',
  'Pressure Cooker 5L', 'Air Fryer 4.7L', 'Blender 600W', '2-Slice Toaster'
);

UPDATE products
SET min_stock_threshold = 3, max_stock_threshold = 50
WHERE product_name IN (
  'Microwave 28L', 'Cordless Power Drill', 'Washing Machine 6.5kg',
  'Smart Washing Machine', 'Smart AC Unit', 'Water Heater 25L'
);

-- ============================================
-- VERIFY DATA ADDED
-- ============================================
SELECT '════════════════════════════════════════' as '===';
SELECT 'DEMO DATA SUMMARY' as Section;
SELECT '════════════════════════════════════════' as '===';
SELECT 'Total Products' as Metric, COUNT(*) as Count FROM products;
SELECT 'Flash Sale Products' as Metric, COUNT(*) as Count FROM flash_sale_products;
SELECT 'Best Sellers' as Metric, COUNT(*) as Count FROM best_sellers;
SELECT 'Trending Products' as Metric, COUNT(*) as Count FROM trending_products;
SELECT 'Deals of the Day' as Metric, COUNT(*) as Count FROM deals_of_the_day;
SELECT 'Tech Parts' as Metric, COUNT(*) as Count FROM tech_part_products;
SELECT 'Product Specifications' as Metric, COUNT(*) as Count FROM product_specifications;
SELECT '════════════════════════════════════════' as '===';
SELECT 'LATEST 10 PRODUCTS ADDED:' as Products;
SELECT product_id, product_name, price, stock_quantity, image_url FROM products ORDER BY product_id DESC LIMIT 10;

COMMIT;
