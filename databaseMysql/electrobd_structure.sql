
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET FOREIGN_KEY_CHECKS = 0;
START TRANSACTION;
SET time_zone = "+00:00";
SET NAMES utf8mb4;

CREATE DATABASE IF NOT EXISTS `asiment3_electrobd`
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `asiment3_electrobd`;

-- -----------------------------------------------------------
-- PROCEDURES
-- -----------------------------------------------------------
DELIMITER $$

DROP PROCEDURE IF EXISTS `sp_search_products`$$
CREATE PROCEDURE `sp_search_products`(IN p_query VARCHAR(255), IN p_limit INT, IN p_offset INT)
BEGIN
  DECLARE search_pattern VARCHAR(257);
  SET search_pattern = CONCAT('%', p_query, '%');
  SELECT p.*, c.category_name, b.brand_name, d.discount_percent,
    CASE WHEN d.discount_percent IS NOT NULL THEN p.price*(1-d.discount_percent/100) ELSE p.price END AS discounted_price,
    (CASE WHEN p.product_name = p_query THEN 100 ELSE 0 END +
     CASE WHEN p.product_name LIKE CONCAT(p_query,'%') THEN 50 ELSE 0 END +
     CASE WHEN p.product_name LIKE search_pattern THEN 25 ELSE 0 END +
     CASE WHEN p.description LIKE search_pattern THEN 10 ELSE 0 END +
     CASE WHEN c.category_name LIKE search_pattern THEN 15 ELSE 0 END +
     CASE WHEN b.brand_name LIKE search_pattern THEN 15 ELSE 0 END) AS relevance_score
  FROM products p
  LEFT JOIN categories c ON p.category_id = c.category_id
  LEFT JOIN brands b ON p.brand_id = b.brand_id
  LEFT JOIN discounts d ON p.product_id = d.product_id AND CURDATE() BETWEEN d.valid_from AND d.valid_to
  WHERE p.product_name LIKE search_pattern OR p.description LIKE search_pattern
     OR c.category_name LIKE search_pattern OR b.brand_name LIKE search_pattern
  HAVING relevance_score > 0
  ORDER BY relevance_score DESC, p.product_name ASC
  LIMIT p_limit OFFSET p_offset;
END$$

DROP PROCEDURE IF EXISTS `sp_stock_in`$$
CREATE PROCEDURE `sp_stock_in`(IN p_product_id INT, IN p_quantity INT, IN p_reference_type VARCHAR(20), IN p_reference_id INT, IN p_notes TEXT, IN p_created_by INT)
BEGIN
  DECLARE current_stock INT;
  DECLARE new_stock INT;
  SELECT stock_quantity INTO current_stock FROM products WHERE product_id = p_product_id;
  SET new_stock = current_stock + p_quantity;
  UPDATE products SET stock_quantity = new_stock WHERE product_id = p_product_id;
  INSERT INTO stock_movements (product_id,movement_type,quantity,previous_stock,new_stock,reference_type,reference_id,notes,created_by)
  VALUES (p_product_id,'IN',p_quantity,current_stock,new_stock,p_reference_type,p_reference_id,p_notes,p_created_by);
  SELECT 'SUCCESS' AS status, p_product_id AS product_id, current_stock AS previous_stock, new_stock AS current_stock, p_quantity AS quantity_added;
END$$

DROP PROCEDURE IF EXISTS `sp_stock_out`$$
CREATE PROCEDURE `sp_stock_out`(IN p_product_id INT, IN p_quantity INT, IN p_reference_type VARCHAR(20), IN p_reference_id INT, IN p_notes TEXT, IN p_created_by INT)
BEGIN
  DECLARE current_stock INT;
  DECLARE new_stock INT;
  SELECT stock_quantity INTO current_stock FROM products WHERE product_id = p_product_id;
  IF current_stock < p_quantity THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock available';
  END IF;
  SET new_stock = current_stock - p_quantity;
  UPDATE products SET stock_quantity = new_stock WHERE product_id = p_product_id;
  INSERT INTO stock_movements (product_id,movement_type,quantity,previous_stock,new_stock,reference_type,reference_id,notes,created_by)
  VALUES (p_product_id,'OUT',p_quantity,current_stock,new_stock,p_reference_type,p_reference_id,p_notes,p_created_by);
  SELECT 'SUCCESS' AS status, p_product_id AS product_id, current_stock AS previous_stock, new_stock AS current_stock, p_quantity AS quantity_removed;
