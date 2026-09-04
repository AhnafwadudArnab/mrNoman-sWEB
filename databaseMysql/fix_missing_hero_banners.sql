-- Fix missing hero banner images
-- Run this ONLY if the uploaded hero banner images are not available on the server.
-- This replaces the hero banners with mid-banner assets (1.png, 2.png, 3.png)
-- which are always present as Flutter assets.
--
-- After running this, go to Admin → Banners and re-upload proper hero images.

UPDATE `banners`
SET `image_url` = 'assets/1.png', `title` = 'Pre-ramadan'
WHERE `banner_id` = 34 AND `banner_type` = 'hero';

UPDATE `banners`
SET `image_url` = 'assets/2.png', `title` = 'Top Products'
WHERE `banner_id` = 35 AND `banner_type` = 'hero';
