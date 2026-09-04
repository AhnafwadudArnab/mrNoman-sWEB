<?php
/**
 * Debug endpoint for collections - traces the exact response format
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

require_once __DIR__ . '/bootstrap.php';

try {
    $db = db();
    
    // Get all active collections
    $stmt = $db->query("SELECT * FROM collections WHERE is_active = 1 ORDER BY display_order ASC");
    $collections = $stmt->fetchAll();
    
    // Format exactly as the main endpoint does
    $response = ['collections' => $collections];
    
    echo json_encode([
        'debug' => [
            'endpoint' => '/collections.php',
            'method' => $_SERVER['REQUEST_METHOD'],
            'query_params' => $_GET,
            'response_format' => 'Standard - wraps collections in "collections" key'
        ],
        'data' => $response,
        'verification' => [
            'has_collections_key' => isset($response['collections']),
            'is_array' => is_array($response['collections']),
            'count' => count($response['collections']),
            'first_item_keys' => array_keys($collections[0] ?? []),
            'expected_flutter_fields' => [
                'name' => 'present: ' . (isset($collections[0]['name']) ? 'YES' : 'NO'),
                'icon' => 'present: ' . (isset($collections[0]['icon']) ? 'YES' : 'NO'),
                'item_count' => 'present: ' . (isset($collections[0]['item_count']) ? 'YES' : 'NO'),
                'slug' => 'present: ' . (isset($collections[0]['slug']) ? 'YES' : 'NO'),
            ]
        ]
    ], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'error' => $e->getMessage(),
        'file' => $e->getFile(),
        'line' => $e->getLine()
    ]);
}
?>
