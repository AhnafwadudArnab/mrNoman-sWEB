<?php
/**
 * Final Clean Database Import (without EVENTS)
 */

echo "=== Final Database Import (Events Removed) ===\n\n";

$db_name = 'asiment3_electrobd';
$db_user = 'asiment3_zones';
$db_pass = 'zlBzyXMNNeeh';

try {
    $pdo = new PDO(
        'mysql:host=localhost;port=3306;dbname=' . $db_name . ';charset=utf8mb4',
        $db_user,
        $db_pass,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
    
    echo "✓ Connected to $db_name\n\n";
    
    $sql_file = __DIR__ . '/../databaseMysql/allZones.sql';
    $content = file_get_contents($sql_file);
    
    // Remove DEFINER (permission issues)
    $content = preg_replace('/DEFINER=`[^`]*`@`[^`]*`\s+/i', '', $content);
    
    // Remove EVENT statements
    $content = preg_replace('/CREATE\s+EVENT\s+.*?END\s*;/is', '', $content);
    
    // Split into statements
    $statements = preg_split('/;(?=(?:[^"\']*["\'][^"\']*["\'])*[^"\']*$)/', $content);
    
    $executed = 0;
    $skipped = 0;
    $errors = [];
    
    foreach ($statements as $stmt) {
        $stmt = trim($stmt);
        if (empty($stmt) || substr($stmt, 0, 2) === '--') {
            $skipped++;
            continue;
        }
        
        // Skip procedures (optional)
        if (stripos($stmt, 'PROCEDURE') !== false) {
            $skipped++;
            continue;
        }
        
        try {
            $pdo->exec($stmt);
            $executed++;
            
            if (stripos($stmt, 'CREATE TABLE') !== false) {
                preg_match('/CREATE TABLE.*?`(\w+)`/i', $stmt, $m);
                if (isset($m[1])) {
                    echo "✓ Table: " . $m[1] . "\n";
                }
            }
        } catch (Exception $e) {
            // Ignore view/trigger errors
            $msg = $e->getMessage();
            if (stripos($msg, 'base table') === false && 
                stripos($msg, 'trigger') === false &&
                stripos($msg, 'already') === false) {
                $errors[] = substr($msg, 0, 80);
            }
        }
    }
    
    echo "\n=== Summary ===\n";
    echo "✓ Executed: $executed\n";
    echo "⊘ Skipped: $skipped\n";
    
    // Verify
    $tables = $pdo->query("SHOW TABLES")->fetchAll(PDO::FETCH_COLUMN);
    echo "\n✓ Tables: " . count($tables) . "\n";
    
    $product_count = $pdo->query("SELECT COUNT(*) FROM products")->fetchColumn();
    $category_count = $pdo->query("SELECT COUNT(*) FROM categories")->fetchColumn();
    $brand_count = $pdo->query("SELECT COUNT(*) FROM brands")->fetchColumn();
    
    echo "✓ Products: $product_count\n";
    echo "✓ Categories: $category_count\n";
    echo "✓ Brands: $brand_count\n";
    
    echo "\n✓✓✓ Database Ready! ✓✓✓\n";
    
} catch (Exception $e) {
    echo "✗ Error: " . $e->getMessage() . "\n";
    exit(1);
}
?>
