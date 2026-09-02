<?php
require_once __DIR__ . '/api/bootstrap.php';

echo "=== Database Import Script ===\n\n";

$db_host = getenv('DB_HOST') ?: 'localhost';
$db_name = getenv('DB_NAME') ?: 'electrobd';
$db_user = getenv('DB_USER') ?: 'root';
$db_port = getenv('DB_PORT') ?: '3306';
$db_pass = getenv('DB_PASSWORD') ?: '';

echo "Connecting to: $db_host:$db_port\n";
echo "Database: $db_name\n";
echo "User: $db_user\n\n";

try {
    $pdo = db();
    echo "✓ Database connected!\n\n";
    
    // Read SQL file
    $sql_file = __DIR__ . '/../databaseMysql/electrobd_structure.sql';
    
    if (!file_exists($sql_file)) {
        echo "✗ SQL file not found: $sql_file\n";
        exit(1);
    }
    
    $sql_content = file_get_contents($sql_file);
    echo "Loading SQL file: " . basename($sql_file) . "\n";
    echo "File size: " . round(strlen($sql_content) / 1024) . " KB\n\n";
    
    // Split SQL statements
    $statements = array_filter(
        array_map('trim', explode(';', $sql_content)),
        fn($s) => !empty($s) && !str_starts_with($s, '--')
    );
    
    echo "Found " . count($statements) . " SQL statements\n\n";
    
    $executed = 0;
    $errors = [];
    
    foreach ($statements as $i => $stmt) {
        $stmt = trim($stmt);
        if (empty($stmt)) continue;
        
        // Skip comments
        if (str_starts_with($stmt, '--') || str_starts_with($stmt, '/*')) {
            continue;
        }
        
        try {
            $pdo->exec($stmt);
            $executed++;
            
            // Show progress for important statements
            if (stripos($stmt, 'CREATE TABLE') !== false) {
                preg_match('/CREATE TABLE IF NOT EXISTS `(\w+)`/', $stmt, $m);
                echo "✓ Table created: " . ($m[1] ?? 'unknown') . "\n";
            }
        } catch (Exception $e) {
            $errors[] = [
                'stmt' => substr($stmt, 0, 100),
                'error' => $e->getMessage()
            ];
        }
    }
    
    echo "\n=== Import Summary ===\n";
    echo "✓ Executed: $executed statements\n";
    
    if (!empty($errors)) {
        echo "✗ Errors: " . count($errors) . "\n";
        foreach ($errors as $err) {
            echo "  - " . substr($err['stmt'], 0, 80) . "...\n";
            echo "    Error: " . substr($err['error'], 0, 100) . "\n";
        }
    } else {
        echo "✓ No errors!\n";
    }
    
    // Verify tables
    $tables = $pdo->query("SHOW TABLES")->fetchAll(PDO::FETCH_COLUMN);
    echo "\n✓ Total tables created: " . count($tables) . "\n";
    
    if (count($tables) > 0) {
        echo "Sample tables: " . implode(', ', array_slice($tables, 0, 5)) . "...\n";
    }
    
    echo "\n✓ Database import completed successfully!\n";
    
} catch (Exception $e) {
    echo "✗ Error: " . $e->getMessage() . "\n";
    exit(1);
}
?>
