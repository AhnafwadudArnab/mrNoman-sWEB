<?php
/**
 * Extract Clean Database SQL
 * Removes procedures, triggers, views and keeps only tables + data
 */

echo "=== Extracting Clean Database SQL ===\n\n";

$sql_file = __DIR__ . '/../databaseMysql/allZones.sql';
$content = file_get_contents($sql_file);

// Split by lines
$lines = explode("\n", $content);

// Find where CREATE TABLE starts (skip procedures)
$start_line = 0;
foreach ($lines as $i => $line) {
    if (strpos($line, 'CREATE TABLE') !== false && strpos($line, 'banners') !== false) {
        $start_line = $i;
        break;
    }
}

echo "Starting from line: " . ($start_line + 1) . "\n";

// Keep only relevant lines
$clean_lines = [];
$skip_mode = false;

for ($i = $start_line; $i < count($lines); $i++) {
    $line = $lines[$i];
    
    // Skip VIEW creation
    if (strpos($line, 'CREATE ALGORITHM') !== false || strpos($line, 'AS SELECT') !== false) {
        $skip_mode = true;
    }
    
    // Stop skipping at next empty line after VIEW
    if ($skip_mode && trim($line) === '') {
        $skip_mode = false;
        continue;
    }
    
    if ($skip_mode) {
        continue;
    }
    
    // Skip comments
    if (strpos(trim($line), '--') === 0) {
        continue;
    }
    
    $clean_lines[] = $line;
}

// Add header
$header = <<<'SQL'
-- ===========================================
-- ElectrocityBD Complete Database
-- For: asiment3_electrobd
-- Generated: 2026
-- ===========================================

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET FOREIGN_KEY_CHECKS = 0;
START TRANSACTION;
SET time_zone = "+00:00";
SET NAMES utf8mb4;

SQL;

$clean_sql = $header . implode("\n", $clean_lines);

// Save clean SQL
$output_file = __DIR__ . '/asiment3_electrobd_clean.sql';
file_put_contents($output_file, $clean_sql);

echo "✓ Clean SQL file created: asiment3_electrobd_clean.sql\n";
echo "✓ File size: " . round(filesize($output_file) / 1024) . " KB\n";
echo "✓ Lines: " . count(explode("\n", $clean_sql)) . "\n";

// Now import this clean SQL
echo "\nImporting clean database...\n\n";

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
    
    // Split and execute statements properly
    $statements = preg_split('/;(?=(?:[^"\']*["\'][^"\']*["\'])*[^"\']*$)/', $clean_sql);
    
    $executed = 0;
    foreach ($statements as $stmt) {
        $stmt = trim($stmt);
        if (empty($stmt) || substr($stmt, 0, 2) === '--') {
            continue;
        }
        
        try {
            $pdo->exec($stmt);
            $executed++;
            
            if ($executed % 10 === 0 || stripos($stmt, 'CREATE TABLE') !== false) {
                if (stripos($stmt, 'CREATE TABLE') !== false) {
                    preg_match('/CREATE TABLE(?:\s+IF\s+NOT\s+EXISTS)?\s+`?(\w+)`?/i', $stmt, $m);
                    echo "✓ Table: " . (isset($m[1]) ? $m[1] : 'unknown') . "\n";
                }
            }
        } catch (Exception $e) {
            // Ignore VIEW errors
            if (stripos($e->getMessage(), 'base table') === false) {
                echo "⚠ Error in statement $executed: " . substr($e->getMessage(), 0, 60) . "\n";
            }
        }
    }
    
    // Verify
    $tables = $pdo->query("SHOW TABLES")->fetchAll(PDO::FETCH_COLUMN);
    
    echo "\n=== Database Ready ===\n";
    echo "✓ Total tables: " . count($tables) . "\n";
    
    // Count data
    $product_count = $pdo->query("SELECT COUNT(*) FROM products")->fetchColumn();
    $category_count = $pdo->query("SELECT COUNT(*) FROM categories")->fetchColumn();
    $brand_count = $pdo->query("SELECT COUNT(*) FROM brands")->fetchColumn();
    $banner_count = $pdo->query("SELECT COUNT(*) FROM banners")->fetchColumn();
    $collection_count = $pdo->query("SELECT COUNT(*) FROM collections")->fetchColumn();
    
    echo "\n📊 Data Ready:\n";
    echo "   ✓ Products: $product_count\n";
    echo "   ✓ Categories: $category_count\n";
    echo "   ✓ Brands: $brand_count\n";
    echo "   ✓ Banners: $banner_count\n";
    echo "   ✓ Collections: $collection_count\n";
    
    echo "\n✓✓✓ Database is ready to use! ✓✓✓\n";
    
} catch (Exception $e) {
    echo "✗ Error: " . $e->getMessage() . "\n";
    exit(1);
}
?>
