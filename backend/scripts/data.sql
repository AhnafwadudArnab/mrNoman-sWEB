-- ============================================================
-- ElectroZoneBD — Sample Data (assets/prod images)
-- Run AFTER schema.sql
-- phpMyAdmin → Import → data.sql
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;

-- ─── CATEGORIES ──────────────────────────────────────────────
INSERT IGNORE INTO `categories` (`category_id`, `category_name`) VALUES
(1,  'Home Appliances'),
(2,  'Kitchen Appliances'),
(3,  'Personal Care'),
(4,  'Fans & Coolers'),
(5,  'Lighting'),
(6,  'Electronics'),
(7,  'Blenders & Mixers'),
(8,  'Irons & Steamers'),
(9,  'Rice Cookers'),
(10, 'Air Fryers');

-- ─── BRANDS ──────────────────────────────────────────────────
INSERT IGNORE INTO `brands` (`brand_id`, `brand_name`, `brand_logo`) VALUES
(1,  'Miyoko',       'assets/Brand Logo/images (1).jpg'),
(2,  'Walton',       'assets/Brand Logo/walton.png'),
(3,  'Singer',       'assets/Brand Logo/singer.png'),
(4,  'LG',           'assets/Brand Logo/LG.png'),
(5,  'Panasonic',    'assets/Brand Logo/panasonnic.png'),
(6,  'Gree',         'assets/Brand Logo/Gree.png'),
(7,  'Pink Panther', 'assets/Brand Logo/images (2).png'),
(8,  'Nima',         'assets/Brand Logo/images (3).png'),
(9,  'Sokany',       'assets/Brand Logo/images (4).png'),
(10, 'Kennede',      'assets/Brand Logo/images (5).png'),
(11, 'AV',           'assets/Brand Logo/images (6).png'),
(12, 'Noha',         'assets/Brand Logo/images (7).png');

-- ─── PRODUCTS ────────────────────────────────────────────────
INSERT IGNORE INTO `products`
  (`product_id`, `product_name`, `description`, `price`, `stock_quantity`, `image_url`, `category_id`, `brand_id`)
