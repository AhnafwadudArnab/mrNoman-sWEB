<?php
header('Content-Type: application/json');
require_once __DIR__ . '/bootstrap.php';
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../middleware/authmiddleware.php';

$db = db();
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

if ($method === 'OPTIONS') { http_response_code(200); exit; }

switch ($method) {
    case 'GET':
        $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 40;
        $stmt = $db->prepare("
            SELECT p.*, c.category_name, b.brand_name, tp.trending_score
            FROM products p
            INNER JOIN trending_products tp ON p.product_id = tp.product_id
            LEFT JOIN categories c ON p.category_id = c.category_id
            LEFT JOIN brands b ON p.brand_id = b.brand_id
            ORDER BY tp.trending_score DESC, tp.created_at DESC
            LIMIT ?
        ");
        $stmt->execute([$limit]);
        echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        break;

    case 'POST':
        AuthMiddleware::authenticateAdmin();
        $data = getJsonBody();
        if (empty($data['product_id'])) {
            http_response_code(400); echo json_encode(['error' => 'product_id required']); exit;
        }
        $stmt = $db->prepare("
            INSERT INTO trending_products (product_id, trending_score)
            VALUES (?, ?)
            ON DUPLICATE KEY UPDATE trending_score = VALUES(trending_score)
        ");
        $stmt->execute([(int)$data['product_id'], (int)($data['trending_score'] ?? 0)]);
        http_response_code(201);
        echo json_encode(['message' => 'Trending product added']);
        break;

    case 'PUT':
        AuthMiddleware::authenticateAdmin();
        $productId = (int)($_GET['product_id'] ?? 0);
        if (!$productId) { http_response_code(400); echo json_encode(['error' => 'product_id required']); exit; }
        $data = getJsonBody();
        $stmt = $db->prepare("UPDATE trending_products SET trending_score = ? WHERE product_id = ?");
        $stmt->execute([(int)($data['trending_score'] ?? 0), $productId]);
        echo json_encode(['message' => 'Trending product updated']);
        break;

    case 'DELETE':
        AuthMiddleware::authenticateAdmin();
        $productId = (int)($_GET['product_id'] ?? 0);
        if (!$productId) { http_response_code(400); echo json_encode(['error' => 'product_id required']); exit; }
        $db->prepare("DELETE FROM trending_products WHERE product_id = ?")->execute([$productId]);
        echo json_encode(['message' => 'Trending product removed']);
        break;

    default:
        http_response_code(405);
        echo json_encode(['message' => 'Method not allowed']);
}
