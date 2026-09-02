-- ============================================================
-- ElectroZoneBD — Full Database Schema
-- Run this in phpMyAdmin → Import
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";

-- ─── USERS ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `users` (
  `user_id`      INT AUTO_INCREMENT PRIMARY KEY,
  `full_name`    VARCHAR(100) NOT NULL,
  `last_name`    VARCHAR(100) DEFAULT '',
  `email`        VARCHAR(150) NOT NULL UNIQUE,
  `password`     VARCHAR(255) NOT NULL,
  `phone_number` VARCHAR(20)  DEFAULT '',
  `address`      TEXT         DEFAULT NULL,
  `gender`       ENUM('Male','Female','Other') DEFAULT 'Male',
  `role`         ENUM('customer','admin') DEFAULT 'customer',
  `created_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── USER PROFILE ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `user_profile` (
  `profile_id`   INT AUTO_INCREMENT PRIMARY KEY,
  `user_id`      INT NOT NULL UNIQUE,
  `full_name`    VARCHAR(100) DEFAULT '',
  `last_name`    VARCHAR(100) DEFAULT '',
  `phone_number` VARCHAR(20)  DEFAULT '',
  `gender`       VARCHAR(20)  DEFAULT '',
  `avatar_url`   VARCHAR(255) DEFAULT NULL,
  `updated_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── CATEGORIES ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `categories` (
  `category_id`   INT AUTO_INCREMENT PRIMARY KEY,
  `category_name` VARCHAR(100) NOT NULL UNIQUE,
  `description`   TEXT DEFAULT NULL,
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `categories` (`category_name`) VALUES
('Home Appliances'),
('Kitchen Appliances'),
('Personal Care'),
('Fans & Coolers'),
('Lighting'),
('Electronics'),
('Blenders & Mixers'),
('Irons & Steamers'),
('Rice Cookers'),
('Air Fryers');

-- ─── BRANDS ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `brands` (
  `brand_id`   INT AUTO_INCREMENT PRIMARY KEY,
  `brand_name` VARCHAR(100) NOT NULL UNIQUE,
  `brand_logo` VARCHAR(255) DEFAULT '',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `brands` (`brand_name`, `brand_logo`) VALUES
('Miyoko',      'assets/Brand Logo/images (1).jpg'),
('Walton',      'assets/Brand Logo/walton.png'),
('Singer',      'assets/Brand Logo/singer.png'),
('LG',          'assets/Brand Logo/LG.png'),
('Panasonic',   'assets/Brand Logo/panasonnic.png'),
('Gree',        'assets/Brand Logo/Gree.png'),
('Pink Panther','assets/Brand Logo/images (2).png'),
('Nima',        'assets/Brand Logo/images (3).png'),
('Sokany',      'assets/Brand Logo/images (4).png'),
('Kennede',     'assets/Brand Logo/images (5).png');

-- ─── PRODUCTS ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `products` (
  `product_id`     INT AUTO_INCREMENT PRIMARY KEY,
  `category_id`    INT DEFAULT NULL,
  `brand_id`       INT DEFAULT NULL,
  `product_name`   VARCHAR(200) NOT NULL,
  `description`    TEXT DEFAULT NULL,
  `price`          DECIMAL(10,2) NOT NULL DEFAULT 0,
  `stock_quantity` INT NOT NULL DEFAULT 0,
  `image_url`      VARCHAR(500) DEFAULT '',
  `specs_json`     JSON DEFAULT NULL,
  `created_at`     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`category_id`) REFERENCES `categories`(`category_id`) ON DELETE SET NULL,
  FOREIGN KEY (`brand_id`)    REFERENCES `brands`(`brand_id`)    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── SAMPLE PRODUCTS (assets/prod/ images) ───────────────────
-- image_url = 'assets/prod/filename' → Flutter loads as asset image
INSERT IGNORE INTO `products`
  (`product_name`, `description`, `price`, `stock_quantity`, `image_url`, `category_id`, `brand_id`)
VALUES
('Miyoko Blender',        'High-power 600W blender for smoothies and juices',    1800, 50, 'assets/prod/blender.jpg',        2, 1),
('Air Fryer 5L',          'Oil-free cooking, 5 litre capacity, digital control', 4500, 30, 'assets/prod/air_fryer.jpg',      10, 2),
('Charger Fan',           'Rechargeable fan with LED light, 3 speed settings',   1200, 80, 'assets/prod/chargerfan.jpg',     4, 10),
('Rice Cooker 1.8L',      'Automatic rice cooker with keep-warm function',       2200, 60, 'assets/prod/rice_cooker.jpg',    9, 1),
('Hand Blender',          'Immersion blender 300W with stainless steel blade',   1500, 45, 'assets/prod/hand_blender.jpg',   7, 7),
('Electric Iron',         'Steam iron 2200W with non-stick soleplate',           1100, 70, 'assets/prod/iron.jpg',           8, 3),
('Mini Cooker',           'Compact electric cooker for small portions',          1600, 40, 'assets/prod/mini_cooker.jpg',    2, 1),
('Hair Dryer 1800W',      'Professional hair dryer with cool shot button',       1300, 55, 'assets/prod/hair_drier.jpg',     3, 9),
('Induction Stove',       '2000W induction cooktop with 8 power levels',        3200, 25, 'assets/prod/induction_stove.jpg',2, 4),
('Grinder 400W',          'Dry and wet grinder with stainless steel jar',        1900, 35, 'assets/prod/grinder.jpg',        2, 8),
('Oven 25L',              '25 litre electric oven with rotisserie function',     5500, 20, 'assets/prod/oven.jpg',           2, 1),
('Curry Cooker',          'Multi-function curry cooker 1.5L',                   1400, 50, 'assets/prod/curry_cooker.jpg',   2, 1),
('Head Massager',         'Electric scalp massager with 4 massage heads',        900, 90, 'assets/prod/head_massager.jpg',  3, 7),
('Massage Gun',           'Deep tissue massage gun 6 speed settings',           3500, 15, 'assets/prod/massage_gun.jpg',    3, 2),
('Electric Stove',        '2-burner electric stove 2500W',                      2800, 30, 'assets/prod/elec_stove.jpg',     2, 3),
('Trimmer Pro',           'Rechargeable hair trimmer with 4 guide combs',       1600, 65, 'assets/prod/trimmer.jpg',        3, 4),
('Rice Cooker 2.8L',      'Large capacity rice cooker with steamer basket',     2800, 40, 'assets/prod/riceCooker2.jpg',    9, 2),
('Hand Blender Pro',      'Professional hand blender 500W with whisk',          2200, 30, 'assets/prod/hand_blender23.jpg', 7, 1),
('Mini Cooker 2',         'Compact multi-cooker with non-stick coating',        1800, 45, 'assets/prod/mini2cokker.jpg',    2, 1),
('Chopper 300W',          'Electric food chopper with 1.2L bowl',               1200, 55, 'assets/prod/chopper.jpg',        2, 8);

-- ─── TECH PART PRODUCTS ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS `tech_part_products` (
  `id`            INT AUTO_INCREMENT PRIMARY KEY,
  `product_id`    INT NOT NULL UNIQUE,
  `display_order` INT DEFAULT 0,
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`product_id`) REFERENCES `products`(`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Assign first 10 products to Tech Part
INSERT IGNORE INTO `tech_part_products` (`product_id`, `display_order`)
SELECT `product_id`, ROW_NUMBER() OVER (ORDER BY `product_id`)
FROM `products` LIMIT 10;

-- ─── TRENDING PRODUCTS ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS `trending_products` (
  `id`             INT AUTO_INCREMENT PRIMARY KEY,
  `product_id`     INT NOT NULL UNIQUE,
  `trending_score` INT DEFAULT 0,
  `image_path`     VARCHAR(500) DEFAULT NULL,  -- override image (asset or upload path)
  `display_order`  INT DEFAULT 0,
  `created_at`     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`product_id`) REFERENCES `products`(`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Assign products to Trending with asset image overrides from assets/trends/
INSERT IGNORE INTO `trending_products` (`product_id`, `trending_score`, `image_path`, `display_order`)
SELECT p.product_id, 100 - ROW_NUMBER() OVER (ORDER BY p.product_id),
  CASE p.product_name
    WHEN 'Miyoko Blender'    THEN 'assets/trends/blender.jpg'
    WHEN 'Air Fryer 5L'      THEN 'assets/trends/air_fryer.jpg'
    WHEN 'Charger Fan'       THEN 'assets/trends/chargerfan.jpg'
    WHEN 'Rice Cooker 1.8L'  THEN 'assets/trends/rice_cooker.jpg'
    WHEN 'Hand Blender'      THEN 'assets/trends/hand_blender.jpg'
    WHEN 'Mini Cooker'       THEN 'assets/trends/mini_cooker.jpg'
    WHEN 'Hair Dryer 1800W'  THEN 'assets/trends/hair_drier.jpg'
    WHEN 'Induction Stove'   THEN 'assets/trends/elec_stove.jpg'
    WHEN 'Head Massager'     THEN 'assets/trends/head_massager.jpg'
    WHEN 'Electric Stove'    THEN 'assets/trends/elec_stove.jpg'
    ELSE p.image_url
  END,
  ROW_NUMBER() OVER (ORDER BY p.product_id)
FROM `products` p LIMIT 10;

-- ─── BEST SELLERS ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `best_sellers` (
  `id`              INT AUTO_INCREMENT PRIMARY KEY,
  `product_id`      INT NOT NULL UNIQUE,
  `sales_count`     INT DEFAULT 0,
  `selling_point`   VARCHAR(200) DEFAULT '',
  `sales_strategy`  VARCHAR(200) DEFAULT '',
  `created_at`      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`product_id`) REFERENCES `products`(`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `best_sellers` (`product_id`, `sales_count`)
SELECT `product_id`, FLOOR(RAND() * 500) + 100
FROM `products` LIMIT 4;

-- ─── DEALS OF THE DAY ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `deals_of_the_day` (
  `deal_id`    INT AUTO_INCREMENT PRIMARY KEY,
  `product_id` INT NOT NULL UNIQUE,
  `deal_price` DECIMAL(10,2) NOT NULL,
  `start_date` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `end_date`   DATETIME DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`product_id`) REFERENCES `products`(`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `deals_of_the_day` (`product_id`, `deal_price`, `end_date`)
SELECT `product_id`, ROUND(`price` * 0.80, 2), DATE_ADD(NOW(), INTERVAL 365 DAY)
FROM `products` LIMIT 6;

-- ─── FLASH SALES ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `flash_sales` (
  `flash_sale_id` INT AUTO_INCREMENT PRIMARY KEY,
  `title`         VARCHAR(200) NOT NULL,
  `start_time`    DATETIME NOT NULL,
  `end_time`      DATETIME NOT NULL,
  `active`        TINYINT(1) DEFAULT 1,
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `flash_sale_products` (
  `id`             INT AUTO_INCREMENT PRIMARY KEY,
  `flash_sale_id`  INT NOT NULL,
  `product_id`     INT NOT NULL,
  `flash_price`    DECIMAL(10,2) NOT NULL,
  `image_path`     VARCHAR(500) DEFAULT NULL,
  `display_order`  INT DEFAULT 0,
  `created_at`     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_fs_product` (`flash_sale_id`, `product_id`),
  FOREIGN KEY (`flash_sale_id`) REFERENCES `flash_sales`(`flash_sale_id`) ON DELETE CASCADE,
  FOREIGN KEY (`product_id`)    REFERENCES `products`(`product_id`)    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `flash_sales` (`title`, `start_time`, `end_time`, `active`) VALUES
('Eid Special Flash Sale', NOW(), DATE_ADD(NOW(), INTERVAL 7 DAY), 1);

INSERT IGNORE INTO `flash_sale_products` (`flash_sale_id`, `product_id`, `flash_price`, `image_path`, `display_order`)
SELECT 1, p.product_id, ROUND(p.price * 0.75, 2),
  CASE p.product_name
    WHEN 'Miyoko Blender'   THEN 'assets/flash/av.jpg'
    WHEN 'Hair Dryer 1800W' THEN 'assets/flash/dryer.jpg'
    WHEN 'Grinder 400W'     THEN 'assets/flash/nima_grinder.jpg'
    WHEN 'Charger Fan'      THEN 'assets/flash/kennede.jpg'
    ELSE NULL
  END,
  ROW_NUMBER() OVER (ORDER BY p.product_id)
FROM `products` p LIMIT 6;

-- ─── COLLECTIONS ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `collections` (
  `collection_id` INT AUTO_INCREMENT PRIMARY KEY,
  `name`          VARCHAR(100) NOT NULL,
  `slug`          VARCHAR(100) NOT NULL UNIQUE,
  `description`   TEXT DEFAULT NULL,
  `icon`          VARCHAR(50)  DEFAULT 'category',
  `image_url`     VARCHAR(500) DEFAULT NULL,
  `is_active`     TINYINT(1)   DEFAULT 1,
  `display_order` INT          DEFAULT 0,
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `collection_items` (
  `item_id`       INT AUTO_INCREMENT PRIMARY KEY,
  `collection_id` INT NOT NULL,
  `item_name`     VARCHAR(100) NOT NULL,
  `display_order` INT DEFAULT 0,
  FOREIGN KEY (`collection_id`) REFERENCES `collections`(`collection_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `collections` (`name`, `slug`, `icon`, `display_order`) VALUES
('Fans',          'fans',          'air',       1),
('Kitchen',       'kitchen',       'kitchen',   2),
('Personal Care', 'personal-care', 'spa',       3),
('Blenders',      'blenders',      'blender',   4);

-- ─── BANNERS ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `banners` (
  `banner_id`     INT AUTO_INCREMENT PRIMARY KEY,
  `banner_type`   ENUM('hero','mid','sidebar') NOT NULL,
  `image_url`     VARCHAR(500) DEFAULT '',
  `link_url`      VARCHAR(500) DEFAULT '',
  `title`         VARCHAR(200) DEFAULT '',
  `description`   TEXT DEFAULT NULL,
  `button_text`   VARCHAR(100) DEFAULT 'Shop Now',
  `display_order` INT DEFAULT 0,
  `active`        TINYINT(1) DEFAULT 1,
  `start_date`    DATE DEFAULT NULL,
  `end_date`      DATE DEFAULT NULL,
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `banners` (`banner_type`, `image_url`, `title`, `button_text`, `display_order`, `active`) VALUES
('hero',    'assets/1.png',          'Eid Special Offers',    'Shop Now',  1, 1),
('hero',    'assets/2.png',          'New Arrivals',          'Explore',   2, 1),
('hero',    'assets/3.png',          'Flash Sale Live',       'Grab Now',  3, 1),
('mid',     'assets/BestSale/2912.jpg', 'Best Deals',         'View All',  1, 1),
('sidebar', '',                      'FLASH SALE',            'VIEW ALL',  0, 1);

-- ─── CART ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `cart` (
  `cart_id`    INT AUTO_INCREMENT PRIMARY KEY,
  `user_id`    INT NOT NULL,
  `product_id` INT NOT NULL,
  `quantity`   INT NOT NULL DEFAULT 1,
  `added_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_cart_user_product` (`user_id`, `product_id`),
  FOREIGN KEY (`user_id`)    REFERENCES `users`(`user_id`)    ON DELETE CASCADE,
  FOREIGN KEY (`product_id`) REFERENCES `products`(`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── ORDERS ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `orders` (
  `order_id`           INT AUTO_INCREMENT PRIMARY KEY,
  `user_id`            INT DEFAULT NULL,              -- NULL for guest orders
  `customer_name`      VARCHAR(150) DEFAULT NULL,     -- guest / override name
  `customer_phone`     VARCHAR(20)  DEFAULT NULL,     -- guest / override phone
  `total_amount`       DECIMAL(10,2) NOT NULL,
  `subtotal_amount`    DECIMAL(10,2) DEFAULT 0.00,
  `delivery_charge`    DECIMAL(10,2) DEFAULT 0.00,
  `coupon_discount`    DECIMAL(10,2) DEFAULT 0.00,
  `delivery_zone`      VARCHAR(50) DEFAULT NULL,
  `coupon_code`        VARCHAR(100) DEFAULT NULL,
  `order_status`       VARCHAR(50)  DEFAULT 'New Order',
  `payment_method`     VARCHAR(50)  DEFAULT 'Cash on Delivery',
  `payment_status`     ENUM('pending','paid','failed','refunded') DEFAULT 'pending',
  `transaction_id`     VARCHAR(100) DEFAULT NULL,
  `delivery_address`   TEXT DEFAULT NULL,
  `estimated_delivery` VARCHAR(100) DEFAULT NULL,
  `order_date`         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `order_items` (
  `item_id`           INT AUTO_INCREMENT PRIMARY KEY,
  `order_id`          INT NOT NULL,
  `product_id`        INT DEFAULT NULL,
  `product_name`      VARCHAR(200) NOT NULL,
  `quantity`          INT NOT NULL,
  `price_at_purchase` DECIMAL(10,2) NOT NULL,
  `image_url`         VARCHAR(500) DEFAULT '',
  FOREIGN KEY (`order_id`)   REFERENCES `orders`(`order_id`)   ON DELETE CASCADE,
  FOREIGN KEY (`product_id`) REFERENCES `products`(`product_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── WISHLISTS ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `wishlists` (
  `wishlist_id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id`     INT NOT NULL,
  `product_id`  INT NOT NULL,
  `added_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_wishlist` (`user_id`, `product_id`),
  FOREIGN KEY (`user_id`)    REFERENCES `users`(`user_id`)    ON DELETE CASCADE,
  FOREIGN KEY (`product_id`) REFERENCES `products`(`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── DISCOUNTS ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `discounts` (
  `discount_id`      INT AUTO_INCREMENT PRIMARY KEY,
  `product_id`       INT NOT NULL UNIQUE,
  `discount_percent` DECIMAL(5,2) NOT NULL,
  `valid_from`       DATE NOT NULL,
  `valid_to`         DATE NOT NULL,
  FOREIGN KEY (`product_id`) REFERENCES `products`(`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── REVIEWS ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `reviews` (
  `review_id`   INT AUTO_INCREMENT PRIMARY KEY,
  `product_id`  INT NOT NULL,
  `user_id`     INT DEFAULT NULL,
  `rating`      TINYINT NOT NULL CHECK (`rating` BETWEEN 1 AND 5),
  `review_text` TEXT DEFAULT NULL,
  `created_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`product_id`) REFERENCES `products`(`product_id`) ON DELETE CASCADE,
  FOREIGN KEY (`user_id`)    REFERENCES `users`(`user_id`)    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── PRODUCT RATINGS (aggregated) ────────────────────────────
CREATE TABLE IF NOT EXISTS `product_ratings` (
  `product_id`   INT PRIMARY KEY,
  `rating_avg`   DECIMAL(3,2) DEFAULT 0,
  `review_count` INT DEFAULT 0,
  `updated_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`product_id`) REFERENCES `products`(`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── PROMOTIONS ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `promotions` (
  `promotion_id`     INT AUTO_INCREMENT PRIMARY KEY,
  `title`            VARCHAR(200) NOT NULL,
  `description`      TEXT DEFAULT NULL,
  `discount_percent` DECIMAL(5,2) DEFAULT NULL,
  `start_date`       DATE DEFAULT NULL,
  `end_date`         DATE DEFAULT NULL,
  `active`           TINYINT(1) DEFAULT 1,
  `created_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── COUPONS / SITE SETTINGS ─────────────────────────────────
CREATE TABLE IF NOT EXISTS `site_settings` (
  `id`            INT AUTO_INCREMENT PRIMARY KEY,
  `setting_key`   VARCHAR(100) NOT NULL UNIQUE,
  `setting_value` TEXT DEFAULT NULL,
  `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── SEARCH HISTORY ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `search_history` (
  `id`            INT AUTO_INCREMENT PRIMARY KEY,
  `user_id`       INT DEFAULT NULL,
  `search_query`  VARCHAR(200) NOT NULL,
  `results_count` INT DEFAULT 0,
  `searched_at`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── NOTIFICATIONS ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `notifications` (
  `notification_id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id`         INT DEFAULT NULL,
  `type`            VARCHAR(50) DEFAULT 'general',
  `title`           VARCHAR(200) NOT NULL,
  `message`         TEXT NOT NULL,
  `is_read`         TINYINT(1) DEFAULT 0,
  `read_at`         DATETIME DEFAULT NULL,
  `related_id`      INT DEFAULT NULL,
  `created_at`      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── PAYMENT METHODS ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `payment_methods` (
  `method_id`   INT AUTO_INCREMENT PRIMARY KEY,
  `name`        VARCHAR(100) NOT NULL,
  `logo_url`    VARCHAR(255) DEFAULT '',
  `is_active`   TINYINT(1) DEFAULT 1,
  `created_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `payment_methods` (`name`, `logo_url`) VALUES
('Cash on Delivery', ''),
('bKash',            'assets/payments/baksh.png'),
('Nagad',            'assets/payments/nagad.png'),
('Visa',             'assets/payments/visa.png'),
('Mastercard',       'assets/payments/master.png');

-- ─── CUSTOMER SUPPORT ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `customer_support` (
  `ticket_id`  INT AUTO_INCREMENT PRIMARY KEY,
  `user_id`    INT DEFAULT NULL,
  `subject`    VARCHAR(200) NOT NULL,
  `message`    TEXT NOT NULL,
  `status`     ENUM('open','in_progress','resolved','closed') DEFAULT 'open',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── PRODUCT SPECIFICATIONS ──────────────────────────────────
CREATE TABLE IF NOT EXISTS `product_specifications` (
  `spec_id`    INT AUTO_INCREMENT PRIMARY KEY,
  `product_id` INT NOT NULL,
  `spec_key`   VARCHAR(100) NOT NULL,
  `spec_value` VARCHAR(500) NOT NULL,
  FOREIGN KEY (`product_id`) REFERENCES `products`(`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── DEALS TIMER ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `deals_timer` (
  `id`         INT AUTO_INCREMENT PRIMARY KEY,
  `days`       INT DEFAULT 3,
  `hours`      INT DEFAULT 11,
  `minutes`    INT DEFAULT 59,
  `seconds`    INT DEFAULT 59,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `deals_timer` (`id`, `days`, `hours`, `minutes`, `seconds`) VALUES (1, 3, 11, 59, 59);

-- ─── PASSWORD RESETS ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `password_resets` (
  `id`         INT AUTO_INCREMENT PRIMARY KEY,
  `email`      VARCHAR(150) NOT NULL,
  `token`      VARCHAR(64)  NOT NULL UNIQUE,
  `expires_at` DATETIME NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_pr_email` (`email`),
  INDEX `idx_pr_token` (`token`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─── ADMIN USER (default) ────────────────────────────────────
-- Password: admin123 (bcrypt) — CHANGE THIS after first login!
INSERT IGNORE INTO `users` (`full_name`, `email`, `password`, `role`) VALUES
('Admin', 'admin@electrozonebd.com',
 '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin'),
('Noman Admin', 'noman@admin_electrozone.com',
 '$2y$10$C0.liivgmh/fNd/f94y0wOrDUFF3r50i34kylma1rWIMeHCfVsIYq', 'admin');

SET FOREIGN_KEY_CHECKS = 1;
