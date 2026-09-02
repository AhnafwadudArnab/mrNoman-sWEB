-- ============================================================
-- ElectroZoneBD - Add Sidebar Promotional Banner
-- Import this file in phpMyAdmin to add sidebar promo
-- ============================================================

USE `asiment3_electrobd`;

-- Clear existing sidebar promos (optional)
DELETE FROM banners WHERE banner_type = 'sidebar';

-- Insert Sidebar Promo Banner
INSERT INTO `banners` 
  (`banner_type`, `image_url`, `link_url`, `title`, `description`, `button_text`, `display_order`, `active`)
VALUES
  (
    'sidebar',
    'assets/Hero banner logos/sidebar-promo.png',
    '/products?action=flash-sale',
    'FLASH SALE',
    'Limited time offers - Don\'t miss out!',
    'VIEW ALL',
    1,
    TRUE
  );

-- Verify insertion
SELECT * FROM banners WHERE banner_type = 'sidebar' AND active = TRUE;

