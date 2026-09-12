<?php
require_once __DIR__ . '/../config/db.php';

$db = (new Database())->getConnection();

echo "Running orders table migration...\n";

// Get existing columns
$existingCols = $db->query("DESCRIBE orders")->fetchAll(PDO::FETCH_COLUMN);

$columnsToAdd = [
    'customer_name' => "ALTER TABLE `orders` ADD COLUMN `customer_name` VARCHAR(150) DEFAULT NULL AFTER `user_id`",
    'customer_phone' => "ALTER TABLE `orders` ADD COLUMN `customer_phone` VARCHAR(20) DEFAULT NULL AFTER `customer_name`",
    'subtotal_amount' => "ALTER TABLE `orders` ADD COLUMN `subtotal_amount` DECIMAL(10,2) DEFAULT 0.00 AFTER `total_amount`",
    'delivery_charge' => "ALTER TABLE `orders` ADD COLUMN `delivery_charge` DECIMAL(10,2) DEFAULT 0.00 AFTER `subtotal_amount`",
    'delivery_zone' => "ALTER TABLE `orders` ADD COLUMN `delivery_zone` VARCHAR(50) DEFAULT NULL AFTER `delivery_charge`",
    'coupon_discount' => "ALTER TABLE `orders` ADD COLUMN `coupon_discount` DECIMAL(10,2) DEFAULT 0.00 AFTER `delivery_zone`",
    'coupon_code' => "ALTER TABLE `orders` ADD COLUMN `coupon_code` VARCHAR(50) DEFAULT NULL AFTER `coupon_discount`"
];

foreach ($columnsToAdd as $col => $sql) {
    if (!in_array($col, $existingCols)) {
        try {
            $db->exec($sql);
            echo "✓ Added column `$col`.\n";
            // Refresh columns list
            $existingCols = $db->query("DESCRIBE orders")->fetchAll(PDO::FETCH_COLUMN);
        } catch (Exception $e) {
            echo "✗ Failed to add `$col`: " . $e->getMessage() . "\n";
        }
    } else {
        echo "✓ Column `$col` already exists.\n";
    }
}

// Check order_items product_id nullable
try {
    $db->exec("ALTER TABLE `order_items` MODIFY COLUMN `product_id` INT DEFAULT NULL");
    echo "✓ order_items.product_id is NULLABLE.\n";
} catch (Exception $e) {
    echo "Notice: " . $e->getMessage() . "\n";
}

$finalCols = $db->query("DESCRIBE orders")->fetchAll(PDO::FETCH_COLUMN);
echo "\nFinal orders columns: " . implode(', ', $finalCols) . "\n";
