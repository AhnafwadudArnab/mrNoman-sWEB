-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Apr 14, 2026 at 11:05 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `electrobd`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_search_products` (IN `p_query` VARCHAR(255), IN `p_limit` INT, IN `p_offset` INT)   BEGIN
    DECLARE search_pattern VARCHAR(257);
    SET search_pattern = CONCAT('%', p_query, '%');
    
    SELECT 
        p.*,
        c.category_name,
        b.brand_name,
        d.discount_percent,
        CASE 
            WHEN d.discount_percent IS NOT NULL 
            THEN p.price * (1 - d.discount_percent/100)
            ELSE p.price 
        END as discounted_price,
        
        (
            CASE WHEN p.product_name = p_query THEN 100 ELSE 0 END +
            CASE WHEN p.product_name LIKE CONCAT(p_query, '%') THEN 50 ELSE 0 END +
            CASE WHEN p.product_name LIKE search_pattern THEN 25 ELSE 0 END +
            CASE WHEN p.description LIKE search_pattern THEN 10 ELSE 0 END +
            CASE WHEN c.category_name LIKE search_pattern THEN 15 ELSE 0 END +
            CASE WHEN b.brand_name LIKE search_pattern THEN 15 ELSE 0 END
        ) as relevance_score
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.category_id
    LEFT JOIN brands b ON p.brand_id = b.brand_id
    LEFT JOIN discounts d ON p.product_id = d.product_id 
        AND CURDATE() BETWEEN d.valid_from AND d.valid_to
    WHERE 
        p.product_name LIKE search_pattern
        OR p.description LIKE search_pattern
        OR c.category_name LIKE search_pattern
        OR b.brand_name LIKE search_pattern
    HAVING relevance_score > 0
    ORDER BY relevance_score DESC, p.product_name ASC
    LIMIT p_limit OFFSET p_offset;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_stock_in` (IN `p_product_id` INT, IN `p_quantity` INT, IN `p_reference_type` VARCHAR(20), IN `p_reference_id` INT, IN `p_notes` TEXT, IN `p_created_by` INT)   BEGIN
  DECLARE current_stock INT;
  DECLARE new_stock INT;
  
  
  SELECT stock_quantity INTO current_stock
  FROM products
  WHERE product_id = p_product_id;
  
  
  SET new_stock = current_stock + p_quantity;
  
  
  UPDATE products
  SET stock_quantity = new_stock
  WHERE product_id = p_product_id;
  
  
  
  INSERT INTO stock_movements (
    product_id,
    movement_type,
    quantity,
    previous_stock,
    new_stock,
    reference_type,
    reference_id,
    notes,
    created_by
  ) VALUES (
    p_product_id,
    'IN',
    p_quantity,
    current_stock,
    new_stock,
    p_reference_type,
    p_reference_id,
    p_notes,
    p_created_by
  );
  
  
  SELECT 
    'SUCCESS' as status,
    p_product_id as product_id,
    current_stock as previous_stock,
    new_stock as current_stock,
    p_quantity as quantity_added;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_stock_in_atomic` (IN `p_product_id` INT, IN `p_quantity` INT, IN `p_reason` ENUM('PURCHASE','RETURN','ADJUSTMENT','INITIAL'), IN `p_reference_id` INT, IN `p_notes` TEXT, IN `p_performed_by` INT)   BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock IN operation failed';
    END;
    
    START TRANSACTION;
    
    
    UPDATE products 
    SET stock_quantity = stock_quantity + p_quantity
    WHERE product_id = p_product_id;
    
    
    INSERT INTO stock_movements (
        product_id, movement_type, quantity, 
        quantity_before, quantity_after, reason, notes, performed_by
    )
    SELECT 
        p_product_id, 'IN', p_quantity,
        stock_quantity - p_quantity, stock_quantity,
        p_reason, p_notes, p_performed_by
    FROM products
    WHERE product_id = p_product_id;
    
    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_stock_out` (IN `p_product_id` INT, IN `p_quantity` INT, IN `p_reference_type` VARCHAR(20), IN `p_reference_id` INT, IN `p_notes` TEXT, IN `p_created_by` INT)   BEGIN
  DECLARE current_stock INT;
  DECLARE new_stock INT;
  
  
  SELECT stock_quantity INTO current_stock
  FROM products
  WHERE product_id = p_product_id;
  
  
  IF current_stock < p_quantity THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Insufficient stock available';
  END IF;
  
  
  SET new_stock = current_stock - p_quantity;
  
  
  UPDATE products
  SET stock_quantity = new_stock
  WHERE product_id = p_product_id;
  
  
  INSERT INTO stock_movements (
    product_id,
    movement_type,
    quantity,
    previous_stock,
    new_stock,
    reference_type,
    reference_id,
    notes,
    created_by
  ) VALUES (
    p_product_id,
    'OUT',
    p_quantity,
    current_stock,
    new_stock,
    p_reference_type,
    p_reference_id,
    p_notes,
    p_created_by
  );
  
  
  SELECT 
    'SUCCESS' as status,
    p_product_id as product_id,
    current_stock as previous_stock,
    new_stock as current_stock,
    p_quantity as quantity_removed;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_stock_out_atomic` (IN `p_product_id` INT, IN `p_quantity` INT, IN `p_reason` ENUM('SALE','DAMAGE','ADJUSTMENT','RETURN'), IN `p_reference_id` INT, IN `p_notes` TEXT, IN `p_performed_by` INT)   BEGIN
    DECLARE current_stock INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock OUT operation failed';
    END;
    
    START TRANSACTION;
    
    
    SELECT stock_quantity INTO current_stock
    FROM products
    WHERE product_id = p_product_id
    FOR UPDATE;
    
    
    IF current_stock < p_quantity THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Insufficient stock';
    END IF;
    
    
    UPDATE products 
    SET stock_quantity = stock_quantity - p_quantity
    WHERE product_id = p_product_id;
    
    
    INSERT INTO stock_movements (
        product_id, movement_type, quantity,
        quantity_before, quantity_after, reason, notes, performed_by
    )
    VALUES (
        p_product_id, 'OUT', p_quantity,
        current_stock, current_stock - p_quantity,
        p_reason, p_notes, p_performed_by
    );
    
    COMMIT;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `banners`
--

CREATE TABLE `banners` (
  `banner_id` int(11) NOT NULL,
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
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `banners`
--

INSERT INTO `banners` (`banner_id`, `banner_type`, `image_url`, `link_url`, `title`, `description`, `button_text`, `display_order`, `active`, `start_date`, `end_date`, `created_at`, `updated_at`) VALUES
(40, 'sidebar', '', '', 'FLASH SALE', 'Up to 20% Off on Earbuds', 'VIEW ALL', 0, 1, NULL, NULL, '2026-04-14 06:31:52', '2026-04-14 06:31:52'),
(53, 'sidebar', 'assets/BestSale/pink lanther.jpg', NULL, 'FLASH SALE', NULL, 'VIEW ALL', 0, 1, NULL, NULL, '2026-04-14 08:08:31', '2026-04-14 08:08:31'),
(60, 'sidebar', 'assets/BestSale/pink lanther.jpg', NULL, 'FLASH SALE', NULL, 'VIEW ALL', 0, 1, NULL, NULL, '2026-04-14 08:09:56', '2026-04-14 08:09:56'),
(101, 'hero', 'assets/Hero banner logos/dopp.png', '', 'HOT DEALS', '', '', 0, 1, NULL, NULL, '2026-04-14 09:00:41', '2026-04-14 09:00:41'),
(102, 'hero', 'assets/Hero banner logos/top.png', '', 'NEW IN', '', '', 1, 1, NULL, NULL, '2026-04-14 09:00:41', '2026-04-14 09:00:41'),
(143, 'mid', 'assets/1.png', '/deals', 'Banner 1', '', 'Shop Now', 1, 1, '2026-04-14', '2027-04-14', '2026-04-14 09:01:42', '2026-04-14 09:01:42'),
(144, 'mid', 'assets/2.png', '/deals', 'Banner 2', '', 'Shop Now', 2, 1, '2026-04-14', '2027-04-14', '2026-04-14 09:01:42', '2026-04-14 09:01:42'),
(145, 'mid', '/uploads/img_69de02735afc77.98844783.png', '/deals', 'Banner 3', '', 'Shop Now', 3, 1, '2026-04-14', '2027-04-14', '2026-04-14 09:01:42', '2026-04-14 09:01:42');

-- --------------------------------------------------------

--
-- Table structure for table `best_sellers`
--

CREATE TABLE `best_sellers` (
  `product_id` int(11) NOT NULL,
  `sales_count` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `selling_point` text DEFAULT NULL,
  `sales_strategy` varchar(255) DEFAULT NULL,
  `last_updated` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `best_sellers`
--

INSERT INTO `best_sellers` (`product_id`, `sales_count`, `created_at`, `selling_point`, `sales_strategy`, `last_updated`) VALUES
(1, 565, '2026-03-05 08:00:00', 'Large 5.5L cooker ideal for family-sized meals.', 'Cook Big, Live Large', '2026-03-05 08:00:00'),
(2, 520, '2026-03-05 08:00:00', 'Affordable grinder with strong everyday performance.', 'Your Daily Spice Partner', '2026-03-05 08:00:00'),
(3, 540, '2026-03-05 08:00:00', 'Fast-boil kettle for daily tea and coffee needs.', 'Hot Water in Minutes', '2026-03-05 08:00:00'),
(4, 450, '2026-04-14 08:08:31', NULL, NULL, '2026-04-14 08:08:31'),
(5, 627, '2026-03-05 08:00:00', 'Top rechargeable fan with reliable backup for load-shedding.', 'Stay Cool, No Matter the Power Cut', '2026-03-05 08:00:00'),
(10, 390, '2026-04-14 08:08:31', NULL, NULL, '2026-04-14 08:08:31'),
(40, 590, '2026-03-05 08:00:00', 'Trusted rice cooker for consistent everyday cooking.', 'Perfect Rice for Every Meal', '2026-03-05 08:00:00'),
(48, 461, '2026-03-05 08:00:00', 'Compact sandwich maker that converts quickly.', 'Quick Breakfast Champion', '2026-03-05 08:00:00'),
(55, 471, '2026-03-05 08:00:00', 'High-power blender suited for heavy use families.', 'Blend Fast, Blend More', '2026-03-05 08:00:00'),
(62, 505, '2026-03-05 08:00:00', 'Digital air fryer with strong demand in smart kitchens.', 'Healthy Frying, Smart Living', '2026-03-05 08:00:00'),
(74, 498, '2026-03-05 08:00:00', 'Popular 25L oven for baking and grilling at home.', 'Bake Better, Every Day', '2026-03-05 08:00:00'),
(76, 485, '2026-03-05 08:00:00', 'Reliable 1.8L rice cooker at a strong value point.', 'Daily Cooking Made Easy', '2026-03-05 08:00:00'),
(122, 0, '2026-04-14 07:56:00', NULL, NULL, '2026-04-14 07:56:00');

-- --------------------------------------------------------

--
-- Table structure for table `brands`
--

CREATE TABLE `brands` (
  `brand_id` int(11) NOT NULL,
  `brand_name` varchar(100) NOT NULL,
  `brand_logo` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `brands`
--

INSERT INTO `brands` (`brand_id`, `brand_name`, `brand_logo`) VALUES
(1, 'Kemei', 'assets/Brand Logo/images (2).png'),
(2, 'Walton', 'assets/Brand Logo/walton.png'),
(3, 'Nova', 'assets/Brand Logo/images.png'),
(4, 'LG', 'assets/Brand Logo/LG.png'),
(5, 'jaipan', 'assets/Brand Logo/images (1).png'),
(6, 'Gree', 'assets/Brand Logo/Gree.png'),
(7, 'Jamuna', 'assets/Brand Logo/jamuna.jpg'),
(8, 'Panasonic', 'assets/Brand Logo/panasonnic.png'),
(9, 'Singer', 'assets/Brand Logo/singer.png'),
(10, 'Vision', 'assets/Brand Logo/vision.jpg'),
(11, 'AV', 'assets/Brand Logo/images (6).png'),
(12, 'Noha', 'assets/Brand Logo/images (7).png'),
(24, 'Philips', 'assets/Brand Logo/images (3).png'),
(25, 'Havells', 'assets/Brand Logo/images (4).png'),
(26, 'ORPAT', 'assets/Brand Logo/images (5).png'),
(27, 'Shinon', 'assets/Brand Logo/images (6).png'),
(28, 'Whirlpool', 'assets/Brand Logo/images (7).png'),
(29, 'Miyoko', 'assets/Brand Logo/images.jpg'),
(32, 'Kennede', 'assets/Brand Logo/images (3).jpg'),
(33, 'SOKA', 'assets/Brand Logo/images (4).jpg'),
(35, 'ButterFly', 'assets/Brand Logo/images (6).jpg'),
(36, 'National Electronics', 'assets/Brand Logo/images (7).jpg'),
(37, 'Hawkins', 'assets/Brand Logo/images (8).jpg'),
(38, 'Nima', 'assets/Brand Logo/images (9).jpg'),
(39, 'Hero', 'assets/Brand Logo/images (10).jpg');

--
-- Triggers `brands`
--
DELIMITER $$
CREATE TRIGGER `after_brand_insert_search` AFTER INSERT ON `brands` FOR EACH ROW BEGIN
    INSERT INTO search_suggestions (suggestion_text, suggestion_type)
    VALUES (NEW.brand_name, 'brand')
    ON DUPLICATE KEY UPDATE 
        suggestion_type = 'brand',
        is_active = TRUE;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `cart`
--

CREATE TABLE `cart` (
  `cart_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `product_id` int(11) DEFAULT NULL,
  `quantity` int(11) DEFAULT 1,
  `added_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `cart`
--

INSERT INTO `cart` (`cart_id`, `user_id`, `product_id`, `quantity`, `added_at`) VALUES
(2, 3, 6, 1, '2026-03-01 08:42:26'),
(19, 19, 5, 1, '2026-03-27 14:27:18'),
(28, 22, 122, 1, '2026-04-14 07:56:11');

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

CREATE TABLE `categories` (
  `category_id` int(11) NOT NULL,
  `category_name` varchar(50) NOT NULL,
  `category_image` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `categories`
--

INSERT INTO `categories` (`category_id`, `category_name`, `category_image`) VALUES
(1, 'Kitchen Appliances', '/assets/categories/kitchen.png'),
(2, 'Personal Care & Lifestyle', '/assets/categories/personalcare.png'),
(3, 'Home Comfort & Utility', '/assets/categories/homecomfort.png'),
(4, 'Electronics & Gadgets', '/assets/categories/lighting.png'),
(5, 'Wiring & Cables', '/assets/categories/wiring.png'),
(6, 'Tools & Hardware', '/assets/categories/tools.png'),
(7, 'Blenders & Mixers', NULL),
(8, 'Irons & Steamers', NULL),
(9, 'Rice Cookers', NULL),
(10, 'Air Fryers', NULL),
(13, 'Personal Care', '/assets/categories/personalcare.png'),
(14, 'Home Appliances', '/assets/categories/homecomfort.png'),
(15, 'Fan & Cooling', '/assets/categories/homecomfort.png');

--
-- Triggers `categories`
--
DELIMITER $$
CREATE TRIGGER `after_category_insert_search` AFTER INSERT ON `categories` FOR EACH ROW BEGIN
    INSERT INTO search_suggestions (suggestion_text, suggestion_type)
    VALUES (NEW.category_name, 'category')
    ON DUPLICATE KEY UPDATE 
        suggestion_type = 'category',
        is_active = TRUE;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `collections`
--

CREATE TABLE `collections` (
  `collection_id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `slug` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `icon` varchar(50) DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `item_count` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1,
  `display_order` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `collections`
