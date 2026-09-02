<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../bootstrap.php';
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../middleware/authmiddleware.php';

$method = $_SERVER['REQUEST_METHOD'];
$user = AuthMiddleware::authenticateAdmin();
$db = db();

if ($method === 'GET') {
    $from = $_GET['from'] ?? date('Y-m-d', strtotime('-30 days'));
    $to   = $_GET['to']   ?? date('Y-m-d');

    // Revenue summary
    $revStmt = $db->prepare("
        SELECT COALESCE(SUM(total_amount), 0) AS total_revenue,
               COUNT(*) AS total_orders,
               AVG(total_amount) AS avg_order_value
        FROM orders
        WHERE DATE(order_date) BETWEEN ? AND ?
    ");
    $revStmt->execute([$from, $to]);
    $revenue = $revStmt->fetch();

    // Orders by status
    $statusStmt = $db->prepare("
        SELECT order_status, COUNT(*) AS count, COALESCE(SUM(total_amount), 0) AS total
        FROM orders
        WHERE DATE(order_date) BETWEEN ? AND ?
        GROUP BY order_status
    ");
    $statusStmt->execute([$from, $to]);
    $byStatus = $statusStmt->fetchAll();

    // Daily revenue
    $dailyStmt = $db->prepare("
        SELECT DATE(order_date) AS day,
               COUNT(*) AS orders,
               COALESCE(SUM(total_amount), 0) AS revenue
        FROM orders
        WHERE DATE(order_date) BETWEEN ? AND ?
        GROUP BY DATE(order_date)
        ORDER BY day ASC
    ");
    $dailyStmt->execute([$from, $to]);
    $daily = $dailyStmt->fetchAll();

    // Top selling products
    $topStmt = $db->prepare("
        SELECT p.product_name, p.product_id,
               SUM(oi.quantity) AS units_sold,
               COALESCE(SUM(oi.quantity * oi.price_at_purchase), 0) AS revenue
        FROM order_items oi
        JOIN products p ON oi.product_id = p.product_id
        JOIN orders o ON oi.order_id = o.order_id
        WHERE DATE(o.order_date) BETWEEN ? AND ?
        GROUP BY oi.product_id, p.product_name
        ORDER BY units_sold DESC
        LIMIT 10
    ");
    $topStmt->execute([$from, $to]);
    $topProducts = $topStmt->fetchAll();

    // New customers in period
    $newCustStmt = $db->prepare("
        SELECT COUNT(*) AS new_customers FROM users
        WHERE role = 'customer' AND DATE(created_at) BETWEEN ? AND ?
    ");
    $newCustStmt->execute([$from, $to]);
    $newCustomers = (int)$newCustStmt->fetchColumn();

    echo json_encode([
        'period'        => ['from' => $from, 'to' => $to],
        'summary'       => $revenue,
        'by_status'     => $byStatus,
        'daily'         => $daily,
        'top_products'  => $topProducts,
        'new_customers' => $newCustomers,
    ]);
    exit;
}

http_response_code(405);
echo json_encode(['error' => 'Method not allowed']);
