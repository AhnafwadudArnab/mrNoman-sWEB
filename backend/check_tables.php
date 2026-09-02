<?php
require 'api/bootstrap.php';

try {
    $pdo = db();
    $tables = $pdo->query('SHOW TABLES')->fetchAll(PDO::FETCH_COLUMN);
    
    echo "=== Database Tables ===\n\n";
    echo "Total tables: " . count($tables) . "\n\n";
    
    foreach ($tables as $table) {
        $count = $pdo->query("SELECT COUNT(*) FROM `$table`")->fetchColumn();
        echo "- $table: $count rows\n";
    }
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?>
