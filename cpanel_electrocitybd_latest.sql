-- ============================================================
-- ElectrocityBD Production Database Export for cPanel / phpMyAdmin
-- Exported on: 2026-09-12 19:00:30 (UTC)
-- Target: cPanel MySQL / phpMyAdmin / MariaDB / MySQL 5.7+ / 8.0+
-- 
-- INSTRUCTIONS FOR CPANEL HOSTING IMPORT:
-- 1. Log in to your cPanel control panel (e.g. yourdomain.com/cpanel).
-- 2. Under "Databases", click "MySQL Databases".
-- 3. Create a new database (e.g. youruser_electrobd).
-- 4. Create a MySQL user and password, then add the user to the database with "ALL PRIVILEGES".
-- 5. Return to cPanel home and open "phpMyAdmin".
-- 6. Select your newly created database from the left navigation tree.
-- 7. Click the "Import" tab on the top menu bar.
-- 8. Click "Choose File" and select this file ("cpanel_electrocitybd_latest.sql").
-- 9. Keep default format (SQL) and click "Import" at the bottom.
-- 10. Update backend/.env or config.php on cPanel with your database name, user, and password.
-- ============================================================

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;


-- --------------------------------------------------------
-- Table structure for table `categories`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `categories`;
CREATE TABLE `categories` (
  `category_id` int NOT NULL AUTO_INCREMENT,
  `category_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `category_image` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`category_id`),
  UNIQUE KEY `idx_category_name_unique` (`category_name`),
  FULLTEXT KEY `ft_category_name` (`category_name`)
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `categories` (`category_id`, `category_name`, `category_image`) VALUES
(16, 'Home Appliances', NULL),
(17, 'Kitchen Appliances', NULL),
(18, 'Personal Care', NULL),
(19, 'Fans & Coolers', NULL),
(20, 'Lighting', NULL),
(21, 'Electronics', NULL),
(22, 'Blenders & Mixers', NULL),
(23, 'Irons & Steamers', NULL),
(24, 'Rice Cookers', NULL),
(25, 'Air Fryers', NULL);


-- --------------------------------------------------------
-- Table structure for table `brands`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `brands`;
CREATE TABLE `brands` (
  `brand_id` int NOT NULL AUTO_INCREMENT,
  `brand_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `brand_logo` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`brand_id`),
  UNIQUE KEY `idx_brand_name_unique` (`brand_name`),
  FULLTEXT KEY `ft_brand_name` (`brand_name`)
) ENGINE=InnoDB AUTO_INCREMENT=106 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `brands` (`brand_id`, `brand_name`, `brand_logo`) VALUES
(96, 'Miyoko', 'assets/Brand Logo/images (1).jpg'),
(97, 'Walton', 'assets/Brand Logo/walton.png'),
(98, 'Singer', 'assets/Brand Logo/singer.png'),
(99, 'LG', 'assets/Brand Logo/LG.png'),
(100, 'Panasonic', 'assets/Brand Logo/panasonnic.png'),
(101, 'Gree', 'assets/Brand Logo/Gree.png'),
(102, 'Pink Panther', 'assets/Brand Logo/images (2).png'),
(103, 'Nima', 'assets/Brand Logo/images (3).png'),
(104, 'Sokany', 'assets/Brand Logo/images (4).png'),
(105, 'Kennede', 'assets/Brand Logo/images (5).png');


-- --------------------------------------------------------
-- Table structure for table `collections`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `collections`;
CREATE TABLE `collections` (
  `collection_id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `slug` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `description` text COLLATE utf8mb4_unicode_ci,
  `icon` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `image_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `item_count` int DEFAULT '0',
  `is_active` tinyint(1) DEFAULT '1',
  `display_order` int DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`collection_id`),
  UNIQUE KEY `slug` (`slug`)
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `collections` (`collection_id`, `name`, `slug`, `description`, `icon`, `image_url`, `item_count`, `is_active`, `display_order`, `created_at`) VALUES
(16, 'Fans', 'fans', NULL, 'air', NULL, 1, 1, 1, '2026-09-03 17:10:04'),
(17, 'Kitchen', 'kitchen', NULL, 'kitchen', NULL, 3, 1, 2, '2026-09-03 17:10:04'),
(18, 'Personal Care', 'personal-care', NULL, 'spa', NULL, 2, 1, 3, '2026-09-03 17:10:04'),
(19, 'Blenders', 'blenders', NULL, 'blender', NULL, 3, 1, 4, '2026-09-03 17:10:04');


