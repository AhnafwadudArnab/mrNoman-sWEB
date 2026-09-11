<?php
require_once __DIR__ . '/bootstrap.php';
$db = db();
$res = [];
try {
    $db->exec("ALTER TABLE products ADD COLUMN regular_price DECIMAL(10,2) NULL AFTER price");
    $res['column'] = 'added';
} catch (Exception $e) {
    $res['column'] = $e->getMessage();
}

// Also update sample products if regular_price is null or 0 so discount badges display immediately
try {
    $db->exec("UPDATE products SET regular_price = ROUND(price * 1.25, 2) WHERE (regular_price IS NULL OR regular_price = 0) AND price > 0 LIMIT 15");
    $res['sample_updated'] = true;
} catch (Exception $e) {
    $res['sample_updated'] = $e->getMessage();
}

echo json_encode($res);
