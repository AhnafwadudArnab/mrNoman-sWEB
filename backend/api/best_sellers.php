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
        $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 10;
        $stmt = $db->prepare("
            SELECT p.*, c.category_name, b.brand_name, bs.sales_count
            FROM products p
            INNER JOIN best_sellers bs ON p.product_id = bs.product_id
            LEFT JOIN categories c ON p.category_id = c.category_id
            LEFT JOIN brands b ON p.brand_id = b.brand_id
            ORDER BY bs.sales_count DESC, bs.created_at DESC
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
            INSERT INTO best_sellers (product_id, sales_count)
            VALUES (?, ?)
            ON DUPLICATE KEY UPDATE sales_count = VALUES(sales_count)
        ");
        $stmt->execute([(int)$data['product_id'], (int)($data['sales_count'] ?? 0)]);
        http_response_code(201);
        echo json_encode(['message' => 'Best seller added']);
        break;

    case 'PUT':
        AuthMiddleware::authenticateAdmin();
        $productId = (int)($_GET['product_id'] ?? 0);
        if (!$productId) { http_response_code(400); echo json_encode(['error' => 'product_id required']); exit; }
        $data = getJsonBody();
        $stmt = $db->prepare("UPDATE best_sellers SET sales_count = ? WHERE product_id = ?");
        $stmt->execute([(int)($data['sales_count'] ?? 0), $productId]);
        echo json_encode(['message' => 'Best seller updated']);
        break;

    case 'DELETE':
        AuthMiddleware::authenticateAdmin();
        $productId = (int)($_GET['product_id'] ?? 0);
        if (!$productId) { http_response_code(400); echo json_encode(['error' => 'product_id required']); exit; }
        $db->prepare("DELETE FROM best_sellers WHERE product_id = ?")->execute([$productId]);
        echo json_encode(['message' => 'Best seller removed']);
        break;

    default:
        http_response_code(405);
        echo json_encode(['message' => 'Method not allowed']);
}
