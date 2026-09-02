<?php
// ============================================
// CORS HEADERS FOR FLUTTER WEB
// ============================================
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Access-Control-Max-Age: 3600');
header('Content-Type: application/json');

// Handle OPTIONS preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}
require_once __DIR__ . '/bootstrap.php';

// Simple health check endpoint
$response = [
    'status' => 'ok',
    'timestamp' => time(),
    'service' => 'electrozonebd API',
    'version' => '1.0.0'
];

// Check database connection
try {
    $db = db();
    $stmt = $db->query("SELECT 1");
    $response['database'] = 'connected';
} catch (Exception $e) {
    $response['database'] = 'disconnected';
    $response['status'] = 'degraded';
}

http_response_code(200);
echo json_encode($response);
