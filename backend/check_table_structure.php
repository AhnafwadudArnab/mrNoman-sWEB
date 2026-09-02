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
    
    echo "=== Products Table Structure ===\n";
    $stmt = $pdo->query("DESCRIBE products");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    foreach ($columns as $col) {
        echo "- {$col['Field']}: {$col['Type']}\n";
    }
    
    echo "\n=== Sample Products Data ===\n";
    $stmt = $pdo->query("SELECT * FROM products LIMIT 3");
    $products = $stmt->fetchAll(PDO::FETCH_ASSOC);
    foreach ($products as $product) {
        echo "\nProduct:\n";
        foreach ($product as $key => $val) {
            $val_short = strlen($val) > 50 ? substr($val, 0, 50) . "..." : $val;
            echo "  $key: $val_short\n";
        }
    }
    
    echo "\n=== Total Count ===\n";
    $result = $pdo->query("SELECT COUNT(*) as count FROM products")->fetch(PDO::FETCH_ASSOC);
    echo "Total Products: " . $result['count'] . "\n";
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
?>
