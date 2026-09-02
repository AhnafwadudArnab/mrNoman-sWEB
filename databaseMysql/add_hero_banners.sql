-- ============================================================
-- ElectroZoneBD - Add Hero Banners
-- Import this file in phpMyAdmin to add hero banners
-- ============================================================

USE `asiment3_electrobd`;

-- Clear existing hero banners (optional)
DELETE FROM banners WHERE banner_type = 'hero';

-- Insert Hero Banners (main carousel)
INSERT INTO `banners` 
  (`banner_type`, `image_url`, `link_url`, `title`, `description`, `button_text`, `display_order`, `active`)
VALUES
  (
    'hero',
    'assets/Hero banner logos/slider1.png',
    '/products?category=1',
    'Latest TVs & Displays',
    'Enjoy premium picture quality with our latest TV collection',
    'Shop Now',
    1,
    TRUE
  ),
  (
    'hero',
    'assets/Hero banner logos/slider2.png',
    '/products?category=2',
    'Mobile Phones & Accessories',
    'Get the latest smartphones and tech accessories',
    'Explore',
    2,
    TRUE
  ),
  (
    'hero',
    'assets/Hero banner logos/slider3.png',
    '/products?category=3',
    'Home Appliances',
    'Smart appliances for your modern home',
    'Browse',
    3,
    TRUE
  ),
  (
    'hero',
    'assets/Hero banner logos/slider1.png',
    '/products?brand=1',
    'Philips Brand Sale',
    'Premium electronics from world-renowned Philips',
    'View All',
    4,
    TRUE
  ),
  (
    'hero',
    'assets/Hero banner logos/slider2.png',
    '/products?brand=2',
    'Walton Electronics',
    'Quality and reliability from Bangladesh',
    'Shop',
    5,
    TRUE
  );

-- Verify insertion
SELECT COUNT(*) as total_hero_banners FROM banners WHERE banner_type = 'hero' AND active = TRUE;

