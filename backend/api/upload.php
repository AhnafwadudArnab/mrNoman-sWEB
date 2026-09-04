<?php
header('Content-Type: application/json');
require_once __DIR__ . '/bootstrap.php';
require_once __DIR__ . '/../config/cors.php';

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
if ($method === 'OPTIONS') {
    http_response_code(200);
    echo json_encode(['ok' => true]);
    exit;
}

if ($method !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

// Require admin authentication for uploads
require_once __DIR__ . '/../middleware/authmiddleware.php';
AuthMiddleware::authenticateAdmin();

if (!isset($_FILES['image'])) {
    http_response_code(400);
    echo json_encode(['error' => 'No file uploaded', 'field' => 'image']);
    exit;
}

try {
    $url = saveUploadedImage($_FILES['image']);
    if (!$url) {
        http_response_code(500);
        echo json_encode(['error' => 'Upload failed', 'message' => 'Could not save image']);
        exit;
    }
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'url' => $url,
        'message' => 'Image uploaded successfully'
    ]);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Upload error',
        'message' => $e->getMessage()
    ]);
}
