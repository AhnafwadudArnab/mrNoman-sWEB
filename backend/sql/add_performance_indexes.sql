-- Performance indexes for faster product queries
-- Run once on your MySQL database

-- Products table
ALTER TABLE products ADD INDEX IF NOT EXISTS idx_category_id (category_id);
ALTER TABLE products ADD INDEX IF NOT EXISTS idx_brand_id (brand_id);
ALTER TABLE products ADD INDEX IF NOT EXISTS idx_created_at (created_at);

-- Section join tables
ALTER TABLE best_sellers ADD INDEX IF NOT EXISTS idx_product_id (product_id);
ALTER TABLE trending_products ADD INDEX IF NOT EXISTS idx_product_id (product_id);
ALTER TABLE deals_of_the_day ADD INDEX IF NOT EXISTS idx_product_id (product_id);
ALTER TABLE flash_sale_products ADD INDEX IF NOT EXISTS idx_product_id (product_id);
ALTER TABLE tech_part_products ADD INDEX IF NOT EXISTS idx_product_id (product_id);

-- Discounts date range lookup
ALTER TABLE discounts ADD INDEX IF NOT EXISTS idx_product_date (product_id, valid_from, valid_to);

-- Product ratings
ALTER TABLE product_ratings ADD INDEX IF NOT EXISTS idx_product_id (product_id);
