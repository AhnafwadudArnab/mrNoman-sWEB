<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../bootstrap.php';
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../middleware/authmiddleware.php';

$method = $_SERVER['REQUEST_METHOD'];
if ($method !== 'GET') {
    http_response_code(405);
    echo json_encode(['message' => 'Method not allowed']);
    exit;
}

$user = AuthMiddleware::authenticateAdmin();
$db = db();

// Total revenue
$revStmt = $db->query('SELECT COALESCE(SUM(total_amount), 0) AS totalRevenue FROM orders');
$rev = $revStmt->fetch();

// Total orders
$ordersStmt = $db->query('SELECT COUNT(*) AS totalOrders FROM orders');
$orders = $ordersStmt->fetch();

// Total customers (exclude admins)
$custStmt = $db->query("SELECT COUNT(*) AS totalCustomers FROM users WHERE role = 'customer'");
$cust = $custStmt->fetch();

// Pending orders count
$pendingStmt = $db->query("SELECT COUNT(*) AS pendingOrders FROM orders WHERE order_status = 'pending'");
$pending = $pendingStmt->fetch();

// Daily revenue for last 8 days (for chart)
$dailyStmt = $db->query("
    SELECT DATE(order_date) AS day, COALESCE(SUM(total_amount), 0) AS revenue
    FROM orders
    WHERE order_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
    GROUP BY DATE(order_date)
    ORDER BY day ASC
");
$dailyRevenue = $dailyStmt->fetchAll();

// Recent orders (last 5)
$recentStmt = $db->query("
    SELECT o.order_id, o.total_amount, o.order_status AS status, o.order_date AS created_at,
           u.full_name, u.email
    FROM orders o
    LEFT JOIN users u ON o.user_id = u.user_id
    ORDER BY o.order_date DESC
    LIMIT 5
");
$recentOrders = $recentStmt->fetchAll();

// Top products by order count
$topProductsStmt = $db->query("
    SELECT p.product_name, COUNT(oi.product_id) AS order_count,
           COALESCE(SUM(oi.quantity * oi.price_at_purchase), 0) AS revenue
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY oi.product_id, p.product_name
    ORDER BY order_count DESC
    LIMIT 5
");
$topProducts = $topProductsStmt->fetchAll();

echo json_encode([
    'totalRevenue'   => (float)($rev['totalRevenue'] ?? 0),
    'totalOrders'    => (int)($orders['totalOrders'] ?? 0),
    'totalCustomers' => (int)($cust['totalCustomers'] ?? 0),
    'pendingOrders'  => (int)($pending['pendingOrders'] ?? 0),
    'dailyRevenue'   => $dailyRevenue,
    'recentOrders'   => $recentOrders,
    'topProducts'    => $topProducts,
]);
