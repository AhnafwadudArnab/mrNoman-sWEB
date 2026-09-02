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
    
    echo "=== Banners Table Check ===\n";
    
    // Check if banners table exists
    $tables = $pdo->query("SHOW TABLES LIKE 'banners'")->fetchAll(PDO::FETCH_COLUMN);
    if (empty($tables)) {
        echo "❌ BANNERS TABLE DOES NOT EXIST!\n";
        echo "\nAll Tables:\n";
        $all = $pdo->query("SHOW TABLES")->fetchAll(PDO::FETCH_COLUMN);
        foreach ($all as $t) {
            echo "  - $t\n";
        }
        exit(1);
    }
    
    echo "✅ Banners table exists\n\n";
    
    // Check banners structure
    echo "=== Banners Table Structure ===\n";
    $columns = $pdo->query("DESCRIBE banners")->fetchAll(PDO::FETCH_ASSOC);
    foreach ($columns as $col) {
        echo "  {$col['Field']}: {$col['Type']}\n";
    }
    
    // Count banners by type
    echo "\n=== Banners by Type ===\n";
    $result = $pdo->query("SELECT banner_type, COUNT(*) as count FROM banners GROUP BY banner_type")->fetchAll(PDO::FETCH_ASSOC);
    foreach ($result as $row) {
        echo "  {$row['banner_type']}: {$row['count']} banners\n";
    }
    
    // Total count
    $total = $pdo->query("SELECT COUNT(*) as count FROM banners")->fetch(PDO::FETCH_ASSOC);
    echo "\nTotal Banners: " . $total['count'] . "\n";
    
    // Sample banners
    if ($total['count'] > 0) {
        echo "\n=== Sample Banners ===\n";
        $stmt = $pdo->query("SELECT banner_type, title, image_url, link_url, active FROM banners LIMIT 5");
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $active = $row['active'] ? '✅' : '❌';
            echo "\n$active {$row['banner_type']}: {$row['title']}\n";
            echo "  Image: {$row['image_url']}\n";
            echo "  Link: {$row['link_url']}\n";
        }
    } else {
        echo "\n⚠️  NO BANNERS FOUND IN DATABASE!\n";
    }
    
    // Check other related tables
    echo "\n=== Related Tables ===\n";
    $tables_to_check = ['best_sellers', 'categories', 'products', 'deals_of_the_day'];
    foreach ($tables_to_check as $table) {
        $count = $pdo->query("SELECT COUNT(*) as count FROM $table")->fetch(PDO::FETCH_ASSOC);
        echo "  $table: " . $count['count'] . " records\n";
    }
    
} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage();
    exit(1);
}
?>
