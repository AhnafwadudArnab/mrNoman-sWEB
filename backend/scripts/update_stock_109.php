<?php
require_once __DIR__ . '/../config/db.php';
$db = (new Database())->getConnection();
$db->exec("UPDATE products SET stock_quantity = 50 WHERE product_id = 109");
echo "Product 109 stock updated to 50.\n";
