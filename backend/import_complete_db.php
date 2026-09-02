<?php
/**
 * Complete Database Import with Products
 * Imports all tables and sample data (skips procedures/triggers which may have syntax issues)
 */

echo "=== Complete Database Import ===\n\n";

$db_name = 'asiment3_electrobd';
$db_user = 'asiment3_zones';
$db_pass = 'zlBzyXMNNeeh';

try {
    // Connect to database
    $pdo = new PDO(
        'mysql:host=localhost;port=3306;dbname=' . $db_name . ';charset=utf8mb4',
        $db_user,
        $db_pass,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
    
    echo "✓ Connected to database: $db_name\n\n";
    
    // Read complete SQL file
    $sql_file = __DIR__ . '/../databaseMysql/allZones.sql';
    $sql_content = file_get_contents($sql_file);
    
    // Remove DEFINER for procedures/triggers (to avoid permission issues)
    $sql_content = preg_replace('/DEFINER=`[^`]*`@`[^`]*`\s+/i', '', $sql_content);
    
    // Extract only CREATE TABLE, INSERT, and other data statements
    // Skip PROCEDURE and TRIGGER definitions
    $lines = explode("\n", $sql_content);
    $filtered_sql = [];
    $in_procedure = false;
    $in_trigger = false;
    
    foreach ($lines as $line) {
        // Skip procedure/trigger blocks
        if (stripos($line, 'CREATE') !== false && stripos($line, 'PROCEDURE') !== false) {
            $in_procedure = true;
            continue;
        }
        if (stripos($line, 'CREATE') !== false && stripos($line, 'TRIGGER') !== false) {
            $in_trigger = true;
            continue;
        }
        
        if (stripos($line, 'DELIMITER') !== false) {
            if ($in_procedure || $in_trigger) {
                $in_procedure = false;
                $in_trigger = false;
            }
            continue;
        }
        
        if (!$in_procedure && !$in_trigger) {
            $filtered_sql[] = $line;
        }
    }
    
    $clean_sql = implode("\n", $filtered_sql);
    
    // Split into statements
    $statements = array_filter(
        array_map('trim', explode(';', $clean_sql)),
        fn($s) => !empty($s) && !str_starts_with(trim($s), '--') && !str_starts_with(trim($s), '/*')
    );
    
    echo "Found " . count($statements) . " SQL statements to execute\n\n";
    
    $executed = 0;
    $skipped = 0;
    $errors = [];
    
    foreach ($statements as $i => $stmt) {
        $stmt = trim($stmt);
        if (empty($stmt)) {
            $skipped++;
            continue;
        }
        
        // Skip SET statements
        if (stripos($stmt, 'SET') === 0 && stripos($stmt, 'SET SQL_MODE') === 0) {
            $skipped++;
            continue;
        }
        
        try {
            $pdo->exec($stmt);
            $executed++;
            
            // Show progress for important statements
            if (stripos($stmt, 'CREATE TABLE') !== false) {
                preg_match('/CREATE TABLE(?:\s+IF\s+NOT\s+EXISTS)?\s+`?(\w+)`?/i', $stmt, $m);
                if (!empty($m[1])) {
                    echo "✓ Table: " . $m[1] . "\n";
                }
            } elseif (stripos($stmt, 'INSERT INTO') === 0) {
                preg_match('/INSERT INTO\s+`?(\w+)`?/i', $stmt, $m);
                if (!empty($m[1]) && $executed % 50 === 0) {
                    echo "✓ Inserted data into tables...\n";
                }
            }
        } catch (Exception $e) {
            $err_msg = $e->getMessage();
            // Only track real errors, skip harmless ones
            if (stripos($err_msg, 'already exists') === false && 
                stripos($err_msg, 'duplicate') === false) {
                $errors[] = [
                    'stmt' => substr($stmt, 0, 60),
                    'error' => substr($err_msg, 0, 100)
                ];
            }
        }
    }
    
    echo "\n=== Import Summary ===\n";
    echo "✓ Executed: $executed statements\n";
    echo "⊘ Skipped: $skipped statements\n";
    
    if (!empty($errors)) {
        echo "⚠ Errors: " . count($errors) . "\n";
        foreach (array_slice($errors, 0, 3) as $err) {
            echo "  - " . $err['stmt'] . "\n";
            echo "    Error: " . $err['error'] . "\n";
        }
    }
    
    // Verify tables
    $tables = $pdo->query("SHOW TABLES")->fetchAll(PDO::FETCH_COLUMN);
    echo "\n✓ Total tables created: " . count($tables) . "\n";
    
    // Count important data
    try {
        $product_count = $pdo->query("SELECT COUNT(*) FROM products")->fetchColumn();
        $category_count = $pdo->query("SELECT COUNT(*) FROM categories")->fetchColumn();
        $brand_count = $pdo->query("SELECT COUNT(*) FROM brands")->fetchColumn();
        $user_count = $pdo->query("SELECT COUNT(*) FROM users")->fetchColumn();
        
        echo "\n📊 Data Summary:\n";
        echo "   Products: $product_count\n";
        echo "   Categories: $category_count\n";
        echo "   Brands: $brand_count\n";
        echo "   Users: $user_count\n";
    } catch (Exception $e) {
        // Tables might not exist yet
    }
    
    echo "\n✓✓✓ Database import completed! ✓✓✓\n";
    
} catch (Exception $e) {
    echo "✗ Fatal Error: " . $e->getMessage() . "\n";
    exit(1);
}
?>