VALUES
(1,  'Miyoko Blender 600W',       '600W powerful blender for smoothies, juices and shakes. 1.5L jar.',                          1800, 50,  'assets/prod/blender.jpg',        2,  1),
(2,  'Air Fryer 5L Digital',      'Oil-free cooking, 5 litre capacity, 8 preset programs, digital touch panel.',                4500, 30,  'assets/prod/air_fryer.jpg',      10, 2),
(3,  'Kennede Charger Fan',       'Rechargeable fan with LED light, USB charging, 3 speed settings, 8 hour backup.',            1200, 80,  'assets/prod/chargerfan.jpg',     4,  10),
(4,  'Rice Cooker 1.8L',          'Automatic rice cooker with keep-warm function, non-stick inner pot.',                        2200, 60,  'assets/prod/rice_cooker.jpg',    9,  1),
(5,  'Hand Blender 300W',         'Immersion blender 300W with stainless steel blade, detachable shaft.',                       1500, 45,  'assets/prod/hand_blender.jpg',   7,  7),
(6,  'Electric Steam Iron',       'Steam iron 2200W with non-stick soleplate, self-clean function.',                            1100, 70,  'assets/prod/iron.jpg',           8,  3),
(7,  'Mini Cooker 1.5L',          'Compact electric cooker for small portions, auto shut-off.',                                 1600, 40,  'assets/prod/mini_cooker.jpg',    2,  1),
(8,  'Sokany Hair Dryer 1800W',   'Professional hair dryer 1800W with cool shot button, 2 speed settings.',                     1300, 55,  'assets/prod/hair_drier.jpg',     3,  9),
(9,  'Induction Stove 2000W',     '2000W induction cooktop with 8 power levels, child lock, timer.',                            3200, 25,  'assets/prod/induction_stove.jpg',2,  4),
(10, 'Nima Grinder 400W',         'Dry and wet grinder 400W with stainless steel jar, 3 jars included.',                        1900, 35,  'assets/prod/grinder.jpg',        2,  8),
(11, 'Miyoko Oven 25L',           '25 litre electric oven with rotisserie, convection, 6 cooking functions.',                   5500, 20,  'assets/prod/oven.jpg',           2,  1),
(12, 'Curry Cooker 1.5L',         'Multi-function curry cooker 1.5L, non-stick coating, glass lid.',                            1400, 50,  'assets/prod/curry_cooker.jpg',   2,  1),
(13, 'Head Massager Electric',    'Electric scalp massager with 4 massage heads, 2 speed settings.',                             900, 90,  'assets/prod/head_massager.jpg',  3,  7),
(14, 'Massage Gun Pro',           'Deep tissue massage gun, 6 speed settings, 6 attachments, 2400mAh battery.',                 3500, 15,  'assets/prod/massage_gun.jpg',    3,  2),
(15, 'Electric Stove 2-Burner',   '2-burner electric stove 2500W, cast iron heating plate, overheat protection.',               2800, 30,  'assets/prod/elec_stove.jpg',     2,  3),
(16, 'Trimmer Pro Rechargeable',  'Rechargeable hair trimmer with 4 guide combs, 60 min runtime.',                              1600, 65,  'assets/prod/trimmer.jpg',        3,  4),
(17, 'Rice Cooker 2.8L Large',    'Large capacity rice cooker 2.8L with steamer basket, keep-warm.',                            2800, 40,  'assets/prod/riceCooker2.jpg',    9,  2),
(18, 'Hand Blender Pro 500W',     'Professional hand blender 500W with whisk and chopper attachments.',                         2200, 30,  'assets/prod/hand_blender23.jpg', 7,  1),
(19, 'Mini Cooker Multi 1.8L',    'Compact multi-cooker 1.8L with non-stick coating, steam, boil, fry.',                        1800, 45,  'assets/prod/mini2cokker.jpg',    2,  1),
(20, 'Food Chopper 300W',         'Electric food chopper 300W with 1.2L bowl, stainless steel blades.',                         1200, 55,  'assets/prod/chopper.jpg',        2,  8),
(21, 'Hanger Fan 3-Speed',        'Hanging fan with 3 speed settings, remote control, timer function.',                         2500, 35,  'assets/prod/hFan3.jpg',          4,  6),
(22, 'Fan Rechargeable 2-in-1',   'Rechargeable table & wall fan, 4000mAh battery, USB-C charging.',                            1800, 60,  'assets/prod/fan2.jpg',           4,  10),
(23, 'Trimmer 2 Cordless',        'Cordless trimmer with precision blade, 45 min runtime, USB charging.',                       1400, 50,  'assets/prod/trimmeer2.jpg',      3,  9),
(24, 'Tele Sett Iron',            'Travel steam iron 1000W, compact design, dual voltage.',                                      900, 75,  'assets/prod/tele_sett.jpg',      8,  3),
(25, 'Catllee Blender',           'Personal blender 350W with travel bottle, BPA-free.',                                        1100, 65,  'assets/prod/catllee.jpg',        7,  7),
(26, 'Mini Hand Mixer',           'Hand mixer 200W with 5 speed settings, 2 beaters included.',                                  800, 80,  'assets/prod/minihand.jpg',       7,  1),
(27, 'Prestige Cooker',           'Pressure cooker 3L stainless steel, safety valve, induction compatible.',                    3200, 25,  'assets/BestSale/prestige.jpg',   2,  2),
(28, 'Electric Kettle 1.8L',      'Electric kettle 1500W, stainless steel, auto shut-off, boil-dry protection.',                1600, 55,  'assets/BestSale/electric kettle.jpg', 2, 3),
(29, 'Pink Panther Blender',      'Stylish blender 500W, 1.5L jar, 3 speed settings, pulse function.',                          2200, 40,  'assets/BestSale/pink lanther.jpg',7, 7),
(30, 'Sokany Hair Straightener',  'Ceramic hair straightener with adjustable temperature 150-230°C.',                            1800, 45,  'assets/BestSale/sokany hair.jpg', 3, 9);

