<?php
/**
 * Database Connection Diagnostic Tool
 * Tests all aspects of database connectivity
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

require_once __DIR__ . '/bootstrap.php';

$diagnostics = [
    'timestamp' => date('Y-m-d H:i:s'),
    'environment' => [],
    'connection' => [],
    'database' => [],
    'tables' => [],
    'summary' => []
];

// ========== ENVIRONMENT VARIABLES ==========
$diagnostics['environment']['DB_HOST'] = getenv('DB_HOST') ?: 'NOT SET';
$diagnostics['environment']['DB_PORT'] = getenv('DB_PORT') ?: 'NOT SET';
$diagnostics['environment']['DB_NAME'] = getenv('DB_NAME') ?: 'NOT SET';
$diagnostics['environment']['DB_USER'] = getenv('DB_USER') ?: 'NOT SET';
$diagnostics['environment']['DB_PASSWORD'] = getenv('DB_PASSWORD') ? '***SET***' : 'NOT SET';
$diagnostics['environment']['APP_ENV'] = getenv('APP_ENV') ?: 'NOT SET';

// ========== CONNECTION TEST ==========
try {
    $database = db();
    $diagnostics['connection']['status'] = 'SUCCESS';
    $diagnostics['connection']['message'] = 'Database connection established';
    
    // Test basic query
    $result = $database->query("SELECT 1 as test");
    $row = $result->fetch();
    $diagnostics['connection']['test_query'] = $row ? 'PASSED' : 'FAILED';
    
} catch (Exception $e) {
    $diagnostics['connection']['status'] = 'FAILED';
    $diagnostics['connection']['message'] = $e->getMessage();
    $diagnostics['connection']['test_query'] = 'FAILED';
}

// ========== DATABASE INFORMATION ==========
if ($diagnostics['connection']['status'] === 'SUCCESS') {
    try {
        $database = db();
        
        // Get database version
        $stmt = $database->query("SELECT VERSION() as version");
        $row = $stmt->fetch();
        $diagnostics['database']['mysql_version'] = $row['version'] ?? 'Unknown';
        
        // Get current database
        $stmt = $database->query("SELECT DATABASE() as dbname");
        $row = $stmt->fetch();
        $diagnostics['database']['current_database'] = $row['dbname'] ?? 'Unknown';
        
        // Get character set
        $stmt = $database->query("SELECT @@character_set_database as charset");
        $row = $stmt->fetch();
        $diagnostics['database']['charset'] = $row['charset'] ?? 'Unknown';
        
    } catch (Exception $e) {
        $diagnostics['database']['error'] = $e->getMessage();
    }
}

// ========== TABLE INFORMATION ==========
if ($diagnostics['connection']['status'] === 'SUCCESS') {
    try {
        $database = db();
        
        // Get all tables
        $tables = $database->query("SHOW TABLES")->fetchAll(PDO::FETCH_COLUMN);
        $diagnostics['tables']['total_count'] = count($tables);
        $diagnostics['tables']['list'] = $tables;
        
        // Check row counts for key tables
        $key_tables = ['products', 'categories', 'users', 'banners', 'brands', 'deals_of_the_day'];
        $diagnostics['tables']['row_counts'] = [];
        
        foreach ($key_tables as $table) {
            try {
                $stmt = $database->prepare("SELECT COUNT(*) as cnt FROM $table");
                $stmt->execute();
                $row = $stmt->fetch();
                $diagnostics['tables']['row_counts'][$table] = $row['cnt'] ?? 0;
            } catch (Exception $e) {
                $diagnostics['tables']['row_counts'][$table] = 'TABLE_NOT_FOUND';
            }
        }
        
    } catch (Exception $e) {
        $diagnostics['tables']['error'] = $e->getMessage();
    }
}

// ========== CONFIGURATION ==========
$diagnostics['config'] = [
    'db_host' => getenv('DB_HOST'),
    'db_port' => getenv('DB_PORT'),
    'db_name' => getenv('DB_NAME'),
    'db_user' => getenv('DB_USER'),
    'app_env' => getenv('APP_ENV'),
];

// ========== SUMMARY ==========
$issues = [];
$successes = [];

// Check environment
if (!getenv('DB_HOST')) $issues[] = "DB_HOST not set";
if (!getenv('DB_NAME')) $issues[] = "DB_NAME not set";
if (!getenv('DB_USER')) $issues[] = "DB_USER not set";
else $successes[] = "All environment variables set";

// Check connection
if ($diagnostics['connection']['status'] === 'SUCCESS') {
    $successes[] = "Database connection successful";
} else {
    $issues[] = "Database connection failed: " . $diagnostics['connection']['message'];
}

// Check tables
if (isset($diagnostics['tables']['total_count'])) {
    if ($diagnostics['tables']['total_count'] > 0) {
        $successes[] = "Database has " . $diagnostics['tables']['total_count'] . " tables";
    } else {
        $issues[] = "No tables found in database";
    }
}

// Check data
$has_data = false;
if (isset($diagnostics['tables']['row_counts'])) {
    foreach ($diagnostics['tables']['row_counts'] as $table => $count) {
        if ($count > 0 && $count !== 'TABLE_NOT_FOUND') {
            $has_data = true;
            $successes[] = "Data found in table: $table ($count rows)";
        }
    }
    if (!$has_data) {
        $issues[] = "No data found in database tables (tables are empty)";
    }
}

$diagnostics['summary']['success'] = $diagnostics['connection']['status'] === 'SUCCESS' && empty($issues);
$diagnostics['summary']['issues'] = $issues;
$diagnostics['summary']['successes'] = $successes;
$diagnostics['summary']['overall_status'] = empty($issues) ? 'HEALTHY' : 'ISSUES_DETECTED';

http_response_code($diagnostics['summary']['success'] ? 200 : 500);
echo json_encode($diagnostics, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
?>
