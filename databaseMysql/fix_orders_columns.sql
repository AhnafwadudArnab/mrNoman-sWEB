-- ============================================================
-- FIX: Add missing columns to orders table
-- Run this in phpMyAdmin → asiment1_electrobd → SQL tab
-- ============================================================

USE `asiment1_electrobd`;

-- Add customer_name column (for guest orders)
ALTER TABLE `orders`
  ADD COLUMN IF NOT EXISTS `customer_name` varchar(150) DEFAULT NULL AFTER `estimated_delivery`;

-- Add customer_phone column (for guest orders)
ALTER TABLE `orders`
  ADD COLUMN IF NOT EXISTS `customer_phone` varchar(20) DEFAULT NULL AFTER `customer_name`;

-- Add order amount breakdown columns so checkout, admin, and track-order pages
-- all read the same saved delivery charge and discount values.
ALTER TABLE `orders`
  ADD COLUMN IF NOT EXISTS `subtotal_amount` decimal(10,2) DEFAULT 0.00 AFTER `total_amount`;

ALTER TABLE `orders`
  ADD COLUMN IF NOT EXISTS `delivery_charge` decimal(10,2) DEFAULT 0.00 AFTER `subtotal_amount`;

ALTER TABLE `orders`
  ADD COLUMN IF NOT EXISTS `coupon_discount` decimal(10,2) DEFAULT 0.00 AFTER `delivery_charge`;

ALTER TABLE `orders`
  ADD COLUMN IF NOT EXISTS `delivery_zone` varchar(50) DEFAULT NULL AFTER `coupon_discount`;

ALTER TABLE `orders`
  ADD COLUMN IF NOT EXISTS `coupon_code` varchar(100) DEFAULT NULL AFTER `delivery_zone`;