-- --------------------------------------------------------
-- Table structure for table `collection_items`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `collection_items`;
CREATE TABLE `collection_items` (
  `item_id` int NOT NULL AUTO_INCREMENT,
  `collection_id` int NOT NULL,
  `item_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `display_order` int DEFAULT '0',
  PRIMARY KEY (`item_id`),
  KEY `collection_id` (`collection_id`),
  CONSTRAINT `collection_items_ibfk_1` FOREIGN KEY (`collection_id`) REFERENCES `collections` (`collection_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------
-- Table structure for table `users`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `user_id` int NOT NULL AUTO_INCREMENT,
  `full_name` varchar(100) NOT NULL,
  `last_name` varchar(100) DEFAULT '',
  `email` varchar(150) NOT NULL,
  `password` varchar(255) NOT NULL,
  `phone_number` varchar(20) DEFAULT '',
  `address` text,
  `gender` enum('Male','Female','Other') DEFAULT 'Male',
  `role` enum('customer','admin') DEFAULT 'customer',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `users` (`user_id`, `full_name`, `last_name`, `email`, `password`, `phone_number`, `address`, `gender`, `role`, `created_at`) VALUES
(2, 'Noman Admin', '', 'noman@admin_electrozone.com', '$2y$10$C0.liivgmh/fNd/f94y0wOrDUFF3r50i34kylma1rWIMeHCfVsIYq', '', NULL, 'Male', 'admin', '2026-09-03 17:10:04'),
(3, 'Admin', '', 'admin@electrobd.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '', NULL, 'Male', 'admin', '2026-09-03 17:10:04'),
(4, 'Test', 'Customer', 'customer@test.com', '$2y$12$/DR.2KL0I4ER1OpAt/CIs.3RKPgfPVb0K1NGQiikTS/p5tuto1inS', '+8801712345678', NULL, 'Male', 'customer', '2026-09-03 18:32:56'),
(5, 'Admin Noman', '', 'adminNoman@electrozonebd.com', '$2y$12$a7kL/Ajes1T7GY1NDa4FEOEaz06Ag2QGTmsUjPxcoBUWK8QkCqM8O', '01700000001', NULL, 'Male', 'admin', '2026-09-13 01:00:09'),
(6, 'Super Admin Roz', '', 'superadmin_roz@electrozonebd.com', '$2y$12$V3IrAHgZLqrt7vGLJKJEwOAJpFE4M23O1KPffzJ93XMe9XPrQIfwK', '01700000002', NULL, 'Male', 'admin', '2026-09-13 01:00:09'),
(7, 'Super Admin EZ', '', 'superadmin@ez.com', '$2y$12$dX/BFd4P7Y/nsH1C21E18.b0WOfBICLCauJNaV3PH8yfMJxc658b2', '01700000003', NULL, 'Male', 'admin', '2026-09-13 01:00:09');


-- --------------------------------------------------------
-- Table structure for table `user_profile`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `user_profile`;
CREATE TABLE `user_profile` (
  `user_id` int NOT NULL,
  `full_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `phone_number` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address` text COLLATE utf8mb4_unicode_ci,
  `gender` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT 'Male',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  CONSTRAINT `user_profile_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------
-- Table structure for table `products`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `products`;
CREATE TABLE `products` (
  `product_id` int NOT NULL AUTO_INCREMENT,
  `category_id` int DEFAULT NULL,
  `brand_id` int DEFAULT NULL,
  `product_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `price` decimal(10,2) NOT NULL,
  `regular_price` decimal(10,2) DEFAULT NULL,
  `stock_quantity` int DEFAULT '0',
  `image_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `specs_json` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `min_stock_threshold` int DEFAULT '5',
  `max_stock_threshold` int DEFAULT '1000',
  `stock_status` enum('IN_STOCK','LOW_STOCK','OUT_OF_STOCK') COLLATE utf8mb4_unicode_ci GENERATED ALWAYS AS ((case when (`stock_quantity` <= 0) then _utf8mb4'OUT_OF_STOCK' when (`stock_quantity` <= `min_stock_threshold`) then _utf8mb4'LOW_STOCK' else _utf8mb4'IN_STOCK' end)) STORED,
  PRIMARY KEY (`product_id`),
  KEY `idx_products_category` (`category_id`),
  KEY `idx_products_brand` (`brand_id`),
  KEY `idx_products_name` (`product_name`),
  KEY `idx_stock_status` (`stock_status`),
  KEY `idx_stock_quantity` (`stock_quantity`),
  KEY `idx_price` (`price`),
  KEY `idx_created_at` (`created_at`),
  FULLTEXT KEY `ft_product_search` (`product_name`,`description`),
  CONSTRAINT `products_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `categories` (`category_id`) ON DELETE SET NULL,
  CONSTRAINT `products_ibfk_2` FOREIGN KEY (`brand_id`) REFERENCES `brands` (`brand_id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=129 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `products` (`product_id`, `category_id`, `brand_id`, `product_name`, `description`, `price`, `regular_price`, `stock_quantity`, `image_url`, `specs_json`, `created_at`, `min_stock_threshold`, `max_stock_threshold`, `stock_status`) VALUES
(109, 22, 96, 'Miyoko Blender 600W', 'High-power 600W blender for smoothies, juices and shakes. 1.5L jar.', '1800.00', '2250.00', 50, 'assets/prod/blender.jpg', NULL, '2026-09-03 17:10:04', 5, 1000, 'IN_STOCK'),
(110, 25, 97, 'Air Fryer 5L Digital', 'Oil-free healthy cooking, 5 litre capacity, 8 preset programs, digital touch panel.', '4500.00', '5625.00', 3, 'assets/prod/air_fryer.jpg', NULL, '2026-09-03 17:10:04', 5, 1000, 'LOW_STOCK'),
(111, 19, 105, 'Kennede Charger Fan', 'Rechargeable fan with LED light, USB charging, 3 speed settings, 8 hour backup.', '1200.00', '1500.00', 80, 'assets/prod/chargerfan.jpg', NULL, '2026-09-03 17:10:04', 5, 1000, 'IN_STOCK'),
(112, 24, 96, 'Rice Cooker 1.8L', 'Automatic electric rice cooker with keep-warm function, non-stick inner pot.', '2200.00', '2750.00', 59, 'assets/prod/rice_cooker.jpg', NULL, '2026-09-03 17:10:04', 5, 1000, 'IN_STOCK'),
(113, 22, 102, 'Hand Blender 300W', 'Immersion blender 300W with stainless steel blade, detachable shaft.', '1500.00', '1875.00', 45, 'assets/prod/hand_blender.jpg', NULL, '2026-09-03 17:10:04', 5, 1000, 'IN_STOCK'),
(114, 23, 98, 'Electric Steam Iron', 'Steam iron 2200W with non-stick soleplate, self-clean function.', '1100.00', '1375.00', 70, 'assets/prod/iron.jpg', NULL, '2026-09-03 17:10:04', 5, 1000, 'IN_STOCK'),
(115, 17, 96, 'Mini Cooker 1.5L', 'Compact electric cooker for small portions, auto shut-off.', '1600.00', '2000.00', 40, 'assets/prod/mini_cooker.jpg', NULL, '2026-09-03 17:10:04', 5, 1000, 'IN_STOCK'),
(116, 18, 104, 'Sokany Hair Dryer 1800W', 'Professional hair dryer 1800W with cool shot button, 2 speed settings.', '1300.00', '1625.00', 55, 'assets/prod/hair_drier.jpg', NULL, '2026-09-03 17:10:04', 5, 1000, 'IN_STOCK'),
(117, 17, 99, 'Induction Stove 2000W', '2000W induction cooktop with 8 power levels, child lock, timer.', '3200.00', '4000.00', 25, 'assets/prod/induction_stove.jpg', NULL, '2026-09-03 17:10:04', 5, 1000, 'IN_STOCK'),
(118, 22, 103, 'Nima Grinder 400W', 'Dry and wet grinder 400W with stainless steel jar, 3 jars included.', '1900.00', '2375.00', 35, 'assets/prod/grinder.jpg', NULL, '2026-09-03 17:10:04', 5, 1000, 'IN_STOCK'),
(119, 17, 96, 'Miyoko Oven 25L', '25 litre electric oven with rotisserie, convection, 6 cooking functions.', '5500.00', '6875.00', 20, 'assets/prod/oven.jpg', NULL, '2026-09-03 17:10:04', 5, 1000, 'IN_STOCK'),
(120, 17, 96, 'Curry Cooker 1.5L', 'Multi-function curry cooker 1.5L, non-stick coating, glass lid.', '1400.00', '1750.00', 50, 'assets/prod/curry_cooker.jpg', NULL, '2026-09-03 17:10:04', 5, 1000, 'IN_STOCK'),
(121, 18, 102, 'Head Massager Electric', 'Electric scalp massager with 4 massage heads, 2 speed settings.', '900.00', '1125.00', 90, 'assets/prod/head_massager.jpg', NULL, '2026-09-03 17:10:04', 5, 1000, 'IN_STOCK'),
(122, 18, 97, 'Deep Tissue Massage Gun Pro', 'Deep tissue percussion massage gun with 6 speed settings, 4 massage attachments, 2400mAh battery.', '3500.00', '4375.00', 15, 'assets/prod/massage_gun.jpg', NULL, '2026-09-03 17:10:04', 5, 1000, 'IN_STOCK'),
(123, 17, 98, 'Electric Stove 2-Burner', '2-burner electric stove 2500W, cast iron heating plate, overheat protection.', '2800.00', '3500.00', 30, 'assets/prod/elec_stove.jpg', NULL, '2026-09-03 17:10:04', 5, 1000, 'IN_STOCK'),
(124, 18, 99, 'Trimmer Pro Rechargeable', 'Rechargeable hair trimmer with 4 guide combs, 60 min runtime.', '1600.00', '2000.00', 65, 'assets/prod/trimmer.jpg', NULL, '2026-09-03 17:10:04', 5, 1000, 'IN_STOCK'),
(125, 24, 97, 'Rice Cooker 2.8L Large', 'Large capacity rice cooker 2.8L with steamer basket, keep-warm.', '2800.00', '3500.00', 40, 'assets/prod/riceCooker2.jpg', NULL, '2026-09-03 17:10:04', 5, 1000, 'IN_STOCK'),
(126, 22, 96, 'Hand Blender Pro 500W', 'Professional hand blender 500W with whisk and chopper attachments.', '2200.00', '2750.00', 30, 'assets/prod/hand_blender23.jpg', NULL, '2026-09-03 17:10:04', 5, 1000, 'IN_STOCK'),
(127, 17, 96, 'Mini Cooker Multi 1.8L', 'Compact multi-cooker 1.8L with non-stick coating, steam, boil, fry.', '1800.00', '2250.00', 45, 'assets/prod/mini2cokker.jpg', NULL, '2026-09-03 17:10:04', 5, 1000, 'IN_STOCK'),
(128, 22, 103, 'Food Chopper 300W', 'Electric food chopper 300W with 1.2L bowl, stainless steel blades.', '1200.00', '1500.00', 55, 'assets/prod/chopper.jpg', NULL, '2026-09-03 17:10:04', 5, 1000, 'IN_STOCK');


-- --------------------------------------------------------
-- Table structure for table `product_specifications`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `product_specifications`;
CREATE TABLE `product_specifications` (
  `spec_id` int NOT NULL AUTO_INCREMENT,
  `product_id` int NOT NULL,
  `spec_key` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `spec_value` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `display_order` int DEFAULT '0',
  PRIMARY KEY (`spec_id`),
  KEY `idx_product_specs` (`product_id`),
  CONSTRAINT `product_specifications_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=192 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------
-- Table structure for table `product_reviews`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `product_reviews`;
CREATE TABLE `product_reviews` (
  `review_id` int NOT NULL AUTO_INCREMENT,
  `product_id` int NOT NULL,
  `user_id` int NOT NULL,
  `rating` int NOT NULL,
  `review_text` text COLLATE utf8mb4_unicode_ci,
  `review_title` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_verified_purchase` tinyint(1) DEFAULT '0',
  `helpful_count` int DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`review_id`),
  KEY `idx_product_id` (`product_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_rating` (`rating`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `product_reviews_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE,
  CONSTRAINT `product_reviews_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `product_reviews_chk_1` CHECK ((`rating` between 1 and 5))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------
-- Table structure for table `product_ratings`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `product_ratings`;
CREATE TABLE `product_ratings` (
  `rating_id` int NOT NULL AUTO_INCREMENT,
  `product_id` int NOT NULL,
  `rating_avg` decimal(3,2) DEFAULT '0.00',
  `review_count` int DEFAULT '0',
  `rating_1_star` int DEFAULT '0',
  `rating_2_star` int DEFAULT '0',
  `rating_3_star` int DEFAULT '0',
  `rating_4_star` int DEFAULT '0',
  `rating_5_star` int DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`rating_id`),
  UNIQUE KEY `unique_product_rating` (`product_id`),
  CONSTRAINT `product_ratings_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=128 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------
-- Table structure for table `collection_products`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `collection_products`;
CREATE TABLE `collection_products` (
  `collection_id` int NOT NULL,
  `product_id` int NOT NULL,
  `added_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`collection_id`,`product_id`),
  KEY `product_id` (`product_id`),
  CONSTRAINT `collection_products_ibfk_1` FOREIGN KEY (`collection_id`) REFERENCES `collections` (`collection_id`) ON DELETE CASCADE,
  CONSTRAINT `collection_products_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `collection_products` (`collection_id`, `product_id`, `added_at`) VALUES
(16, 111, '2026-09-11 15:20:38'),
(17, 110, '2026-09-11 15:20:38'),
(17, 120, '2026-09-11 15:20:38'),
(17, 123, '2026-09-11 15:20:38'),
(18, 116, '2026-09-11 15:20:38'),
(18, 121, '2026-09-11 15:20:38'),
(19, 109, '2026-09-11 15:20:38'),
(19, 113, '2026-09-11 15:20:38'),
(19, 126, '2026-09-11 15:20:38');


-- --------------------------------------------------------
-- Table structure for table `banners`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `banners`;
CREATE TABLE `banners` (
  `banner_id` int NOT NULL AUTO_INCREMENT,
  `banner_type` enum('hero','mid','sidebar') COLLATE utf8mb4_unicode_ci NOT NULL,
  `image_url` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `link_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `title` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `button_text` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `display_order` int DEFAULT '0',
  `active` tinyint(1) DEFAULT '1',
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`banner_id`)
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `banners` (`banner_id`, `banner_type`, `image_url`, `link_url`, `title`, `description`, `button_text`, `display_order`, `active`, `start_date`, `end_date`, `created_at`, `updated_at`) VALUES
(1, 'hero', 'assets/1.png', NULL, 'Eid Special Offers', NULL, 'Shop Now', 1, 1, NULL, NULL, '2026-09-03 17:10:04', '2026-09-03 17:10:04'),
(2, 'hero', 'assets/2.png', NULL, 'New Arrivals', NULL, 'Explore', 2, 1, NULL, NULL, '2026-09-03 17:10:04', '2026-09-03 17:10:04'),
(3, 'hero', 'assets/3.png', NULL, 'Flash Sale Live', NULL, 'Grab Now', 3, 1, NULL, NULL, '2026-09-03 17:10:04', '2026-09-03 17:10:04'),
(15, 'mid', '/api/public/uploads/img_6aa3b8ad5ecce7.03654027.jpg', '/deals', 'Banner 1', '', 'Shop Now', 1, 1, '2026-09-11', '2027-09-11', '2026-09-11 14:16:49', '2026-09-11 14:16:49'),
(16, 'mid', '/api/public/uploads/img_6aa3b8b6a19397.66401137.jpg', '/deals', 'Banner 2', '', 'Shop Now', 2, 1, '2026-09-11', '2027-09-11', '2026-09-11 14:16:49', '2026-09-11 14:16:49'),
(17, 'mid', '/api/public/uploads/img_6aa3b8bf8630d6.11042318.jpg', '/deals', 'Banner 3', '', 'Shop Now', 3, 1, '2026-09-11', '2027-09-11', '2026-09-11 14:16:49', '2026-09-11 14:16:49'),
(19, 'sidebar', '', '', 'FLASH SALE', 'upto 30% Discounts', 'View All', 0, 1, NULL, NULL, '2026-09-11 15:49:25', '2026-09-11 15:49:25');


-- --------------------------------------------------------
-- Table structure for table `deals_timer`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `deals_timer`;
CREATE TABLE `deals_timer` (
  `timer_id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Timer',
  `description` text COLLATE utf8mb4_unicode_ci,
  `end_time` datetime DEFAULT NULL,
  `days` int DEFAULT '3',
  `hours` int DEFAULT '11',
  `minutes` int DEFAULT '15',
  `seconds` int DEFAULT '0',
  `is_active` tinyint(1) DEFAULT '1',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`timer_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `deals_timer` (`timer_id`, `title`, `description`, `end_time`, `days`, `hours`, `minutes`, `seconds`, `is_active`, `updated_at`) VALUES
(3, 'Offers New Year', 'New Offers', '2026-09-14 19:16:00', 0, 0, 0, 0, 0, '2026-09-11 15:23:38');


-- --------------------------------------------------------
-- Table structure for table `deals_of_the_day`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `deals_of_the_day`;
CREATE TABLE `deals_of_the_day` (
  `deal_id` int NOT NULL AUTO_INCREMENT,
  `product_id` int DEFAULT NULL,
  `deal_price` decimal(10,2) DEFAULT NULL,
  `start_date` datetime DEFAULT NULL,
  `end_date` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`deal_id`),
  KEY `product_id` (`product_id`),
  KEY `idx_deals_created` (`created_at`),
  CONSTRAINT `deals_of_the_day_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=43 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `deals_of_the_day` (`deal_id`, `product_id`, `deal_price`, `start_date`, `end_date`, `created_at`) VALUES
(37, 121, '720.00', NULL, '2027-09-03 17:10:04', '2026-09-03 17:10:04'),
(38, 114, '880.00', NULL, '2027-09-03 17:10:04', '2026-09-03 17:10:04'),
(39, 111, '960.00', NULL, '2027-09-03 17:10:04', '2026-09-03 17:10:04'),
(40, 128, '960.00', NULL, '2027-09-03 17:10:04', '2026-09-03 17:10:04'),
(41, 116, '1040.00', NULL, '2027-09-03 17:10:04', '2026-09-03 17:10:04'),
(42, 120, '1120.00', NULL, '2027-09-03 17:10:04', '2026-09-03 17:10:04');


-- --------------------------------------------------------
-- Table structure for table `flash_sales`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `flash_sales`;
CREATE TABLE `flash_sales` (
  `flash_sale_id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `start_time` datetime NOT NULL,
  `end_time` datetime NOT NULL,
  `active` tinyint(1) DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`flash_sale_id`),
  KEY `idx_flash_sales_active` (`active`,`end_time`),
  KEY `idx_flash_sales_created` (`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `flash_sales` (`flash_sale_id`, `title`, `start_time`, `end_time`, `active`, `created_at`) VALUES
(2, 'Eid Special Flash Sale', '2026-09-03 17:10:04', '2026-09-10 17:10:04', 0, '2026-09-03 17:10:04');


-- --------------------------------------------------------
-- Table structure for table `flash_sale_products`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `flash_sale_products`;
CREATE TABLE `flash_sale_products` (
  `flash_sale_product_id` int NOT NULL AUTO_INCREMENT,
  `flash_sale_id` int NOT NULL,
  `product_id` int NOT NULL,
  `flash_price` decimal(10,2) NOT NULL,
  `image_path` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `display_order` int DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`flash_sale_product_id`),
  UNIQUE KEY `unique_flash_product` (`flash_sale_id`,`product_id`),
  KEY `product_id` (`product_id`),
  KEY `idx_flash_sale_products_order` (`display_order`),
  KEY `idx_flash_sale_products_created` (`created_at`),
  CONSTRAINT `flash_sale_products_ibfk_1` FOREIGN KEY (`flash_sale_id`) REFERENCES `flash_sales` (`flash_sale_id`) ON DELETE CASCADE,
  CONSTRAINT `flash_sale_products_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `flash_sale_products` (`flash_sale_product_id`, `flash_sale_id`, `product_id`, `flash_price`, `image_path`, `display_order`, `created_at`) VALUES
(15, 1, 109, '1350.00', 'assets/flash/av.jpg', 1, '2026-09-03 17:10:04'),
(16, 1, 110, '3375.00', NULL, 2, '2026-09-03 17:10:04'),
(17, 1, 111, '900.00', 'assets/flash/kennede.jpg', 3, '2026-09-03 17:10:04'),
(18, 1, 112, '1650.00', NULL, 4, '2026-09-03 17:10:04'),
(19, 1, 113, '1125.00', NULL, 5, '2026-09-03 17:10:04'),
(20, 1, 114, '825.00', NULL, 6, '2026-09-03 17:10:04');


-- --------------------------------------------------------
-- Table structure for table `trending_products`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `trending_products`;
CREATE TABLE `trending_products` (
  `trending_product_id` int NOT NULL AUTO_INCREMENT,
  `product_id` int NOT NULL,
  `trending_score` int DEFAULT '0',
  `image_path` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `display_order` int DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `last_updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`trending_product_id`),
  UNIQUE KEY `unique_trending_product` (`product_id`),
  KEY `idx_trending_products_order` (`display_order`),
  KEY `idx_trending_products_score` (`trending_score`),
  KEY `idx_trending_created` (`created_at`),
  CONSTRAINT `trending_products_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=65 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `trending_products` (`trending_product_id`, `product_id`, `trending_score`, `image_path`, `display_order`, `created_at`, `updated_at`, `last_updated`) VALUES
(50, 109, 101, 'assets/trends/blender.jpg', 1, '2026-09-03 17:10:04', '2026-09-13 00:14:03', '2026-09-13 00:14:03'),
(51, 110, 99, 'assets/trends/air_fryer.jpg', 2, '2026-09-03 17:10:04', '2026-09-13 00:15:31', '2026-09-13 00:15:31'),
(52, 111, 98, 'assets/trends/chargerfan.jpg', 3, '2026-09-03 17:10:04', '2026-09-13 00:15:31', '2026-09-13 00:15:31'),
(53, 112, 97, 'assets/trends/rice_cooker.jpg', 4, '2026-09-03 17:10:04', '2026-09-11 15:30:21', '2026-09-11 15:30:21'),
(54, 113, 95, 'assets/trends/hand_blender.jpg', 5, '2026-09-03 17:10:04', '2026-09-03 17:10:04', '2026-09-03 17:10:04'),
(55, 114, 94, 'assets/prod/iron.jpg', 6, '2026-09-03 17:10:04', '2026-09-03 17:10:04', '2026-09-03 17:10:04'),
(56, 115, 93, 'assets/trends/mini_cooker.jpg', 7, '2026-09-03 17:10:04', '2026-09-03 17:10:04', '2026-09-03 17:10:04'),
(57, 116, 92, 'assets/trends/hair_drier.jpg', 8, '2026-09-03 17:10:04', '2026-09-03 17:10:04', '2026-09-03 17:10:04'),
(58, 117, 91, 'assets/trends/elec_stove.jpg', 9, '2026-09-03 17:10:04', '2026-09-03 17:10:04', '2026-09-03 17:10:04'),
(59, 118, 90, 'assets/prod/grinder.jpg', 10, '2026-09-03 17:10:04', '2026-09-03 17:10:04', '2026-09-03 17:10:04');


-- --------------------------------------------------------
-- Table structure for table `best_sellers`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `best_sellers`;
CREATE TABLE `best_sellers` (
  `product_id` int NOT NULL,
  `sales_count` int DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `selling_point` text COLLATE utf8mb4_unicode_ci,
  `sales_strategy` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `last_updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`product_id`),
  KEY `idx_best_sellers_created` (`created_at`),
  CONSTRAINT `best_sellers_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `best_sellers` (`product_id`, `sales_count`, `created_at`, `selling_point`, `sales_strategy`, `last_updated`) VALUES
(109, 581, '2026-09-03 17:10:04', NULL, NULL, '2026-09-13 00:14:03'),
(110, 502, '2026-09-03 17:10:04', NULL, NULL, '2026-09-13 00:15:31'),
(111, 167, '2026-09-03 17:10:04', NULL, NULL, '2026-09-13 00:15:31'),
(112, 228, '2026-09-03 17:10:04', NULL, NULL, '2026-09-11 15:30:21');


-- --------------------------------------------------------
-- Table structure for table `tech_part_products`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `tech_part_products`;
CREATE TABLE `tech_part_products` (
  `product_id` int NOT NULL,
  `display_order` int DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`product_id`),
  KEY `idx_techpart_created` (`created_at`),
  CONSTRAINT `tech_part_products_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `tech_part_products` (`product_id`, `display_order`, `created_at`) VALUES
(109, 1, '2026-09-03 17:10:04'),
(110, 2, '2026-09-03 17:10:04'),
(111, 3, '2026-09-03 17:10:04'),
(112, 4, '2026-09-03 17:10:04'),
(113, 5, '2026-09-03 17:10:04'),
(114, 6, '2026-09-03 17:10:04'),
(115, 7, '2026-09-03 17:10:04'),
(116, 8, '2026-09-03 17:10:04'),
(117, 9, '2026-09-03 17:10:04'),
(118, 10, '2026-09-03 17:10:04');


-- --------------------------------------------------------
-- Table structure for table `payment_methods`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `payment_methods`;
CREATE TABLE `payment_methods` (
  `method_id` int NOT NULL AUTO_INCREMENT,
  `method_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `method_type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'mobile_banking',
  `is_enabled` tinyint(1) DEFAULT '1',
  `account_number` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `display_order` int DEFAULT '0',
  `icon_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`method_id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `payment_methods` (`method_id`, `method_name`, `method_type`, `is_enabled`, `account_number`, `display_order`, `icon_url`, `created_at`, `updated_at`) VALUES
(7, 'bKash', 'mobile_banking', 1, '', 1, 'assets/payments/baksh.png', '2026-09-03 17:10:04', '2026-09-11 22:02:27'),
(8, 'Nagad', 'mobile_banking', 1, '', 2, 'assets/payments/nagad.png', '2026-09-03 17:10:04', '2026-09-03 17:10:04'),
(9, 'Rocket', 'mobile_banking', 1, '', 3, 'assets/payments/rocket.png', '2026-09-03 17:10:04', '2026-09-03 17:10:04'),
(10, 'Upay', 'mobile_banking', 1, '', 4, 'assets/payments/upay.png', '2026-09-03 17:10:04', '2026-09-03 17:10:04'),
(11, 'Cash on Delivery', 'cash', 1, '', 5, '', '2026-09-03 17:10:04', '2026-09-03 17:10:04'),
(12, 'Visa', 'card', 0, '', 6, 'assets/payments/visa.png', '2026-09-03 17:10:04', '2026-09-11 01:40:30'),
(13, 'Mastercard', 'card', 0, '', 7, 'assets/payments/master.png', '2026-09-03 17:10:04', '2026-09-03 17:10:04');


-- --------------------------------------------------------
-- Table structure for table `orders`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `orders`;
CREATE TABLE `orders` (
  `order_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `customer_name` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `customer_phone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `total_amount` decimal(10,2) NOT NULL,
  `subtotal_amount` decimal(10,2) DEFAULT '0.00',
  `delivery_charge` decimal(10,2) DEFAULT '0.00',
  `delivery_zone` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `coupon_discount` decimal(10,2) DEFAULT '0.00',
  `coupon_code` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `order_status` enum('pending','processing','shipped','delivered','cancelled') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `payment_method` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT 'Cash on Delivery',
  `payment_status` enum('unpaid','paid') COLLATE utf8mb4_unicode_ci DEFAULT 'unpaid',
  `delivery_address` text COLLATE utf8mb4_unicode_ci,
  `transaction_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `estimated_delivery` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `order_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`order_id`),
  KEY `idx_orders_user` (`user_id`),
  KEY `idx_orders_date` (`order_date`),
  KEY `idx_orders_status` (`order_status`),
  CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=71 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `orders` (`order_id`, `user_id`, `customer_name`, `customer_phone`, `total_amount`, `subtotal_amount`, `delivery_charge`, `delivery_zone`, `coupon_discount`, `coupon_code`, `order_status`, `payment_method`, `payment_status`, `delivery_address`, `transaction_id`, `estimated_delivery`, `order_date`) VALUES
(41, 4, NULL, NULL, '3500.00', '0.00', '0.00', NULL, '0.00', NULL, 'pending', 'Bkash', 'unpaid', '123 Main Street, Dhaka', 'BKH-6a9968f8c7cb8', NULL, '2026-09-03 18:32:56'),
(42, 4, NULL, NULL, '7200.00', '0.00', '0.00', NULL, '0.00', NULL, 'processing', 'Card', 'paid', '456 Gulshan, Dhaka', 'CARD-6a9968f8c7cbb', NULL, '2026-09-03 18:32:56'),
(43, 4, NULL, NULL, '4800.00', '0.00', '0.00', NULL, '0.00', NULL, 'shipped', 'Nagad', 'paid', '789 Dhanmondi, Dhaka', 'NAG-6a9968f8c7cbc', NULL, '2026-09-03 18:32:56'),
(44, 4, NULL, NULL, '2100.00', '0.00', '0.00', NULL, '0.00', NULL, 'delivered', 'Rocket', 'paid', '321 Mirpur, Dhaka', 'RKT-6a9968f8c7cbd', NULL, '2026-09-03 18:32:56'),
(45, 4, NULL, NULL, '5600.00', '0.00', '0.00', NULL, '0.00', NULL, 'processing', 'Cash on Delivery', 'unpaid', '654 Banani, Dhaka', 'COD-6a9968f8c7cbe', NULL, '2026-09-03 18:32:56'),
(46, 4, NULL, NULL, '3809.00', '0.00', '0.00', NULL, '0.00', NULL, 'pending', 'Bkash', 'paid', 'Address 46, Dhaka', 'Bka-6a996b7b89073', NULL, '2026-09-03 18:43:39'),
(47, 4, NULL, NULL, '13167.00', '0.00', '0.00', NULL, '0.00', NULL, 'pending', 'Nagad', 'paid', 'Address 47, Dhaka', 'Nag-6a996b7b8a124', NULL, '2026-09-03 18:43:39'),
(48, 4, NULL, NULL, '3125.00', '0.00', '0.00', NULL, '0.00', NULL, 'processing', 'Rocket', 'paid', 'Address 48, Dhaka', 'Roc-6a996b7b8b087', NULL, '2026-09-03 18:43:39'),
(49, 4, NULL, NULL, '8374.00', '0.00', '0.00', NULL, '0.00', NULL, 'processing', 'Card', 'paid', 'Address 49, Dhaka', 'Car-6a996b7b8be90', NULL, '2026-09-03 18:43:39'),
(50, 4, NULL, NULL, '13310.00', '0.00', '0.00', NULL, '0.00', NULL, 'shipped', 'Cash on Delivery', 'unpaid', 'Address 50, Dhaka', 'Cas-6a996b7b8cc9c', NULL, '2026-09-03 18:43:39'),
(51, 4, NULL, NULL, '7625.00', '0.00', '0.00', NULL, '0.00', NULL, 'shipped', 'Bkash', 'paid', 'Address 51, Dhaka', 'Bka-6a996b7b8dac9', NULL, '2026-09-03 18:43:39'),
(53, 4, NULL, NULL, '3117.00', '0.00', '0.00', NULL, '0.00', NULL, 'delivered', 'Rocket', 'paid', 'Address 53, Dhaka', 'Roc-6a996b7b8f6f8', NULL, '2026-09-03 18:43:39'),
(54, 4, NULL, NULL, '9639.00', '0.00', '0.00', NULL, '0.00', NULL, 'delivered', 'Card', 'paid', 'Address 54, Dhaka', 'Car-6a996b7b905d6', NULL, '2026-09-03 18:43:39'),
(55, 4, NULL, NULL, '11437.00', '0.00', '0.00', NULL, '0.00', NULL, 'cancelled', 'Cash on Delivery', 'unpaid', 'Address 55, Dhaka', 'Cas-6a996b7b91333', NULL, '2026-09-03 18:43:39'),
(56, 4, NULL, NULL, '10286.00', '0.00', '0.00', NULL, '0.00', NULL, 'pending', 'Bkash', 'paid', 'Address 56, Dhaka', 'Bka-6a996b7b921f1', NULL, '2026-09-03 18:43:39'),
(57, 4, NULL, NULL, '8041.00', '0.00', '0.00', NULL, '0.00', NULL, 'pending', 'Nagad', 'paid', 'Address 57, Dhaka', 'Nag-6a996b7b92f94', NULL, '2026-09-03 18:43:39'),
(58, 4, NULL, NULL, '3853.00', '0.00', '0.00', NULL, '0.00', NULL, 'processing', 'Rocket', 'paid', 'Address 58, Dhaka', 'Roc-6a996b7b93e39', NULL, '2026-09-03 18:43:39'),
(59, 4, NULL, NULL, '9177.00', '0.00', '0.00', NULL, '0.00', NULL, 'processing', 'Card', 'paid', 'Address 59, Dhaka', 'Car-6a996b7b94ab5', NULL, '2026-09-03 18:43:39'),
(60, 4, NULL, NULL, '11588.00', '0.00', '0.00', NULL, '0.00', NULL, 'shipped', 'Cash on Delivery', 'unpaid', 'Address 60, Dhaka', 'Cas-6a996b7b9572a', NULL, '2026-09-03 18:43:39'),
(61, 4, NULL, NULL, '3319.00', '0.00', '0.00', NULL, '0.00', NULL, 'shipped', 'Bkash', 'paid', 'Address 61, Dhaka', 'Bka-6a996b7b96474', NULL, '2026-09-03 18:43:39'),
(62, 4, NULL, NULL, '9086.00', '0.00', '0.00', NULL, '0.00', NULL, 'delivered', 'Nagad', 'paid', 'Address 62, Dhaka', 'Nag-6a996b7b972a8', NULL, '2026-09-03 18:43:39'),
(63, 4, NULL, NULL, '8989.00', '0.00', '0.00', NULL, '0.00', NULL, 'delivered', 'Rocket', 'paid', 'Address 63, Dhaka', 'Roc-6a996b7b97f99', NULL, '2026-09-03 18:43:39'),
(64, 4, NULL, NULL, '6453.00', '0.00', '0.00', NULL, '0.00', NULL, 'delivered', 'Card', 'paid', 'Address 64, Dhaka', 'Car-6a996b7b98e42', NULL, '2026-09-03 18:43:39'),
(65, 4, NULL, NULL, '5494.00', '0.00', '0.00', NULL, '0.00', NULL, 'cancelled', 'Cash on Delivery', 'unpaid', 'Address 65, Dhaka', 'Cas-6a996b7b99c08', NULL, '2026-09-03 18:43:39'),
(66, 5, NULL, NULL, '2260.00', '0.00', '0.00', NULL, '0.00', NULL, 'pending', 'Cash on Delivery', 'unpaid', 'norda,dhaka', 'COD-1789119021224', '16 September 2026', '2026-09-11 15:30:21');


-- --------------------------------------------------------
-- Table structure for table `order_items`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `order_items`;
CREATE TABLE `order_items` (
  `order_item_id` int NOT NULL AUTO_INCREMENT,
  `order_id` int DEFAULT NULL,
  `product_id` int DEFAULT NULL,
  `product_name` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `quantity` int NOT NULL,
  `price_at_purchase` decimal(10,2) NOT NULL,
  `color` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT '',
  `image_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`order_item_id`),
  KEY `idx_order_items_order` (`order_id`),
  KEY `idx_product_id` (`product_id`),
  CONSTRAINT `order_items_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE,
  CONSTRAINT `order_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=60 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `order_items` (`order_item_id`, `order_id`, `product_id`, `product_name`, `quantity`, `price_at_purchase`, `color`, `image_url`) VALUES
(30, 41, 122, NULL, 2, '4972.00', '', NULL),
(31, 42, 112, NULL, 1, '2176.00', '', NULL),
(32, 43, 109, NULL, 2, '3555.00', '', NULL),
(33, 44, 124, NULL, 2, '2790.00', '', NULL),
(34, 45, 109, NULL, 3, '3550.00', '', NULL),
(35, 46, 117, NULL, 3, '1759.00', '', NULL),
(36, 47, 112, NULL, 2, '7464.00', '', NULL),
(37, 48, 112, NULL, 1, '2047.00', '', NULL),
(38, 49, 126, NULL, 4, '2809.00', '', NULL),
(39, 50, 126, NULL, 2, '4345.00', '', NULL),
(40, 51, 125, NULL, 2, '1394.00', '', NULL),
(42, 53, 127, NULL, 3, '4880.00', '', NULL),
(43, 54, 121, NULL, 5, '7924.00', '', NULL),
(44, 55, 123, NULL, 4, '3312.00', '', NULL),
(45, 56, 114, NULL, 5, '1307.00', '', NULL),
(46, 57, 116, NULL, 4, '7075.00', '', NULL),
(47, 58, 127, NULL, 5, '6692.00', '', NULL),
(48, 59, 122, NULL, 2, '7215.00', '', NULL),
(49, 60, 122, NULL, 2, '1712.00', '', NULL),
(50, 61, 111, NULL, 4, '6286.00', '', NULL),
(51, 62, 110, NULL, 2, '2879.00', '', NULL),
(52, 63, 119, NULL, 3, '2227.00', '', NULL),
(53, 64, 117, NULL, 1, '7713.00', '', NULL),
(54, 65, 119, NULL, 3, '1468.00', '', NULL),
(55, 66, 112, 'Rice Cooker 1.8L', 1, '2200.00', '', 'assets/prod/rice_cooker.jpg');


-- --------------------------------------------------------
-- Table structure for table `payments`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `payments`;
CREATE TABLE `payments` (
  `payment_id` int NOT NULL AUTO_INCREMENT,
  `order_id` int DEFAULT NULL,
  `payment_method` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `transaction_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `amount` decimal(10,2) DEFAULT NULL,
  `payment_status` enum('pending','completed','failed') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `payment_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`payment_id`),
  KEY `order_id` (`order_id`),
  CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------
-- Table structure for table `cart`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `cart`;
CREATE TABLE `cart` (
  `cart_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `product_id` int DEFAULT NULL,
  `quantity` int DEFAULT '1',
  `added_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`cart_id`),
  KEY `idx_cart_user` (`user_id`),
  KEY `idx_product_id` (`product_id`),
  CONSTRAINT `cart_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `cart_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------
-- Table structure for table `wishlists`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `wishlists`;
CREATE TABLE `wishlists` (
  `wishlist_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `product_id` int DEFAULT NULL,
  `added_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`wishlist_id`),
  KEY `idx_wishlists_user` (`user_id`),
  KEY `idx_product_id` (`product_id`),
  CONSTRAINT `wishlists_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `wishlists_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------
-- Table structure for table `search_suggestions`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `search_suggestions`;
CREATE TABLE `search_suggestions` (
  `suggestion_id` int NOT NULL AUTO_INCREMENT,
  `suggestion_text` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `suggestion_type` enum('product','category','brand','keyword') COLLATE utf8mb4_unicode_ci DEFAULT 'keyword',
  `search_count` int DEFAULT '0',
  `last_searched` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_active` tinyint(1) DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`suggestion_id`),
  UNIQUE KEY `suggestion_text` (`suggestion_text`),
  KEY `idx_suggestion_text` (`suggestion_text`),
  KEY `idx_search_count` (`search_count`),
  KEY `idx_type` (`suggestion_type`)
) ENGINE=InnoDB AUTO_INCREMENT=241 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `search_suggestions` (`suggestion_id`, `suggestion_text`, `suggestion_type`, `search_count`, `last_searched`, `is_active`, `created_at`) VALUES
(201, 'Air Fryer 5L Digital', 'product', 0, '2026-09-12 23:51:05', 1, '2026-09-12 23:51:05'),
(202, 'Curry Cooker 1.5L', 'product', 0, '2026-09-12 23:51:05', 1, '2026-09-12 23:51:05'),
(203, 'Deep Tissue Massage Gun Pro', 'product', 0, '2026-09-12 23:51:05', 1, '2026-09-12 23:51:05'),
(204, 'Electric Steam Iron', 'product', 0, '2026-09-12 23:51:05', 1, '2026-09-12 23:51:05'),
(205, 'Electric Stove 2-Burner', 'product', 0, '2026-09-12 23:51:05', 1, '2026-09-12 23:51:05'),
(206, 'Food Chopper 300W', 'product', 0, '2026-09-12 23:51:05', 1, '2026-09-12 23:51:05'),
(207, 'Hand Blender 300W', 'product', 0, '2026-09-12 23:51:05', 1, '2026-09-12 23:51:05'),
(208, 'Hand Blender Pro 500W', 'product', 0, '2026-09-12 23:51:05', 1, '2026-09-12 23:51:05'),
(209, 'Head Massager Electric', 'product', 0, '2026-09-12 23:51:05', 1, '2026-09-12 23:51:05'),
(210, 'Induction Stove 2000W', 'product', 0, '2026-09-12 23:51:05', 1, '2026-09-12 23:51:05'),
(211, 'Kennede Charger Fan', 'product', 0, '2026-09-12 23:51:05', 1, '2026-09-12 23:51:05'),
(212, 'Mini Cooker 1.5L', 'product', 0, '2026-09-12 23:51:05', 1, '2026-09-12 23:51:05'),
(213, 'Mini Cooker Multi 1.8L', 'product', 0, '2026-09-12 23:51:05', 1, '2026-09-12 23:51:05'),
(214, 'Miyoko Blender 600W', 'product', 0, '2026-09-12 23:51:06', 1, '2026-09-12 23:51:06'),
(215, 'Miyoko Oven 25L', 'product', 0, '2026-09-12 23:51:06', 1, '2026-09-12 23:51:06'),
(216, 'Nima Grinder 400W', 'product', 0, '2026-09-12 23:51:06', 1, '2026-09-12 23:51:06'),
(217, 'Rice Cooker 1.8L', 'product', 0, '2026-09-12 23:51:06', 1, '2026-09-12 23:51:06'),
(218, 'Rice Cooker 2.8L Large', 'product', 0, '2026-09-12 23:51:06', 1, '2026-09-12 23:51:06'),
(219, 'Sokany Hair Dryer 1800W', 'product', 0, '2026-09-12 23:51:06', 1, '2026-09-12 23:51:06'),
(220, 'Trimmer Pro Rechargeable', 'product', 0, '2026-09-12 23:51:06', 1, '2026-09-12 23:51:06'),
(221, 'Air Fryers', 'category', 0, '2026-09-12 23:51:06', 1, '2026-09-12 23:51:06'),
(222, 'Blenders & Mixers', 'category', 0, '2026-09-12 23:51:06', 1, '2026-09-12 23:51:06'),
(223, 'Electronics', 'category', 0, '2026-09-12 23:51:06', 1, '2026-09-12 23:51:06'),
(224, 'Fans & Coolers', 'category', 0, '2026-09-12 23:51:06', 1, '2026-09-12 23:51:06'),
(225, 'Home Appliances', 'category', 0, '2026-09-12 23:51:06', 1, '2026-09-12 23:51:06'),
(226, 'Irons & Steamers', 'category', 0, '2026-09-12 23:51:06', 1, '2026-09-12 23:51:06'),
(227, 'Kitchen Appliances', 'category', 0, '2026-09-12 23:51:06', 1, '2026-09-12 23:51:06'),
(228, 'Lighting', 'category', 0, '2026-09-12 23:51:06', 1, '2026-09-12 23:51:06'),
(229, 'Personal Care', 'category', 0, '2026-09-12 23:51:06', 1, '2026-09-12 23:51:06'),
(230, 'Rice Cookers', 'category', 0, '2026-09-12 23:51:06', 1, '2026-09-12 23:51:06'),
(231, 'Gree', 'brand', 0, '2026-09-12 23:51:06', 1, '2026-09-12 23:51:06'),
(232, 'Kennede', 'brand', 0, '2026-09-12 23:51:06', 1, '2026-09-12 23:51:06'),
(233, 'LG', 'brand', 0, '2026-09-12 23:51:06', 1, '2026-09-12 23:51:06'),
(234, 'Miyoko', 'brand', 0, '2026-09-12 23:51:06', 1, '2026-09-12 23:51:06'),
(235, 'Nima', 'brand', 0, '2026-09-12 23:51:06', 1, '2026-09-12 23:51:06'),
(236, 'Panasonic', 'brand', 0, '2026-09-12 23:51:06', 1, '2026-09-12 23:51:06'),
(237, 'Pink Panther', 'brand', 0, '2026-09-12 23:51:06', 1, '2026-09-12 23:51:06'),
(238, 'Singer', 'brand', 0, '2026-09-12 23:51:06', 1, '2026-09-12 23:51:06'),
(239, 'Sokany', 'brand', 0, '2026-09-12 23:51:06', 1, '2026-09-12 23:51:06'),
(240, 'Walton', 'brand', 0, '2026-09-12 23:51:06', 1, '2026-09-12 23:51:06');


-- --------------------------------------------------------
-- Table structure for table `search_history`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `search_history`;
CREATE TABLE `search_history` (
  `search_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `search_query` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `results_count` int DEFAULT '0',
  `searched_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`search_id`),
  KEY `idx_search_query` (`search_query`),
  KEY `idx_searched_at` (`searched_at`),
  KEY `idx_user_query` (`user_id`,`search_query`),
  CONSTRAINT `search_history_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------
-- Table structure for table `search_analytics`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `search_analytics`;
CREATE TABLE `search_analytics` (
  `analytics_id` int NOT NULL AUTO_INCREMENT,
  `date` date NOT NULL,
  `search_query` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `total_searches` int DEFAULT '0',
  `unique_users` int DEFAULT '0',
  `avg_results` int DEFAULT '0',
  `zero_results_count` int DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`analytics_id`),
  UNIQUE KEY `unique_date_query` (`date`,`search_query`),
  KEY `idx_date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------
-- Table structure for table `stock_alerts`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `stock_alerts`;
CREATE TABLE `stock_alerts` (
  `alert_id` int NOT NULL AUTO_INCREMENT,
  `product_id` int NOT NULL,
  `alert_type` enum('LOW_STOCK','OUT_OF_STOCK','OVERSTOCK') COLLATE utf8mb4_unicode_ci NOT NULL,
  `threshold_quantity` int DEFAULT '5',
  `current_quantity` int NOT NULL,
  `is_resolved` tinyint(1) DEFAULT '0',
  `resolved_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`alert_id`),
  KEY `product_id` (`product_id`),
  KEY `idx_unresolved` (`is_resolved`,`created_at`),
  CONSTRAINT `stock_alerts_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------
-- Table structure for table `stock_movements`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `stock_movements`;
CREATE TABLE `stock_movements` (
  `movement_id` int NOT NULL AUTO_INCREMENT,
  `product_id` int NOT NULL,
  `movement_type` enum('IN','OUT','ADJUSTMENT') COLLATE utf8mb4_unicode_ci NOT NULL,
  `quantity` int NOT NULL,
  `previous_stock` int NOT NULL,
  `new_stock` int NOT NULL,
  `reference_type` enum('PURCHASE','SALE','RETURN','DAMAGE','ADJUSTMENT','INITIAL') COLLATE utf8mb4_unicode_ci DEFAULT 'ADJUSTMENT',
  `reference_id` int DEFAULT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `created_by` int DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`movement_id`),
  KEY `idx_product_date` (`product_id`,`created_at`),
  KEY `idx_movement_type` (`movement_type`),
  KEY `idx_reference` (`reference_type`,`reference_id`),
  KEY `created_by` (`created_by`),
  CONSTRAINT `stock_movements_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=141 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------
-- Table structure for table `site_settings`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `site_settings`;
CREATE TABLE `site_settings` (
  `setting_key` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `setting_value` text COLLATE utf8mb4_unicode_ci,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------
-- Table structure for table `promotions`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `promotions`;
CREATE TABLE `promotions` (
  `promotion_id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `discount_percent` decimal(5,2) DEFAULT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `active` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`promotion_id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------
-- Table structure for table `discounts`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `discounts`;
CREATE TABLE `discounts` (
  `discount_id` int NOT NULL AUTO_INCREMENT,
  `product_id` int DEFAULT NULL,
  `discount_percent` decimal(5,2) DEFAULT NULL,
  `valid_from` date DEFAULT NULL,
  `valid_to` date DEFAULT NULL,
  PRIMARY KEY (`discount_id`),
  KEY `product_id` (`product_id`),
  CONSTRAINT `discounts_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------
-- Table structure for table `reviews`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `reviews`;
CREATE TABLE `reviews` (
  `review_id` int NOT NULL AUTO_INCREMENT,
  `product_id` int NOT NULL,
  `user_id` int DEFAULT NULL,
  `rating` int DEFAULT NULL,
  `review_text` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`review_id`),
  KEY `idx_reviews_product` (`product_id`),
  KEY `idx_reviews_user` (`user_id`),
  CONSTRAINT `reviews_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE,
  CONSTRAINT `reviews_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL,
  CONSTRAINT `reviews_chk_1` CHECK ((`rating` between 1 and 5))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------
-- Table structure for table `reports`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `reports`;
CREATE TABLE `reports` (
  `report_id` int NOT NULL AUTO_INCREMENT,
  `admin_id` int DEFAULT NULL,
  `report_type` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `details` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`report_id`),
  KEY `admin_id` (`admin_id`),
  CONSTRAINT `reports_ibfk_1` FOREIGN KEY (`admin_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------
-- Table structure for table `notifications`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `notifications`;
CREATE TABLE `notifications` (
  `notification_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `type` varchar(50) DEFAULT 'general',
  `title` varchar(200) NOT NULL,
  `message` text NOT NULL,
  `is_read` tinyint(1) DEFAULT '0',
  `read_at` datetime DEFAULT NULL,
  `related_id` int DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`notification_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------
-- Table structure for table `customer_support`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `customer_support`;
CREATE TABLE `customer_support` (
  `ticket_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `subject` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `message` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('open','in_progress','resolved','closed') COLLATE utf8mb4_unicode_ci DEFAULT 'open',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `resolved_by` int DEFAULT NULL,
  `resolved_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`ticket_id`),
  KEY `idx_customer_support_user` (`user_id`),
  KEY `idx_customer_support_status` (`status`),
  KEY `resolved_by` (`resolved_by`),
  CONSTRAINT `customer_support_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL,
  CONSTRAINT `customer_support_ibfk_2` FOREIGN KEY (`resolved_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------
-- Table structure for table `password_resets`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `password_resets`;
CREATE TABLE `password_resets` (
  `id` int NOT NULL AUTO_INCREMENT,
  `email` varchar(150) NOT NULL,
  `token` varchar(64) NOT NULL,
  `expires_at` datetime NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `token` (`token`),
  KEY `idx_pr_email` (`email`),
  KEY `idx_pr_token` (`token`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------
-- Table structure for table `password_reset_tokens`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `password_reset_tokens`;
CREATE TABLE `password_reset_tokens` (
  `token_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `email` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `token` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `reset_code` varchar(6) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `expires_at` datetime NOT NULL,
  `used` tinyint(1) DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`token_id`),
  UNIQUE KEY `token` (`token`),
  KEY `user_id` (`user_id`),
  KEY `idx_token` (`token`),
  KEY `idx_email` (`email`),
  KEY `idx_expires` (`expires_at`),
  KEY `idx_reset_code` (`reset_code`),
  CONSTRAINT `password_reset_tokens_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------
-- Table structure for table `csrf_tokens`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `csrf_tokens`;
CREATE TABLE `csrf_tokens` (
  `token_id` int NOT NULL AUTO_INCREMENT,
  `token` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` int DEFAULT NULL,
  `session_id` varchar(128) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `expires_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`token_id`),
  UNIQUE KEY `token` (`token`),
  KEY `idx_token` (`token`),
  KEY `idx_expires` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------
-- Table structure for table `rate_limits`
-- --------------------------------------------------------

DROP TABLE IF EXISTS `rate_limits`;
CREATE TABLE `rate_limits` (
  `id` int NOT NULL AUTO_INCREMENT,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci NOT NULL,
  `endpoint` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `request_count` int DEFAULT '1',
  `window_start` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ip_endpoint` (`ip_address`,`endpoint`),
  KEY `idx_window` (`window_start`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Finalizing Import
-- --------------------------------------------------------
SET FOREIGN_KEY_CHECKS = 1;
COMMIT;

-- ============================================================
-- Export Complete: 201 total rows exported across 41 tables.
-- ============================================================