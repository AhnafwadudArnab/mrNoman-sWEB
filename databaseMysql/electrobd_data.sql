-- ============================================================
-- ElectrocityBD - DATABASE DATA (All Data)
-- File 2 of 2: Import this SECOND in phpMyAdmin
-- ============================================================
-- HOW TO USE:
--   1. Make sure you already imported File 1 (electrobd_structure.sql)
--   2. Open phpMyAdmin on cPanel
--   3. Select the asiment1_electrobd database
--   4. Click Import -> choose this file -> Go
-- ============================================================
-- NOTE: Admin login credentials:
--   Email: ahnaf@electrocitybd.com
--   Password: (your existing password - bcrypt hashed in DB)
-- ============================================================

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET FOREIGN_KEY_CHECKS = 0;
START TRANSACTION;
SET time_zone = "+00:00";
SET NAMES utf8mb4;
USE `asiment1_electrobd`;

-- brands
INSERT IGNORE INTO `brands` (`brand_id`, `brand_name`, `brand_logo`) VALUES
(1, 'Philips', 'assets/Brand Logo/images (2).png'),
(2, 'Walton', 'assets/Brand Logo/walton.png'),
(3, 'Samsung', 'assets/Brand Logo/images.png'),
(4, 'LG', 'assets/Brand Logo/LG.png'),
(5, 'Sony', 'assets/Brand Logo/images (1).png'),
(6, 'Gree', 'assets/Brand Logo/Gree.png'),
(7, 'Jamuna', 'assets/Brand Logo/jamuna.jpg'),
(8, 'Panasonic', 'assets/Brand Logo/panasonnic.png'),
(9, 'Singer', 'assets/Brand Logo/singer.png'),
(10, 'Vision', 'assets/Brand Logo/vision.jpg'),
(24, 'Sharp', 'assets/Brand Logo/images (3).png'),
(25, 'Toshiba', 'assets/Brand Logo/images (4).png'),
(26, 'Hitachi', 'assets/Brand Logo/images (5).png'),
(27, 'Haier', 'assets/Brand Logo/images (6).png'),
(28, 'Whirlpool', 'assets/Brand Logo/images (7).png'),
(29, 'Electrolux', 'assets/Brand Logo/images.jpg'),
(30, 'Bosch', 'assets/Brand Logo/images (1).jpg'),
(31, 'Siemens', 'assets/Brand Logo/images (2).jpg'),
(32, 'Midea', 'assets/Brand Logo/images (3).jpg'),
(33, 'TCL', 'assets/Brand Logo/images (4).jpg'),
(34, 'Hisense', 'assets/Brand Logo/images (5).jpg'),
(35, 'Konka', 'assets/Brand Logo/images (6).jpg'),
(36, 'Changhong', 'assets/Brand Logo/images (7).jpg'),
(37, 'Skyworth', 'assets/Brand Logo/images (8).jpg'),
(38, 'Videocon', 'assets/Brand Logo/images (9).jpg'),
(39, 'Onida', 'assets/Brand Logo/images (10).jpg'),
(40, 'BPL', 'assets/Brand Logo/images (11).jpg'),
(95, 'Unknown', NULL);

--
-- Triggers `brands`
--
-- (Trigger definition intentionally omitted in data-only import file)

-- --------------------------------------------------------

-- categories
INSERT IGNORE INTO `categories` (`category_id`, `category_name`, `category_image`) VALUES
(1, 'Kitchen Appliances', '/assets/categories/kitchen.png'),
(2, 'Personal Care & Lifestyle', '/assets/categories/personalcare.png'),
(3, 'Home Comfort & Utility', '/assets/categories/homecomfort.png'),
(4, 'Electronics & Gadgets', '/assets/categories/lighting.png'),
(5, 'Wiring & Cables', '/assets/categories/wiring.png'),
(6, 'Tools & Hardware', '/assets/categories/tools.png'),
(13, 'Personal Care', '/assets/categories/personalcare.png'),
(14, 'Home Appliances', '/assets/categories/homecomfort.png'),
(15, 'Fan & Cooling', '/assets/categories/homecomfort.png');

--
-- Triggers `categories`
--
-- (Trigger definition intentionally omitted in data-only import file)

-- --------------------------------------------------------

--
-- Table structure for table `collections`
--


--
-- Dumping data for table `collections`
--


