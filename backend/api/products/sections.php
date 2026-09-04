<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../bootstrap.php';
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../middleware/authmiddleware.php';

$method = $_SERVER['REQUEST_METHOD'];
if ($method !== 'PUT') {
    http_response_code(405);
    echo json_encode(['message' => 'Method not allowed']);
    exit;
}

$admin = AuthMiddleware::authenticateAdmin();
$db = db();
$productId = isset($_GET['id']) ? (int)$_GET['id'] : 0;
if ($productId <= 0) {
    http_response_code(400);
    echo json_encode(['message' => 'id required']);
    exit;
}
$data = json_decode(file_get_contents('php://input'), true) ?: [];
$updated = [];

try {
    if (!empty($data['best_sellers'])) {
        $stmt = $db->prepare('INSERT INTO best_sellers (product_id, sales_count, last_updated) VALUES (?, 1, NOW())
                              ON DUPLICATE KEY UPDATE sales_count = sales_count, last_updated = NOW()');
        $stmt->execute([$productId]);
        $updated[] = 'best_sellers';
    }
    if (!empty($data['trending'])) {
        $stmt = $db->prepare('INSERT INTO trending_products (product_id, trending_score, last_updated) VALUES (?, 1, NOW())
                              ON DUPLICATE KEY UPDATE trending_score = trending_score, last_updated = NOW()');
        $stmt->execute([$productId]);
        $updated[] = 'trending';
    }
    echo json_encode(['message' => 'Sections updated', 'updated' => $updated, 'productId' => $productId]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['message' => 'Failed to update sections']);
}
