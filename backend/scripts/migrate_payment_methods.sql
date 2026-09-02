-- ============================================================
-- Migration: Fix payment_methods table for production
-- Run this in phpMyAdmin if your DB already exists
-- ============================================================

-- Step 1: Drop old table if it has wrong schema (name/logo_url/is_active)
-- ONLY run this if your table has the OLD schema columns
-- Check first: DESCRIBE payment_methods;

-- If old schema exists, recreate it:
DROP TABLE IF EXISTS `payment_methods`;

CREATE TABLE `payment_methods` (
  `method_id`      INT AUTO_INCREMENT PRIMARY KEY,
  `method_name`    VARCHAR(100) NOT NULL,
  `method_type`    VARCHAR(50)  DEFAULT 'mobile_banking',
  `is_enabled`     TINYINT(1)   DEFAULT 1,
  `account_number` VARCHAR(100) DEFAULT '',
  `display_order`  INT          DEFAULT 0,
  `icon_url`       VARCHAR(255) DEFAULT '',
  `created_at`     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Step 2: Insert all payment methods including Rocket & Upay
INSERT INTO `payment_methods` (`method_name`, `method_type`, `is_enabled`, `account_number`, `display_order`, `icon_url`) VALUES
('bKash',            'mobile_banking', 1, '', 1, 'assets/payments/baksh.png'),
('Nagad',            'mobile_banking', 1, '', 2, 'assets/payments/nagad.png'),
('Rocket',           'mobile_banking', 1, '', 3, 'assets/payments/rocket.png'),
('Upay',             'mobile_banking', 1, '', 4, 'assets/payments/upay.png'),
('Cash on Delivery', 'cash',           1, '', 5, ''),
('Visa',             'card',           0, '', 6, 'assets/payments/visa.png'),
('Mastercard',       'card',           0, '', 7, 'assets/payments/master.png');