-- ─── TECH PART ───────────────────────────────────────────────
INSERT IGNORE INTO `tech_part_products` (`product_id`, `display_order`) VALUES
(1,  1), (2,  2), (3,  3), (4,  4), (5,  5),
(6,  6), (7,  7), (8,  8), (9,  9), (10, 10),
(11, 11),(12, 12),(13, 13),(14, 14),(15, 15);

-- ─── TRENDING ────────────────────────────────────────────────
-- image_path overrides product image_url for trending section
INSERT IGNORE INTO `trending_products` (`product_id`, `trending_score`, `image_path`, `display_order`) VALUES
(1,  100, 'assets/trends/blender.jpg',        1),
(2,  95,  'assets/trends/air_fryer.jpg',      2),
(3,  90,  'assets/trends/chargerfan.jpg',     3),
(4,  85,  'assets/trends/rice_cooker.jpg',    4),
(5,  80,  'assets/trends/hand_blender.jpg',   5),
(7,  75,  'assets/trends/mini_cooker.jpg',    6),
(8,  70,  'assets/trends/hair_drier.jpg',     7),
(9,  65,  'assets/trends/elec_stove.jpg',     8),
(10, 60,  'assets/trends/blender.jpg',        9),
(13, 55,  'assets/trends/head_massager.jpg',  10),
(15, 50,  'assets/trends/elec_stove.jpg',     11),
(17, 45,  'assets/trends/rice_cooker.jpg',    12),
(19, 40,  'assets/trends/mini2cokker.jpg',    13),
(25, 35,  'assets/trends/catllee.jpg',        14),
(26, 30,  'assets/trends/minihand.jpg',       15);

-- ─── BEST SELLERS ────────────────────────────────────────────
INSERT IGNORE INTO `best_sellers` (`product_id`, `sales_count`) VALUES
(1,  520),
(3,  480),
(4,  450),
(10, 390);

-- ─── DEALS OF THE DAY ────────────────────────────────────────
INSERT IGNORE INTO `deals_of_the_day` (`product_id`, `deal_price`, `end_date`) VALUES
(1,  1440, DATE_ADD(NOW(), INTERVAL 365 DAY)),
(2,  3600, DATE_ADD(NOW(), INTERVAL 365 DAY)),
(5,  1200, DATE_ADD(NOW(), INTERVAL 365 DAY)),
(8,  1040, DATE_ADD(NOW(), INTERVAL 365 DAY)),
(10, 1520, DATE_ADD(NOW(), INTERVAL 365 DAY)),
(28, 1280, DATE_ADD(NOW(), INTERVAL 365 DAY)),
(29, 1760, DATE_ADD(NOW(), INTERVAL 365 DAY)),
(7,  1280, DATE_ADD(NOW(), INTERVAL 365 DAY)),
(12, 1120, DATE_ADD(NOW(), INTERVAL 365 DAY));

-- ─── FLASH SALE ──────────────────────────────────────────────
INSERT IGNORE INTO `flash_sales` (`flash_sale_id`, `title`, `start_time`, `end_time`, `active`) VALUES
(1, 'Eid Special Flash Sale', NOW(), DATE_ADD(NOW(), INTERVAL 7 DAY), 1);

