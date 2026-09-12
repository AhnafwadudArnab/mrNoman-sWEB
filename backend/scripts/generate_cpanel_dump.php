<?php
/**
 * cPanel Database Export Generator
 * Exports a clean, 100% complete MySQL dump ready for cPanel phpMyAdmin / MySQL import.
 * 
 * Key Features for cPanel Hosting:
 * - NO "CREATE DATABASE" or "USE database" statements (avoids cPanel permission errors)
 * - Safe foreign key handling (SET FOREIGN_KEY_CHECKS = 0 at start, 1 at commit)
 * - Transaction wrapping (START TRANSACTION / COMMIT)
 * - Standard utf8mb4 encoding & NO_AUTO_VALUE_ON_ZERO mode
 * - Clean multi-row INSERTs for fast phpMyAdmin execution without packet overflow
 * - Exports all tables and triggers with DEFINER clauses stripped (prevents cPanel Error 1227 SUPER privilege error)
 */

require_once __DIR__ . '/../config/db.php';

try {
    $db = (new Database())->getConnection();
    if (!$db) {
        throw new Exception("Could not connect to database.");
    }

    echo "Connected to database successfully.\n";

    $workspaceRoot = realpath(__DIR__ . '/../..');
    $outputFileRoot = $workspaceRoot . '/cpanel_electrocitybd_latest.sql';
    $outputFileDbDir = $workspaceRoot . '/databaseMysql/cpanel_database_ready.sql';

    $handle = fopen($outputFileRoot, 'w');
    if (!$handle) {
        throw new Exception("Failed to open output file: $outputFileRoot");
    }

    $timestamp = date('Y-m-d H:i:s');
    $header = <<<SQL
-- ============================================================
-- ElectrocityBD Production Database Export for cPanel / phpMyAdmin
-- Exported on: {$timestamp} (UTC)
-- Target: cPanel MySQL / phpMyAdmin / MariaDB / MySQL 5.7+ / 8.0+
-- 
-- INSTRUCTIONS FOR CPANEL HOSTING IMPORT:
-- 1. Log in to your cPanel control panel (e.g. yourdomain.com/cpanel).
-- 2. Under "Databases", click "MySQL Databases".
-- 3. Create a new database (e.g. youruser_electrobd).
-- 4. Create a MySQL user and password, then add the user to the database with "ALL PRIVILEGES".
-- 5. Return to cPanel home and open "phpMyAdmin".
-- 6. Select your newly created database from the left navigation tree.
-- 7. Click the "Import" tab on the top menu bar.
-- 8. Click "Choose File" and select this file ("cpanel_electrocitybd_latest.sql").
-- 9. Keep default format (SQL) and click "Import" at the bottom.
-- 10. Update backend/.env or config.php on cPanel with your database name, user, and password.
-- ============================================================

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;


SQL;

    fwrite($handle, $header);

    // Fetch all base tables
    $stmt = $db->query("SHOW FULL TABLES WHERE Table_type = 'BASE TABLE'");
    $rawTables = [];
    while ($row = $stmt->fetch(PDO::FETCH_NUM)) {
        $rawTables[] = $row[0];
    }

    // Preferred logical ordering for clean reading
    $preferredOrder = [
        'categories',
        'brands',
        'collections',
        'collection_items',
        'users',
        'user_profile',
        'products',
        'product_specifications',
        'product_reviews',
        'product_ratings',
        'collection_products',
        'banners',
        'deals_timer',
        'deals_of_the_day',
        'flash_sales',
        'flash_sale_products',
        'trending_products',
        'best_sellers',
        'tech_part_products',
        'payment_methods',
        'orders',
        'order_items',
        'payments',
        'cart',
        'wishlists',
        'search_suggestions',
        'search_history',
        'search_analytics',
        'stock_alerts',
        'stock_movements',
        'site_settings',
        'promotions',
        'discounts',
        'reviews',
        'reports',
        'notifications',
        'customer_support',
        'password_resets',
        'password_reset_tokens',
        'csrf_tokens',
        'rate_limits'
    ];

    $tables = [];
    foreach ($preferredOrder as $t) {
        if (in_array($t, $rawTables)) {
            $tables[] = $t;
        }
    }
    // Append any extra tables not in preferred list
    foreach ($rawTables as $t) {
        if (!in_array($t, $tables)) {
            $tables[] = $t;
        }
    }

    $tableCount = count($tables);
    echo "Found {$tableCount} tables to export.\n";

    $totalRowsExported = 0;

    foreach ($tables as $table) {
        echo "Exporting table: `{$table}`... ";

        fwrite($handle, "\n-- --------------------------------------------------------\n");
        fwrite($handle, "-- Table structure for table `{$table}`\n");
        fwrite($handle, "-- --------------------------------------------------------\n\n");
        fwrite($handle, "DROP TABLE IF EXISTS `{$table}`;\n");

        // Get CREATE TABLE
        $createStmt = $db->query("SHOW CREATE TABLE `{$table}`");
        $createRow = $createStmt->fetch(PDO::FETCH_NUM);
        $createSql = $createRow[1] . ";\n\n";

        // Universal cPanel compatibility: replace MySQL 8-specific collation with universal utf8mb4_unicode_ci
        $createSql = str_replace('utf8mb4_0900_ai_ci', 'utf8mb4_unicode_ci', $createSql);

        fwrite($handle, $createSql);

        // Fetch data
        $dataStmt = $db->query("SELECT * FROM `{$table}`");
        $rowCount = 0;
        $batch = [];
        $columns = [];

        // Determine column count and names
        $colCount = $dataStmt->columnCount();
        for ($i = 0; $i < $colCount; $i++) {
            $colMeta = $dataStmt->getColumnMeta($i);
            $columns[] = '`' . $colMeta['name'] . '`';
        }

        $colList = implode(', ', $columns);

        while ($row = $dataStmt->fetch(PDO::FETCH_ASSOC)) {
            $rowCount++;
            $values = [];
            foreach ($row as $val) {
                if ($val === null) {
                    $values[] = 'NULL';
                } elseif (is_numeric($val) && !is_string($val)) {
                    $values[] = $val;
                } else {
                    $values[] = $db->quote($val);
                }
            }
            $batch[] = '(' . implode(', ', $values) . ')';

            if (count($batch) >= 50) {
                fwrite($handle, "INSERT INTO `{$table}` ({$colList}) VALUES\n" . implode(",\n", $batch) . ";\n\n");
                $batch = [];
            }
        }

        if (!empty($batch)) {
            fwrite($handle, "INSERT INTO `{$table}` ({$colList}) VALUES\n" . implode(",\n", $batch) . ";\n\n");
        }

        echo "({$rowCount} rows)\n";
        $totalRowsExported += $rowCount;
    }

    // Export Triggers
    echo "Exporting triggers...\n";
    $triggerStmt = $db->query("SHOW TRIGGERS");
    $triggers = $triggerStmt->fetchAll(PDO::FETCH_ASSOC);

    if (!empty($triggers)) {
        fwrite($handle, "\n-- --------------------------------------------------------\n");
        fwrite($handle, "-- Triggers (Cleaned of DEFINER clauses for cPanel compatibility)\n");
        fwrite($handle, "-- --------------------------------------------------------\n\n");
        fwrite($handle, "DELIMITER $$\n");

        foreach ($triggers as $trig) {
            $trigName = $trig['Trigger'];
            $createTrigStmt = $db->query("SHOW CREATE TRIGGER `{$trigName}`");
            $trigRow = $createTrigStmt->fetch(PDO::FETCH_ASSOC);
            $createTrigSql = $trigRow['SQL Original Statement'];
            
            // Remove DEFINER clause if present to avoid cPanel user mismatch / Error 1227
            $cleanedTrigSql = preg_replace('/DEFINER\s*=\s*`[^`]+`@`[^`]+`\s*/i', '', $createTrigSql);
            $cleanedTrigSql = preg_replace('/DEFINER\s*=\s*[^\s]+\s*/i', '', $cleanedTrigSql);

            fwrite($handle, $cleanedTrigSql . "$$\n\n");
            echo "Exported trigger: `{$trigName}`\n";
        }

        fwrite($handle, "DELIMITER ;\n\n");
    }

    // Footer
    $footer = <<<SQL
-- --------------------------------------------------------
-- Finalizing Import
-- --------------------------------------------------------
SET FOREIGN_KEY_CHECKS = 1;
COMMIT;

-- ============================================================
-- Export Complete: {$totalRowsExported} total rows exported across {$tableCount} tables.
-- ============================================================
SQL;

    fwrite($handle, $footer);
    fclose($handle);

    // Also copy to databaseMysql/cpanel_database_ready.sql
    if (!is_dir(dirname($outputFileDbDir))) {
        mkdir(dirname($outputFileDbDir), 0777, true);
    }
    copy($outputFileRoot, $outputFileDbDir);

    $filesize = round(filesize($outputFileRoot) / 1024, 2);
    echo "\n✓ SUCCESS: Generated clean cPanel SQL export!\n";
    echo "Files created:\n";
    echo "  1. {$outputFileRoot} ({$filesize} KB)\n";
    echo "  2. {$outputFileDbDir} ({$filesize} KB)\n";
    echo "Total tables: {$tableCount}\n";
    echo "Total rows: {$totalRowsExported}\n";

} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
    exit(1);
}
