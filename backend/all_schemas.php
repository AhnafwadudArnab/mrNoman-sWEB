<?php
require 'config/env.php';
$config = require 'config.php';

try {
    $pdo = new PDO(
        'mysql:host=' . $config['db']['host'] . ';dbname=' . $config['db']['name'],
        $config['db']['user'],
        $config['db']['pass']
    );
    
    $tables = ['products', 'categories', 'brands', 'best_sellers', 'orders', 'order_items'];
    
    foreach ($tables as $table) {
        echo "\n=== " . strtoupper($table) . " ===\n";
        try {
            $result = $pdo->query("DESCRIBE $table");
            $columns = $result->fetchAll(PDO::FETCH_ASSOC);
            foreach ($columns as $col) {
                echo $col['Field'] . " (" . $col['Type'] . ")\n";
            }
        } catch (Exception $e) {
            echo "❌ Table does not exist: " . $e->getMessage() . "\n";
        }
    }
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