--

INSERT INTO `collections` (`collection_id`, `name`, `slug`, `description`, `icon`, `image_url`, `item_count`, `is_active`, `display_order`, `created_at`) VALUES
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

CREATE TABLE `collection_items` (
  `item_id` int(11) NOT NULL,
  `collection_id` int(11) NOT NULL,
  `item_name` varchar(100) NOT NULL,
  `display_order` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `collection_items`
--

INSERT INTO `collection_items` (`item_id`, `collection_id`, `item_name`, `display_order`) VALUES
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
(11, 5, 'Head Massage', 2),
(12, 1, 'Charger Fan', 1),
(13, 1, 'Table Fan', 2),
(14, 1, 'Ceiling Fan', 3),
(15, 2, 'Blender', 1),
(16, 2, 'Rice Cooker', 2),
(17, 2, 'Oven', 3),
(18, 2, 'Induction Stove', 4),
(19, 3, 'Hair Dryer', 1),
(20, 3, 'Trimmer', 2),
(21, 3, 'Massager', 3),
(22, 4, 'Hand Blender', 1),
(23, 4, 'Stand Blender', 2),
(24, 4, 'Food Chopper', 3),
(25, 5, 'Steam Iron', 1),
(26, 5, 'Travel Iron', 2),
(27, 6, 'Rice Cooker 1.8L', 1),
(28, 6, 'Rice Cooker 2.8L', 2),
(29, 1, 'Charger Fan', 1),
(30, 1, 'Table Fan', 2),
(31, 1, 'Ceiling Fan', 3),
(32, 2, 'Blender', 1),
(33, 2, 'Rice Cooker', 2),
(34, 2, 'Oven', 3),
(35, 2, 'Induction Stove', 4),
(36, 3, 'Hair Dryer', 1),
(37, 3, 'Trimmer', 2),
(38, 3, 'Massager', 3),
(39, 4, 'Hand Blender', 1),
(40, 4, 'Stand Blender', 2),
(41, 4, 'Food Chopper', 3),
(42, 5, 'Steam Iron', 1),
(43, 5, 'Travel Iron', 2),
(44, 6, 'Rice Cooker 1.8L', 1),
(45, 6, 'Rice Cooker 2.8L', 2);

-- --------------------------------------------------------

--
-- Table structure for table `collection_products`
--

CREATE TABLE `collection_products` (
  `collection_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `added_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `collection_products`
--

INSERT INTO `collection_products` (`collection_id`, `product_id`, `added_at`) VALUES
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

CREATE TABLE `csrf_tokens` (
  `token_id` int(11) NOT NULL,
  `token` varchar(64) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `session_id` varchar(128) DEFAULT NULL,
  `expires_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `customer_support`
--

CREATE TABLE `customer_support` (
  `ticket_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `subject` varchar(150) NOT NULL,
  `message` text NOT NULL,
  `status` enum('open','in_progress','resolved','closed') DEFAULT 'open',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `resolved_by` int(11) DEFAULT NULL,
  `resolved_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `deals_of_the_day`
--

CREATE TABLE `deals_of_the_day` (
  `deal_id` int(11) NOT NULL,
  `product_id` int(11) DEFAULT NULL,
  `deal_price` decimal(10,2) DEFAULT NULL,
  `start_date` datetime DEFAULT NULL,
  `end_date` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `deals_of_the_day`
--

INSERT INTO `deals_of_the_day` (`deal_id`, `product_id`, `deal_price`, `start_date`, `end_date`, `created_at`) VALUES
(21, 5, 1990.00, '2026-03-05 00:00:00', '2026-03-12 23:59:59', '2026-03-05 08:00:00'),
(22, 40, 2390.00, '2026-03-05 00:00:00', '2026-03-12 23:59:59', '2026-03-05 08:00:00'),
(23, 62, 6490.00, '2026-03-05 00:00:00', '2026-03-12 23:59:59', '2026-03-05 08:00:00'),
(24, 74, 7690.00, '2026-03-05 00:00:00', '2026-03-12 23:59:59', '2026-03-05 08:00:00'),
(25, 76, 2990.00, '2026-03-05 00:00:00', '2026-03-12 23:59:59', '2026-03-05 08:00:00'),
(26, 48, 1490.00, '2026-03-05 00:00:00', '2026-03-12 23:59:59', '2026-03-05 08:00:00'),
(27, 51, 1390.00, '2026-03-05 00:00:00', '2026-03-12 23:59:59', '2026-03-05 08:00:00'),
(28, 57, 3290.00, '2026-03-05 00:00:00', '2026-03-12 23:59:59', '2026-03-05 08:00:00'),
(29, 67, 1090.00, '2026-03-05 00:00:00', '2026-03-12 23:59:59', '2026-03-05 08:00:00'),
(30, 70, 2590.00, '2026-03-05 00:00:00', '2026-03-12 23:59:59', '2026-03-05 08:00:00'),
(37, 1, 1440.00, NULL, '2027-04-14 14:08:31', '2026-04-14 08:08:31'),
(38, 2, 3600.00, NULL, '2027-04-14 14:08:31', '2026-04-14 08:08:31'),
(39, 5, 1200.00, NULL, '2027-04-14 14:08:31', '2026-04-14 08:08:31'),
(40, 8, 1040.00, NULL, '2027-04-14 14:08:31', '2026-04-14 08:08:31'),
(41, 10, 1520.00, NULL, '2027-04-14 14:08:31', '2026-04-14 08:08:31'),
(42, 28, 1280.00, NULL, '2027-04-14 14:08:31', '2026-04-14 08:08:31'),
(43, 29, 1760.00, NULL, '2027-04-14 14:08:31', '2026-04-14 08:08:31'),
(44, 7, 1280.00, NULL, '2027-04-14 14:08:31', '2026-04-14 08:08:31'),
(45, 12, 1120.00, NULL, '2027-04-14 14:08:31', '2026-04-14 08:08:31'),
(46, 1, 1440.00, NULL, '2027-04-14 14:09:53', '2026-04-14 08:09:53'),
(47, 2, 3600.00, NULL, '2027-04-14 14:09:53', '2026-04-14 08:09:53'),
(48, 5, 1200.00, NULL, '2027-04-14 14:09:53', '2026-04-14 08:09:53'),
(49, 8, 1040.00, NULL, '2027-04-14 14:09:53', '2026-04-14 08:09:53'),
(50, 10, 1520.00, NULL, '2027-04-14 14:09:53', '2026-04-14 08:09:53'),
(51, 28, 1280.00, NULL, '2027-04-14 14:09:53', '2026-04-14 08:09:53'),
(52, 29, 1760.00, NULL, '2027-04-14 14:09:53', '2026-04-14 08:09:53'),
(53, 7, 1280.00, NULL, '2027-04-14 14:09:53', '2026-04-14 08:09:53'),
(54, 12, 1120.00, NULL, '2027-04-14 14:09:53', '2026-04-14 08:09:53');

-- --------------------------------------------------------

--
-- Table structure for table `deals_timer`
--

CREATE TABLE `deals_timer` (
  `timer_id` int(11) NOT NULL,
  `title` varchar(100) NOT NULL DEFAULT 'Timer',
  `description` text DEFAULT NULL,
  `end_time` datetime DEFAULT NULL,
  `days` int(11) DEFAULT 3,
  `hours` int(11) DEFAULT 11,
  `minutes` int(11) DEFAULT 15,
  `seconds` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `deals_timer`
--

INSERT INTO `deals_timer` (`timer_id`, `title`, `description`, `end_time`, `days`, `hours`, `minutes`, `seconds`, `is_active`, `updated_at`) VALUES
(3, 'Offers', 'boishakhi offer', '2026-04-16 00:00:00', 0, 0, 0, 0, 1, '2026-04-14 06:25:51');

-- --------------------------------------------------------

--
-- Table structure for table `discounts`
--

CREATE TABLE `discounts` (
  `discount_id` int(11) NOT NULL,
  `product_id` int(11) DEFAULT NULL,
  `discount_percent` decimal(5,2) DEFAULT NULL,
  `valid_from` date DEFAULT NULL,
  `valid_to` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `flash_sales`
--

CREATE TABLE `flash_sales` (
  `flash_sale_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `start_time` datetime NOT NULL,
  `end_time` datetime NOT NULL,
  `active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `flash_sales`
--

INSERT INTO `flash_sales` (`flash_sale_id`, `title`, `start_time`, `end_time`, `active`, `created_at`) VALUES
(1, 'Weekend Flash Sale', '2026-03-05 10:00:00', '2026-04-26 19:22:23', 1, '2026-03-05 08:00:00'),
(2, 'Auto Test Flash', '2026-04-03 22:59:36', '2026-04-05 23:59:36', 0, '2026-04-03 17:59:36');

-- --------------------------------------------------------

--
-- Table structure for table `flash_sale_products`
--

CREATE TABLE `flash_sale_products` (
  `flash_sale_product_id` int(11) NOT NULL,
  `flash_sale_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `flash_price` decimal(10,2) NOT NULL,
  `image_path` varchar(255) DEFAULT NULL,
  `display_order` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `flash_sale_products`
--

INSERT INTO `flash_sale_products` (`flash_sale_product_id`, `flash_sale_id`, `product_id`, `flash_price`, `image_path`, `display_order`, `created_at`) VALUES
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
(12, 1, 61, 2390.00, NULL, 12, '2026-03-05 08:00:00'),
(15, 2, 48, 1390.00, NULL, 1, '2026-04-03 17:59:36'),
(16, 2, 49, 2720.00, NULL, 2, '2026-04-03 17:59:36'),
(18, 1, 1, 1350.00, 'assets/flash/av.jpg', 1, '2026-04-14 08:08:31'),
(19, 1, 8, 975.00, 'assets/flash/dryer.jpg', 2, '2026-04-14 08:08:31'),
(20, 1, 10, 1425.00, 'assets/flash/nima_grinder.jpg', 3, '2026-04-14 08:08:31'),
(21, 1, 3, 900.00, 'assets/flash/kennede.jpg', 4, '2026-04-14 08:08:31'),
(22, 1, 5, 1125.00, 'assets/flash/handmixxer.jpg', 5, '2026-04-14 08:08:31'),
(23, 1, 6, 825.00, 'assets/flash/ironma.jpg', 6, '2026-04-14 08:08:31'),
(24, 1, 28, 1200.00, 'assets/flash/miyoko_kettle.jpg', 7, '2026-04-14 08:08:31'),
(25, 1, 29, 1650.00, 'assets/flash/pink.jpg', 8, '2026-04-14 08:08:31');

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `order_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `total_amount` decimal(10,2) NOT NULL,
  `order_status` enum('pending','processing','shipped','delivered','cancelled') DEFAULT 'pending',
  `payment_method` varchar(50) DEFAULT 'Cash on Delivery',
  `payment_status` enum('unpaid','paid') DEFAULT 'unpaid',
  `delivery_address` text DEFAULT NULL,
  `transaction_id` varchar(100) DEFAULT NULL,
  `estimated_delivery` varchar(50) DEFAULT NULL,
  `order_date` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`order_id`, `user_id`, `total_amount`, `order_status`, `payment_method`, `payment_status`, `delivery_address`, `transaction_id`, `estimated_delivery`, `order_date`) VALUES
(43, 20, 4500.00, 'cancelled', 'Nagad', 'unpaid', 'flaroki bazar,munshiganj, munshiganj,dhaka - 4512', '44sdreex', '9 April 2026', '2026-04-03 20:35:47'),
(44, 21, 4400.00, 'delivered', 'Cash on Delivery', 'unpaid', 'Inladan road,Ujbekistan, 12flat,23 road, ujbekistan 5408, ujbekistan - 5408', 'COD-1775738879968', '14 April 2026', '2026-04-09 12:47:59'),
(48, 22, 2200.00, 'processing', 'Nagad', 'unpaid', 'mouchak,dhaka, dhaka - 1200', 'jfkkszzx47', '18 April 2026', '2026-04-13 10:06:41'),
(49, 22, 18000.00, 'pending', 'bKash', 'unpaid', 'mouchak,Dhaka, 13 building no,mouchak,dhaka, dhaka 1400, dhaka - 1001', 'jshbdxvvxd', '18 April 2026', '2026-04-13 10:33:04'),
(50, 22, 1850.00, 'delivered', 'Cash on Delivery', 'unpaid', 'fokirapol dhaka, Dhaka - 1212', 'COD-1776148408773', '19 April 2026', '2026-04-14 06:33:29');

-- --------------------------------------------------------

--
-- Table structure for table `order_items`
--

CREATE TABLE `order_items` (
  `order_item_id` int(11) NOT NULL,
  `order_id` int(11) DEFAULT NULL,
  `product_id` int(11) DEFAULT NULL,
  `product_name` varchar(150) DEFAULT NULL,
  `quantity` int(11) NOT NULL,
  `price_at_purchase` decimal(10,2) NOT NULL,
  `color` varchar(50) DEFAULT '',
  `image_url` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `order_items`
--

INSERT INTO `order_items` (`order_item_id`, `order_id`, `product_id`, `product_name`, `quantity`, `price_at_purchase`, `color`, `image_url`) VALUES
(34, 43, 55, 'LR2018 Blender', 1, 4500.00, '', 'assets/flash/lr2018.jpg'),
(35, 44, 5, 'Kennede Charger Fan 2912', 2, 2200.00, '', 'assets/Deals of the Day/kennede_charger_fan.jpg'),
(39, 48, 5, 'Kennede Charger Fan 2912', 1, 2200.00, '', 'assets/Deals of the Day/kennede_charger_fan.jpg'),
(40, 49, 25, 'Corsair K95 RGB Platinum Mechanical Gaming Keyboard', 1, 18000.00, '', 'assets/prod/09.png'),
(41, 50, 48, 'AV Sandwich Maker', 1, 1850.00, '', 'assets/trends/av_sandwich_maker.jpg');

-- --------------------------------------------------------

--
-- Table structure for table `password_reset_tokens`
--

CREATE TABLE `password_reset_tokens` (
  `token_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `email` varchar(100) NOT NULL,
  `token` varchar(255) NOT NULL,
  `reset_code` varchar(6) DEFAULT NULL,
  `expires_at` datetime NOT NULL,
  `used` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `password_reset_tokens`
--

INSERT INTO `password_reset_tokens` (`token_id`, `user_id`, `email`, `token`, `reset_code`, `expires_at`, `used`, `created_at`) VALUES
(26, 20, '4irh456@gmail.com', 'da494d7286e73595253625eae67f17298a820222a1dcdcb1799a2cbf26e38843', '132383', '2026-04-04 03:14:58', 1, '2026-04-03 20:14:58');

-- --------------------------------------------------------

--
-- Table structure for table `payments`
--

CREATE TABLE `payments` (
  `payment_id` int(11) NOT NULL,
  `order_id` int(11) DEFAULT NULL,
  `payment_method` varchar(50) DEFAULT NULL,
  `transaction_id` varchar(100) DEFAULT NULL,
  `amount` decimal(10,2) DEFAULT NULL,
  `payment_status` enum('pending','completed','failed') DEFAULT 'pending',
  `payment_date` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `payment_methods`
--

CREATE TABLE `payment_methods` (
  `method_id` int(11) NOT NULL,
  `method_name` varchar(100) NOT NULL,
  `method_type` varchar(50) NOT NULL DEFAULT 'mobile_banking',
  `is_enabled` tinyint(1) DEFAULT 1,
  `account_number` varchar(50) DEFAULT NULL,
  `display_order` int(11) DEFAULT 0,
  `icon_url` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `payment_methods`
--

INSERT INTO `payment_methods` (`method_id`, `method_name`, `method_type`, `is_enabled`, `account_number`, `display_order`, `icon_url`, `created_at`, `updated_at`) VALUES
(1, 'bKash', 'mobile_banking', 1, '01996-242974', 1, '', '2026-03-01 13:10:23', '2026-03-29 14:37:03'),
(2, 'Nagad', 'mobile_banking', 1, '01840658317', 2, '', '2026-03-01 13:10:23', '2026-03-29 14:37:30'),
(6, 'Cash on Delivery', 'cash', 1, '', 3, '', '2026-03-01 13:10:45', '2026-04-03 20:40:25');

-- --------------------------------------------------------

--
-- Table structure for table `products`
--

CREATE TABLE `products` (
  `product_id` int(11) NOT NULL,
  `category_id` int(11) DEFAULT NULL,
  `brand_id` int(11) DEFAULT NULL,
  `product_name` varchar(150) NOT NULL,
  `description` text DEFAULT NULL,
  `price` decimal(10,2) NOT NULL,
  `stock_quantity` int(11) DEFAULT 0,
  `image_url` varchar(255) DEFAULT NULL,
  `specs_json` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `min_stock_threshold` int(11) DEFAULT 5 COMMENT 'Minimum stock before alert',
  `max_stock_threshold` int(11) DEFAULT 1000 COMMENT 'Maximum stock capacity',
  `stock_status` enum('IN_STOCK','LOW_STOCK','OUT_OF_STOCK') GENERATED ALWAYS AS (case when `stock_quantity` <= 0 then 'OUT_OF_STOCK' when `stock_quantity` <= `min_stock_threshold` then 'LOW_STOCK' else 'IN_STOCK' end) STORED
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `products`
--

INSERT INTO `products` (`product_id`, `category_id`, `brand_id`, `product_name`, `description`, `price`, `stock_quantity`, `image_url`, `specs_json`, `created_at`, `min_stock_threshold`, `max_stock_threshold`) VALUES
(1, 1, 2, 'Miyako Curry Cooker 5.5L', 'Family Reliable: 5.5L large capacity, non-stick coating, and automatic cooking mode. Best for cooking large portions of curry or rice for big families in one go.', 2500.00, 14, 'assets/Deals of the Day/miyoko.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
(2, 6, 2, 'Nima 2-in-1 Grinder 400W', 'Budget Friendly: 450W powerful motor, stainless steel blades, suitable for dry and wet grinding. The most popular choice for grinding spices or coffee quickly at a low price.', 1450.00, 25, 'assets/Deals of the Day/nima_grinder.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
(3, 1, 2, 'Miyako Kettle 180 PS 1.8L', 'Quick Solution: 1.8L capacity, auto-shutoff feature (turns off automatically when water boils). The best choice for getting hot water for tea or coffee in just a few minutes.', 1450.00, 28, 'assets/Deals of the Day/miyoko_kettle.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
(4, 2, 3, 'Sokany Hair Dryer HS-3820', 'Perfect Look: 2000-2200W power, hot and cold air options, includes concentrator nozzle. Affordable and durable for achieving a salon-style hair drying experience at home.', 1180.00, 20, 'assets/Deals of the Day/sokany_dyer.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
(5, 3, 2, 'Kennede Charger Fan 2912', 'Load-shedding Master: 12-inch size, rechargeable battery, 5–6 hours backup, and built-in LED light. Your best friend during summer days due to its long-lasting battery backup.', 2200.00, 10, 'assets/Deals of the Day/kennede_charger_fan.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
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
(18, 7, 1, 'Hand Blender Pro 500W', 'Professional hand blender 500W with whisk and chopper attachments.', 2200.00, 30, 'assets/prod/hand_blender23.jpg', NULL, '2026-04-14 08:08:31', 5, 1000),
(19, 3, 4, 'LG Table Fan 16\"', 'LG Table Fan with 3 speed settings and oscillation. Energy-efficient and quiet operation.', 2200.00, 20, 'assets/prod/hFan3.jpg', NULL, '2026-03-01 07:11:36', 5, 1000),
(20, 2, 8, 'Food Chopper 300W', 'Electric food chopper 300W with 1.2L bowl, stainless steel blades.', 1200.00, 55, 'assets/prod/chopper.jpg', NULL, '2026-04-14 08:08:31', 5, 1000),
(21, 4, 6, 'Hanger Fan 3-Speed', 'Hanging fan with 3 speed settings, remote control, timer function.', 2500.00, 35, 'assets/prod/hFan3.jpg', NULL, '2026-04-14 08:08:31', 5, 1000),
(22, 4, 10, 'Fan Rechargeable 2-in-1', 'Rechargeable table & wall fan, 4000mAh battery, USB-C charging.', 1800.00, 60, 'assets/prod/fan2.jpg', NULL, '2026-04-14 08:08:31', 5, 1000),
(23, 3, 9, 'Trimmer 2 Cordless', 'Cordless trimmer with precision blade, 45 min runtime, USB charging.', 1400.00, 50, 'assets/prod/trimmeer2.jpg', NULL, '2026-04-14 08:08:31', 5, 1000),
(24, 8, 3, 'Tele Sett Iron', 'Travel steam iron 1000W, compact design, dual voltage.', 900.00, 75, 'assets/prod/tele_sett.jpg', NULL, '2026-04-14 08:08:31', 5, 1000),
(25, 4, 5, 'food warmer', 'Cherry MX Speed switches,', 18000.00, 14, 'assets/prod/09.png', NULL, '2026-03-01 07:11:36', 5, 1000),
(26, 7, 1, 'Mini Hand Mixer', 'Hand mixer 200W with 5 speed settings, 2 beaters included.', 800.00, 80, 'assets/prod/minihand.jpg', NULL, '2026-04-14 08:08:31', 5, 1000),
(27, 2, 2, 'Prestige Cooker', 'Pressure cooker 3L stainless steel, safety valve, induction compatible.', 3200.00, 25, 'assets/BestSale/prestige.jpg', NULL, '2026-04-14 08:08:31', 5, 1000),
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
(48, 1, 9, 'AV Sandwich Maker', 'High quality AV Sandwich Maker from Singer. Perfect for your home needs.', 1850.00, 59, 'assets/trends/av_sandwich_maker.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(49, 13, 8, 'Hair Dryer Professional', 'High quality Hair Dryer Professional from Philips. Perfect for your home needs.', 3200.00, 45, 'assets/trends/hair_drier.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(50, 13, 8, 'Hair Dryer Compact', 'High quality Hair Dryer Compact from Panasonic. Perfect for your home needs.', 1950.00, 40, 'assets/flash/dyrer.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(51, 1, 2, 'Hand Mixer', 'High quality Hand Mixer from Walton. Perfect for your home needs.', 1650.00, 37, 'assets/flash/handmixxer.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(52, 14, 10, 'Iron Master', 'High quality Iron Master from Vision. Perfect for your home needs.', 2100.00, 60, 'assets/flash/ironma.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(53, 1, 7, 'JY Mini Rice Cooker 1880', 'High quality JY Mini Rice Cooker 1880 from Jamuna. Perfect for your home needs.', 3200.00, 30, 'assets/flash/jy mini 1880.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(54, 15, 4, 'Kennede Charger Fan', 'High quality Kennede Charger Fan from LG. Perfect for your home needs.', 2800.00, 55, 'assets/flash/kennede.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
(55, 1, 3, 'LR2018 Blender', 'High quality LR2018 Blender from Samsung. Perfect for your home needs.', 4500.00, 24, 'assets/flash/lr2018.jpg', NULL, '2026-03-02 08:21:39', 5, 1000),
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
(122, 5, 32, 'yt', 'hhh', 450.00, 10, '/uploads/img_69ddf30fa3cf42.29250226.jpg', NULL, '2026-04-14 07:55:59', 5, 1000);

--
-- Triggers `products`
--
DELIMITER $$
CREATE TRIGGER `after_product_insert_search` AFTER INSERT ON `products` FOR EACH ROW BEGIN
    INSERT INTO search_suggestions (suggestion_text, suggestion_type)
    VALUES (NEW.product_name, 'product')
    ON DUPLICATE KEY UPDATE 
        suggestion_type = 'product',
        is_active = TRUE;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `after_product_stock_update` AFTER UPDATE ON `products` FOR EACH ROW BEGIN
  IF OLD.stock_quantity != NEW.stock_quantity THEN
    INSERT INTO stock_movements (
      product_id,
      movement_type,
      quantity,
      previous_stock,
      new_stock,
      reference_type,
      notes
    ) VALUES (
      NEW.product_id,
      IF(NEW.stock_quantity > OLD.stock_quantity, 'IN', 'OUT'),
      ABS(NEW.stock_quantity - OLD.stock_quantity),
      OLD.stock_quantity,
      NEW.stock_quantity,
      'ADJUSTMENT',
      CONCAT('Auto-tracked: Stock changed from ', OLD.stock_quantity, ' to ', NEW.stock_quantity)
    );
  END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `product_ratings`
--

CREATE TABLE `product_ratings` (
  `rating_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `rating_avg` decimal(3,2) DEFAULT 0.00,
  `review_count` int(11) DEFAULT 0,
  `rating_1_star` int(11) DEFAULT 0,
  `rating_2_star` int(11) DEFAULT 0,
  `rating_3_star` int(11) DEFAULT 0,
  `rating_4_star` int(11) DEFAULT 0,
  `rating_5_star` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `product_ratings`
--

INSERT INTO `product_ratings` (`rating_id`, `product_id`, `rating_avg`, `review_count`, `rating_1_star`, `rating_2_star`, `rating_3_star`, `rating_4_star`, `rating_5_star`, `created_at`, `updated_at`) VALUES
(1, 1, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(2, 2, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(3, 3, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(4, 4, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(5, 5, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(6, 6, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(7, 7, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(8, 8, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(9, 9, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(10, 10, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(11, 11, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(12, 12, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(13, 13, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(14, 14, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(15, 16, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(16, 17, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(18, 19, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(23, 25, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(26, 28, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(27, 29, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(28, 30, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(29, 31, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(30, 32, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(31, 33, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(32, 34, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(33, 35, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(34, 36, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(35, 37, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(36, 38, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(37, 39, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(38, 40, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(43, 45, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(46, 48, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(47, 49, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(48, 50, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(49, 51, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(50, 52, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(51, 53, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(52, 54, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(53, 55, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(54, 56, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(55, 57, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(56, 58, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(57, 59, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(58, 60, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(59, 61, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(60, 62, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(61, 63, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(62, 64, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(63, 65, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(64, 66, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(65, 67, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(66, 68, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(67, 69, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(68, 70, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(69, 71, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(70, 72, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(71, 73, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(72, 74, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(73, 75, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(74, 76, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(75, 77, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50'),
(78, 15, 4.50, 0, 0, 0, 0, 0, 0, '2026-03-04 10:23:50', '2026-03-04 10:23:50');

-- --------------------------------------------------------

--
-- Table structure for table `product_reviews`
--

CREATE TABLE `product_reviews` (
  `review_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `rating` int(11) NOT NULL CHECK (`rating` between 1 and 5),
  `review_text` text DEFAULT NULL,
  `review_title` varchar(255) DEFAULT NULL,
  `is_verified_purchase` tinyint(1) DEFAULT 0,
  `helpful_count` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Triggers `product_reviews`
--
DELIMITER $$
CREATE TRIGGER `after_review_delete` AFTER DELETE ON `product_reviews` FOR EACH ROW BEGIN
    DECLARE avg_rating DECIMAL(3,2);
    DECLARE total_reviews INT;
    DECLARE count_1 INT;
    DECLARE count_2 INT;
    DECLARE count_3 INT;
    DECLARE count_4 INT;
    DECLARE count_5 INT;
    
    SELECT 
        COALESCE(AVG(rating), 0),
        COUNT(*),
        SUM(CASE WHEN rating = 1 THEN 1 ELSE 0 END),
        SUM(CASE WHEN rating = 2 THEN 1 ELSE 0 END),
        SUM(CASE WHEN rating = 3 THEN 1 ELSE 0 END),
        SUM(CASE WHEN rating = 4 THEN 1 ELSE 0 END),
        SUM(CASE WHEN rating = 5 THEN 1 ELSE 0 END)
    INTO avg_rating, total_reviews, count_1, count_2, count_3, count_4, count_5
    FROM product_reviews
    WHERE product_id = OLD.product_id;
    
    UPDATE product_ratings SET
        rating_avg = avg_rating,
        review_count = total_reviews,
        rating_1_star = COALESCE(count_1, 0),
        rating_2_star = COALESCE(count_2, 0),
        rating_3_star = COALESCE(count_3, 0),
        rating_4_star = COALESCE(count_4, 0),
        rating_5_star = COALESCE(count_5, 0)
    WHERE product_id = OLD.product_id;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `after_review_insert` AFTER INSERT ON `product_reviews` FOR EACH ROW BEGIN
    DECLARE avg_rating DECIMAL(3,2);
    DECLARE total_reviews INT;
    DECLARE count_1 INT;
    DECLARE count_2 INT;
    DECLARE count_3 INT;
    DECLARE count_4 INT;
    DECLARE count_5 INT;
    
    
    SELECT 
        AVG(rating),
        COUNT(*),
        SUM(CASE WHEN rating = 1 THEN 1 ELSE 0 END),
        SUM(CASE WHEN rating = 2 THEN 1 ELSE 0 END),
        SUM(CASE WHEN rating = 3 THEN 1 ELSE 0 END),
        SUM(CASE WHEN rating = 4 THEN 1 ELSE 0 END),
        SUM(CASE WHEN rating = 5 THEN 1 ELSE 0 END)
    INTO avg_rating, total_reviews, count_1, count_2, count_3, count_4, count_5
    FROM product_reviews
    WHERE product_id = NEW.product_id;
    
    
    INSERT INTO product_ratings (
        product_id, rating_avg, review_count,
        rating_1_star, rating_2_star, rating_3_star, rating_4_star, rating_5_star
    ) VALUES (
        NEW.product_id, avg_rating, total_reviews,
        count_1, count_2, count_3, count_4, count_5
    )
    ON DUPLICATE KEY UPDATE
        rating_avg = avg_rating,
        review_count = total_reviews,
        rating_1_star = count_1,
        rating_2_star = count_2,
        rating_3_star = count_3,
        rating_4_star = count_4,
        rating_5_star = count_5;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `after_review_update` AFTER UPDATE ON `product_reviews` FOR EACH ROW BEGIN
    DECLARE avg_rating DECIMAL(3,2);
    DECLARE total_reviews INT;
    DECLARE count_1 INT;
    DECLARE count_2 INT;
    DECLARE count_3 INT;
    DECLARE count_4 INT;
    DECLARE count_5 INT;
    
    SELECT 
        AVG(rating),
        COUNT(*),
        SUM(CASE WHEN rating = 1 THEN 1 ELSE 0 END),
        SUM(CASE WHEN rating = 2 THEN 1 ELSE 0 END),
        SUM(CASE WHEN rating = 3 THEN 1 ELSE 0 END),
        SUM(CASE WHEN rating = 4 THEN 1 ELSE 0 END),
        SUM(CASE WHEN rating = 5 THEN 1 ELSE 0 END)
    INTO avg_rating, total_reviews, count_1, count_2, count_3, count_4, count_5
    FROM product_reviews
    WHERE product_id = NEW.product_id;
    
    UPDATE product_ratings SET
        rating_avg = avg_rating,
        review_count = total_reviews,
        rating_1_star = count_1,
        rating_2_star = count_2,
        rating_3_star = count_3,
        rating_4_star = count_4,
        rating_5_star = count_5
    WHERE product_id = NEW.product_id;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `product_specifications`
--

CREATE TABLE `product_specifications` (
  `spec_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `spec_key` varchar(100) NOT NULL,
  `spec_value` text NOT NULL,
  `display_order` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `product_specifications`
--

INSERT INTO `product_specifications` (`spec_id`, `product_id`, `spec_key`, `spec_value`, `display_order`) VALUES
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
(112, 25, 'Switch Type', 'Cherry MX Speed', 1),
(113, 25, 'Lighting', 'Per-key RGB', 2),
(114, 25, 'Controls', 'Dedicated Media Controls', 3),
(115, 25, 'Type', 'Mechanical Gaming Keyboard', 4),
(116, 25, 'Rating', '4', 5),
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

CREATE TABLE `promotions` (
  `promotion_id` int(11) NOT NULL,
  `title` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `discount_percent` decimal(5,2) DEFAULT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `active` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `promotions`
--

INSERT INTO `promotions` (`promotion_id`, `title`, `description`, `discount_percent`, `start_date`, `end_date`, `active`) VALUES
(1, 'Mega Smartphone Sale', 'Up to 90% off on smartphones', 90.00, '2026-03-01', '2026-03-31', 0),
(2, 'Laptop Clearance', 'Huge discounts on laptops', 85.00, '2026-03-01', '2026-03-31', 0),
(3, 'Home Appliances', 'Save big on home appliances', 80.00, '2026-03-01', '2026-03-31', 0),
(4, 'Fashion Deals', 'Fashion items at unbeatable prices', 75.00, '2026-03-01', '2026-03-31', 0),
(5, 'Winter Sale', 'Up to 20% off on lighting products', 20.00, '2026-03-01', '2026-03-31', 0),
(9, 'Auto Promo Check', 'Auto verification promo', NULL, '2026-04-03', '2026-04-07', 0),
(10, 'Auto Promo Check', 'Auto verification promo', NULL, '2026-04-03', '2026-04-07', 0);

-- --------------------------------------------------------

--
-- Table structure for table `rate_limits`
--

CREATE TABLE `rate_limits` (
  `id` int(11) NOT NULL,
  `ip_address` varchar(45) NOT NULL,
  `endpoint` varchar(255) NOT NULL,
  `request_count` int(11) DEFAULT 1,
  `window_start` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `reports`
--

CREATE TABLE `reports` (
  `report_id` int(11) NOT NULL,
  `admin_id` int(11) DEFAULT NULL,
  `report_type` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `details` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `reviews`
--

CREATE TABLE `reviews` (
  `review_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `rating` int(11) DEFAULT NULL CHECK (`rating` >= 1 and `rating` <= 5),
  `review_text` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `search_analytics`
--

CREATE TABLE `search_analytics` (
  `analytics_id` int(11) NOT NULL,
  `date` date NOT NULL,
  `search_query` varchar(255) NOT NULL,
  `total_searches` int(11) DEFAULT 0,
  `unique_users` int(11) DEFAULT 0,
  `avg_results` int(11) DEFAULT 0,
  `zero_results_count` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `search_history`
--

CREATE TABLE `search_history` (
  `search_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `search_query` varchar(255) NOT NULL,
  `results_count` int(11) DEFAULT 0,
  `searched_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `search_history`
--

INSERT INTO `search_history` (`search_id`, `user_id`, `search_query`, `results_count`, `searched_at`) VALUES
(1, NULL, 'fan', 19, '2026-03-27 11:08:19');

-- --------------------------------------------------------

--
-- Table structure for table `search_suggestions`
--

CREATE TABLE `search_suggestions` (
  `suggestion_id` int(11) NOT NULL,
  `suggestion_text` varchar(255) NOT NULL,
  `suggestion_type` enum('product','category','brand','keyword') DEFAULT 'keyword',
  `search_count` int(11) DEFAULT 0,
  `last_searched` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `search_suggestions`
--

INSERT INTO `search_suggestions` (`suggestion_id`, `suggestion_text`, `suggestion_type`, `search_count`, `last_searched`, `is_active`, `created_at`) VALUES
(1, 'Acer SB220Q bi 21.5 Inches Full HD Monitor', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(2, 'Air Fryer Digital', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(3, 'ASUS ROG Strix G15 Gaming Laptop', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(4, 'AV Multi Cooker', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(5, 'AV Sandwich Maker', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(6, 'AV Sandwich Maker 296', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(7, 'AV Sandwich Maker 560', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(8, 'Blender', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(9, 'Blender Pro 2000', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(10, 'Charger Fan Portable', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(11, 'Copper Wire', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(12, 'Corsair K95 RGB Platinum Mechanical Gaming Keyboard', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(13, 'Dell UltraSharp U2723QE 27 Inch 4K Monitor', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
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
(27, 'Intel Core i7 12th Gen Processor', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
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
(43, 'LG Table Fan 16\"', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(44, 'Logitech MX Master 3 Wireless Mouse', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(45, 'LR2018 Blender', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(46, 'Mini Cooker Compact', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
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
(59, 'P9 Max Bluetooth Headphones', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(60, 'Panasonic Cooker 5L', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(61, 'Panasonic Mixer Grinder', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(62, 'Pink Leather Iron', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(63, 'prestige cooker', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(64, 'Prestige Rice Cooker 1.8L', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(65, 'Razer DeathAdder V2 Pro Wireless Gaming Mouse', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(66, 'Rice Cooker 1.8L', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(67, 'Samsung CCTV Camera', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
(68, 'Samsung T7 Portable SSD 1TB', 'product', 0, '2026-03-04 10:49:34', 1, '2026-03-04 10:49:34'),
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
(174, 'Checkpoint Test 1774606938183', 'product', 0, '2026-03-27 10:22:18', 1, '2026-03-27 10:22:18'),
(175, 'No-Image Test 1774606938329', 'product', 0, '2026-03-27 10:22:18', 1, '2026-03-27 10:22:18'),
(176, 'Preservation Test Product 1774606938413', 'product', 0, '2026-03-27 10:22:18', 1, '2026-03-27 10:22:18'),
(177, 'Flow Test Product 1774606938432', 'product', 0, '2026-03-27 10:22:18', 1, '2026-03-27 10:22:18'),
(178, 'No-Image Product 1774606938667', 'product', 0, '2026-03-27 10:22:18', 1, '2026-03-27 10:22:18'),
(179, 'Test Product 1774606938665', 'product', 0, '2026-03-27 10:22:18', 1, '2026-03-27 10:22:18'),
(180, 'Test Product Large 1774606938723', 'product', 0, '2026-03-27 10:22:18', 1, '2026-03-27 10:22:18'),
(181, 'পণ্য Test 产品 1774606938761', 'product', 0, '2026-03-27 10:22:18', 1, '2026-03-27 10:22:18'),
(182, 'পণ্য Test 产品 🔥 1774606939204', 'product', 0, '2026-03-27 10:22:19', 1, '2026-03-27 10:22:19'),
(183, 'Concurrent Test 0 1774606939258', 'product', 0, '2026-03-27 10:22:19', 1, '2026-03-27 10:22:19'),
(184, 'Concurrent Test 1 1774606939258', 'product', 0, '2026-03-27 10:22:19', 1, '2026-03-27 10:22:19'),
(185, 'Concurrent Test 2 1774606939258', 'product', 0, '2026-03-27 10:22:19', 1, '2026-03-27 10:22:19'),
(186, 'Checkpoint Test 1774607183834', 'product', 0, '2026-03-27 10:26:23', 1, '2026-03-27 10:26:23'),
(187, 'No-Image Test 1774607183948', 'product', 0, '2026-03-27 10:26:28', 1, '2026-03-27 10:26:28'),
(188, 'Flow Test Product 1774607188948', 'product', 0, '2026-03-27 10:26:28', 1, '2026-03-27 10:26:28'),
(189, 'পণ্য Test 产品 🔥 1774607189414', 'product', 0, '2026-03-27 10:26:29', 1, '2026-03-27 10:26:29'),
(190, 'Concurrent Test 0 1774607189432', 'product', 0, '2026-03-27 10:26:29', 1, '2026-03-27 10:26:29'),
(191, 'Concurrent Test 1 1774607189433', 'product', 0, '2026-03-27 10:26:29', 1, '2026-03-27 10:26:29'),
(192, 'Concurrent Test 2 1774607189433', 'product', 0, '2026-03-27 10:26:29', 1, '2026-03-27 10:26:29'),
(193, 'Checkpoint Test 1774609716175', 'product', 0, '2026-03-27 11:08:36', 1, '2026-03-27 11:08:36'),
(194, 'No-Image Test 1774609716283', 'product', 0, '2026-03-27 11:08:41', 1, '2026-03-27 11:08:41'),
(195, 'Flow Test Product 1774609721141', 'product', 0, '2026-03-27 11:08:41', 1, '2026-03-27 11:08:41'),
(196, 'পণ্য Test 产品 🔥 1774609721622', 'product', 0, '2026-03-27 11:08:41', 1, '2026-03-27 11:08:41'),
(197, 'Concurrent Test 0 1774609721641', 'product', 0, '2026-03-27 11:08:41', 1, '2026-03-27 11:08:41'),
(198, 'Concurrent Test 1 1774609721641', 'product', 0, '2026-03-27 11:08:41', 1, '2026-03-27 11:08:41'),
(199, 'Concurrent Test 2 1774609721642', 'product', 0, '2026-03-27 11:08:41', 1, '2026-03-27 11:08:41'),
(200, 'miyoko', 'product', 0, '2026-03-29 17:41:10', 1, '2026-03-29 17:41:10'),
(201, 'powerhouse', 'brand', 0, '2026-04-09 12:34:45', 1, '2026-04-09 12:34:45'),
(202, 'miyoko blender', 'product', 0, '2026-04-09 12:57:06', 1, '2026-04-09 12:57:06'),
(203, 'roz', 'product', 0, '2026-04-14 05:43:20', 1, '2026-04-14 05:43:20'),
(205, 'dddd', 'product', 0, '2026-04-14 06:06:06', 1, '2026-04-14 06:06:06'),
(206, 'rox', 'product', 0, '2026-04-14 06:15:13', 1, '2026-04-14 06:15:13'),
(207, 'eooee', 'product', 0, '2026-04-14 06:29:59', 1, '2026-04-14 06:29:59'),
(208, 'koi', 'product', 0, '2026-04-14 06:50:10', 1, '2026-04-14 06:50:10'),
(209, 'soss', 'product', 0, '2026-04-14 06:54:34', 1, '2026-04-14 06:54:34'),
(210, 'ghgh', 'product', 0, '2026-04-14 07:00:03', 1, '2026-04-14 07:00:03'),
(211, 'dse', 'product', 0, '2026-04-14 07:17:31', 1, '2026-04-14 07:17:31'),
(212, 'rio', 'product', 0, '2026-04-14 07:28:38', 1, '2026-04-14 07:28:38'),
(213, 'ffff', 'product', 0, '2026-04-14 07:32:22', 1, '2026-04-14 07:32:22'),
(214, 'gor', 'product', 0, '2026-04-14 07:43:37', 1, '2026-04-14 07:43:37'),
(215, 'yt', 'product', 0, '2026-04-14 07:55:59', 1, '2026-04-14 07:55:59'),
(216, 'Blenders & Mixers', 'category', 0, '2026-04-14 08:08:31', 1, '2026-04-14 08:08:31'),
(217, 'Irons & Steamers', 'category', 0, '2026-04-14 08:08:31', 1, '2026-04-14 08:08:31'),
(218, 'Rice Cookers', 'category', 0, '2026-04-14 08:08:31', 1, '2026-04-14 08:08:31'),
(219, 'Air Fryers', 'category', 0, '2026-04-14 08:08:31', 1, '2026-04-14 08:08:31'),
(220, 'AV', 'brand', 0, '2026-04-14 08:08:31', 1, '2026-04-14 08:08:31'),
(221, 'Noha', 'brand', 0, '2026-04-14 08:08:31', 1, '2026-04-14 08:08:31'),
(222, 'Hand Blender Pro 500W', 'product', 0, '2026-04-14 08:08:31', 1, '2026-04-14 08:08:31'),
(223, 'Food Chopper 300W', 'product', 0, '2026-04-14 08:08:31', 1, '2026-04-14 08:08:31'),
(224, 'Hanger Fan 3-Speed', 'product', 0, '2026-04-14 08:08:31', 1, '2026-04-14 08:08:31'),
(225, 'Fan Rechargeable 2-in-1', 'product', 0, '2026-04-14 08:08:31', 1, '2026-04-14 08:08:31'),
(226, 'Trimmer 2 Cordless', 'product', 0, '2026-04-14 08:08:31', 1, '2026-04-14 08:08:31'),
(227, 'Tele Sett Iron', 'product', 0, '2026-04-14 08:08:31', 1, '2026-04-14 08:08:31'),
(228, 'Mini Hand Mixer', 'product', 0, '2026-04-14 08:08:31', 1, '2026-04-14 08:08:31');

-- --------------------------------------------------------

--
-- Table structure for table `site_settings`
--

CREATE TABLE `site_settings` (
  `setting_key` varchar(100) NOT NULL,
  `setting_value` text DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `site_settings`
--

INSERT INTO `site_settings` (`setting_key`, `setting_value`, `updated_at`) VALUES
('active_coupon', '{\"code\":\"EID25\",\"percent\":25,\"scope\":\"cart\",\"active\":true}', '2026-04-03 17:59:01'),
('currency', 'BDT', '2026-03-01 07:11:36'),
('delivery_charge_inside_dhaka', '80', '2026-04-13 11:01:06'),
('delivery_charge_outside_dhaka', '140', '2026-04-13 11:01:07'),
('section_filter_best_sellers', '{\"limit\": 10, \"sort\": \"sales_desc\"}', '2026-03-01 07:11:36'),
('section_filter_deals', '{\"limit\": 10, \"sort\": \"newest\"}', '2026-03-01 07:11:36'),
('section_filter_flash_sale', '{\"limit\": 10, \"sort\": \"newest\"}', '2026-03-01 07:11:36'),
('section_filter_tech_part', '{\"limit\": 10, \"sort\": \"display_order\"}', '2026-03-01 07:11:36'),
('section_filter_trending', '{\"limit\": 10, \"sort\": \"score_desc\"}', '2026-03-01 07:11:36'),
('site_email', 'info@electrocitybd.com', '2026-03-01 07:11:36'),
('site_name', 'ElectrocityBD', '2026-03-01 07:11:36'),
('site_phone', '+880 1234-567890', '2026-03-01 07:11:36'),
('support_whatsapp_number', '01840658317', '2026-04-09 12:25:02'),
('tax_rate', '0.00', '2026-03-01 07:11:36');

-- --------------------------------------------------------

--
-- Table structure for table `stock_alerts`
--

CREATE TABLE `stock_alerts` (
  `alert_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `alert_type` enum('LOW_STOCK','OUT_OF_STOCK','OVERSTOCK') NOT NULL,
  `threshold_quantity` int(11) DEFAULT 5,
  `current_quantity` int(11) NOT NULL,
  `is_resolved` tinyint(1) DEFAULT 0,
  `resolved_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `stock_alerts`
--

INSERT INTO `stock_alerts` (`alert_id`, `product_id`, `alert_type`, `threshold_quantity`, `current_quantity`, `is_resolved`, `resolved_at`, `created_at`) VALUES
(1, 15, 'LOW_STOCK', 5, 5, 0, NULL, '2026-03-04 09:38:39');

-- --------------------------------------------------------

--
-- Table structure for table `stock_movements`
--

CREATE TABLE `stock_movements` (
  `movement_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `movement_type` enum('IN','OUT','ADJUSTMENT') NOT NULL,
  `quantity` int(11) NOT NULL,
  `previous_stock` int(11) NOT NULL,
  `new_stock` int(11) NOT NULL,
  `reference_type` enum('PURCHASE','SALE','RETURN','DAMAGE','ADJUSTMENT','INITIAL') DEFAULT 'ADJUSTMENT',
  `reference_id` int(11) DEFAULT NULL COMMENT 'Order ID or other reference',
  `notes` text DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL COMMENT 'Admin user who made the change',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `stock_movements`
--

INSERT INTO `stock_movements` (`movement_id`, `product_id`, `movement_type`, `quantity`, `previous_stock`, `new_stock`, `reference_type`, `reference_id`, `notes`, `created_by`, `created_at`) VALUES
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
(140, 108, 'OUT', 5, 12, 7, 'ADJUSTMENT', NULL, 'Auto-tracked: Stock changed from 12 to 7', NULL, '2026-03-29 17:50:12'),
(143, 55, 'OUT', 1, 25, 24, 'ADJUSTMENT', NULL, 'Auto-tracked: Stock changed from 25 to 24', NULL, '2026-04-03 20:35:47'),
(144, 5, 'OUT', 2, 16, 14, 'ADJUSTMENT', NULL, 'Auto-tracked: Stock changed from 16 to 14', NULL, '2026-04-09 12:48:00'),
(145, 5, 'OUT', 1, 14, 13, 'ADJUSTMENT', NULL, 'Auto-tracked: Stock changed from 14 to 13', NULL, '2026-04-13 09:29:28'),
(146, 5, 'OUT', 1, 13, 12, 'ADJUSTMENT', NULL, 'Auto-tracked: Stock changed from 13 to 12', NULL, '2026-04-13 09:34:20'),
(147, 5, 'OUT', 1, 12, 11, 'ADJUSTMENT', NULL, 'Auto-tracked: Stock changed from 12 to 11', NULL, '2026-04-13 09:37:55'),
(148, 5, 'OUT', 1, 11, 10, 'ADJUSTMENT', NULL, 'Auto-tracked: Stock changed from 11 to 10', NULL, '2026-04-13 10:06:41'),
(149, 25, 'OUT', 1, 12, 11, 'ADJUSTMENT', NULL, 'Auto-tracked: Stock changed from 12 to 11', NULL, '2026-04-13 10:33:04'),
(150, 25, 'IN', 3, 11, 14, 'ADJUSTMENT', NULL, 'Auto-tracked: Stock changed from 11 to 14', NULL, '2026-04-14 06:20:56'),
(151, 48, 'OUT', 1, 60, 59, 'ADJUSTMENT', NULL, 'Auto-tracked: Stock changed from 60 to 59', NULL, '2026-04-14 06:33:29');

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

-- --------------------------------------------------------

--
-- Table structure for table `tech_part_products`
--

CREATE TABLE `tech_part_products` (
  `product_id` int(11) NOT NULL,
  `display_order` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tech_part_products`
--

INSERT INTO `tech_part_products` (`product_id`, `display_order`, `created_at`) VALUES
(1, 1, '2026-04-14 08:08:31'),
(2, 2, '2026-04-14 08:08:31'),
(3, 3, '2026-04-14 08:08:31'),
(4, 4, '2026-04-14 08:08:31'),
(5, 5, '2026-04-14 08:08:31'),
(6, 6, '2026-04-14 08:08:31'),
(7, 7, '2026-04-14 08:08:31'),
(8, 8, '2026-04-14 08:08:31'),
(9, 9, '2026-04-14 08:08:31'),
(10, 6, '2026-03-05 08:00:00'),
(11, 11, '2026-04-14 08:08:31'),
(12, 12, '2026-04-14 08:08:31'),
(13, 13, '2026-04-14 08:08:31'),
(14, 14, '2026-04-14 08:08:31'),
(15, 15, '2026-04-14 08:08:31'),
(25, 9, '2026-03-27 13:47:55'),
(45, 8, '2026-03-05 08:00:00');

-- --------------------------------------------------------

--
-- Table structure for table `trending_products`
--

CREATE TABLE `trending_products` (
  `trending_product_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `trending_score` int(11) DEFAULT 0,
  `image_path` varchar(255) DEFAULT NULL,
  `display_order` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `last_updated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `trending_products`
--

INSERT INTO `trending_products` (`trending_product_id`, `product_id`, `trending_score`, `image_path`, `display_order`, `created_at`, `updated_at`, `last_updated`) VALUES
(1, 62, 98, NULL, 1, '2026-03-05 08:00:00', '2026-03-05 08:00:00', '2026-03-05 08:00:00'),
(2, 74, 96, NULL, 2, '2026-03-05 08:00:00', '2026-03-05 08:00:00', '2026-03-05 08:00:00'),
(3, 64, 95, NULL, 3, '2026-03-05 08:00:00', '2026-03-05 08:00:00', '2026-03-05 08:00:00'),
(4, 76, 94, NULL, 4, '2026-03-05 08:00:00', '2026-03-05 08:00:00', '2026-03-05 08:00:00'),
(5, 48, 94, NULL, 5, '2026-03-05 08:00:00', '2026-04-14 06:33:29', '2026-04-14 06:33:29'),
(6, 70, 92, NULL, 6, '2026-03-05 08:00:00', '2026-03-05 08:00:00', '2026-03-05 08:00:00'),
(7, 65, 91, NULL, 7, '2026-03-05 08:00:00', '2026-03-05 08:00:00', '2026-03-05 08:00:00'),
(8, 55, 91, NULL, 8, '2026-03-05 08:00:00', '2026-04-03 20:35:47', '2026-04-03 20:35:47'),
(9, 57, 89, NULL, 9, '2026-03-05 08:00:00', '2026-03-05 08:00:00', '2026-03-05 08:00:00'),
(10, 67, 88, NULL, 10, '2026-03-05 08:00:00', '2026-03-05 08:00:00', '2026-03-05 08:00:00'),
(11, 51, 95, NULL, 11, '2026-03-05 08:00:00', '2026-03-27 14:23:44', '2026-03-27 14:23:44'),
(12, 60, 86, NULL, 12, '2026-03-05 08:00:00', '2026-03-05 08:00:00', '2026-03-05 08:00:00'),
(48, 5, 6, NULL, 0, '2026-03-29 17:23:35', '2026-04-13 10:06:41', '2026-04-13 10:06:41'),
(58, 25, 1, NULL, 0, '2026-04-13 10:33:04', '2026-04-13 10:33:04', '2026-04-13 10:33:04'),
(68, 1, 100, 'assets/trends/blender.jpg', 1, '2026-04-14 08:08:31', '2026-04-14 08:08:31', '2026-04-14 08:08:31'),
(69, 2, 95, 'assets/trends/air_fryer.jpg', 2, '2026-04-14 08:08:31', '2026-04-14 08:08:31', '2026-04-14 08:08:31'),
(70, 3, 90, 'assets/trends/chargerfan.jpg', 3, '2026-04-14 08:08:31', '2026-04-14 08:08:31', '2026-04-14 08:08:31'),
(71, 4, 85, 'assets/trends/rice_cooker.jpg', 4, '2026-04-14 08:08:31', '2026-04-14 08:08:31', '2026-04-14 08:08:31'),
(72, 7, 75, 'assets/trends/mini_cooker.jpg', 6, '2026-04-14 08:08:31', '2026-04-14 08:08:31', '2026-04-14 08:08:31'),
(73, 8, 70, 'assets/trends/hair_drier.jpg', 7, '2026-04-14 08:08:31', '2026-04-14 08:08:31', '2026-04-14 08:08:31'),
(74, 9, 65, 'assets/trends/elec_stove.jpg', 8, '2026-04-14 08:08:31', '2026-04-14 08:08:31', '2026-04-14 08:08:31'),
(75, 10, 60, 'assets/trends/blender.jpg', 9, '2026-04-14 08:08:31', '2026-04-14 08:08:31', '2026-04-14 08:08:31'),
(76, 13, 55, 'assets/trends/head_massager.jpg', 10, '2026-04-14 08:08:31', '2026-04-14 08:08:31', '2026-04-14 08:08:31'),
(77, 15, 50, 'assets/trends/elec_stove.jpg', 11, '2026-04-14 08:08:31', '2026-04-14 08:08:31', '2026-04-14 08:08:31'),
(78, 17, 45, 'assets/trends/rice_cooker.jpg', 12, '2026-04-14 08:08:31', '2026-04-14 08:08:31', '2026-04-14 08:08:31'),
(79, 19, 40, 'assets/trends/mini2cokker.jpg', 13, '2026-04-14 08:08:31', '2026-04-14 08:08:31', '2026-04-14 08:08:31'),
(80, 26, 30, 'assets/trends/minihand.jpg', 15, '2026-04-14 08:08:31', '2026-04-14 08:08:31', '2026-04-14 08:08:31');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `user_id` int(11) NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `last_name` varchar(50) NOT NULL DEFAULT '',
  `email` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `phone_number` varchar(20) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `gender` varchar(10) DEFAULT 'Male',
  `role` enum('admin','customer') DEFAULT 'customer',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `full_name`, `last_name`, `email`, `password`, `phone_number`, `address`, `gender`, `role`, `created_at`) VALUES
(3, 'Ahnaf', 'Admin', 'ahnaf@electrocitybd.com', '$2y$10$Y0ysFLshD8qCXIWxuHq1WOglx2zCPzeCOt4V9nynBs534xlDlUIsW', NULL, NULL, 'Male', 'admin', '2026-03-01 07:22:57'),
(9, 'Ahnaf', '', 'aarnab222126@gmail.com', '$2y$10$3PG6FeR6dfYH5wyrUIG0suGDkk4KzvnnMk5Waw92kD32gFZx1oZmi', '', NULL, 'Male', 'customer', '2026-03-04 12:48:41'),
(20, 'sara', '', '4irh456@gmail.com', '$2y$10$A0wAsXNAX.xlIaq4NTyyIuXjsMfUeo4QBjI1VKCxQf98sHtKqeeqm', '', NULL, 'Male', 'customer', '2026-04-01 15:41:39'),
(22, 'rafee', 'hasan', 'rafee@gmail.com', '$2y$10$AHl2Zp6FgJEkOR.cza1t7erLIYUKfrjbIRwVrfAmzSwIkoOC7iJA6', '01840652718', 'mouchak,Dhaka, 13 building no,mouchak,dhaka, dhaka 1400', 'Male', 'customer', '2026-04-13 09:21:37'),
(24, 'Noman Admin', '', 'noman@admin_electrozone.com', '$2y$10$C0.liivgmh/fNd/f94y0wOrDUFF3r50i34kylma1rWIMeHCfVsIYq', NULL, NULL, 'Male', 'admin', '2026-04-14 08:10:10');

-- --------------------------------------------------------

--
-- Table structure for table `user_profile`
--

CREATE TABLE `user_profile` (
  `user_id` int(11) NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `last_name` varchar(50) NOT NULL DEFAULT '',
  `phone_number` varchar(20) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `gender` varchar(10) DEFAULT 'Male',
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_profile`
--

INSERT INTO `user_profile` (`user_id`, `full_name`, `last_name`, `phone_number`, `address`, `gender`, `updated_at`) VALUES
(3, 'Ahnaf', 'Admin', NULL, NULL, 'Male', '2026-03-01 07:22:57'),
(20, 'sara', '', '', NULL, 'Male', '2026-04-01 15:41:39'),
(21, 'raj', 'Chopra', '01998435352', 'Inladan road,Ujbekistan, 12flat,23 road, ujbekistan 5408', 'Male', '2026-04-09 12:45:57'),
(22, 'rafee', 'hasan', '01840652718', 'mouchak,Dhaka, 13 building no,mouchak,dhaka, dhaka 1400', 'Male', '2026-04-13 10:13:37');

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_active_stock_alerts`
-- (See below for the actual view)
--
CREATE TABLE `v_active_stock_alerts` (
`alert_id` int(11)
,`product_id` int(11)
,`product_name` varchar(150)
,`category_name` varchar(50)
,`brand_name` varchar(100)
,`alert_type` enum('LOW_STOCK','OUT_OF_STOCK','OVERSTOCK')
,`threshold_quantity` int(11)
,`current_quantity` int(11)
,`created_at` timestamp
,`days_pending` int(7)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_popular_searches`
-- (See below for the actual view)
--
CREATE TABLE `v_popular_searches` (
`search_query` varchar(255)
,`search_count` bigint(21)
,`last_searched` timestamp
,`unique_users` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_stock_summary`
-- (See below for the actual view)
--
CREATE TABLE `v_stock_summary` (
`product_id` int(11)
,`product_name` varchar(150)
,`category_name` varchar(50)
,`brand_name` varchar(100)
,`stock_quantity` int(11)
,`min_stock_threshold` int(11)
,`stock_status` enum('IN_STOCK','LOW_STOCK','OUT_OF_STOCK')
,`total_stock_in` decimal(32,0)
,`total_stock_out` decimal(32,0)
,`total_movements` bigint(21)
,`last_movement_date` timestamp
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_trending_searches`
-- (See below for the actual view)
--
CREATE TABLE `v_trending_searches` (
`search_query` varchar(255)
,`search_count` bigint(21)
,`last_searched` timestamp
);

-- --------------------------------------------------------

--
-- Table structure for table `wishlists`
--

CREATE TABLE `wishlists` (
  `wishlist_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `product_id` int(11) DEFAULT NULL,
  `added_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure for view `v_active_stock_alerts`
--
DROP TABLE IF EXISTS `v_active_stock_alerts`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_active_stock_alerts`  AS SELECT `sa`.`alert_id` AS `alert_id`, `sa`.`product_id` AS `product_id`, `p`.`product_name` AS `product_name`, `c`.`category_name` AS `category_name`, `b`.`brand_name` AS `brand_name`, `sa`.`alert_type` AS `alert_type`, `sa`.`threshold_quantity` AS `threshold_quantity`, `sa`.`current_quantity` AS `current_quantity`, `sa`.`created_at` AS `created_at`, to_days(current_timestamp()) - to_days(`sa`.`created_at`) AS `days_pending` FROM (((`stock_alerts` `sa` join `products` `p` on(`sa`.`product_id` = `p`.`product_id`)) left join `categories` `c` on(`p`.`category_id` = `c`.`category_id`)) left join `brands` `b` on(`p`.`brand_id` = `b`.`brand_id`)) WHERE `sa`.`is_resolved` = 0 ORDER BY `sa`.`created_at` DESC ;

-- --------------------------------------------------------

--
-- Structure for view `v_popular_searches`
--
DROP TABLE IF EXISTS `v_popular_searches`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_popular_searches`  AS SELECT `search_history`.`search_query` AS `search_query`, count(0) AS `search_count`, max(`search_history`.`searched_at`) AS `last_searched`, count(distinct `search_history`.`user_id`) AS `unique_users` FROM `search_history` WHERE `search_history`.`searched_at` >= current_timestamp() - interval 30 day GROUP BY `search_history`.`search_query` HAVING `search_count` > 1 ORDER BY count(0) DESC, max(`search_history`.`searched_at`) DESC ;

-- --------------------------------------------------------

--
-- Structure for view `v_stock_summary`
--
DROP TABLE IF EXISTS `v_stock_summary`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_stock_summary`  AS SELECT `p`.`product_id` AS `product_id`, `p`.`product_name` AS `product_name`, `c`.`category_name` AS `category_name`, `b`.`brand_name` AS `brand_name`, `p`.`stock_quantity` AS `stock_quantity`, `p`.`min_stock_threshold` AS `min_stock_threshold`, `p`.`stock_status` AS `stock_status`, coalesce(sum(case when `sm`.`movement_type` = 'IN' then `sm`.`quantity` else 0 end),0) AS `total_stock_in`, coalesce(sum(case when `sm`.`movement_type` = 'OUT' then `sm`.`quantity` else 0 end),0) AS `total_stock_out`, count(distinct `sm`.`movement_id`) AS `total_movements`, max(`sm`.`created_at`) AS `last_movement_date` FROM (((`products` `p` left join `categories` `c` on(`p`.`category_id` = `c`.`category_id`)) left join `brands` `b` on(`p`.`brand_id` = `b`.`brand_id`)) left join `stock_movements` `sm` on(`p`.`product_id` = `sm`.`product_id`)) GROUP BY `p`.`product_id`, `p`.`product_name`, `c`.`category_name`, `b`.`brand_name`, `p`.`stock_quantity`, `p`.`min_stock_threshold`, `p`.`stock_status` ;

-- --------------------------------------------------------

--
-- Structure for view `v_trending_searches`
--
DROP TABLE IF EXISTS `v_trending_searches`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_trending_searches`  AS SELECT `search_history`.`search_query` AS `search_query`, count(0) AS `search_count`, max(`search_history`.`searched_at`) AS `last_searched` FROM `search_history` WHERE `search_history`.`searched_at` >= current_timestamp() - interval 7 day GROUP BY `search_history`.`search_query` ORDER BY count(0) DESC LIMIT 0, 20 ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `banners`
--
ALTER TABLE `banners`
  ADD PRIMARY KEY (`banner_id`);

--
-- Indexes for table `best_sellers`
--
ALTER TABLE `best_sellers`
  ADD PRIMARY KEY (`product_id`),
  ADD KEY `idx_best_sellers_created` (`created_at`);

--
-- Indexes for table `brands`
--
ALTER TABLE `brands`
  ADD PRIMARY KEY (`brand_id`),
  ADD UNIQUE KEY `idx_brand_name_unique` (`brand_name`);
ALTER TABLE `brands` ADD FULLTEXT KEY `ft_brand_name` (`brand_name`);

--
-- Indexes for table `cart`
--
ALTER TABLE `cart`
  ADD PRIMARY KEY (`cart_id`),
  ADD KEY `idx_cart_user` (`user_id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_product_id` (`product_id`);

--
-- Indexes for table `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`category_id`),
  ADD UNIQUE KEY `idx_category_name_unique` (`category_name`);
ALTER TABLE `categories` ADD FULLTEXT KEY `ft_category_name` (`category_name`);

--
-- Indexes for table `collections`
--
ALTER TABLE `collections`
  ADD PRIMARY KEY (`collection_id`),
  ADD UNIQUE KEY `slug` (`slug`);

--
-- Indexes for table `collection_items`
--
ALTER TABLE `collection_items`
  ADD PRIMARY KEY (`item_id`),
  ADD KEY `collection_id` (`collection_id`);

--
-- Indexes for table `collection_products`
--
ALTER TABLE `collection_products`
  ADD PRIMARY KEY (`collection_id`,`product_id`),
  ADD KEY `product_id` (`product_id`);

--
-- Indexes for table `csrf_tokens`
--
ALTER TABLE `csrf_tokens`
  ADD PRIMARY KEY (`token_id`),
  ADD UNIQUE KEY `token` (`token`),
  ADD KEY `idx_token` (`token`),
  ADD KEY `idx_expires` (`expires_at`);

--
-- Indexes for table `customer_support`
--
ALTER TABLE `customer_support`
  ADD PRIMARY KEY (`ticket_id`),
  ADD KEY `resolved_by` (`resolved_by`),
  ADD KEY `idx_customer_support_user` (`user_id`),
  ADD KEY `idx_customer_support_status` (`status`);

--
-- Indexes for table `deals_of_the_day`
--
ALTER TABLE `deals_of_the_day`
  ADD PRIMARY KEY (`deal_id`),
  ADD KEY `product_id` (`product_id`),
  ADD KEY `idx_deals_created` (`created_at`);

--
-- Indexes for table `deals_timer`
--
ALTER TABLE `deals_timer`
  ADD PRIMARY KEY (`timer_id`);

--
-- Indexes for table `discounts`
--
ALTER TABLE `discounts`
  ADD PRIMARY KEY (`discount_id`),
  ADD KEY `product_id` (`product_id`);

--
-- Indexes for table `flash_sales`
--
ALTER TABLE `flash_sales`
  ADD PRIMARY KEY (`flash_sale_id`),
  ADD KEY `idx_flash_sales_active` (`active`,`end_time`),
  ADD KEY `idx_flash_sales_created` (`created_at`);

--
-- Indexes for table `flash_sale_products`
--
ALTER TABLE `flash_sale_products`
  ADD PRIMARY KEY (`flash_sale_product_id`),
  ADD UNIQUE KEY `unique_flash_product` (`flash_sale_id`,`product_id`),
  ADD KEY `product_id` (`product_id`),
  ADD KEY `idx_flash_sale_products_order` (`display_order`),
  ADD KEY `idx_flash_sale_products_created` (`created_at`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`order_id`),
  ADD KEY `idx_orders_user` (`user_id`),
  ADD KEY `idx_orders_date` (`order_date`),
  ADD KEY `idx_orders_status` (`order_status`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_order_status` (`order_status`),
  ADD KEY `idx_order_date` (`order_date`);

--
-- Indexes for table `order_items`
--
ALTER TABLE `order_items`
  ADD PRIMARY KEY (`order_item_id`),
  ADD KEY `idx_order_items_order` (`order_id`),
  ADD KEY `idx_order_id` (`order_id`),
  ADD KEY `idx_product_id` (`product_id`);

--
-- Indexes for table `password_reset_tokens`
--
ALTER TABLE `password_reset_tokens`
  ADD PRIMARY KEY (`token_id`),
  ADD UNIQUE KEY `token` (`token`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `idx_token` (`token`),
  ADD KEY `idx_email` (`email`),
  ADD KEY `idx_expires` (`expires_at`),
  ADD KEY `idx_reset_code` (`reset_code`);

--
-- Indexes for table `payments`
--
ALTER TABLE `payments`
  ADD PRIMARY KEY (`payment_id`),
  ADD KEY `order_id` (`order_id`);

--
-- Indexes for table `payment_methods`
--
ALTER TABLE `payment_methods`
  ADD PRIMARY KEY (`method_id`);

--
-- Indexes for table `products`
--
ALTER TABLE `products`
  ADD PRIMARY KEY (`product_id`),
  ADD KEY `idx_products_category` (`category_id`),
  ADD KEY `idx_products_brand` (`brand_id`),
  ADD KEY `idx_products_name` (`product_name`),
  ADD KEY `idx_stock_status` (`stock_status`),
  ADD KEY `idx_stock_quantity` (`stock_quantity`),
  ADD KEY `idx_category_id` (`category_id`),
  ADD KEY `idx_brand_id` (`brand_id`),
  ADD KEY `idx_price` (`price`),
  ADD KEY `idx_created_at` (`created_at`);
ALTER TABLE `products` ADD FULLTEXT KEY `ft_product_search` (`product_name`,`description`);

--
-- Indexes for table `product_ratings`
--
ALTER TABLE `product_ratings`
  ADD PRIMARY KEY (`rating_id`),
  ADD UNIQUE KEY `unique_product_rating` (`product_id`);

--
-- Indexes for table `product_reviews`
--
ALTER TABLE `product_reviews`
  ADD PRIMARY KEY (`review_id`),
  ADD KEY `idx_product_id` (`product_id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_rating` (`rating`),
  ADD KEY `idx_created_at` (`created_at`);

--
-- Indexes for table `product_specifications`
--
ALTER TABLE `product_specifications`
  ADD PRIMARY KEY (`spec_id`),
  ADD KEY `idx_product_specs` (`product_id`);

--
-- Indexes for table `promotions`
--
ALTER TABLE `promotions`
  ADD PRIMARY KEY (`promotion_id`);

--
-- Indexes for table `rate_limits`
--
ALTER TABLE `rate_limits`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_ip_endpoint` (`ip_address`,`endpoint`),
  ADD KEY `idx_window` (`window_start`);

--
-- Indexes for table `reports`
--
ALTER TABLE `reports`
  ADD PRIMARY KEY (`report_id`),
  ADD KEY `admin_id` (`admin_id`);

--
-- Indexes for table `reviews`
--
ALTER TABLE `reviews`
  ADD PRIMARY KEY (`review_id`),
  ADD KEY `idx_reviews_product` (`product_id`),
  ADD KEY `idx_reviews_user` (`user_id`);

--
-- Indexes for table `search_analytics`
--
ALTER TABLE `search_analytics`
  ADD PRIMARY KEY (`analytics_id`),
  ADD UNIQUE KEY `unique_date_query` (`date`,`search_query`),
  ADD KEY `idx_date` (`date`),
  ADD KEY `idx_total_searches` (`total_searches`);

--
-- Indexes for table `search_history`
--
ALTER TABLE `search_history`
  ADD PRIMARY KEY (`search_id`),
  ADD KEY `idx_search_query` (`search_query`),
  ADD KEY `idx_searched_at` (`searched_at`),
  ADD KEY `idx_user_query` (`user_id`,`search_query`),
  ADD KEY `idx_query_date` (`search_query`,`searched_at`);

--
-- Indexes for table `search_suggestions`
--
ALTER TABLE `search_suggestions`
  ADD PRIMARY KEY (`suggestion_id`),
  ADD UNIQUE KEY `suggestion_text` (`suggestion_text`),
  ADD KEY `idx_suggestion_text` (`suggestion_text`),
  ADD KEY `idx_search_count` (`search_count`),
  ADD KEY `idx_type` (`suggestion_type`);

--
-- Indexes for table `site_settings`
--
ALTER TABLE `site_settings`
  ADD PRIMARY KEY (`setting_key`);

--
-- Indexes for table `stock_alerts`
--
ALTER TABLE `stock_alerts`
  ADD PRIMARY KEY (`alert_id`),
  ADD KEY `product_id` (`product_id`),
  ADD KEY `idx_unresolved` (`is_resolved`,`created_at`);

--
-- Indexes for table `stock_movements`
--
ALTER TABLE `stock_movements`
  ADD PRIMARY KEY (`movement_id`),
  ADD KEY `created_by` (`created_by`),
  ADD KEY `idx_product_date` (`product_id`,`created_at`),
  ADD KEY `idx_movement_type` (`movement_type`),
  ADD KEY `idx_reference` (`reference_type`,`reference_id`);

--
-- Indexes for table `tech_part_products`
--
ALTER TABLE `tech_part_products`
  ADD PRIMARY KEY (`product_id`),
  ADD KEY `idx_techpart_created` (`created_at`),
  ADD KEY `idx_tech_part_created` (`created_at`);

--
-- Indexes for table `trending_products`
--
ALTER TABLE `trending_products`
  ADD PRIMARY KEY (`trending_product_id`),
  ADD UNIQUE KEY `unique_trending_product` (`product_id`),
  ADD KEY `idx_trending_products_order` (`display_order`),
  ADD KEY `idx_trending_products_score` (`trending_score`),
  ADD KEY `idx_trending_created` (`created_at`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `unique_email` (`email`);

--
-- Indexes for table `user_profile`
--
ALTER TABLE `user_profile`
  ADD PRIMARY KEY (`user_id`);

--
-- Indexes for table `wishlists`
--
ALTER TABLE `wishlists`
  ADD PRIMARY KEY (`wishlist_id`),
  ADD KEY `idx_wishlists_user` (`user_id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_product_id` (`product_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `banners`
--
ALTER TABLE `banners`
  MODIFY `banner_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=146;

--
-- AUTO_INCREMENT for table `brands`
--
ALTER TABLE `brands`
  MODIFY `brand_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=97;

--
-- AUTO_INCREMENT for table `cart`
--
ALTER TABLE `cart`
  MODIFY `cart_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

--
-- AUTO_INCREMENT for table `categories`
--
ALTER TABLE `categories`
  MODIFY `category_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `collections`
--
ALTER TABLE `collections`
  MODIFY `collection_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `collection_items`
--
ALTER TABLE `collection_items`
  MODIFY `item_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=46;

--
-- AUTO_INCREMENT for table `csrf_tokens`
--
ALTER TABLE `csrf_tokens`
  MODIFY `token_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `customer_support`
--
ALTER TABLE `customer_support`
  MODIFY `ticket_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `deals_of_the_day`
--
ALTER TABLE `deals_of_the_day`
  MODIFY `deal_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=55;

--
-- AUTO_INCREMENT for table `deals_timer`
--
ALTER TABLE `deals_timer`
  MODIFY `timer_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `discounts`
--
ALTER TABLE `discounts`
  MODIFY `discount_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `flash_sales`
--
ALTER TABLE `flash_sales`
  MODIFY `flash_sale_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `flash_sale_products`
--
ALTER TABLE `flash_sale_products`
  MODIFY `flash_sale_product_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=34;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `order_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=51;

--
-- AUTO_INCREMENT for table `order_items`
--
ALTER TABLE `order_items`
  MODIFY `order_item_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=42;

--
-- AUTO_INCREMENT for table `password_reset_tokens`
--
ALTER TABLE `password_reset_tokens`
  MODIFY `token_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

--
-- AUTO_INCREMENT for table `payments`
--
ALTER TABLE `payments`
  MODIFY `payment_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `payment_methods`
--
ALTER TABLE `payment_methods`
  MODIFY `method_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `products`
--
ALTER TABLE `products`
  MODIFY `product_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=123;

--
-- AUTO_INCREMENT for table `product_ratings`
--
ALTER TABLE `product_ratings`
  MODIFY `rating_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=128;

--
-- AUTO_INCREMENT for table `product_reviews`
--
ALTER TABLE `product_reviews`
  MODIFY `review_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `product_specifications`
--
ALTER TABLE `product_specifications`
  MODIFY `spec_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=192;

--
-- AUTO_INCREMENT for table `promotions`
--
ALTER TABLE `promotions`
  MODIFY `promotion_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `rate_limits`
--
ALTER TABLE `rate_limits`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `reports`
--
ALTER TABLE `reports`
  MODIFY `report_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `reviews`
--
ALTER TABLE `reviews`
  MODIFY `review_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `search_analytics`
--
ALTER TABLE `search_analytics`
  MODIFY `analytics_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `search_history`
--
ALTER TABLE `search_history`
  MODIFY `search_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `search_suggestions`
--
ALTER TABLE `search_suggestions`
  MODIFY `suggestion_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=230;

--
-- AUTO_INCREMENT for table `stock_alerts`
--
ALTER TABLE `stock_alerts`
  MODIFY `alert_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `stock_movements`
--
ALTER TABLE `stock_movements`
  MODIFY `movement_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=152;

--
-- AUTO_INCREMENT for table `trending_products`
--
ALTER TABLE `trending_products`
  MODIFY `trending_product_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=113;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT for table `wishlists`
--
ALTER TABLE `wishlists`
  MODIFY `wishlist_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `best_sellers`
--
ALTER TABLE `best_sellers`
  ADD CONSTRAINT `best_sellers_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE;

--
-- Constraints for table `cart`
--
ALTER TABLE `cart`
  ADD CONSTRAINT `cart_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `cart_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE;

--
-- Constraints for table `collection_items`
--
ALTER TABLE `collection_items`
  ADD CONSTRAINT `collection_items_ibfk_1` FOREIGN KEY (`collection_id`) REFERENCES `collections` (`collection_id`) ON DELETE CASCADE;

--
-- Constraints for table `collection_products`
--
ALTER TABLE `collection_products`
  ADD CONSTRAINT `collection_products_ibfk_1` FOREIGN KEY (`collection_id`) REFERENCES `collections` (`collection_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `collection_products_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE;

--
-- Constraints for table `customer_support`
--
ALTER TABLE `customer_support`
  ADD CONSTRAINT `customer_support_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `customer_support_ibfk_2` FOREIGN KEY (`resolved_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

--
-- Constraints for table `deals_of_the_day`
--
ALTER TABLE `deals_of_the_day`
  ADD CONSTRAINT `deals_of_the_day_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE;

--
-- Constraints for table `discounts`
--
ALTER TABLE `discounts`
  ADD CONSTRAINT `discounts_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE;

--
-- Constraints for table `flash_sale_products`
--
ALTER TABLE `flash_sale_products`
  ADD CONSTRAINT `flash_sale_products_ibfk_1` FOREIGN KEY (`flash_sale_id`) REFERENCES `flash_sales` (`flash_sale_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `flash_sale_products_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE;

--
-- Constraints for table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `order_items`
--
ALTER TABLE `order_items`
  ADD CONSTRAINT `order_items_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `order_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE SET NULL;

--
-- Constraints for table `password_reset_tokens`
--
ALTER TABLE `password_reset_tokens`
  ADD CONSTRAINT `password_reset_tokens_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `payments`
--
ALTER TABLE `payments`
  ADD CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE;

--
-- Constraints for table `products`
--
ALTER TABLE `products`
  ADD CONSTRAINT `products_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `categories` (`category_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `products_ibfk_2` FOREIGN KEY (`brand_id`) REFERENCES `brands` (`brand_id`) ON DELETE SET NULL;

--
-- Constraints for table `product_ratings`
--
ALTER TABLE `product_ratings`
  ADD CONSTRAINT `product_ratings_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE;

--
-- Constraints for table `product_reviews`
--
ALTER TABLE `product_reviews`
  ADD CONSTRAINT `product_reviews_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `product_reviews_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `product_specifications`
--
ALTER TABLE `product_specifications`
  ADD CONSTRAINT `product_specifications_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE;

--
-- Constraints for table `reports`
--
ALTER TABLE `reports`
  ADD CONSTRAINT `reports_ibfk_1` FOREIGN KEY (`admin_id`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `reviews`
--
ALTER TABLE `reviews`
  ADD CONSTRAINT `reviews_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `reviews_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

--
-- Constraints for table `search_history`
--
ALTER TABLE `search_history`
  ADD CONSTRAINT `search_history_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

--
-- Constraints for table `stock_alerts`
--
ALTER TABLE `stock_alerts`
  ADD CONSTRAINT `stock_alerts_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE;

--
-- Constraints for table `tech_part_products`
--
ALTER TABLE `tech_part_products`
  ADD CONSTRAINT `tech_part_products_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE;

--
-- Constraints for table `trending_products`
--
ALTER TABLE `trending_products`
  ADD CONSTRAINT `trending_products_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE;

--
-- Constraints for table `user_profile`
--
ALTER TABLE `user_profile`
  ADD CONSTRAINT `user_profile_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `wishlists`
--
ALTER TABLE `wishlists`
  ADD CONSTRAINT `wishlists_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `wishlists_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE;

DELIMITER $$
--
-- Events
--
CREATE DEFINER=`root`@`localhost` EVENT `daily_search_analytics` ON SCHEDULE EVERY 1 DAY STARTS '2026-03-05 00:00:00' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN
    INSERT INTO search_analytics (date, search_query, total_searches, unique_users, avg_results, zero_results_count)
    SELECT 
        DATE(searched_at) as date,
        search_query,
        COUNT(*) as total_searches,
        COUNT(DISTINCT user_id) as unique_users,
        AVG(results_count) as avg_results,
        SUM(CASE WHEN results_count = 0 THEN 1 ELSE 0 END) as zero_results_count
    FROM search_history
    WHERE DATE(searched_at) = CURDATE() - INTERVAL 1 DAY
    GROUP BY DATE(searched_at), search_query
    ON DUPLICATE KEY UPDATE
        total_searches = VALUES(total_searches),
        unique_users = VALUES(unique_users),
        avg_results = VALUES(avg_results),
        zero_results_count = VALUES(zero_results_count);
END$$

CREATE DEFINER=`root`@`localhost` EVENT `cleanup_old_search_history` ON SCHEDULE EVERY 1 WEEK STARTS '2026-03-04 16:49:34' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN
    DELETE FROM search_history
    WHERE searched_at < DATE_SUB(NOW(), INTERVAL 90 DAY);
END$$

DELIMITER ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
