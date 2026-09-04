-- ============================================================
-- ElectroZoneBD — DB Verification Script
-- Based on LIVE DB dump: asiment1_electrobd.sql (Apr 26, 2026)
-- 
-- ✅ ALL FIXES ALREADY APPLIED IN LIVE DB:
--    - orders.customer_name ✓
--    - orders.customer_phone ✓
--    - site_settings.id ✓
--    - notifications table ✓
--    - product_sections table ✓
--    - ratings view ✓
--
-- This script just VERIFIES everything is correct.
-- Run in phpMyAdmin → asiment1_electrobd → SQL tab
-- ============================================================

USE `asiment1_electrobd`;

SELECT 'orders.customer_name'   AS item, IF(COUNT(*)>0,'✓ OK','✗ MISSING') AS status FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='orders' AND COLUMN_NAME='customer_name'
UNION ALL
SELECT 'orders.customer_phone',          IF(COUNT(*)>0,'✓ OK','✗ MISSING') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='orders' AND COLUMN_NAME='customer_phone'
UNION ALL
SELECT 'site_settings.id',               IF(COUNT(*)>0,'✓ OK','✗ MISSING') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='site_settings' AND COLUMN_NAME='id'
UNION ALL
SELECT 'notifications table',            IF(COUNT(*)>0,'✓ OK','✗ MISSING') FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='notifications'
UNION ALL
SELECT 'product_sections table',         IF(COUNT(*)>0,'✓ OK','✗ MISSING') FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='product_sections'
UNION ALL
SELECT 'ratings view',                   IF(COUNT(*)>0,'✓ OK','✗ MISSING') FROM information_schema.VIEWS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='ratings'
UNION ALL
SELECT 'flash_sales end_time',           IF(COUNT(*)>0,'✓ OK','✗ MISSING') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='flash_sales' AND COLUMN_NAME='end_time'
UNION ALL
SELECT 'payment_methods is_enabled',     IF(COUNT(*)>0,'✓ OK','✗ MISSING') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='payment_methods' AND COLUMN_NAME='is_enabled';
