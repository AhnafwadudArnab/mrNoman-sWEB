-- ============================================================
-- Migration: Guest Order Support
-- Run this in phpMyAdmin → SQL tab
-- Allows orders without a logged-in user account
-- ============================================================

-- 1. Make user_id nullable (guest orders have no user account)
ALTER TABLE `orders`
  MODIFY COLUMN `user_id` INT DEFAULT NULL;

-- 2. Drop the existing FK that enforces NOT NULL user reference
--    (MySQL requires dropping FK before modifying the column constraint)
ALTER TABLE `orders`
  DROP FOREIGN KEY IF EXISTS `orders_ibfk_1`;

-- 3. Re-add FK as nullable (ON DELETE SET NULL so guest orders survive user deletion)
ALTER TABLE `orders`
  ADD CONSTRAINT `orders_ibfk_1`
  FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`) ON DELETE SET NULL;

-- 4. Add customer_name and customer_phone for guest orders
--    (also useful for logged-in users who enter a different delivery contact)
ALTER TABLE `orders`
  ADD COLUMN IF NOT EXISTS `customer_name`  VARCHAR(150) DEFAULT NULL AFTER `user_id`,
  ADD COLUMN IF NOT EXISTS `customer_phone` VARCHAR(20)  DEFAULT NULL AFTER `customer_name`;

-- 5. Add delivery_address column if it doesn't exist under that name
--    (schema uses shipping_address but controller uses delivery_address)
ALTER TABLE `orders`
  ADD COLUMN IF NOT EXISTS `delivery_address` TEXT DEFAULT NULL AFTER `customer_phone`,
  ADD COLUMN IF NOT EXISTS `order_status`     VARCHAR(50) DEFAULT 'New Order' AFTER `delivery_address`,
  ADD COLUMN IF NOT EXISTS `estimated_delivery` VARCHAR(100) DEFAULT NULL AFTER `order_status`;

-- Done
SELECT 'Migration complete: guest order support added' AS result;