INSERT IGNORE INTO `flash_sale_products` (`flash_sale_id`, `product_id`, `flash_price`, `image_path`, `display_order`) VALUES
(1, 1,  1350, 'assets/flash/av.jpg',              1),
(1, 8,   975, 'assets/flash/dryer.jpg',            2),
(1, 10,  1425,'assets/flash/nima_grinder.jpg',     3),
(1, 3,   900, 'assets/flash/kennede.jpg',          4),
(1, 5,  1125, 'assets/flash/handmixxer.jpg',       5),
(1, 6,   825, 'assets/flash/ironma.jpg',           6),
(1, 28, 1200, 'assets/flash/miyoko_kettle.jpg',    7),
(1, 29, 1650, 'assets/flash/pink.jpg',             8);

-- ─── BANNERS ─────────────────────────────────────────────────
INSERT IGNORE INTO `banners` (`banner_type`, `image_url`, `title`, `button_text`, `display_order`, `active`) VALUES
('hero',    'assets/1.png',                          'Eid Special Offers',       'Shop Now',  1, 1),
('hero',    'assets/2.png',                          'New Arrivals 2026',         'Explore',   2, 1),
('hero',    'assets/3.png',                          'Flash Sale Live Now',       'Grab Now',  3, 1),
('mid',     'assets/BestSale/2912.jpg',              'Best Deals This Week',      'View All',  1, 1),
('mid',     'assets/BestSale/curry cooker.jpg',      'Kitchen Essentials',        'Shop Now',  2, 1),
('mid',     'assets/BestSale/electric kettle.jpg',   'Home Appliances Sale',      'View All',  3, 1),
('sidebar', 'assets/BestSale/pink lanther.jpg',      'FLASH SALE',                'VIEW ALL',  0, 1);

-- ─── COLLECTIONS ─────────────────────────────────────────────
INSERT IGNORE INTO `collections` (`collection_id`, `name`, `slug`, `icon`, `display_order`) VALUES
(1, 'Fans & Coolers',  'fans',          'air',       1),
(2, 'Kitchen',         'kitchen',       'kitchen',   2),
(3, 'Personal Care',   'personal-care', 'spa',       3),
(4, 'Blenders',        'blenders',      'blender',   4),
(5, 'Irons',           'irons',         'iron',      5),
(6, 'Rice Cookers',    'rice-cookers',  'restaurant',6);

INSERT IGNORE INTO `collection_items` (`collection_id`, `item_name`, `display_order`) VALUES
(1, 'Charger Fan',    1), (1, 'Table Fan',      2), (1, 'Ceiling Fan',    3),
(2, 'Blender',        1), (2, 'Rice Cooker',    2), (2, 'Oven',           3), (2, 'Induction Stove', 4),
(3, 'Hair Dryer',     1), (3, 'Trimmer',        2), (3, 'Massager',       3),
(4, 'Hand Blender',   1), (4, 'Stand Blender',  2), (4, 'Food Chopper',   3),
(5, 'Steam Iron',     1), (5, 'Travel Iron',    2),
(6, 'Rice Cooker 1.8L',1),(6, 'Rice Cooker 2.8L',2);

-- ─── PAYMENT METHODS ─────────────────────────────────────────
INSERT IGNORE INTO `payment_methods` (`name`, `logo_url`, `is_active`) VALUES
('Cash on Delivery', '',                          1),
('bKash',            'assets/payments/baksh.png', 1),
('Nagad',            'assets/payments/nagad.png', 1),
('Visa',             'assets/payments/visa.png',  1),
('Mastercard',       'assets/payments/master.png',1);

-- ─── DEALS TIMER ─────────────────────────────────────────────
INSERT IGNORE INTO `deals_timer` (`id`, `days`, `hours`, `minutes`, `seconds`)
VALUES (1, 3, 11, 59, 59)
ON DUPLICATE KEY UPDATE `days`=3, `hours`=11, `minutes`=59, `seconds`=59;

-- ─── ADMIN USER ──────────────────────────────────────────────
-- Password: admin123  ← CHANGE after first login
INSERT IGNORE INTO `users` (`full_name`, `email`, `password`, `role`) VALUES
('Admin', 'admin@electrozonebd.com',
 '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin');

SET FOREIGN_KEY_CHECKS = 1;
