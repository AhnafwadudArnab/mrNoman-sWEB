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
    
    echo "=== Database Connection: SUCCESS ===\n\n";
    
    // Check products table
    echo "=== Products Table Check ===\n";
    $result = $pdo->query("SELECT COUNT(*) as count FROM products")->fetch(PDO::FETCH_ASSOC);
    echo "Total Products: " . $result['count'] . "\n";
    
    if ($result['count'] > 0) {
        echo "\nFirst 3 products:\n";
        $stmt = $pdo->query("SELECT id, name, category_id, price, status, created_at FROM products LIMIT 3");
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            echo "- ID: {$row['id']}, Name: {$row['name']}, Price: {$row['price']}, Status: {$row['status']}\n";
        }
    } else {
        echo "\n⚠️  NO PRODUCTS FOUND IN DATABASE!\n";
    }
    
    echo "\n=== Categories Table Check ===\n";
    $result = $pdo->query("SELECT COUNT(*) as count FROM categories")->fetch(PDO::FETCH_ASSOC);
    echo "Total Categories: " . $result['count'] . "\n";
    if ($result['count'] > 0) {
        echo "Categories: ";
        $cats = $pdo->query("SELECT DISTINCT name FROM categories LIMIT 5")->fetchAll(PDO::FETCH_COLUMN);
        echo implode(", ", $cats) . "\n";
    }
    
    echo "\n=== Best Sellers Table Check ===\n";
    $result = $pdo->query("SELECT COUNT(*) as count FROM best_sellers")->fetch(PDO::FETCH_ASSOC);
    echo "Total Best Sellers: " . $result['count'] . "\n";
    
    echo "\n=== Check Products API ===\n";
    $result = $pdo->query("SHOW TABLES LIKE '%product%'")->fetchAll(PDO::FETCH_COLUMN);
    echo "Product-related tables: " . implode(", ", $result) . "\n";
    
} catch (Exception $e) {
    echo "❌ Connection Error: " . $e->getMessage();
    exit(1);
}
?>
