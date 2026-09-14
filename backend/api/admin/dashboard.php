<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, X-Authorization');
header('Content-Type: application/json');
header('Cache-Control: no-cache, no-store, must-revalidate');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Flexible requires
if (file_exists(__DIR__ . '/../bootstrap.php')) {
    require_once __DIR__ . '/../bootstrap.php';
} elseif (file_exists(__DIR__ . '/../../bootstrap.php')) {
    require_once __DIR__ . '/../../bootstrap.php';
}

if (file_exists(__DIR__ . '/../config/cors.php')) {
    require_once __DIR__ . '/../config/cors.php';
} elseif (file_exists(__DIR__ . '/../../config/cors.php')) {
    require_once __DIR__ . '/../../config/cors.php';
}

if (file_exists(__DIR__ . '/../middleware/authmiddleware.php')) {
    require_once __DIR__ . '/../middleware/authmiddleware.php';
} elseif (file_exists(__DIR__ . '/../../middleware/authmiddleware.php')) {
    require_once __DIR__ . '/../../middleware/authmiddleware.php';
}

try {
    $user = AuthMiddleware::authenticateAdmin();
    $db = db();

    // Total revenue
    $rev = ['totalRevenue' => 0];
    try {
        $revStmt = $db->query('SELECT COALESCE(SUM(total_amount), 0) AS totalRevenue FROM orders');
        if ($revStmt) $rev = $revStmt->fetch() ?: ['totalRevenue' => 0];
    } catch (Exception $e) {}

    // Total orders
    $orders = ['totalOrders' => 0];
    try {
        $ordersStmt = $db->query('SELECT COUNT(*) AS totalOrders FROM orders');
        if ($ordersStmt) $orders = $ordersStmt->fetch() ?: ['totalOrders' => 0];
    } catch (Exception $e) {}

    // Total customers (exclude admins)
    $cust = ['totalCustomers' => 0];
    try {
        $custStmt = $db->query("SELECT COUNT(*) AS totalCustomers FROM users WHERE role = 'customer'");
        if ($custStmt) $cust = $custStmt->fetch() ?: ['totalCustomers' => 0];
    } catch (Exception $e) {}

    // Pending orders count
    $pending = ['pendingOrders' => 0];
    try {
        $pendingStmt = $db->query("SELECT COUNT(*) AS pendingOrders FROM orders WHERE order_status = 'pending'");
        if ($pendingStmt) $pending = $pendingStmt->fetch() ?: ['pendingOrders' => 0];
    } catch (Exception $e) {}

    // Days parameter for chart (default 8 days)
    $days = isset($_GET['days']) ? (int)$_GET['days'] : 8;
    if ($days < 7) $days = 7;
    if ($days > 90) $days = 90;

    // Daily revenue for last $days (for chart)
    $dailyRevenue = [];
    try {
        $dailyStmt = $db->prepare("
            SELECT DATE(order_date) AS day, COALESCE(SUM(total_amount), 0) AS revenue
            FROM orders
            WHERE order_date >= DATE_SUB(CURDATE(), INTERVAL ? DAY)
            GROUP BY DATE(order_date)
            ORDER BY day ASC
        ");
        $dailyStmt->execute([$days - 1]);
        $rawRows = $dailyStmt->fetchAll() ?: [];

        $revByDate = [];
        foreach ($rawRows as $r) {
            $revByDate[$r['day']] = (float)$r['revenue'];
        }

        for ($i = $days - 1; $i >= 0; $i--) {
            $dateStr = date('Y-m-d', strtotime("-$i days"));
            $dailyRevenue[] = [
                'day'     => $dateStr,
                'revenue' => $revByDate[$dateStr] ?? 0.0,
            ];
        }
    } catch (Exception $e) {
        for ($i = $days - 1; $i >= 0; $i--) {
            $dailyRevenue[] = [
                'day'     => date('Y-m-d', strtotime("-$i days")),
                'revenue' => 0.0,
            ];
        }
    }

    // Recent orders (last 5)
    $recentOrders = [];
    try {
        $recentStmt = $db->query("
            SELECT o.order_id, o.total_amount, o.order_status AS status, o.order_date AS created_at,
                   u.full_name, u.email
            FROM orders o
            LEFT JOIN users u ON o.user_id = u.user_id
            ORDER BY o.order_date DESC
            LIMIT 5
        ");
        if ($recentStmt) $recentOrders = $recentStmt->fetchAll() ?: [];
    } catch (Exception $e) {}

    // Top products by order count
    $topProducts = [];
    try {
        $topProductsStmt = $db->query("
            SELECT p.product_name, COUNT(oi.product_id) AS order_count,
                   COALESCE(SUM(oi.quantity * oi.price_at_purchase), 0) AS revenue
            FROM order_items oi
            JOIN products p ON oi.product_id = p.product_id
            GROUP BY oi.product_id, p.product_name
            ORDER BY order_count DESC
            LIMIT 5
        ");
        if ($topProductsStmt) $topProducts = $topProductsStmt->fetchAll() ?: [];
    } catch (Exception $e) {}

    echo json_encode([
        'totalRevenue'   => (float)($rev['totalRevenue'] ?? 0),
        'totalOrders'    => (int)($orders['totalOrders'] ?? 0),
        'totalCustomers' => (int)($cust['totalCustomers'] ?? 0),
        'pendingOrders'  => (int)($pending['pendingOrders'] ?? 0),
        'dailyRevenue'   => $dailyRevenue,
        'recentOrders'   => $recentOrders,
        'topProducts'    => $topProducts,
    ]);
} catch (Exception $ex) {
    http_response_code(500);
    echo json_encode(['error' => $ex->getMessage()]);
}
