<?php
header('Content-Type: application/json');
ob_start(); // buffer any PHP warnings/notices so they don't corrupt JSON output
require_once __DIR__ . '/../bootstrap.php';
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../controllers/orderController.php';
require_once __DIR__ . '/../../middleware/authmiddleware.php';

$db = db();
$order = new OrderController($db);

$method = $_SERVER['REQUEST_METHOD'];

// POST (place order) supports both authenticated and guest users.
// All other methods (GET, PUT, DELETE) still require authentication.
if ($method === 'POST') {
    $user = AuthMiddleware::optionalAuth(); // null for guest
} else {
    ob_clean(); // discard any buffered output before auth check
    $user = AuthMiddleware::authenticate(); // hard-fail if no token
}

// Clean buffer before any output to prevent JSON corruption
ob_clean();

switch ($method) {
    case 'GET':
        if (isset($_GET['id'])) {
            echo json_encode($order->getOrderDetails($_GET['id'], $user['user_id']));
        } elseif (isset($_GET['admin']) && $user['role'] === 'admin') {
            try {
                $orders = $order->getAllOrders($_GET);
                echo json_encode($orders);
            } catch (Exception $e) {
                error_log("getAllOrders failed: " . $e->getMessage());
                http_response_code(500);
                echo json_encode(['error' => 'Failed to load orders: ' . $e->getMessage()]);
            }
        } else {
            echo json_encode($order->getUserOrders($user['user_id']));
        }
        break;
        
    case 'POST':
        $post_data = json_decode(file_get_contents('php://input'), true);
        $user_id = $user ? $user['user_id'] : null; // null = guest order
        echo json_encode($order->createOrder($user_id, $post_data));
        break;
        
    case 'PUT':
        if (!isset($_GET['id'])) {
            http_response_code(400);
            echo json_encode(['message' => 'Order ID required']);
            break;
        }
        
        if ($user['role'] !== 'admin') {
            http_response_code(403);
            echo json_encode(['message' => 'Admin access required']);
            break;
        }
        
        $put_data = json_decode(file_get_contents('php://input'), true);
        echo json_encode($order->updateStatus($_GET['id'], $put_data, $user['user_id']));
        break;
        
    case 'DELETE':
        if (!isset($_GET['id'])) {
            http_response_code(400);
            echo json_encode(['message' => 'Order ID required']);
            break;
        }
        
        if ($user['role'] !== 'admin') {
            http_response_code(403);
            echo json_encode(['message' => 'Admin access required']);
            break;
        }
        
        echo json_encode($order->deleteOrder($_GET['id'], $user['user_id']));
        break;
        
    default:
        http_response_code(405);
        echo json_encode(['message' => 'Method not allowed']);
}
?>
