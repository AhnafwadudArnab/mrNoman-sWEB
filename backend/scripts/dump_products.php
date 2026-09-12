<?php
require_once __DIR__ . '/../config/database.php';

try {
    $db = (new Database())->getConnection();
    $stmt = $db->query("SELECT product_id, product_name, image_url, category_id, description FROM products ORDER BY product_id ASC");
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
    file_put_contents(__DIR__ . '/current_products.json', json_encode($rows, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
    echo "SUCCESS: dumped " . count($rows) . " products to current_products.json\n";
} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
