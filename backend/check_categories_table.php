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
    
    echo "=== Categories Table Structure ===\n";
    $columns = $pdo->query("DESCRIBE categories")->fetchAll(PDO::FETCH_ASSOC);
    foreach ($columns as $col) {
        echo "  {$col['Field']}: {$col['Type']}\n";
    }
    
    echo "\n=== Sample Categories ===\n";
    $stmt = $pdo->query("SELECT * FROM categories LIMIT 3");
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        echo "\n- Category:\n";
        foreach ($row as $key => $val) {
            echo "  $key: $val\n";
        }
    }
    
} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage();
}
?>
