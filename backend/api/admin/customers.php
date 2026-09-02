<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../bootstrap.php';
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../middleware/authmiddleware.php';

$method = $_SERVER['REQUEST_METHOD'];
$user = AuthMiddleware::authenticateAdmin();
$db = db();

if ($method === 'GET') {
    $limit = (int)($_GET['limit'] ?? 100);
    $offset = (int)($_GET['offset'] ?? 0);
    $search = $_GET['search'] ?? '';

    $where = "WHERE u.role = 'customer'";
    $params = [];
    if ($search) {
        $where .= " AND (u.full_name LIKE ? OR u.email LIKE ? OR u.phone_number LIKE ?)";
        $params = ["%$search%", "%$search%", "%$search%"];
    }

    $stmt = $db->prepare("
        SELECT u.user_id, u.full_name, u.last_name, u.email, u.phone_number,
               u.gender, u.role, u.created_at,
               COUNT(DISTINCT o.order_id) AS total_orders,
               COALESCE(SUM(o.total_amount), 0) AS total_spent
        FROM users u
        LEFT JOIN orders o ON u.user_id = o.user_id
        $where
        GROUP BY u.user_id
        ORDER BY u.created_at DESC
        LIMIT $limit OFFSET $offset
    ");
    $stmt->execute($params);
    $customers = $stmt->fetchAll();

    $countStmt = $db->prepare("SELECT COUNT(*) FROM users u $where");
    $countStmt->execute($params);
    $total = (int)$countStmt->fetchColumn();

    echo json_encode(['customers' => $customers, 'total' => $total]);
    exit;
}

if ($method === 'DELETE') {
    $id = (int)($_GET['id'] ?? 0);
    if (!$id) { http_response_code(400); echo json_encode(['error' => 'ID required']); exit; }
    $db->prepare("DELETE FROM users WHERE user_id = ? AND role = 'customer'")->execute([$id]);
    echo json_encode(['success' => true, 'message' => 'Customer deleted']);
    exit;
}

http_response_code(405);
echo json_encode(['error' => 'Method not allowed']);
