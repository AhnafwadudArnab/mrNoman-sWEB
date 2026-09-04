<?php
/**
 * Test collections endpoint with debugging info
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

require_once __DIR__ . '/bootstrap.php';

try {
    $db = db();
    
    // Get all active collections
    $stmt = $db->query("SELECT * FROM collections WHERE is_active = 1 ORDER BY display_order ASC");
    $collections = $stmt->fetchAll();
    
    $result = [
        'success' => true,
        'count' => count($collections),
        'collections' => $collections,
        'debug' => [
            'endpoint_called' => 'GET /api/collections.php',
            'db_connection' => 'connected',
            'response_format' => 'collections array in response'
        ]
    ];
    
    http_response_code(200);
    echo json_encode($result, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>
