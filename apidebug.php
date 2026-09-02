<?php
// DELETE AFTER TESTING
header('Content-Type: application/json');

$results = [];

// Check if key files exist
$results['api_index']     = file_exists(__DIR__ . '/api/index.php') ? 'YES' : 'NO';
$results['api_htaccess']  = file_exists(__DIR__ . '/api/.htaccess') ? 'YES' : 'NO';
$results['config_dir']    = is_dir(__DIR__ . '/config') ? 'YES' : 'NO';
$results['env_file']      = file_exists(__DIR__ . '/.env') ? 'YES' : 'NO';
$results['bootstrap']     = file_exists(__DIR__ . '/api/bootstrap.php') ? 'YES' : 'NO';
$results['cors_php']      = file_exists(__DIR__ . '/config/cors.php') ? 'YES' : 'NO';
$results['vendor']        = is_dir(__DIR__ . '/vendor') ? 'YES' : 'NO';

// Try loading bootstrap directly
try {
    ob_start();
    require_once __DIR__ . '/api/bootstrap.php';
    ob_end_clean();
    $results['bootstrap_load'] = 'OK';
    
    // Try DB
    $pdo = db();
    $results['db_connect'] = 'OK';
    
    // Try products endpoint
    $stmt = $pdo->query("SELECT COUNT(*) FROM products");
    $results['products_count'] = $stmt->fetchColumn();
    
} catch (Throwable $e) {
    ob_end_clean();
    $results['bootstrap_error'] = $e->getMessage();
    $results['error_file'] = $e->getFile();
    $results['error_line'] = $e->getLine();
}

echo json_encode($results, JSON_PRETTY_PRINT);