-- products
INSERT IGNORE INTO `products` (`product_id`, `category_id`, `brand_id`, `product_name`, `description`, `price`, `stock_quantity`, `image_url`, `specs_json`, `created_at`, `min_stock_threshold`, `max_stock_threshold`) VALUES
(1, 1, 2, 'Miyako Curry Cooker 5.5L', 'Family Reliable: 5.5L large capacity, non-stick coating, and automatic cooking mode. Best for cooking large portions of curry or rice for big families in one go.', 2500.00, 14, 'assets/Deals of the Day/miyoko.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
(2, 6, 2, 'Nima 2-in-1 Grinder 400W', 'Budget Friendly: 450W powerful motor, stainless steel blades, suitable for dry and wet grinding. The most popular choice for grinding spices or coffee quickly at a low price.', 1450.00, 25, 'assets/Deals of the Day/nima_grinder.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
(3, 1, 2, 'Miyako Kettle 180 PS 1.8L', 'Quick Solution: 1.8L capacity, auto-shutoff feature (turns off automatically when water boils). The best choice for getting hot water for tea or coffee in just a few minutes.', 1450.00, 28, 'assets/Deals of the Day/miyoko_kettle.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
(4, 2, 3, 'Sokany Hair Dryer HS-3820', 'Perfect Look: 2000-2200W power, hot and cold air options, includes concentrator nozzle. Affordable and durable for achieving a salon-style hair drying experience at home.', 1180.00, 20, 'assets/Deals of the Day/sokany_dyer.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
(5, 3, 2, 'Kennede Charger Fan 2912', 'Load-shedding Master: 12-inch size, rechargeable battery, 5–6 hours backup, and built-in LED light. Your best friend during summer days due to its long-lasting battery backup.', 2200.00, 16, 'assets/Deals of the Day/kennede_charger_fan.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
(6, 1, 2, 'Miyako Pink Panther Blender 750W', 'All-in-One: 750W copper motor, 3 stainless steel jars, overload protection. Perfect for everything from making juice to grinding spice pastes.', 4050.00, 12, 'assets/Deals of the Day/pinkPanther_blender.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
(7, 1, 2, 'NOHA Hotel King Blender 1050W', 'For Heavy Users: 1050W high-power motor, heavy-duty blades, anti-jam design. Extremely durable for those who require heavy blending every single day.', 4500.00, 10, 'assets/Deals of the Day/noha_hot_king.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
(8, 1, 2, 'AV Sandwich Maker 296', 'Instant Breakfast: Non-stick grill plates, fast heating technology, and easy to clean. An essential for modern kitchens to quickly prepare breakfast or tiffins.', 1400.00, 22, 'assets/Deals of the Day/av_sandwich_maker.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
(9, 1, 2, 'Miyako 25L Electric Oven', 'For Baking Lovers: 25L size, timer and temperature control, baking and grilling facilities. The best entry-level oven for baking cakes or making roasted chicken.', 5500.00, 8, 'assets/Deals of the Day/miyoko_25l_oven.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
(10, 4, 3, 'Samsung CCTV Camera', 'High-quality security camera with night vision, motion detection, and remote viewing. Perfect for home and office security monitoring.', 8500.00, 12, 'assets/prod/2.png', NULL, '2026-03-01 07:11:36', 5, 1000),
(11, 1, 2, 'Walton Blender 3-in-1 Machine', 'Versatile 3-in-1 blender with multiple jars for blending, grinding, and mixing. Powerful motor for all your kitchen needs.', 5500.00, 18, 'assets/prod/blender.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
(12, 1, 1, 'Panasonic Cooker 5L', 'Large 5L capacity rice cooker with keep-warm function. Non-stick inner pot and automatic cooking for perfect rice every time.', 8500.00, 10, 'assets/prod/rice_cooker.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
(13, 3, 2, 'Jamuna Fan', 'High-speed ceiling fan with energy-efficient motor. Provides powerful airflow while consuming less electricity.', 4200.00, 25, 'assets/prod/fan2.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
(14, 3, 2, 'Walton AC 1.5 Ton', 'Energy-efficient 1.5 ton air conditioner with fast cooling, auto-restart, and sleep mode. Perfect for medium-sized rooms.', 32200.00, 8, 'assets/prod/2.png', NULL, '2026-03-01 07:11:36', 5, 1000),
(15, 3, 2, 'Walton AC 2 Ton', 'Powerful 2 ton air conditioner with turbo cooling, dehumidifier, and smart temperature control. Ideal for large rooms.', 46500.00, 5, 'assets/prod/3.png', NULL, '2026-03-01 07:11:36', 5, 1000),
(16, 1, 1, 'Panasonic Mixer Grinder', 'Multi-purpose mixer grinder with 3 jars and stainless steel blades. Perfect for grinding spices, making chutneys, and mixing batters.', 2800.00, 20, 'assets/prod/grinder.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
(17, 3, 3, 'Hikvision Air Purifier', 'Advanced air purifier with HEPA filter, removes 99.9% pollutants, dust, and allergens. Quiet operation with multiple fan speeds.', 18500.00, 7, 'assets/prod/4.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
(18, 2, 5, 'P9 Max Bluetooth Headphones', 'Wireless Bluetooth headphones with noise cancellation, deep bass, and 20-hour battery life. Comfortable over-ear design.', 1850.00, 30, 'assets/prod/5.png', NULL, '2026-03-01 07:11:36', 5, 1000),
(19, 3, 4, 'LG Table Fan 16\"', 'LG Table Fan with 3 speed settings and oscillation. Energy-efficient and quiet operation.', 2200.00, 20, 'assets/prod/hFan3.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
(20, 4, 3, 'Acer SB220Q bi 21.5 Inches Full HD Monitor', 'Full HD 1920x1080 resolution, IPS panel, ultra-thin design with zero-frame. Perfect for office work and entertainment.', 9400.00, 15, 'assets/prod/6.png', NULL, '2026-03-01 07:11:36', 5, 1000),
(21, 4, 1, 'Intel Core i7 12th Gen Processor', '12th generation Intel Core i7 processor with 12 cores, 20 threads. High performance for gaming and productivity.', 45999.00, 10, 'assets/prod/7.png', NULL, '2026-03-01 07:11:36', 5, 1000),
(22, 4, 3, 'ASUS ROG Strix G15 Gaming Laptop', 'AMD Ryzen 9, RTX 3070, 16GB RAM, 1TB SSD. Ultimate gaming performance with RGB keyboard.', 120000.00, 5, 'assets/prod/8.png', NULL, '2026-03-01 07:11:36', 5, 1000),
(23, 4, 4, 'Logitech MX Master 3 Wireless Mouse', 'Advanced wireless mouse with MagSpeed scroll wheel, ergonomic design, and multi-device connectivity.', 8500.00, 20, 'assets/prod/9.png', NULL, '2026-03-01 07:11:36', 5, 1000),
(24, 4, 3, 'Samsung T7 Portable SSD 1TB', 'Ultra-fast portable SSD with USB 3.2 Gen 2, read speeds up to 1050 MB/s. Compact and durable design.', 12000.00, 18, 'assets/prod/01.png', NULL, '2026-03-01 07:11:36', 5, 1000),
(25, 4, 5, 'Corsair K95 RGB Platinum Mechanical Gaming Keyboard', 'Cherry MX Speed switches, per-key RGB backlighting, dedicated media controls. Premium gaming keyboard.', 18000.00, 12, 'assets/prod/09.png', NULL, '2026-03-01 07:11:36', 5, 1000),
(26, 4, 5, 'Razer DeathAdder V2 Pro Wireless Gaming Mouse', '20K DPI optical sensor, 70-hour battery life, ergonomic design. Professional gaming mouse.', 10500.00, 15, 'assets/prod/99.png', NULL, '2026-03-01 07:11:36', 5, 1000),
(27, 4, 3, 'Dell UltraSharp U2723QE 27 Inch 4K Monitor', '4K UHD resolution, IPS Black technology, USB-C connectivity. Professional-grade color accuracy.', 35000.00, 8, 'assets/prod/1.png', NULL, '2026-03-01 07:11:36', 5, 1000),
(28, 3, 2, 'Kennede Charger Fan 2412', '12-inch rechargeable fan with LED light, 4-6 hours backup. Compact and portable design for load-shedding.', 1800.00, 20, 'assets/Collections/Kennede & Defender Charger Fan/2412.png', NULL, '2026-03-01 07:11:36', 5, 1000),
(29, 3, 2, 'Kennede Charger Fan 2916', '16-inch powerful rechargeable fan with 6-8 hours backup. High-speed motor with adjustable height.', 2400.00, 18, 'assets/Collections/Kennede & Defender Charger Fan/2916.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
(30, 3, 2, 'Kennede Charger Fan 2926', '16-inch premium rechargeable fan with remote control, 8-10 hours backup. Multiple speed settings.', 2800.00, 15, 'assets/Collections/Kennede & Defender Charger Fan/2926.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
(31, 3, 2, 'Kennede Charger Fan 2936S', '16-inch super powerful fan with solar charging option, 10-12 hours backup. Eco-friendly solution.', 3200.00, 12, 'assets/Collections/Kennede & Defender Charger Fan/2936s.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
(32, 3, 2, 'Kennede Charger Fan 2956P', '16-inch premium plus model with USB charging port, 12-14 hours backup. Can charge mobile phones.', 3500.00, 10, 'assets/Collections/Kennede & Defender Charger Fan/2956p.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
(33, 3, 2, 'HK Defender Charger Fan 2914', '14-inch defender series with strong build, 6-8 hours backup. Durable for heavy use.', 2100.00, 16, 'assets/Collections/Kennede & Defender Charger Fan/HK_Defender_2914.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
(34, 3, 2, 'HK Defender Charger Fan 2916', '16-inch defender series with metal blades, 8-10 hours backup. Industrial-grade quality.', 2600.00, 14, 'assets/Collections/Kennede & Defender Charger Fan/HK_Defender_2916.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
(35, 3, 2, 'HK Defender Charger Fan 2916 Plus', '16-inch defender plus with enhanced motor, 10-12 hours backup. Maximum airflow performance.', 2900.00, 12, 'assets/Collections/Kennede & Defender Charger Fan/HK_Defender_2916_1.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
(36, 3, 2, 'Kennede Charger Fan 2912 (Deal Model)', '12-inch rechargeable fan, same as product 5 but different image. Popular deal model.', 2200.00, 18, 'assets/Collections/Kennede & Defender Charger Fan/2912.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
(37, 1, 2, 'AV Sandwich Maker 560', 'Non-stick grill plates, fast heating, easy to clean. Perfect for students and small families for quick breakfast.', 1850.00, 25, 'assets/flash/av.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
(38, 2, 2, 'Scarlet Hand Mixer HE-133', 'Powerful hand mixer for cake making and whisking eggs. Lightweight and easy to use. Budget-friendly kitchen essential.', 750.00, 30, 'assets/flash/handmixxer.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
(39, 3, 2, 'Kennede Charger Fan 2912 Flash', '12-inch rechargeable fan with LED light, 5-6 hours backup. Summer season hot item with special flash price.', 3500.00, 20, 'assets/flash/kennede.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
(40, 1, 1, 'Prestige Rice Cooker 1.8L', 'Known for durability and perfectly cooked rice every time. Non-stick inner pot, keep-warm function. The perfect rice cooker for daily use.', 2800.00, 22, 'assets/bestSale/prestige.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
(45, 1, 3, 'Smart LED Strip', 'RGB Smart LED Strip 5m', 1200.00, 30, 'assets/prod/5.jpg', NULL, '2026-03-01 07:11:55', 5, 1000),
(48, 1, 9, 'AV Sandwich Maker', 'High quality AV Sandwich Maker from Singer. Perfect for your home needs.', 1850.00, 60, 'assets/trends/av_sandwich_maker.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(49, 13, 8, 'Hair Dryer Professional', 'High quality Hair Dryer Professional from Philips. Perfect for your home needs.', 3200.00, 45, 'assets/trends/hair_drier.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(50, 13, 8, 'Hair Dryer Compact', 'High quality Hair Dryer Compact from Panasonic. Perfect for your home needs.', 1950.00, 40, 'assets/flash/dyrer.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(51, 1, 2, 'Hand Mixer', 'High quality Hand Mixer from Walton. Perfect for your home needs.', 1650.00, 37, 'assets/flash/handmixxer.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(52, 14, 10, 'Iron Master', 'High quality Iron Master from Vision. Perfect for your home needs.', 2100.00, 60, 'assets/flash/ironma.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(53, 1, 7, 'JY Mini Rice Cooker 1880', 'High quality JY Mini Rice Cooker 1880 from Jamuna. Perfect for your home needs.', 3200.00, 30, 'assets/flash/jy mini 1880.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(54, 15, 4, 'Kennede Charger Fan', 'High quality Kennede Charger Fan from LG. Perfect for your home needs.', 2800.00, 55, 'assets/flash/kennede.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(55, 1, 3, 'LR2018 Blender', 'High quality LR2018 Blender from Samsung. Perfect for your home needs.', 4500.00, 25, 'assets/flash/lr2018.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(56, 1, 6, 'Miyoko Electric Kettle', 'High quality Miyoko Electric Kettle from Gree. Perfect for your home needs.', 1650.00, 75, 'assets/trends/miyoko.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(57, 1, 2, 'Nima Grinder 400W', 'High quality Nima Grinder 400W from Walton. Perfect for your home needs.', 3800.00, 40, 'assets/flash/nima_grinder.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(58, 14, 9, 'Pink Leather Iron', 'High quality Pink Leather Iron from Singer. Perfect for your home needs.', 2300.00, 60, 'assets/trends/pink.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(59, 1, 1, 'Scarlet Hand Mixer', 'High quality Scarlet Hand Mixer from Philips. Perfect for your home needs.', 1900.00, 45, 'assets/flash/scarlet handmixer.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(60, 15, 10, 'WD Mini Fan', 'High quality WD Mini Fan from Vision. Perfect for your home needs.', 1200.00, 79, 'assets/flash/wd minifan.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(61, 1, 7, 'YG Mini Cooker 717', 'High quality YG Mini Cooker 717 from Jamuna. Perfect for your home needs.', 2900.00, 35, 'assets/flash/yg mini 717.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(62, 1, 1, 'Air Fryer Digital', 'Trending Air Fryer Digital from Philips. High demand product with excellent features.', 7200.00, 40, 'assets/trends/air_fryer.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(63, 1, 9, 'AV Multi Cooker', 'Trending AV Multi Cooker from Singer. High demand product with excellent features.', 3200.00, 35, 'assets/trends/av.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(64, 1, 2, 'Blender Pro 2000', 'Trending Blender Pro 2000 from Walton. High demand product with excellent features.', 4500.00, 50, 'assets/trends/blender.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(65, 1, 6, 'Electric Kettle', 'Trending Electric Kettle from Gree. High demand product with excellent features.', 1750.00, 80, 'assets/trends/catllee.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(66, 15, 4, 'Charger Fan Portable', 'Trending Charger Fan Portable from LG. High demand product with excellent features.', 2200.00, 70, 'assets/trends/chargerfan.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(67, 1, 10, 'Electric Stove Single', 'Trending Electric Stove Single from Vision. High demand product with excellent features.', 1250.00, 55, 'assets/trends/elec_stove.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(68, 1, 3, 'Hand Blender 3-in-1', 'Trending Hand Blender 3-in-1 from Samsung. High demand product with excellent features.', 2800.00, 50, 'assets/trends/hand_blender.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(69, 13, 5, 'Head Massager Electric', 'Trending Head Massager Electric from Sony. High demand product with excellent features.', 3800.00, 30, 'assets/trends/head_massager.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(70, 15, 4, 'Kennede Rechargeable Fan', 'Trending Kennede Rechargeable Fan from LG. High demand product with excellent features.', 2900.00, 65, 'assets/trends/kennede.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(71, 1, 7, 'Mini Cooker Compact', 'Trending Mini Cooker Compact from Jamuna. High demand product with excellent features.', 2500.00, 40, 'assets/trends/mini_cooker.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(72, 1, 7, 'Mini Cooker Deluxe', 'Trending Mini Cooker Deluxe from Jamuna. High demand product with excellent features.', 3100.00, 35, 'assets/trends/mini2cokker.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(73, 1, 2, 'Mini Hand Blender', 'Trending Mini Hand Blender from Walton. High demand product with excellent features.', 1900.00, 55, 'assets/trends/minihand.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(74, 1, 6, 'Miyoko Oven 25L', 'Trending Miyoko Oven 25L from Gree. High demand product with excellent features.', 8500.00, 25, 'assets/trends/miyoko_25l_oven.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(75, 1, 10, 'Noha Hot King Cooker', 'Trending Noha Hot King Cooker from Vision. High demand product with excellent features.', 4200.00, 30, 'assets/trends/noha_hot_king.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(76, 1, 2, 'Rice Cooker 1.8L', 'Trending Rice Cooker 1.8L from Walton. High demand product with excellent features.', 3500.00, 50, 'assets/trends/rice_cooker.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(77, 13, 1, 'Hair Styling Tool', 'Trending Hair Styling Tool from Philips. High demand product with excellent features.', 2700.00, 40, 'assets/trends/tele_sett.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(108, 1, 32, 'miyoko', 'hfgkjdfkgjnfgjdg', 10000.00, 7, '/uploads/img_69c9643617b7d8.11792352.jpg', NULL, '2026-03-29 17:41:10', 5, 1000);

--
-- Triggers `products`
--
-- (Trigger definition intentionally omitted in data-only import file)

-- --------------------------------------------------------

--
-- Table structure for table `product_ratings`
--


--
-- Dumping data for table `product_ratings`
--


-- product_specifications
INSERT IGNORE INTO `product_specifications` (`spec_id`, `product_id`, `spec_key`, `spec_value`, `display_order`) VALUES
(1, 1, 'Capacity', '5.5 Liters', 1),
(2, 1, 'Coating', 'Non-stick', 2),
(3, 1, 'Cooking Mode', 'Automatic', 3),
(4, 1, 'USP', 'Family Reliable - Best for large families', 4),
(5, 2, 'Power', '450W', 1),
(6, 2, 'Motor Type', 'Powerful Motor', 2),
(7, 2, 'Blade Material', 'Stainless Steel', 3),
(8, 2, 'Grinding Type', 'Dry and Wet', 4),
(9, 2, 'USP', 'Budget Friendly - Quick grinding at low price', 5),
(10, 3, 'Capacity', '1.8 Liters', 1),
(11, 3, 'Model', '180 PS', 2),
(12, 3, 'Safety Feature', 'Auto-shutoff when water boils', 3),
(13, 3, 'USP', 'Quick Solution - Hot water in minutes', 4),
(14, 4, 'Model', 'HS-3820', 1),
(15, 4, 'Power', '2000-2200W', 2),
(16, 4, 'Air Options', 'Hot and Cold', 3),
(17, 4, 'Accessories', 'Concentrator Nozzle', 4),
(18, 4, 'USP', 'Perfect Look - Salon-style at home', 5),
(19, 5, 'Model', '2912', 1),
(20, 5, 'Size', '12 inch', 2),
(21, 5, 'Battery Type', 'Rechargeable', 3),
(22, 5, 'Backup Time', '5-6 hours', 4),
(23, 5, 'Extra Feature', 'Built-in LED light', 5),
(24, 5, 'USP', 'Load-shedding Master - Long battery backup', 6),
(25, 6, 'Power', '750W', 1),
(26, 6, 'Motor Type', 'Copper Motor', 2),
(27, 6, 'Jars', '3 Stainless Steel Jars', 3),
(28, 6, 'Safety', 'Overload Protection', 4),
(29, 6, 'USP', 'All-in-One - Juice to spice grinding', 5),
(30, 7, 'Power', '1050W', 1),
(31, 7, 'Motor Type', 'High-power Motor', 2),
(32, 7, 'Blade Type', 'Heavy-duty Blades', 3),
(33, 7, 'Design', 'Anti-jam Design', 4),
(34, 7, 'USP', 'For Heavy Users - Extremely durable', 5),
(35, 8, 'Model', '296', 1),
(36, 8, 'Plates', 'Non-stick Grill Plates', 2),
(37, 8, 'Heating', 'Fast Heating Technology', 3),
(38, 8, 'Maintenance', 'Easy to Clean', 4),
(39, 8, 'USP', 'Instant Breakfast - Quick tiffin preparation', 5),
(40, 9, 'Capacity', '25 Liters', 1),
(41, 9, 'Controls', 'Timer and Temperature Control', 2),
(42, 9, 'Functions', 'Baking and Grilling', 3),
(43, 9, 'USP', 'For Baking Lovers - Entry-level oven', 4),
(44, 10, 'Brand', 'Samsung', 1),
(45, 10, 'Features', 'Night Vision, Motion Detection', 2),
(46, 10, 'Connectivity', 'Remote Viewing', 3),
(47, 10, 'USP', 'High-quality security monitoring', 4),
(48, 11, 'Brand', 'Walton', 1),
(49, 11, 'Type', '3-in-1 Machine', 2),
(50, 11, 'Functions', 'Blending, Grinding, Mixing', 3),
(51, 11, 'USP', 'Versatile kitchen companion', 4),
(52, 12, 'Brand', 'Panasonic', 1),
(53, 12, 'Capacity', '5 Liters', 2),
(54, 12, 'Coating', 'Non-stick Inner Pot', 3),
(55, 12, 'Features', 'Keep-warm Function, Automatic Cooking', 4),
(56, 12, 'USP', 'Perfect rice every time', 5),
(57, 13, 'Brand', 'Jamuna', 1),
(58, 13, 'Type', 'Ceiling Fan', 2),
(59, 13, 'Motor', 'Energy-efficient', 3),
(60, 13, 'USP', 'Powerful airflow, low electricity consumption', 4),
(61, 14, 'Brand', 'Walton', 1),
(62, 14, 'Capacity', '1.5 Ton', 2),
(63, 14, 'Features', 'Fast Cooling, Auto-restart, Sleep Mode', 3),
(64, 14, 'Energy', 'Energy-efficient', 4),
(65, 14, 'USP', 'Perfect for medium-sized rooms', 5),
(66, 15, 'Brand', 'Walton', 1),
(67, 15, 'Capacity', '2 Ton', 2),
(68, 15, 'Features', 'Turbo Cooling, Dehumidifier, Smart Control', 3),
(69, 15, 'USP', 'Ideal for large rooms', 4),
(70, 16, 'Brand', 'Panasonic', 1),
(71, 16, 'Jars', '3 Jars', 2),
(72, 16, 'Blade Material', 'Stainless Steel', 3),
(73, 16, 'Functions', 'Grinding Spices, Making Chutneys, Mixing Batters', 4),
(74, 16, 'USP', 'Multi-purpose kitchen tool', 5),
(75, 17, 'Brand', 'Hikvision', 1),
(76, 17, 'Filter Type', 'HEPA Filter', 2),
(77, 17, 'Efficiency', 'Removes 99.9% Pollutants', 3),
(78, 17, 'Operation', 'Quiet with Multiple Fan Speeds', 4),
(79, 17, 'USP', 'Advanced air purification', 5),
(80, 18, 'Brand', 'P9 Max', 1),
(81, 18, 'Type', 'Wireless Bluetooth', 2),
(82, 18, 'Features', 'Noise Cancellation, Deep Bass', 3),
(83, 18, 'Battery Life', '20 Hours', 4),
(84, 18, 'Design', 'Comfortable Over-ear', 5),
(85, 18, 'USP', 'Premium audio experience', 6),
(86, 20, 'Screen Size', '21.5 Inches', 1),
(87, 20, 'Resolution', 'Full HD 1920x1080', 2),
(88, 20, 'Panel Type', 'IPS', 3),
(89, 20, 'Design', 'Ultra-thin Zero-frame', 4),
(90, 20, 'Rating', '5', 5),
(91, 21, 'Generation', '12th Gen', 1),
(92, 21, 'Cores', '12 Cores', 2),
(93, 21, 'Threads', '20 Threads', 3),
(94, 21, 'Performance', 'High Performance Gaming & Productivity', 4),
(95, 21, 'Rating', '5', 5),
(96, 22, 'Processor', 'AMD Ryzen 9', 1),
(97, 22, 'Graphics', 'RTX 3070', 2),
(98, 22, 'RAM', '16GB', 3),
(99, 22, 'Storage', '1TB SSD', 4),
(100, 22, 'Features', 'RGB Keyboard', 5),
(101, 22, 'Rating', '4', 6),
(102, 23, 'Model', 'MX Master 3', 1),
(103, 23, 'Type', 'Wireless', 2),
(104, 23, 'Features', 'MagSpeed Scroll Wheel, Ergonomic Design', 3),
(105, 23, 'Connectivity', 'Multi-device', 4),
(106, 23, 'Rating', '4', 5),
(107, 24, 'Capacity', '1TB', 1),
(108, 24, 'Interface', 'USB 3.2 Gen 2', 2),
(109, 24, 'Speed', 'Up to 1050 MB/s', 3),
(110, 24, 'Design', 'Compact and Durable', 4),
(111, 24, 'Rating', '5', 5),
(112, 25, 'Switch Type', 'Cherry MX Speed', 1),
(113, 25, 'Lighting', 'Per-key RGB', 2),
(114, 25, 'Controls', 'Dedicated Media Controls', 3),
(115, 25, 'Type', 'Mechanical Gaming Keyboard', 4),
(116, 25, 'Rating', '4', 5),
(117, 26, 'Sensor', '20K DPI Optical', 1),
(118, 26, 'Battery', '70-hour Battery Life', 2),
(119, 26, 'Design', 'Ergonomic', 3),
(120, 26, 'Type', 'Wireless Gaming Mouse', 4),
(121, 26, 'Rating', '4', 5),
(122, 27, 'Screen Size', '27 Inch', 1),
(123, 27, 'Resolution', '4K UHD', 2),
(124, 27, 'Technology', 'IPS Black', 3),
(125, 27, 'Connectivity', 'USB-C', 4),
(126, 27, 'Features', 'Professional Color Accuracy', 5),
(127, 27, 'Rating', '5', 6),
(128, 28, 'Size', '12 inch', 1),
(129, 28, 'Battery Backup', '4-6 hours', 2),
(130, 28, 'Features', 'LED Light, Rechargeable', 3),
(131, 28, 'Design', 'Compact and Portable', 4),
(132, 29, 'Size', '16 inch', 1),
(133, 29, 'Battery Backup', '6-8 hours', 2),
(134, 29, 'Features', 'High-speed Motor, Adjustable Height', 3),
(135, 29, 'Power', 'Powerful Airflow', 4),
(136, 30, 'Size', '16 inch', 1),
(137, 30, 'Battery Backup', '8-10 hours', 2),
(138, 30, 'Features', 'Remote Control, Multiple Speed Settings', 3),
(139, 30, 'Type', 'Premium Model', 4),
(140, 31, 'Size', '16 inch', 1),
(141, 31, 'Battery Backup', '10-12 hours', 2),
(142, 31, 'Features', 'Solar Charging Option', 3),
(143, 31, 'Type', 'Eco-friendly Solution', 4),
(144, 31, 'Power', 'Super Powerful', 5),
(145, 32, 'Size', '16 inch', 1),
(146, 32, 'Battery Backup', '12-14 hours', 2),
(147, 32, 'Features', 'USB Charging Port, Can Charge Phones', 3),
(148, 32, 'Type', 'Premium Plus Model', 4),
(149, 33, 'Size', '14 inch', 1),
(150, 33, 'Battery Backup', '6-8 hours', 2),
(151, 33, 'Build', 'Strong and Durable', 3),
(152, 33, 'Series', 'Defender Series', 4),
(153, 34, 'Size', '16 inch', 1),
(154, 34, 'Battery Backup', '8-10 hours', 2),
(155, 34, 'Blades', 'Metal Blades', 3),
(156, 34, 'Quality', 'Industrial-grade', 4),
(157, 34, 'Series', 'Defender Series', 5),
(158, 35, 'Size', '16 inch', 1),
(159, 35, 'Battery Backup', '10-12 hours', 2),
(160, 35, 'Motor', 'Enhanced Motor', 3),
(161, 35, 'Performance', 'Maximum Airflow', 4),
(162, 35, 'Series', 'Defender Plus', 5),
(163, 36, 'Size', '12 inch', 1),
(164, 36, 'Battery Backup', '5-6 hours', 2),
(165, 36, 'Features', 'LED Light, Rechargeable', 3),
(166, 36, 'Type', 'Popular Deal Model', 4),
(167, 37, 'Model', '560', 1),
(168, 37, 'Plates', 'Non-stick Grill Plates', 2),
(169, 37, 'Heating', 'Fast Heating', 3),
(170, 37, 'Maintenance', 'Easy to Clean', 4),
(171, 37, 'Best For', 'Students & Small Families', 5),
(172, 37, 'USP', 'Perfect for Quick Breakfast', 6),
(173, 38, 'Model', 'HE-133', 1),
(174, 38, 'Type', 'Hand Mixer', 2),
(175, 38, 'Power', 'Powerful Motor', 3),
(176, 38, 'Weight', 'Lightweight', 4),
(177, 38, 'Use', 'Cake Making, Whisking Eggs', 5),
(178, 38, 'USP', 'Incredibly Cheap & Effective', 6),
(179, 39, 'Model', '2912', 1),
(180, 39, 'Size', '12 inch', 2),
(181, 39, 'Battery Backup', '5-6 hours', 3),
(182, 39, 'Features', 'LED Light, Rechargeable', 4),
(183, 39, 'Season', 'Summer Hot Item', 5),
(184, 39, 'USP', 'Biggest Flash Sale Attraction', 6),
(185, 40, 'Brand', 'Prestige', 1),
(186, 40, 'Capacity', '1.8 Liters', 2),
(187, 40, 'Coating', 'Non-stick Inner Pot', 3),
(188, 40, 'Features', 'Keep-warm Function', 4),
(189, 40, 'Quality', 'Known for Durability', 5),
(190, 40, 'USP', 'The Perfect Rice, Every Single Meal', 6),
(191, 40, 'Strategy', 'Perfectly Cooked Rice Every Time', 7);

-- --------------------------------------------------------

--
-- Table structure for table `promotions`
--


--
-- Dumping data for table `promotions`
--



-- collections
INSERT IGNORE INTO `collections` (`collection_id`, `name`, `slug`, `description`, `icon`, `image_url`, `item_count`, `is_active`, `display_order`, `created_at`) VALUES
(1, 'Fans', 'fans', 'Cooling solutions for your home', 'air', NULL, 16, 1, 1, '2026-03-01 07:11:36'),
(2, 'Cookers', 'cookers', 'Kitchen cooking appliances', 'soup_kitchen', NULL, 10, 1, 2, '2026-03-01 07:11:36'),
(3, 'Blenders', 'blenders', 'Blending and mixing solutions', 'blender', NULL, 11, 1, 3, '2026-03-01 07:11:36'),
(4, 'Phone Related', 'phone-related', 'Phone accessories and devices', 'phone', NULL, 0, 1, 4, '2026-03-01 07:11:36'),
(5, 'Massager Items', 'massager-items', 'Relaxation and massage products', 'spa', NULL, 1, 1, 5, '2026-03-01 07:11:36'),
(6, 'Trimmer', 'trimmer', 'Personal grooming tools', 'content_cut', NULL, 0, 1, 6, '2026-03-01 07:11:36'),
(7, 'Electric Chula', 'electric-chula', 'Electric cooking stoves', 'local_fire_department', NULL, 1, 1, 7, '2026-03-01 07:11:36'),
(8, 'Iron', 'iron', 'Ironing solutions', 'iron', NULL, 3, 1, 8, '2026-03-01 07:11:36'),
(9, 'Chopper', 'chopper', 'Food chopping tools', 'cut', NULL, 0, 1, 9, '2026-03-01 07:11:36'),
(10, 'Grinder', 'grinder', 'Grinding appliances', 'settings', NULL, 3, 1, 10, '2026-03-01 07:11:36'),
(11, 'Kettle', 'kettle', 'Water boiling solutions', 'coffee_maker', NULL, 3, 1, 11, '2026-03-01 07:11:36'),
(12, 'Hair Dryer', 'hair-dryer', 'Hair drying tools', 'air', NULL, 3, 1, 12, '2026-03-01 07:11:36'),
(13, 'Oven', 'oven', 'Baking and cooking ovens', 'microwave', NULL, 2, 1, 13, '2026-03-01 07:11:36'),
(14, 'Air Fryer', 'air-fryer', 'Healthy frying solutions', 'kitchen', NULL, 1, 1, 14, '2026-03-01 07:11:36'),
(15, 'Home Essentials', '', 'Must-have products for every home', NULL, 'home_essentials.png', 0, 1, 0, '2026-03-01 07:11:55');

-- --------------------------------------------------------

--
-- Table structure for table `collection_items`
--


--
-- Dumping data for table `collection_items`
--



-- collection_items
INSERT IGNORE INTO `collection_items` (`item_id`, `collection_id`, `item_name`, `display_order`) VALUES
(1, 1, 'Charger Fan', 1),
(2, 1, 'Mini Hand Fan', 2),
(3, 2, 'Rice Cooker', 1),
(4, 2, 'Mini Cooker', 2),
(5, 2, 'Curry Cooker', 3),
(6, 3, 'Hand Blender', 1),
(7, 3, 'Blender', 2),
(8, 4, 'Telephone Set', 1),
(9, 4, 'Sim Telephone', 2),
(10, 5, 'Massage Gun', 1),
(11, 5, 'Head Massage', 2);

-- --------------------------------------------------------

--
-- Table structure for table `collection_products`
--


--
-- Dumping data for table `collection_products`
--



-- collection_products
INSERT IGNORE INTO `collection_products` (`collection_id`, `product_id`, `added_at`) VALUES
(1, 5, '2026-03-01 07:11:36'),
(1, 13, '2026-03-01 07:11:36'),
(1, 19, '2026-03-01 07:11:36'),
(1, 28, '2026-03-01 07:11:36'),
(1, 29, '2026-03-01 07:11:36'),
(1, 30, '2026-03-01 07:11:36'),
(1, 31, '2026-03-01 07:11:36'),
(1, 32, '2026-03-01 07:11:36'),
(1, 33, '2026-03-01 07:11:36'),
(1, 34, '2026-03-01 07:11:36'),
(1, 35, '2026-03-01 07:11:36'),
(1, 36, '2026-03-01 07:11:36'),
(1, 54, '2026-03-02 10:10:25'),
(1, 60, '2026-03-02 10:10:25'),
(1, 66, '2026-03-02 10:10:25'),
(1, 70, '2026-03-02 10:10:25'),
(2, 1, '2026-03-01 07:11:36'),
(2, 5, '2026-03-04 09:52:37'),
(2, 12, '2026-03-01 07:11:36'),
(2, 13, '2026-03-04 09:52:37'),
(2, 19, '2026-03-04 09:52:37'),
(2, 28, '2026-03-04 09:52:37'),
(2, 29, '2026-03-04 09:52:37'),
(2, 30, '2026-03-04 09:52:37'),
(2, 31, '2026-03-04 09:52:37'),
(2, 32, '2026-03-04 09:52:37'),
(2, 33, '2026-03-04 09:52:37'),
(2, 34, '2026-03-04 09:52:37'),
(2, 35, '2026-03-04 09:52:37'),
(2, 36, '2026-03-04 09:52:37'),
(2, 39, '2026-03-04 09:52:37'),
(2, 40, '2026-03-02 10:18:53'),
(2, 53, '2026-03-02 10:18:53'),
(2, 54, '2026-03-04 09:52:37'),
(2, 60, '2026-03-04 09:52:37'),
(2, 61, '2026-03-02 10:18:53'),
(2, 63, '2026-03-02 10:18:53'),
(2, 66, '2026-03-04 09:52:37'),
(2, 70, '2026-03-04 09:52:37'),
(2, 71, '2026-03-02 10:18:53'),
(2, 72, '2026-03-02 10:18:53'),
(2, 75, '2026-03-02 10:18:53'),
(2, 76, '2026-03-02 10:18:53'),
(3, 1, '2026-03-04 09:52:37'),
(3, 6, '2026-03-01 07:11:36'),
(3, 7, '2026-03-02 10:18:53'),
(3, 11, '2026-03-01 07:11:36'),
(3, 12, '2026-03-04 09:52:37'),
(3, 16, '2026-03-01 07:11:36'),
(3, 38, '2026-03-02 10:18:53'),
(3, 40, '2026-03-04 09:52:37'),
(3, 51, '2026-03-02 10:18:53'),
(3, 53, '2026-03-04 09:52:37'),
(3, 55, '2026-03-02 10:18:53'),
(3, 59, '2026-03-02 10:18:53'),
(3, 61, '2026-03-04 09:52:37'),
(3, 63, '2026-03-04 09:52:37'),
(3, 64, '2026-03-02 10:18:53'),
(3, 68, '2026-03-02 10:18:53'),
(3, 71, '2026-03-04 09:52:37'),
(3, 72, '2026-03-04 09:52:37'),
(3, 73, '2026-03-02 10:18:53'),
(3, 75, '2026-03-04 09:52:37'),
(3, 76, '2026-03-04 09:52:37'),
(4, 6, '2026-03-04 09:52:37'),
(4, 7, '2026-03-04 09:52:37'),
(4, 11, '2026-03-04 09:52:37'),
(4, 16, '2026-03-04 09:52:37'),
(4, 38, '2026-03-04 09:52:37'),
(4, 51, '2026-03-04 09:52:37'),
(4, 55, '2026-03-04 09:52:37'),
(4, 59, '2026-03-04 09:52:37'),
(4, 64, '2026-03-04 09:52:37'),
(4, 68, '2026-03-04 09:52:37'),
(4, 73, '2026-03-04 09:52:37'),
(5, 5, '2026-03-04 09:52:37'),
(5, 18, '2026-03-04 09:52:37'),
(5, 28, '2026-03-04 09:52:37'),
(5, 29, '2026-03-04 09:52:37'),
(5, 30, '2026-03-04 09:52:37'),
(5, 31, '2026-03-04 09:52:37'),
(5, 32, '2026-03-04 09:52:37'),
(5, 33, '2026-03-04 09:52:37'),
(5, 34, '2026-03-04 09:52:37'),
(5, 35, '2026-03-04 09:52:37'),
(5, 36, '2026-03-04 09:52:37'),
(5, 39, '2026-03-04 09:52:37'),
(5, 54, '2026-03-04 09:52:37'),
(5, 66, '2026-03-04 09:52:37'),
(5, 69, '2026-03-02 10:18:53'),
(6, 69, '2026-03-04 09:52:37'),
(7, 67, '2026-03-02 10:18:53'),
(8, 52, '2026-03-02 10:18:53'),
(8, 58, '2026-03-02 10:18:53'),
(8, 67, '2026-03-04 09:52:37'),
(9, 52, '2026-03-04 09:52:37'),
(9, 58, '2026-03-04 09:52:37'),
(10, 2, '2026-03-02 10:18:53'),
(10, 16, '2026-03-02 10:18:53'),
(10, 57, '2026-03-02 10:18:53'),
(11, 2, '2026-03-04 09:52:37'),
(11, 3, '2026-03-02 10:18:53'),
(11, 16, '2026-03-04 09:52:37'),
(11, 56, '2026-03-02 10:18:53'),
(11, 57, '2026-03-04 09:52:37'),
(11, 65, '2026-03-02 10:18:53'),
(12, 3, '2026-03-04 09:52:37'),
(12, 4, '2026-03-02 10:18:53'),
(12, 49, '2026-03-02 10:18:53'),
(12, 50, '2026-03-02 10:18:53'),
(12, 56, '2026-03-04 09:52:37'),
(12, 65, '2026-03-04 09:52:37'),
(13, 4, '2026-03-04 09:52:37'),
(13, 9, '2026-03-02 10:18:53'),
(13, 49, '2026-03-04 09:52:37'),
(13, 50, '2026-03-04 09:52:37'),
(13, 74, '2026-03-02 10:18:53'),
(14, 9, '2026-03-04 09:52:37'),
(14, 62, '2026-03-02 10:18:53'),
(14, 74, '2026-03-04 09:52:37'),
(15, 62, '2026-03-04 09:52:37');

-- --------------------------------------------------------

--
-- Table structure for table `csrf_tokens`
--


-- --------------------------------------------------------

--
-- Table structure for table `customer_support`
--


-- --------------------------------------------------------

--
-- Table structure for table `deals_of_the_day`
--


--
-- Dumping data for table `deals_of_the_day`
--



-- banners
INSERT IGNORE INTO `banners` (`banner_id`, `banner_type`, `image_url`, `link_url`, `title`, `description`, `button_text`, `display_order`, `active`, `start_date`, `end_date`, `created_at`, `updated_at`) VALUES
(10, 'sidebar', '', '', 'FLASH SALE', 'Up to 400% Off on Earbuds', 'VIEW ALL', 0, 1, NULL, NULL, '2026-03-29 16:59:51', '2026-03-29 16:59:51'),
(14, 'mid', 'assets/1.png', '/deals', 'Banner 1', '', 'Shop Now', 1, 1, '2026-03-29', '2027-03-29', '2026-03-29 17:30:42', '2026-03-29 17:30:42'),
(15, 'mid', 'assets/2.png', '/deals', 'Banner 2', '', 'Shop Now', 2, 1, '2026-03-29', '2027-03-29', '2026-03-29 17:30:42', '2026-03-29 17:30:42'),
(16, 'mid', 'assets/3.png', '/deals', 'Banner 3', '', 'Shop Now', 3, 1, '2026-03-29', '2027-03-29', '2026-03-29 17:30:42', '2026-03-29 17:30:42'),
(20, 'hero', 'assets/Hero banner logos/dopp.png', '', 'HOT DEALS', '', '', 0, 1, NULL, NULL, '2026-03-29 17:34:01', '2026-03-29 17:34:01'),
(21, 'hero', 'assets/Hero banner logos/top.png', '', 'NEW IN', '', '', 1, 1, NULL, NULL, '2026-03-29 17:34:01', '2026-03-29 17:34:01');

-- --------------------------------------------------------

--
-- Table structure for table `best_sellers`
--


--
-- Dumping data for table `best_sellers`
--



-- best_sellers
INSERT IGNORE INTO `best_sellers` (`product_id`, `sales_count`, `created_at`, `selling_point`, `sales_strategy`, `last_updated`) VALUES
(1, 565, '2026-03-05 08:00:00', 'Large 5.5L cooker ideal for family-sized meals.', 'Cook Big, Live Large', '2026-03-05 08:00:00'),
(2, 520, '2026-03-05 08:00:00', 'Affordable grinder with strong everyday performance.', 'Your Daily Spice Partner', '2026-03-05 08:00:00'),
(3, 540, '2026-03-05 08:00:00', 'Fast-boil kettle for daily tea and coffee needs.', 'Hot Water in Minutes', '2026-03-05 08:00:00'),
(5, 621, '2026-03-05 08:00:00', 'Top rechargeable fan with reliable backup for load-shedding.', 'Stay Cool, No Matter the Power Cut', '2026-03-05 08:00:00'),
(40, 590, '2026-03-05 08:00:00', 'Trusted rice cooker for consistent everyday cooking.', 'Perfect Rice for Every Meal', '2026-03-05 08:00:00'),
(48, 460, '2026-03-05 08:00:00', 'Compact sandwich maker that converts quickly.', 'Quick Breakfast Champion', '2026-03-05 08:00:00'),
(55, 470, '2026-03-05 08:00:00', 'High-power blender suited for heavy use families.', 'Blend Fast, Blend More', '2026-03-05 08:00:00'),
(62, 505, '2026-03-05 08:00:00', 'Digital air fryer with strong demand in smart kitchens.', 'Healthy Frying, Smart Living', '2026-03-05 08:00:00'),
(74, 498, '2026-03-05 08:00:00', 'Popular 25L oven for baking and grilling at home.', 'Bake Better, Every Day', '2026-03-05 08:00:00'),
(76, 485, '2026-03-05 08:00:00', 'Reliable 1.8L rice cooker at a strong value point.', 'Daily Cooking Made Easy', '2026-03-05 08:00:00'),
(108, 5, '2026-03-29 17:41:10', NULL, NULL, '2026-03-29 17:41:10');

-- --------------------------------------------------------

--
-- Table structure for table `brands`
--


--
-- Dumping data for table `brands`
--



-- deals_of_the_day
INSERT IGNORE INTO `deals_of_the_day` (`deal_id`, `product_id`, `deal_price`, `start_date`, `end_date`, `created_at`) VALUES
(21, 5, 1990.00, '2026-03-05 00:00:00', '2026-03-12 23:59:59', '2026-03-05 08:00:00'),
(22, 40, 2390.00, '2026-03-05 00:00:00', '2026-03-12 23:59:59', '2026-03-05 08:00:00'),
(23, 62, 6490.00, '2026-03-05 00:00:00', '2026-03-12 23:59:59', '2026-03-05 08:00:00'),
(24, 74, 7690.00, '2026-03-05 00:00:00', '2026-03-12 23:59:59', '2026-03-05 08:00:00'),
(25, 76, 2990.00, '2026-03-05 00:00:00', '2026-03-12 23:59:59', '2026-03-05 08:00:00'),
(26, 48, 1490.00, '2026-03-05 00:00:00', '2026-03-12 23:59:59', '2026-03-05 08:00:00'),
(27, 51, 1390.00, '2026-03-05 00:00:00', '2026-03-12 23:59:59', '2026-03-05 08:00:00'),
(28, 57, 3290.00, '2026-03-05 00:00:00', '2026-03-12 23:59:59', '2026-03-05 08:00:00'),
(29, 67, 1090.00, '2026-03-05 00:00:00', '2026-03-12 23:59:59', '2026-03-05 08:00:00'),
(30, 70, 2590.00, '2026-03-05 00:00:00', '2026-03-12 23:59:59', '2026-03-05 08:00:00');

-- --------------------------------------------------------

--
-- Table structure for table `deals_timer`
--


--
-- Dumping data for table `deals_timer`
--



-- deals_timer
INSERT IGNORE INTO `deals_timer` (`timer_id`, `title`, `description`, `end_time`, `days`, `hours`, `minutes`, `seconds`, `is_active`, `updated_at`) VALUES
(2, 'jj', 'hhh', '2026-05-01 23:00:00', 0, 0, 0, 0, 1, '2026-03-29 17:52:00');



-- flash_sales
INSERT IGNORE INTO `flash_sales` (`flash_sale_id`, `title`, `start_time`, `end_time`, `active`, `created_at`) VALUES
(1, 'Weekend Flash Sale', '2026-03-05 10:00:00', '2026-04-26 19:22:23', 1, '2026-03-05 08:00:00');

-- --------------------------------------------------------

--
-- Table structure for table `flash_sale_products`
--


--
-- Dumping data for table `flash_sale_products`
--



-- flash_sale_products
INSERT IGNORE INTO `flash_sale_products` (`flash_sale_product_id`, `flash_sale_id`, `product_id`, `flash_price`, `image_path`, `display_order`, `created_at`) VALUES
(1, 1, 48, 1490.00, NULL, 1, '2026-03-05 08:00:00'),
(2, 1, 49, 2690.00, NULL, 2, '2026-03-05 08:00:00'),
(3, 1, 50, 1590.00, NULL, 3, '2026-03-05 08:00:00'),
(4, 1, 51, 1350.00, NULL, 4, '2026-03-05 08:00:00'),
(5, 1, 52, 1690.00, NULL, 5, '2026-03-05 08:00:00'),
(6, 1, 53, 2590.00, NULL, 6, '2026-03-05 08:00:00'),
(7, 1, 55, 3690.00, NULL, 7, '2026-03-05 08:00:00'),
(8, 1, 56, 1450.00, NULL, 8, '2026-03-05 08:00:00'),
(9, 1, 57, 3190.00, NULL, 9, '2026-03-05 08:00:00'),
(10, 1, 58, 1890.00, NULL, 10, '2026-03-05 08:00:00'),
(11, 1, 60, 990.00, NULL, 11, '2026-03-05 08:00:00'),
(12, 1, 61, 2390.00, NULL, 12, '2026-03-05 08:00:00');

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--


-- --------------------------------------------------------

--
-- Table structure for table `order_items`
--


-- --------------------------------------------------------

--
-- Table structure for table `password_reset_tokens`
--


--
-- Dumping data for table `password_reset_tokens`
--



-- promotions
INSERT IGNORE INTO `promotions` (`promotion_id`, `title`, `description`, `discount_percent`, `start_date`, `end_date`, `active`) VALUES
(1, 'Mega Smartphone Sale', 'Up to 90% off on smartphones', 90.00, '2026-03-01', '2026-03-31', 1),
(2, 'Laptop Clearance', 'Huge discounts on laptops', 85.00, '2026-03-01', '2026-03-31', 1),
(3, 'Home Appliances', 'Save big on home appliances', 80.00, '2026-03-01', '2026-03-31', 1),
(4, 'Fashion Deals', 'Fashion items at unbeatable prices', 75.00, '2026-03-01', '2026-03-31', 1),
(5, 'Winter Sale', 'Up to 20% off on lighting products', 20.00, '2026-03-01', '2026-03-31', 1);

-- --------------------------------------------------------

--
-- Table structure for table `rate_limits`
--


-- --------------------------------------------------------

--
-- Table structure for table `reports`
--


-- --------------------------------------------------------

--
-- Table structure for table `reviews`
--


-- --------------------------------------------------------

--
-- Table structure for table `search_analytics`
--


-- --------------------------------------------------------

--
-- Table structure for table `search_history`
--


--
-- Dumping data for table `search_history`
--



-- payment_methods
INSERT IGNORE INTO `payment_methods` (`method_id`, `method_name`, `method_type`, `is_enabled`, `account_number`, `display_order`, `icon_url`, `created_at`, `updated_at`) VALUES
(1, 'bKash', 'mobile_banking', 1, '01996-242974', 1, '', '2026-03-01 13:10:23', '2026-03-29 14:37:03'),
(2, 'Nagad', 'mobile_banking', 1, '01840658317', 2, '', '2026-03-01 13:10:23', '2026-03-29 14:37:30'),
(6, 'Cash on Delivery', 'cash', 1, '', 3, NULL, '2026-03-01 13:10:45', '2026-03-01 13:10:45');

-- --------------------------------------------------------

--
-- Table structure for table `products`
--


--
-- Dumping data for table `products`
--



-- site_settings
INSERT IGNORE INTO `site_settings` (`setting_key`, `setting_value`, `updated_at`) VALUES
('currency', 'BDT', '2026-03-01 07:11:36'),
('section_filter_best_sellers', '{\"limit\": 10, \"sort\": \"sales_desc\"}', '2026-03-01 07:11:36'),
('section_filter_deals', '{\"limit\": 10, \"sort\": \"newest\"}', '2026-03-01 07:11:36'),
('section_filter_flash_sale', '{\"limit\": 10, \"sort\": \"newest\"}', '2026-03-01 07:11:36'),
('section_filter_tech_part', '{\"limit\": 10, \"sort\": \"display_order\"}', '2026-03-01 07:11:36'),
('section_filter_trending', '{\"limit\": 10, \"sort\": \"score_desc\"}', '2026-03-01 07:11:36'),
('site_email', 'info@electrocitybd.com', '2026-03-01 07:11:36'),
('site_name', 'ElectrocityBD', '2026-03-01 07:11:36'),
('site_phone', '+880 1234-567890', '2026-03-01 07:11:36'),
('tax_rate', '0.00', '2026-03-01 07:11:36');

-- --------------------------------------------------------

--
-- Table structure for table `stock_alerts`
--


--
-- Dumping data for table `stock_alerts`
--



-- search_history
INSERT IGNORE INTO `search_history` (`search_id`, `user_id`, `search_query`, `results_count`, `searched_at`) VALUES
(1, NULL, 'fan', 19, '2026-03-27 11:08:19');



-- search_suggestions
INSERT IGNORE INTO `search_suggestions` (`suggestion_id`, `suggestion_text`, `suggestion_type`, `search_count`, `last_searched`, `is_active`, `created_at`) VALUES
(2, 'Air Fryer Digital', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(4, 'AV Multi Cooker', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(5, 'AV Sandwich Maker', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(6, 'AV Sandwich Maker 296', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(7, 'AV Sandwich Maker 560', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(8, 'Blender', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(9, 'Blender Pro 2000', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(10, 'Charger Fan Portable', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(11, 'Copper Wire', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(14, 'Electric Iron', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(15, 'Electric Kettle', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(16, 'Electric Stove Single', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(17, 'Hair Dryer Compact', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(18, 'Hair Dryer Professional', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(19, 'Hair Styling Tool', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(20, 'Hand Blender 3-in-1', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(21, 'Hand Mixer', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(22, 'Head Massager Electric', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(23, 'Hikvision Air Purifier', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(24, 'HK Defender Charger Fan 2914', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(25, 'HK Defender Charger Fan 2916', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(26, 'HK Defender Charger Fan 2916 Plus', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(28, 'Iron Master', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(29, 'Jamuna Fan', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(30, 'JY Mini Rice Cooker 1880', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(31, 'Kennede Charger Fan', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(32, 'Kennede Charger Fan 2412', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(33, 'Kennede Charger Fan 2912', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(34, 'Kennede Charger Fan 2912 (Deal Model)', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(35, 'Kennede Charger Fan 2912 Flash', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(36, 'Kennede Charger Fan 2916', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(37, 'Kennede Charger Fan 2926', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(38, 'Kennede Charger Fan 2936S', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(39, 'Kennede Charger Fan 2956P', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(40, 'kennede fan', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(41, 'Kennede Rechargeable Fan', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(42, 'LED Bulb', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(47, 'Mini Cooker Deluxe', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(48, 'Mini Hand Blender', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(49, 'Miyako 25L Electric Oven', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(50, 'Miyako Curry Cooker 5.5L', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(51, 'Miyako Kettle 180 PS 1.8L', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(52, 'Miyako Pink Panther Blender 750W', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(53, 'Miyoko Electric Kettle', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(54, 'Miyoko Oven 25L', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(55, 'Nima 2-in-1 Grinder 400W', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(56, 'Nima Grinder 400W', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(57, 'Noha Hot King Cooker', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(58, 'NOHA Hotel King Blender 1050W', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(60, 'Panasonic Cooker 5L', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(61, 'Panasonic Mixer Grinder', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(62, 'Pink Leather Iron', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(63, 'prestige cooker', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(64, 'Prestige Rice Cooker 1.8L', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(66, 'Rice Cooker 1.8L', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(67, 'Samsung CCTV Camera', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(69, 'Scarlet Hand Mixer', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(70, 'Scarlet Hand Mixer HE-133', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(71, 'Screwdriver Set', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(72, 'Smart LED Strip', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(73, 'Sokany Hair Dryer HS-3820', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(74, 'Tube Light', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(75, 'Walton AC 1.5 Ton', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(76, 'Walton AC 2 Ton', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(77, 'Walton Blender 3-in-1 Machine', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(78, 'WD Mini Fan', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(79, 'YG Mini Cooker 717', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(128, 'Electronics', 'category', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(129, 'Home Appliances', 'category', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(130, 'Home Comfort & Utility', 'category', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(131, 'Kitchen Appliances', 'category', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(132, 'Lighting', 'category', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(133, 'Personal Care', 'category', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(134, 'Personal Care & Lifestyle', 'category', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(135, 'Tools', 'category', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(136, 'Wiring', 'category', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(143, 'Bosch', 'brand', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(144, 'BPL', 'brand', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(145, 'Changhong', 'brand', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(146, 'Electrolux', 'brand', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(147, 'Gree', 'brand', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(148, 'Haier', 'brand', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(149, 'Hisense', 'brand', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(150, 'Hitachi', 'brand', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(151, 'Jamuna', 'brand', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(152, 'Konka', 'brand', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(153, 'LG', 'brand', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(154, 'Midea', 'brand', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(155, 'Onida', 'brand', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(156, 'Panasonic', 'brand', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(157, 'Philips', 'brand', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(158, 'Samsung', 'brand', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(159, 'Sharp', 'brand', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(160, 'Siemens', 'brand', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(161, 'Singer', 'brand', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(162, 'Skyworth', 'brand', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(163, 'Sony', 'brand', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(164, 'TCL', 'brand', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(165, 'Toshiba', 'brand', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(166, 'Unknown', 'brand', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(167, 'Videocon', 'brand', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(168, 'Vision', 'brand', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(169, 'Walton', 'brand', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(170, 'Whirlpool', 'brand', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(200, 'miyoko', 'product', 0, '2026-03-29 17:41:10', 1, '2026-03-29 17:41:10');

-- --------------------------------------------------------

--
-- Table structure for table `site_settings`
--


--
-- Dumping data for table `site_settings`
--



-- tech_part_products
INSERT IGNORE INTO `tech_part_products` (`product_id`, `display_order`, `created_at`) VALUES
(10, 6, '2026-03-05 08:00:00'),
(18, 7, '2026-03-27 13:47:55'),
(20, 8, '2026-03-05 08:00:00'),
(21, 3, '2026-03-05 08:00:00'),
(22, 1, '2026-03-05 08:00:00'),
(23, 5, '2026-03-05 08:00:00'),
(24, 4, '2026-03-05 08:00:00'),
(25, 9, '2026-03-27 13:47:55'),
(26, 10, '2026-03-05 08:00:00'),
(27, 2, '2026-03-05 08:00:00'),
(45, 8, '2026-03-05 08:00:00');


-- trending_products
INSERT IGNORE INTO `trending_products` (`trending_product_id`, `product_id`, `trending_score`, `image_path`, `display_order`, `created_at`, `updated_at`, `last_updated`) VALUES
(1, 62, 98, NULL, 1, '2026-03-05 08:00:00', '2026-03-05 08:00:00', '2026-03-05 08:00:00'),
(2, 74, 96, NULL, 2, '2026-03-05 08:00:00', '2026-03-05 08:00:00', '2026-03-05 08:00:00'),
(3, 64, 95, NULL, 3, '2026-03-05 08:00:00', '2026-03-05 08:00:00', '2026-03-05 08:00:00'),
(4, 76, 94, NULL, 4, '2026-03-05 08:00:00', '2026-03-05 08:00:00', '2026-03-05 08:00:00'),
(5, 48, 93, NULL, 5, '2026-03-05 08:00:00', '2026-03-05 08:00:00', '2026-03-05 08:00:00'),
(6, 70, 92, NULL, 6, '2026-03-05 08:00:00', '2026-03-05 08:00:00', '2026-03-05 08:00:00'),
(7, 65, 91, NULL, 7, '2026-03-05 08:00:00', '2026-03-05 08:00:00', '2026-03-05 08:00:00'),
(8, 55, 90, NULL, 8, '2026-03-05 08:00:00', '2026-03-05 08:00:00', '2026-03-05 08:00:00'),
(9, 57, 89, NULL, 9, '2026-03-05 08:00:00', '2026-03-05 08:00:00', '2026-03-05 08:00:00'),
(10, 67, 88, NULL, 10, '2026-03-05 08:00:00', '2026-03-05 08:00:00', '2026-03-05 08:00:00'),
(11, 51, 95, NULL, 11, '2026-03-05 08:00:00', '2026-03-27 14:23:44', '2026-03-27 14:23:44'),
(12, 60, 86, NULL, 12, '2026-03-05 08:00:00', '2026-03-05 08:00:00', '2026-03-05 08:00:00'),
(48, 5, 1, NULL, 0, '2026-03-29 17:23:35', '2026-03-29 17:23:35', '2026-03-29 17:23:35'),
(49, 108, 1, NULL, 0, '2026-03-29 17:50:12', '2026-03-29 17:50:12', '2026-03-29 17:50:12');



-- stock_alerts
INSERT IGNORE INTO `stock_alerts` (`alert_id`, `product_id`, `alert_type`, `threshold_quantity`, `current_quantity`, `is_resolved`, `resolved_at`, `created_at`) VALUES
(1, 15, 'LOW_STOCK', 5, 5, 0, NULL, '2026-03-04 09:38:39'),
(2, 22, 'LOW_STOCK', 5, 5, 0, NULL, '2026-03-04 09:38:39');

-- --------------------------------------------------------

--
-- Table structure for table `stock_movements`
--


--
-- Dumping data for table `stock_movements`
--



-- stock_movements
INSERT IGNORE INTO `stock_movements` (`movement_id`, `product_id`, `movement_type`, `quantity`, `previous_stock`, `new_stock`, `reference_type`, `reference_id`, `notes`, `created_by`, `created_at`) VALUES
(1, 1, 'IN', 14, 0, 14, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(2, 2, 'IN', 25, 0, 25, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(3, 3, 'IN', 28, 0, 28, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(4, 4, 'IN', 20, 0, 20, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(5, 5, 'IN', 17, 0, 17, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(6, 6, 'IN', 12, 0, 12, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(7, 7, 'IN', 10, 0, 10, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(8, 8, 'IN', 22, 0, 22, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(9, 9, 'IN', 8, 0, 8, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(10, 10, 'IN', 12, 0, 12, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(11, 11, 'IN', 18, 0, 18, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(12, 12, 'IN', 10, 0, 10, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(13, 13, 'IN', 25, 0, 25, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(14, 14, 'IN', 8, 0, 8, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(15, 15, 'IN', 5, 0, 5, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(16, 16, 'IN', 20, 0, 20, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(17, 17, 'IN', 7, 0, 7, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(18, 18, 'IN', 30, 0, 30, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(19, 19, 'IN', 20, 0, 20, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(20, 20, 'IN', 15, 0, 15, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(21, 21, 'IN', 10, 0, 10, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(22, 22, 'IN', 5, 0, 5, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(23, 23, 'IN', 20, 0, 20, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(24, 24, 'IN', 18, 0, 18, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(25, 25, 'IN', 12, 0, 12, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(26, 26, 'IN', 15, 0, 15, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(27, 27, 'IN', 8, 0, 8, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(28, 28, 'IN', 20, 0, 20, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(29, 29, 'IN', 18, 0, 18, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(30, 30, 'IN', 15, 0, 15, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(31, 31, 'IN', 12, 0, 12, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(32, 32, 'IN', 10, 0, 10, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(33, 33, 'IN', 16, 0, 16, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(34, 34, 'IN', 14, 0, 14, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(35, 35, 'IN', 12, 0, 12, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(36, 36, 'IN', 18, 0, 18, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(37, 37, 'IN', 25, 0, 25, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(38, 38, 'IN', 30, 0, 30, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(39, 39, 'IN', 20, 0, 20, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(40, 40, 'IN', 22, 0, 22, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(41, 41, 'IN', 100, 0, 100, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(42, 42, 'IN', 50, 0, 50, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(43, 43, 'IN', 200, 0, 200, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(44, 44, 'IN', 75, 0, 75, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(45, 45, 'IN', 30, 0, 30, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(46, 46, 'IN', 40, 0, 40, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(47, 47, 'IN', 15, 0, 15, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(48, 48, 'IN', 60, 0, 60, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(49, 49, 'IN', 45, 0, 45, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(50, 50, 'IN', 40, 0, 40, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(51, 51, 'IN', 45, 0, 45, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(52, 52, 'IN', 60, 0, 60, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(53, 53, 'IN', 30, 0, 30, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(54, 54, 'IN', 55, 0, 55, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(55, 55, 'IN', 25, 0, 25, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(56, 56, 'IN', 75, 0, 75, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(57, 57, 'IN', 40, 0, 40, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(58, 58, 'IN', 60, 0, 60, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(59, 59, 'IN', 45, 0, 45, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(60, 60, 'IN', 79, 0, 79, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(61, 61, 'IN', 35, 0, 35, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(62, 62, 'IN', 40, 0, 40, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(63, 63, 'IN', 35, 0, 35, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(64, 64, 'IN', 50, 0, 50, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(65, 65, 'IN', 80, 0, 80, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(66, 66, 'IN', 70, 0, 70, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(67, 67, 'IN', 55, 0, 55, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(68, 68, 'IN', 50, 0, 50, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(69, 69, 'IN', 30, 0, 30, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(70, 70, 'IN', 65, 0, 65, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(71, 71, 'IN', 40, 0, 40, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(72, 72, 'IN', 35, 0, 35, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(73, 73, 'IN', 55, 0, 55, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(74, 74, 'IN', 25, 0, 25, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(75, 75, 'IN', 30, 0, 30, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(76, 76, 'IN', 50, 0, 50, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(77, 77, 'IN', 40, 0, 40, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(78, 78, 'IN', 16, 0, 16, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(79, 81, 'IN', 15, 0, 15, 'INITIAL', NULL, 'Initial stock entry from existing data', NULL, '2026-03-04 09:38:39'),
(80, 5, 'OUT', 2, 17, 15, 'SALE', 22, 'Order shipment deduction', 1, '2026-03-04 10:05:10'),
(81, 5, 'IN', 2, 15, 17, 'RETURN', 22, 'Customer return restocked', 1, '2026-03-04 10:28:44'),
(82, 60, 'OUT', 4, 79, 75, 'SALE', 25, 'Order shipment deduction', 1, '2026-03-04 10:42:15'),
(83, 60, 'IN', 4, 75, 79, 'RETURN', 25, 'Return and quality check passed', 1, '2026-03-04 11:02:19'),
(84, 47, 'OUT', 1, 15, 14, 'DAMAGE', NULL, 'Transit damage adjustment', 1, '2026-03-04 11:14:06'),
(85, 47, 'IN', 1, 14, 15, 'ADJUSTMENT', NULL, 'Manual correction after recount', 1, '2026-03-04 11:33:52'),
(86, 15, 'OUT', 1, 5, 4, 'SALE', 24, 'Order reservation', 1, '2026-03-04 11:47:01'),
(87, 15, 'IN', 1, 4, 5, 'RETURN', 24, 'Cancelled order returned to stock', 1, '2026-03-04 12:06:37'),
(88, 22, 'IN', 3, 5, 8, 'PURCHASE', 1001, 'Supplier refill batch', 1, '2026-03-04 12:24:20'),
(89, 22, 'OUT', 3, 8, 5, 'SALE', 26, 'Allocated to priority order', 1, '2026-03-04 12:41:09'),
(128, 84, 'OUT', 10, 10, 0, 'ADJUSTMENT', NULL, 'Auto-tracked: Stock changed from 10 to 0', NULL, '2026-03-27 10:22:18'),
(129, 90, 'OUT', 3, 3, 0, 'ADJUSTMENT', NULL, 'Auto-tracked: Stock changed from 3 to 0', NULL, '2026-03-27 10:26:23'),
(130, 97, 'OUT', 3, 3, 0, 'ADJUSTMENT', NULL, 'Auto-tracked: Stock changed from 3 to 0', NULL, '2026-03-27 11:08:36'),
(131, 51, 'OUT', 1, 45, 44, 'ADJUSTMENT', NULL, 'Auto-tracked: Stock changed from 45 to 44', NULL, '2026-03-27 14:23:10'),
(132, 51, 'OUT', 1, 44, 43, 'ADJUSTMENT', NULL, 'Auto-tracked: Stock changed from 44 to 43', NULL, '2026-03-27 14:23:16'),
(133, 51, 'OUT', 1, 43, 42, 'ADJUSTMENT', NULL, 'Auto-tracked: Stock changed from 43 to 42', NULL, '2026-03-27 14:23:20'),
(134, 51, 'OUT', 1, 42, 41, 'ADJUSTMENT', NULL, 'Auto-tracked: Stock changed from 42 to 41', NULL, '2026-03-27 14:23:25'),
(135, 51, 'OUT', 1, 41, 40, 'ADJUSTMENT', NULL, 'Auto-tracked: Stock changed from 41 to 40', NULL, '2026-03-27 14:23:30'),
(136, 51, 'OUT', 1, 40, 39, 'ADJUSTMENT', NULL, 'Auto-tracked: Stock changed from 40 to 39', NULL, '2026-03-27 14:23:35'),
(137, 51, 'OUT', 1, 39, 38, 'ADJUSTMENT', NULL, 'Auto-tracked: Stock changed from 39 to 38', NULL, '2026-03-27 14:23:39'),
(138, 51, 'OUT', 1, 38, 37, 'ADJUSTMENT', NULL, 'Auto-tracked: Stock changed from 38 to 37', NULL, '2026-03-27 14:23:44'),
(139, 5, 'OUT', 1, 17, 16, 'ADJUSTMENT', NULL, 'Auto-tracked: Stock changed from 17 to 16', NULL, '2026-03-29 17:23:35'),
(140, 108, 'OUT', 5, 12, 7, 'ADJUSTMENT', NULL, 'Auto-tracked: Stock changed from 12 to 7', NULL, '2026-03-29 17:50:12');

--
-- Triggers `stock_movements`
--
DELIMITER $$
CREATE TRIGGER `after_stock_movement_insert` AFTER INSERT ON `stock_movements` FOR EACH ROW BEGIN
  DECLARE current_stock INT;
  DECLARE min_threshold INT;
  DECLARE alert_type_val VARCHAR(20);
  
  
  SELECT stock_quantity, min_stock_threshold 
  INTO current_stock, min_threshold
  FROM products 
  WHERE product_id = NEW.product_id;
  
  
  IF current_stock <= 0 THEN
    SET alert_type_val = 'OUT_OF_STOCK';
  ELSEIF current_stock <= min_threshold THEN
    SET alert_type_val = 'LOW_STOCK';
  ELSE
    SET alert_type_val = NULL;
  END IF;
  
  
  IF alert_type_val IS NOT NULL THEN
    INSERT INTO stock_alerts (
      product_id,
      alert_type,
      threshold_quantity,
      current_quantity,
      is_resolved
    ) VALUES (
      NEW.product_id,
      alert_type_val,
      min_threshold,
      current_stock,
      FALSE
    )
    ON DUPLICATE KEY UPDATE
      current_quantity = current_stock,
      is_resolved = FALSE,
      created_at = CURRENT_TIMESTAMP;
  END IF;
END
$$
DELIMITER ;



-- -----------------------------------------------------------
-- AUTO_INCREMENT values (so new records continue from correct IDs)
-- -----------------------------------------------------------
ALTER TABLE `banners` MODIFY `banner_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;
ALTER TABLE `brands` MODIFY `brand_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=96;
ALTER TABLE `cart` MODIFY `cart_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;
ALTER TABLE `categories` MODIFY `category_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;
ALTER TABLE `collections` MODIFY `collection_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;
ALTER TABLE `collection_items` MODIFY `item_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;
ALTER TABLE `csrf_tokens` MODIFY `token_id` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `customer_support` MODIFY `ticket_id` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `deals_of_the_day` MODIFY `deal_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=37;
ALTER TABLE `deals_timer` MODIFY `timer_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;
ALTER TABLE `discounts` MODIFY `discount_id` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `flash_sales` MODIFY `flash_sale_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;
ALTER TABLE `flash_sale_products` MODIFY `flash_sale_product_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;
ALTER TABLE `orders` MODIFY `order_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=41;
ALTER TABLE `order_items` MODIFY `order_item_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=30;
ALTER TABLE `password_reset_tokens` MODIFY `token_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;
ALTER TABLE `payments` MODIFY `payment_id` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `payment_methods` MODIFY `method_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;
ALTER TABLE `products` MODIFY `product_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=109;
ALTER TABLE `product_ratings` MODIFY `rating_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=128;
ALTER TABLE `product_reviews` MODIFY `review_id` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `product_specifications` MODIFY `spec_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=192;
ALTER TABLE `promotions` MODIFY `promotion_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;
ALTER TABLE `rate_limits` MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `reports` MODIFY `report_id` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `reviews` MODIFY `review_id` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `search_analytics` MODIFY `analytics_id` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `search_history` MODIFY `search_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;
ALTER TABLE `search_suggestions` MODIFY `suggestion_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=201;
ALTER TABLE `stock_alerts` MODIFY `alert_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;
ALTER TABLE `stock_movements` MODIFY `movement_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=141;
ALTER TABLE `trending_products` MODIFY `trending_product_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=50;
ALTER TABLE `users` MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;
ALTER TABLE `wishlists` MODIFY `wishlist_id` int(11) NOT NULL AUTO_INCREMENT;

SET FOREIGN_KEY_CHECKS = 1;
COMMIT;


