-- Fix: Allow product_id to be NULL in order_items
-- This is required for guest orders or items from non-DB sources
ALTER TABLE order_items MODIFY COLUMN product_id INT NULL;
