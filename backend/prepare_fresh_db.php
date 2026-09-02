<?php
/**
 * Fresh Database Setup Script
 * Drops existing database, recreates it with complete structure and data
 */

echo "=== Fresh Database Setup ===\n\n";

$db_host = 'localhost';
$db_port = '3306';
$db_name = 'asiment3_electrobd';
$db_user = 'asiment3_zones';
$db_pass = 'zlBzyXMNNeeh';

try {
    // Connect without database
    $pdo = new PDO(
        'mysql:host=' . $db_host . ';port=' . $db_port . ';charset=utf8mb4',
        'root',
        '',
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
    
    echo "✓ Connected to MySQL\n";
    
    // Drop existing database
    echo "\nDropping existing database: $db_name...\n";
    $pdo->exec("DROP DATABASE IF EXISTS `$db_name`");
    echo "✓ Database dropped\n";
    
    // Create new database
    echo "\nCreating fresh database: $db_name...\n";
    $pdo->exec("CREATE DATABASE `$db_name` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
    echo "✓ Database created\n";
    
    // Create user if not exists
    echo "\nSetting up user: $db_user...\n";
    try {
        $pdo->exec("CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_pass'");
    } catch (Exception $e) {
        // User might already exist
        echo "⚠ User may already exist\n";
    }
    
    $pdo->exec("GRANT ALL PRIVILEGES ON `$db_name`.* TO '$db_user'@'localhost'");
    $pdo->exec("FLUSH PRIVILEGES");
    echo "✓ User privileges granted\n";
    
    // Now connect to new database and import data
    echo "\nConnecting to new database...\n";
    $pdo2 = new PDO(
        'mysql:host=' . $db_host . ';port=' . $db_port . ';dbname=' . $db_name . ';charset=utf8mb4',
        $db_user,
        $db_pass,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
    echo "✓ Connected to $db_name\n";
    
    // Read SQL file
    $sql_file = __DIR__ . '/../databaseMysql/allZones.sql';
    
    if (!file_exists($sql_file)) {
        die("SQL file not found: $sql_file\n");
    }
    
    echo "\nImporting database structure and data...\n";
    $sql_content = file_get_contents($sql_file);
    
    // Replace database references
    $sql_content = str_replace('`electrobd`', '`' . $db_name . '`', $sql_content);
    $sql_content = str_replace('DEFINER=`root`@`localhost`', 'DEFINER=`' . $db_user . '`@`localhost`', $sql_content);
    
    // Split and execute statements
    $statements = array_filter(
        array_map('trim', preg_split('/;(?=(?:[^"\']*["\'][^"\']*["\'])*[^"\']*$)/', $sql_content)),
        function($s) {
            $s = trim($s);
            return !empty($s) && !str_starts_with($s, '--') && !str_starts_with($s, '/*');
        }
    );
    
    $executed = 0;
    $errors = [];
    
    foreach ($statements as $stmt) {
        $stmt = trim($stmt);
        if (empty($stmt)) continue;
        
        try {
            $pdo2->exec($stmt);
            $executed++;
            
            // Show progress for important statements
            if (stripos($stmt, 'CREATE TABLE') !== false) {
                preg_match('/CREATE TABLE(?:\s+IF\s+NOT\s+EXISTS)?\s+`?(\w+)`?/i', $stmt, $m);
                if (!empty($m[1])) {
                    echo "✓ Table: " . $m[1] . "\n";
                }
            }
        } catch (Exception $e) {
            $errors[] = [
                'stmt' => substr($stmt, 0, 80),
                'error' => $e->getMessage()
            ];
        }
    }
    
    echo "\n=== Import Summary ===\n";
    echo "✓ Executed: $executed statements\n";
    
    if (!empty($errors)) {
        echo "⚠ Non-critical errors: " . count($errors) . "\n";
        foreach (array_slice($errors, 0, 5) as $err) {
            echo "  - " . substr($err['stmt'], 0, 60) . "...\n";
        }
        if (count($errors) > 5) {
            echo "  ... and " . (count($errors) - 5) . " more\n";
        }
    }
    
    // Verify tables
    $tables = $pdo2->query("SHOW TABLES")->fetchAll(PDO::FETCH_COLUMN);
    echo "\n✓ Total tables: " . count($tables) . "\n";
    
    // Count products
    $product_count = $pdo2->query("SELECT COUNT(*) FROM products")->fetchColumn();
    $category_count = $pdo2->query("SELECT COUNT(*) FROM categories")->fetchColumn();
    $brand_count = $pdo2->query("SELECT COUNT(*) FROM brands")->fetchColumn();
    
    echo "✓ Products: $product_count\n";
    echo "✓ Categories: $category_count\n";
    echo "✓ Brands: $brand_count\n";
    
    echo "\n✓✓✓ Fresh database setup completed successfully! ✓✓✓\n\n";
    echo "Connection Details:\n";
    echo "  Host: $db_host\n";
    echo "  Database: $db_name\n";
    echo "  User: $db_user\n";
    echo "  Password: $db_pass\n";
    
} catch (Exception $e) {
    echo "✗ Error: " . $e->getMessage() . "\n";
    exit(1);
}
?>
