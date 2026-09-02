<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../bootstrap.php';
require_once __DIR__ . '/../../config/cors.php';

$db = db();

$method = $_SERVER['REQUEST_METHOD'];

// Simple token validation (in production, use proper JWT validation)
function validateToken($db) {
    $headers = getallheaders();
    $token = str_replace('Bearer ', '', $headers['Authorization'] ?? '');
    
    // For demo, we'll just check if token exists
    // In production, validate against database or JWT
    return !empty($token);
}

if ($method === 'GET') {
    if (!validateToken($db)) {
        http_response_code(401);
        echo json_encode(['message' => 'Unauthorized']);
        exit;
    }
    
    // For demo, get user from token (simplified)
    // In production, decode JWT or lookup token in database
    $headers = getallheaders();
    $token = str_replace('Bearer ', '', $headers['Authorization'] ?? '');
    
    // Simplified: return a default user profile
    // In production, get user_id from token and fetch from database
    
    echo json_encode([
        'user_id' => 1,
        'firstName' => 'User',
        'lastName' => '',
        'email' => 'user@example.com',
        'phone' => '',
        'gender' => 'Male',
        'role' => 'customer'
    ]);
    
} else {
    http_response_code(405);
    echo json_encode(['message' => 'Method not allowed']);
}
?>
