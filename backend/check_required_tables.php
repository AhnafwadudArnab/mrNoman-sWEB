<?php
require_once __DIR__ . '/config/env.php';

$db_host = getenv('DB_HOST') ?: 'localhost';
$db_name = getenv('DB_NAME') ?: 'electrobd';
$db_user = getenv('DB_USER') ?: 'root';
$db_port = getenv('DB_PORT') ?: '3306';
$db_pass = getenv('DB_PASSWORD') ?: '';

try {
    $dsn = "mysql:host=$db_host;port=$db_port;dbname=$db_name;charset=utf8mb4";
    $pdo = new PDO($dsn, $db_user, $db_pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    ]);
    
    echo "=== Checking Required Tables ===\n\n";
    
    $tables_to_check = [
        'collections' => 'getCollections()',
        'deals_timer' => 'getFlashSalesTimer()',
        'trending_products' => 'getTrendingProducts()',
        'product_ratings' => 'formatProduct() ratings',
        'flash_sales' => 'getFlashSales()',
        'flash_sale_products' => 'getFlashSales()',
        'deals_of_the_day' => 'getDealsOfTheDay()'
    ];
    
    $all_exist = $pdo->query("SHOW TABLES")->fetchAll(PDO::FETCH_COLUMN);
    
    foreach ($tables_to_check as $table => $usage) {
        $exists = in_array($table, $all_exist) ? '✅' : '❌';
        echo "$exists $table - Used by: $usage\n";
    }
    
    echo "\n=== All Tables in Database ===\n";
    foreach ($all_exist as $table) {
        echo "  - $table\n";
    }
    
} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage();
}
?>