END$$

DELIMITER ;

-- -----------------------------------------------------------
-- TABLES (dependency order)
-- -----------------------------------------------------------

CREATE TABLE IF NOT EXISTS `users` (
  `user_id` int(11) NOT NULL AUTO_INCREMENT,
  `full_name` varchar(100) NOT NULL,
  `last_name` varchar(50) NOT NULL DEFAULT '',
  `email` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `phone_number` varchar(20) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `gender` varchar(10) DEFAULT 'Male',
  `role` enum('admin','customer') DEFAULT 'customer',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `unique_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `user_profile` (
  `user_id` int(11) NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `last_name` varchar(50) NOT NULL DEFAULT '',
  `phone_number` varchar(20) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `gender` varchar(10) DEFAULT 'Male',
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`user_id`),
  CONSTRAINT `user_profile_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `brands` (
  `brand_id` int(11) NOT NULL AUTO_INCREMENT,
  `brand_name` varchar(100) NOT NULL,
  `brand_logo` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`brand_id`),
  UNIQUE KEY `idx_brand_name_unique` (`brand_name`),
  FULLTEXT KEY `ft_brand_name` (`brand_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `categories` (
  `category_id` int(11) NOT NULL AUTO_INCREMENT,
  `category_name` varchar(50) NOT NULL,
  `category_image` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`category_id`),
  UNIQUE KEY `idx_category_name_unique` (`category_name`),
  FULLTEXT KEY `ft_category_name` (`category_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `search_suggestions` (
  `suggestion_id` int(11) NOT NULL AUTO_INCREMENT,
  `suggestion_text` varchar(255) NOT NULL,
  `suggestion_type` enum('product','category','brand','keyword') DEFAULT 'keyword',
  `search_count` int(11) DEFAULT 0,
  `last_searched` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`suggestion_id`),
  UNIQUE KEY `suggestion_text` (`suggestion_text`),
  KEY `idx_suggestion_text` (`suggestion_text`),
  KEY `idx_search_count` (`search_count`),
  KEY `idx_type` (`suggestion_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `products` (
  `product_id` int(11) NOT NULL AUTO_INCREMENT,
  `category_id` int(11) DEFAULT NULL,
  `brand_id` int(11) DEFAULT NULL,
  `product_name` varchar(150) NOT NULL,
  `description` text DEFAULT NULL,
  `price` decimal(10,2) NOT NULL,
  `stock_quantity` int(11) DEFAULT 0,
  `image_url` varchar(255) DEFAULT NULL,
  `specs_json` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `min_stock_threshold` int(11) DEFAULT 5,
  `max_stock_threshold` int(11) DEFAULT 1000,
  `stock_status` enum('IN_STOCK','LOW_STOCK','OUT_OF_STOCK') GENERATED ALWAYS AS (
    CASE WHEN `stock_quantity` <= 0 THEN 'OUT_OF_STOCK'
         WHEN `stock_quantity` <= `min_stock_threshold` THEN 'LOW_STOCK'
         ELSE 'IN_STOCK' END) STORED,
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `reviews` (
  `review_id` int(11) NOT NULL AUTO_INCREMENT,
  `product_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `rating` int(11) DEFAULT NULL CHECK (`rating` BETWEEN 1 AND 5),
  `review_text` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`review_id`),
  KEY `idx_reviews_product` (`product_id`),
  KEY `idx_reviews_user` (`user_id`),
  CONSTRAINT `reviews_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE,
  CONSTRAINT `reviews_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `product_reviews` (
  `review_id` int(11) NOT NULL AUTO_INCREMENT,
  `product_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `rating` int(11) NOT NULL CHECK (`rating` BETWEEN 1 AND 5),
  `review_text` text DEFAULT NULL,
  `review_title` varchar(255) DEFAULT NULL,
  `is_verified_purchase` tinyint(1) DEFAULT 0,
  `helpful_count` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`review_id`),
  KEY `idx_product_id` (`product_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_rating` (`rating`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `product_reviews_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE,
  CONSTRAINT `product_reviews_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `product_ratings` (
  `rating_id` int(11) NOT NULL AUTO_INCREMENT,
  `product_id` int(11) NOT NULL,
  `rating_avg` decimal(3,2) DEFAULT 0.00,
  `review_count` int(11) DEFAULT 0,
  `rating_1_star` int(11) DEFAULT 0,
  `rating_2_star` int(11) DEFAULT 0,
  `rating_3_star` int(11) DEFAULT 0,
  `rating_4_star` int(11) DEFAULT 0,
  `rating_5_star` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`rating_id`),
  UNIQUE KEY `unique_product_rating` (`product_id`),
  CONSTRAINT `product_ratings_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `product_specifications` (
  `spec_id` int(11) NOT NULL AUTO_INCREMENT,
  `product_id` int(11) NOT NULL,
  `spec_key` varchar(100) NOT NULL,
  `spec_value` text NOT NULL,
  `display_order` int(11) DEFAULT 0,
  PRIMARY KEY (`spec_id`),
  KEY `idx_product_specs` (`product_id`),
  CONSTRAINT `product_specifications_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `discounts` (
  `discount_id` int(11) NOT NULL AUTO_INCREMENT,
  `product_id` int(11) DEFAULT NULL,
  `discount_percent` decimal(5,2) DEFAULT NULL,
  `valid_from` date DEFAULT NULL,
  `valid_to` date DEFAULT NULL,
  PRIMARY KEY (`discount_id`),
  KEY `product_id` (`product_id`),
  CONSTRAINT `discounts_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `cart` (
  `cart_id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `product_id` int(11) DEFAULT NULL,
  `quantity` int(11) DEFAULT 1,
  `added_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`cart_id`),
  KEY `idx_cart_user` (`user_id`),
  KEY `idx_product_id` (`product_id`),
  CONSTRAINT `cart_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `cart_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `orders` (
  `order_id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `total_amount` decimal(10,2) NOT NULL,
  `order_status` enum('pending','processing','shipped','delivered','cancelled') DEFAULT 'pending',
  `payment_method` varchar(50) DEFAULT 'Cash on Delivery',
  `payment_status` enum('unpaid','paid') DEFAULT 'unpaid',
  `delivery_address` text DEFAULT NULL,
  `transaction_id` varchar(100) DEFAULT NULL,
  `estimated_delivery` varchar(50) DEFAULT NULL,
  `order_date` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`order_id`),
  KEY `idx_orders_user` (`user_id`),
  KEY `idx_orders_date` (`order_date`),
  KEY `idx_orders_status` (`order_status`),
  CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `order_items` (
  `order_item_id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` int(11) DEFAULT NULL,
  `product_id` int(11) DEFAULT NULL,
  `product_name` varchar(150) DEFAULT NULL,
  `quantity` int(11) NOT NULL,
  `price_at_purchase` decimal(10,2) NOT NULL,
  `color` varchar(50) DEFAULT '',
  `image_url` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`order_item_id`),
  KEY `idx_order_items_order` (`order_id`),
  KEY `idx_product_id` (`product_id`),
  CONSTRAINT `order_items_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE,
  CONSTRAINT `order_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `wishlists` (
  `wishlist_id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `product_id` int(11) DEFAULT NULL,
  `added_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`wishlist_id`),
  KEY `idx_wishlists_user` (`user_id`),
  KEY `idx_product_id` (`product_id`),
  CONSTRAINT `wishlists_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `wishlists_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `customer_support` (
  `ticket_id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `subject` varchar(150) NOT NULL,
  `message` text NOT NULL,
  `status` enum('open','in_progress','resolved','closed') DEFAULT 'open',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `resolved_by` int(11) DEFAULT NULL,
  `resolved_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`ticket_id`),
  KEY `idx_customer_support_user` (`user_id`),
  KEY `idx_customer_support_status` (`status`),
  KEY `resolved_by` (`resolved_by`),
  CONSTRAINT `customer_support_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL,
  CONSTRAINT `customer_support_ibfk_2` FOREIGN KEY (`resolved_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `promotions` (
  `promotion_id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `discount_percent` decimal(5,2) DEFAULT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `active` tinyint(1) DEFAULT 1,
  PRIMARY KEY (`promotion_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `flash_sales` (
  `flash_sale_id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `start_time` datetime NOT NULL,
  `end_time` datetime NOT NULL,
  `active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`flash_sale_id`),
  KEY `idx_flash_sales_active` (`active`,`end_time`),
  KEY `idx_flash_sales_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `flash_sale_products` (
  `flash_sale_product_id` int(11) NOT NULL AUTO_INCREMENT,
  `flash_sale_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `flash_price` decimal(10,2) NOT NULL,
  `image_path` varchar(255) DEFAULT NULL,
  `display_order` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`flash_sale_product_id`),
  UNIQUE KEY `unique_flash_product` (`flash_sale_id`,`product_id`),
  KEY `product_id` (`product_id`),
  KEY `idx_flash_sale_products_order` (`display_order`),
  KEY `idx_flash_sale_products_created` (`created_at`),
  CONSTRAINT `flash_sale_products_ibfk_1` FOREIGN KEY (`flash_sale_id`) REFERENCES `flash_sales` (`flash_sale_id`) ON DELETE CASCADE,
  CONSTRAINT `flash_sale_products_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `collections` (
  `collection_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `slug` varchar(100) NOT NULL DEFAULT '',
  `description` text DEFAULT NULL,
  `icon` varchar(50) DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `item_count` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1,
  `display_order` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`collection_id`),
  UNIQUE KEY `slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `collection_items` (
  `item_id` int(11) NOT NULL AUTO_INCREMENT,
  `collection_id` int(11) NOT NULL,
  `item_name` varchar(100) NOT NULL,
  `display_order` int(11) DEFAULT 0,
  PRIMARY KEY (`item_id`),
  KEY `collection_id` (`collection_id`),
  CONSTRAINT `collection_items_ibfk_1` FOREIGN KEY (`collection_id`) REFERENCES `collections` (`collection_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `collection_products` (
  `collection_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `added_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`collection_id`,`product_id`),
  KEY `product_id` (`product_id`),
  CONSTRAINT `collection_products_ibfk_1` FOREIGN KEY (`collection_id`) REFERENCES `collections` (`collection_id`) ON DELETE CASCADE,
  CONSTRAINT `collection_products_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `deals_of_the_day` (
  `deal_id` int(11) NOT NULL AUTO_INCREMENT,
  `product_id` int(11) DEFAULT NULL,
  `deal_price` decimal(10,2) DEFAULT NULL,
  `start_date` datetime DEFAULT NULL,
  `end_date` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`deal_id`),
  KEY `product_id` (`product_id`),
  KEY `idx_deals_created` (`created_at`),
  CONSTRAINT `deals_of_the_day_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `deals_timer` (
  `timer_id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(100) NOT NULL DEFAULT 'Timer',
  `description` text DEFAULT NULL,
  `end_time` datetime DEFAULT NULL,
  `days` int(11) DEFAULT 3,
  `hours` int(11) DEFAULT 11,
  `minutes` int(11) DEFAULT 15,
  `seconds` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`timer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `best_sellers` (
  `product_id` int(11) NOT NULL,
  `sales_count` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `selling_point` text DEFAULT NULL,
  `sales_strategy` varchar(255) DEFAULT NULL,
  `last_updated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`product_id`),
  KEY `idx_best_sellers_created` (`created_at`),
  CONSTRAINT `best_sellers_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `trending_products` (
  `trending_product_id` int(11) NOT NULL AUTO_INCREMENT,
  `product_id` int(11) NOT NULL,
  `trending_score` int(11) DEFAULT 0,
  `image_path` varchar(255) DEFAULT NULL,
  `display_order` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `last_updated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`trending_product_id`),
  UNIQUE KEY `unique_trending_product` (`product_id`),
  KEY `idx_trending_products_order` (`display_order`),
  KEY `idx_trending_products_score` (`trending_score`),
  KEY `idx_trending_created` (`created_at`),
  CONSTRAINT `trending_products_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tech_part_products` (
  `product_id` int(11) NOT NULL,
  `display_order` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`product_id`),
  KEY `idx_techpart_created` (`created_at`),
  CONSTRAINT `tech_part_products_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `banners` (
  `banner_id` int(11) NOT NULL AUTO_INCREMENT,
  `banner_type` enum('hero','mid','sidebar') NOT NULL,
  `image_url` varchar(255) NOT NULL,
  `link_url` varchar(255) DEFAULT NULL,
  `title` varchar(100) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `button_text` varchar(50) DEFAULT NULL,
  `display_order` int(11) DEFAULT 0,
  `active` tinyint(1) DEFAULT 1,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`banner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `payments` (
  `payment_id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` int(11) DEFAULT NULL,
  `payment_method` varchar(50) DEFAULT NULL,
  `transaction_id` varchar(100) DEFAULT NULL,
  `amount` decimal(10,2) DEFAULT NULL,
  `payment_status` enum('pending','completed','failed') DEFAULT 'pending',
  `payment_date` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`payment_id`),
  KEY `order_id` (`order_id`),
  CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `payment_methods` (
  `method_id` int(11) NOT NULL AUTO_INCREMENT,
  `method_name` varchar(100) NOT NULL,
  `method_type` varchar(50) NOT NULL DEFAULT 'mobile_banking',
  `is_enabled` tinyint(1) DEFAULT 1,
  `account_number` varchar(50) DEFAULT NULL,
  `display_order` int(11) DEFAULT 0,
  `icon_url` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`method_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `password_reset_tokens` (
  `token_id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `email` varchar(100) NOT NULL,
  `token` varchar(255) NOT NULL,
  `reset_code` varchar(6) DEFAULT NULL,
  `expires_at` datetime NOT NULL,
  `used` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`token_id`),
  UNIQUE KEY `token` (`token`),
  KEY `user_id` (`user_id`),
  KEY `idx_token` (`token`),
  KEY `idx_email` (`email`),
  KEY `idx_expires` (`expires_at`),
  KEY `idx_reset_code` (`reset_code`),
  CONSTRAINT `password_reset_tokens_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `search_history` (
  `search_id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `search_query` varchar(255) NOT NULL,
  `results_count` int(11) DEFAULT 0,
  `searched_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`search_id`),
  KEY `idx_search_query` (`search_query`),
  KEY `idx_searched_at` (`searched_at`),
  KEY `idx_user_query` (`user_id`,`search_query`),
  CONSTRAINT `search_history_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `search_analytics` (
  `analytics_id` int(11) NOT NULL AUTO_INCREMENT,
  `date` date NOT NULL,
  `search_query` varchar(255) NOT NULL,
  `total_searches` int(11) DEFAULT 0,
  `unique_users` int(11) DEFAULT 0,
  `avg_results` int(11) DEFAULT 0,
  `zero_results_count` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`analytics_id`),
  UNIQUE KEY `unique_date_query` (`date`,`search_query`),
  KEY `idx_date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `stock_movements` (
  `movement_id` int(11) NOT NULL AUTO_INCREMENT,
  `product_id` int(11) NOT NULL,
  `movement_type` enum('IN','OUT','ADJUSTMENT') NOT NULL,
  `quantity` int(11) NOT NULL,
  `previous_stock` int(11) NOT NULL,
  `new_stock` int(11) NOT NULL,
  `reference_type` enum('PURCHASE','SALE','RETURN','DAMAGE','ADJUSTMENT','INITIAL') DEFAULT 'ADJUSTMENT',
  `reference_id` int(11) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`movement_id`),
  KEY `idx_product_date` (`product_id`,`created_at`),
  KEY `idx_movement_type` (`movement_type`),
  KEY `idx_reference` (`reference_type`,`reference_id`),
  KEY `created_by` (`created_by`),
  CONSTRAINT `stock_movements_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `stock_alerts` (
  `alert_id` int(11) NOT NULL AUTO_INCREMENT,
  `product_id` int(11) NOT NULL,
  `alert_type` enum('LOW_STOCK','OUT_OF_STOCK','OVERSTOCK') NOT NULL,
  `threshold_quantity` int(11) DEFAULT 5,
  `current_quantity` int(11) NOT NULL,
  `is_resolved` tinyint(1) DEFAULT 0,
  `resolved_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`alert_id`),
  KEY `product_id` (`product_id`),
  KEY `idx_unresolved` (`is_resolved`,`created_at`),
  CONSTRAINT `stock_alerts_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `csrf_tokens` (
  `token_id` int(11) NOT NULL AUTO_INCREMENT,
  `token` varchar(64) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `session_id` varchar(128) DEFAULT NULL,
  `expires_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`token_id`),
  UNIQUE KEY `token` (`token`),
  KEY `idx_token` (`token`),
  KEY `idx_expires` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `rate_limits` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ip_address` varchar(45) NOT NULL,
  `endpoint` varchar(255) NOT NULL,
  `request_count` int(11) DEFAULT 1,
  `window_start` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_ip_endpoint` (`ip_address`,`endpoint`),
  KEY `idx_window` (`window_start`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `reports` (
  `report_id` int(11) NOT NULL AUTO_INCREMENT,
  `admin_id` int(11) DEFAULT NULL,
  `report_type` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `details` text DEFAULT NULL,
  PRIMARY KEY (`report_id`),
  KEY `admin_id` (`admin_id`),
  CONSTRAINT `reports_ibfk_1` FOREIGN KEY (`admin_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `site_settings` (
  `setting_key` varchar(100) NOT NULL,
  `setting_value` text DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------
-- TRIGGERS
-- -----------------------------------------------------------
DELIMITER $$

DROP TRIGGER IF EXISTS `after_brand_insert_search`$$
CREATE TRIGGER `after_brand_insert_search` AFTER INSERT ON `brands` FOR EACH ROW
BEGIN
  INSERT INTO search_suggestions (suggestion_text, suggestion_type)
  VALUES (NEW.brand_name, 'brand')
  ON DUPLICATE KEY UPDATE suggestion_type = 'brand', is_active = TRUE;
END$$

DROP TRIGGER IF EXISTS `after_category_insert_search`$$
CREATE TRIGGER `after_category_insert_search` AFTER INSERT ON `categories` FOR EACH ROW
BEGIN
  INSERT INTO search_suggestions (suggestion_text, suggestion_type)
  VALUES (NEW.category_name, 'category')
  ON DUPLICATE KEY UPDATE suggestion_type = 'category', is_active = TRUE;
END$$

DROP TRIGGER IF EXISTS `after_product_insert_search`$$
CREATE TRIGGER `after_product_insert_search` AFTER INSERT ON `products` FOR EACH ROW
BEGIN
  INSERT INTO search_suggestions (suggestion_text, suggestion_type)
  VALUES (NEW.product_name, 'product')
  ON DUPLICATE KEY UPDATE suggestion_type = 'product', is_active = TRUE;
END$$

DROP TRIGGER IF EXISTS `after_product_stock_update`$$
CREATE TRIGGER `after_product_stock_update` AFTER UPDATE ON `products` FOR EACH ROW
BEGIN
  IF OLD.stock_quantity != NEW.stock_quantity THEN
    INSERT INTO stock_movements (product_id,movement_type,quantity,previous_stock,new_stock,reference_type,notes)
    VALUES (NEW.product_id, IF(NEW.stock_quantity > OLD.stock_quantity,'IN','OUT'),
      ABS(NEW.stock_quantity - OLD.stock_quantity), OLD.stock_quantity, NEW.stock_quantity,
      'ADJUSTMENT', CONCAT('Auto-tracked: Stock changed from ',OLD.stock_quantity,' to ',NEW.stock_quantity));
  END IF;
END$$

DELIMITER ;

-- -----------------------------------------------------------
-- VIEWS
-- -----------------------------------------------------------
DROP VIEW IF EXISTS `v_active_stock_alerts`;
CREATE VIEW `v_active_stock_alerts` AS
  SELECT sa.alert_id, sa.product_id, p.product_name, c.category_name, b.brand_name,
    sa.alert_type, sa.threshold_quantity, sa.current_quantity, sa.created_at,
    TO_DAYS(CURRENT_TIMESTAMP()) - TO_DAYS(sa.created_at) AS days_pending
  FROM stock_alerts sa
  JOIN products p ON sa.product_id = p.product_id
  LEFT JOIN categories c ON p.category_id = c.category_id
  LEFT JOIN brands b ON p.brand_id = b.brand_id
  WHERE sa.is_resolved = 0
  ORDER BY sa.created_at DESC;

DROP VIEW IF EXISTS `v_popular_searches`;
CREATE VIEW `v_popular_searches` AS
  SELECT search_query, COUNT(*) AS search_count, MAX(searched_at) AS last_searched,
    COUNT(DISTINCT user_id) AS unique_users
  FROM search_history
  WHERE searched_at >= CURRENT_TIMESTAMP() - INTERVAL 30 DAY
  GROUP BY search_query HAVING search_count > 1
  ORDER BY search_count DESC, last_searched DESC;

DROP VIEW IF EXISTS `v_stock_summary`;
CREATE VIEW `v_stock_summary` AS
  SELECT p.product_id, p.product_name, c.category_name, b.brand_name,
    p.stock_quantity, p.min_stock_threshold, p.stock_status,
    COALESCE(SUM(CASE WHEN sm.movement_type='IN' THEN sm.quantity ELSE 0 END),0) AS total_stock_in,
    COALESCE(SUM(CASE WHEN sm.movement_type='OUT' THEN sm.quantity ELSE 0 END),0) AS total_stock_out,
    COUNT(DISTINCT sm.movement_id) AS total_movements,
    MAX(sm.created_at) AS last_movement_date
  FROM products p
  LEFT JOIN categories c ON p.category_id = c.category_id
  LEFT JOIN brands b ON p.brand_id = b.brand_id
  LEFT JOIN stock_movements sm ON p.product_id = sm.product_id
  GROUP BY p.product_id, p.product_name, c.category_name, b.brand_name, p.stock_quantity, p.min_stock_threshold, p.stock_status;

DROP VIEW IF EXISTS `v_trending_searches`;
CREATE VIEW `v_trending_searches` AS
  SELECT search_query, COUNT(*) AS search_count, MAX(searched_at) AS last_searched
  FROM search_history
  WHERE searched_at >= CURRENT_TIMESTAMP() - INTERVAL 7 DAY
  GROUP BY search_query
  ORDER BY search_count DESC
  LIMIT 20;

SET FOREIGN_KEY_CHECKS = 1;
COMMIT;
