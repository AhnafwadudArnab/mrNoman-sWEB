-- ============================================================
-- Add Tech Part Products
-- Run in phpMyAdmin → asiment1_electrobd → SQL tab
-- ============================================================

USE `asiment1_electrobd`;

-- Clear existing and re-insert with more products
DELETE FROM `tech_part_products`;

INSERT INTO `tech_part_products` (`product_id`, `display_order`, `created_at`) VALUES
(10, 1, NOW()),   -- Samsung CCTV Camera (Electronics & Gadgets)
(45, 2, NOW()),   -- Smart LED Strip (Electronics)
(17, 3, NOW()),   -- Hikvision Air Purifier (Home Comfort)
(14, 4, NOW()),   -- Walton AC 1.5 Ton (Home Comfort)
(15, 5, NOW()),   -- Walton AC 2 Ton (Home Comfort)
(62, 6, NOW()),   -- Air Fryer Digital (trending)
(74, 7, NOW()),   -- Miyoko Oven 25L (trending)
(9,  8, NOW()),   -- Miyako 25L Electric Oven
(19, 9, NOW()),   -- LG Table Fan 16"
(55, 10, NOW());  -- LR2018 Blender

-- Verify
SELECT tp.product_id, tp.display_order, p.product_name, p.price, p.image_url
FROM tech_part_products tp
JOIN products p ON tp.product_id = p.product_id
ORDER BY tp.display_order;
