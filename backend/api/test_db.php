<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

require_once __DIR__ . '/bootstrap.php';

$result = [
    'status' => 'unknown',
    'errors' => [],
    'info' => []
];

// Test 1: Environment
try {
    $host = getenv('DB_HOST');
    $port = getenv('DB_PORT');
    $name = getenv('DB_NAME');
    $user = getenv('DB_USER');
    $pass = getenv('DB_PASSWORD');
    
    $result['info']['db_host'] = $host ?: 'NOT SET';
    $result['info']['db_port'] = $port ?: 'NOT SET';
    $result['info']['db_name'] = $name ?: 'NOT SET';
    $result['info']['db_user'] = $user ?: 'NOT SET';
    $result['info']['has_password'] = !empty($pass);
    
} catch (Exception $e) {
    $result['errors'][] = 'Env error: ' . $e->getMessage();
}

// Test 2: Connection
try {
    $db = db();
    $result['info']['connection'] = 'SUCCESS';
    $result['status'] = 'connected';
    
    // Test query
    $stmt = $db->query("SELECT 1");
    $result['info']['test_query'] = 'SUCCESS';
    
    // Get version
    $stmt = $db->query("SELECT VERSION() as v");
    $row = $stmt->fetch();
    $result['info']['mysql_version'] = $row['v'] ?? 'unknown';
    
    // Get current database
    $stmt = $db->query("SELECT DATABASE() as db");
    $row = $stmt->fetch();
    $result['info']['current_db'] = $row['db'] ?? 'unknown';
    
} catch (Throwable $e) {
    $result['errors'][] = 'Connection error: ' . $e->getMessage();
    $result['status'] = 'failed';
    http_response_code(500);
}

// Test 3: Tables
try {
    if ($result['status'] === 'connected') {
        $db = db();
        $tables = $db->query("SHOW TABLES")->fetchAll(PDO::FETCH_COLUMN);
        $result['info']['table_count'] = count($tables);
        
        $row_counts = [];
        foreach (['products', 'categories', 'users', 'banners', 'brands'] as $t) {
            try {
                $c = $db->query("SELECT COUNT(*) FROM $t")->fetchColumn();
                $row_counts[$t] = intval($c);
            } catch (Exception $e) {
                $row_counts[$t] = 0;
            }
        }
        $result['info']['row_counts'] = $row_counts;
    }
} catch (Throwable $e) {
    $result['errors'][] = 'Table check error: ' . $e->getMessage();
}

if (empty($result['errors'])) {
    $result['status'] = 'healthy';
    http_response_code(200);
} else {
    http_response_code(500);
}

echo json_encode($result, JSON_PRETTY_PRINT);
?>
