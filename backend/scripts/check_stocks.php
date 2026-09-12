<?php
require_once __DIR__ . '/../config/db.php';
$db = (new Database())->getConnection();
$rows = $db->query("SELECT product_id, product_name, stock_quantity, price FROM products ORDER BY product_id ASC")->fetchAll(PDO::FETCH_ASSOC);
foreach($rows as $r) {
    echo "ID: " . str_pad($r['product_id'], 4) . " | Stock: " . str_pad($r['stock_quantity'], 4) . " | Price: " . str_pad($r['price'], 7) . " | " . $r['product_name'] . "\n";
}
