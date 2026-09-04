<?php
require_once __DIR__ . '/bootstrap.php';
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../middleware/authmiddleware.php';

$db = db();
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
if ($method === 'OPTIONS') { http_response_code(200); exit; }

$user = AuthMiddleware::authenticate();

switch ($method) {
    case 'GET':
        // Derive payment info from orders table (no separate payments table in schema)
        if (isset($_GET['order_id'])) {
            $stmt = $db->prepare("
                SELECT order_id, payment_method, payment_status, total_amount, transaction_id, order_date
                FROM orders WHERE order_id = ? AND user_id = ?
            ");
            $stmt->execute([(int)$_GET['order_id'], $user['user_id']]);
            jsonResponse($stmt->fetch() ?: []);
        } else {
            $isAdmin = strtolower($user['role'] ?? '') === 'admin';
            if ($isAdmin) {
                $stmt = $db->query("
                    SELECT o.order_id, o.payment_method, o.payment_status,
                           o.total_amount, o.transaction_id, o.order_date,
                           u.full_name, u.email
                    FROM orders o
                    LEFT JOIN users u ON o.user_id = u.user_id
                    ORDER BY o.order_date DESC
                    LIMIT 200
                ");
            } else {
                $stmt = $db->prepare("
                    SELECT order_id, payment_method, payment_status,
                           total_amount, transaction_id, order_date
                    FROM orders WHERE user_id = ? ORDER BY order_date DESC
                ");
                $stmt->execute([$user['user_id']]);
            }
            jsonResponse($stmt->fetchAll());
        }
        break;

    default:
        errorResponse('Method not allowed', 405);
}
