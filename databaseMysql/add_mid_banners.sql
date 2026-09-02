-- ============================================================
-- ElectroZoneBD - Add Mid Banners
-- Import this file in phpMyAdmin to add mid-page banners
-- ============================================================

USE `asiment3_electrobd`;

-- Clear existing mid banners (optional)
DELETE FROM banners WHERE banner_type = 'mid';

-- Insert Mid Banners (mid-page promotional banners)
INSERT INTO `banners` 
  (`banner_type`, `image_url`, `link_url`, `title`, `description`, `button_text`, `display_order`, `active`, `start_date`, `end_date`)
VALUES
  (
    'mid',
    'assets/mid-banner-products/banner1.jpg',
    '/products?action=deals',
    'Deals of the Day',
    'Limited time offers on selected products',
    'Shop Deals',
    1,
    TRUE,
    CURDATE(),
    DATE_ADD(CURDATE(), INTERVAL 1 YEAR)
  ),
  (
    'mid',
    'assets/mid-banner-products/banner2.jpg',
    '/products?action=flash-sale',
    'Flash Sale',
    'Up to 50% off on electronics',
    'View Sale',
    2,
    TRUE,
    CURDATE(),
    DATE_ADD(CURDATE(), INTERVAL 1 YEAR)
  ),
  (
    'mid',
    'assets/mid-banner-products/banner3.jpg',
    '/products?category=1',
    'Best Sellers',
    'Most popular products this month',
    'See More',
    3,
    TRUE,
    CURDATE(),
    DATE_ADD(CURDATE(), INTERVAL 1 YEAR)
  ),
  (
    'mid',
    'assets/mid-banner-products/banner4.jpg',
    '/products?sort=new',
    'New Arrivals',
    'Check out the latest products',
    'Browse New',
    4,
    TRUE,
    CURDATE(),
    DATE_ADD(CURDATE(), INTERVAL 1 YEAR)
  );

-- Verify insertion
SELECT COUNT(*) as total_mid_banners FROM banners WHERE banner_type = 'mid' AND active = TRUE;

