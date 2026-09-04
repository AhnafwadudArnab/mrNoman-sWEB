<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/bootstrap.php';
require_once __DIR__ . '/../middleware/authmiddleware.php';
require_once __DIR__ . '/../controllers/paymentMethodController.php';
require_once __DIR__ . '/../util/TokenExtractor.php';

// Get database connection
$conn = db();

$controller = new PaymentMethodController($conn);
$method = $_SERVER['REQUEST_METHOD'];
$input = json_decode(file_get_contents('php://input'), true);
if (!is_array($input)) {
    $input = [];
}

function normalize_enabled_value($value) {
    if (is_bool($value)) return $value ? 1 : 0;
    if (is_numeric($value)) return ((int)$value) === 1 ? 1 : 0;
    $value = strtolower(trim((string)$value));
    return in_array($value, ['1', 'true', 'yes', 'on', 'enabled'], true) ? 1 : 0;
}

// Get payment method ID from URL if present
$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$uri_parts = explode('/', $uri);
$method_id = isset($_GET['id']) && is_numeric($_GET['id']) ? (int)$_GET['id'] : null;

// Extract ID from URL like /api/payment_methods/1
if (!$method_id && count($uri_parts) > 2 && is_numeric($uri_parts[count($uri_parts) - 1])) {
    $method_id = (int)$uri_parts[count($uri_parts) - 1];
}

try {
    switch ($method) {
        case 'GET':
            if ($method_id) {
                // Get single payment method
                $result = $controller->getById($method_id);
            } elseif (isset($_GET['enabled']) && $_GET['enabled'] === 'true') {
                // Get only enabled methods
                $result = $controller->getEnabled();
            } else {
                // Get all payment methods
                $result = $controller->getAll();
            }
            break;
            
        case 'POST':
            // Create new payment method (admin only)
            $token = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
            $token = str_replace('Bearer ', '', $token);
            
            if (empty($token)) {
                http_response_code(401);
                echo json_encode(['success' => false, 'message' => 'Unauthorized']);
                exit;
            }
            
            $result = $controller->create($input);
            break;
            
        case 'PUT':
            // Update payment method (admin only)
            $token = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
            $token = str_replace('Bearer ', '', $token);
            
            if (empty($token)) {
                http_response_code(401);
                echo json_encode(['success' => false, 'message' => 'Unauthorized']);
                exit;
            }
            
            // Log the request for debugging
            error_log("PUT Request - Method ID from URL: " . ($method_id ?? 'null'));
            error_log("PUT Request - Input data: " . json_encode($input));
            
            if (!$method_id && isset($input['method_id'])) {
                $method_id = (int)$input['method_id'];
            }
            
            if (!$method_id) {
                http_response_code(400);
                echo json_encode(['success' => false, 'message' => 'Method ID required']);
                exit;
            }
            
            // Check if it's a toggle status request
            if (isset($input['toggle_status'])) {
                $enabled = normalize_enabled_value($input['is_enabled'] ?? 0);
                error_log("Toggle status request for method $method_id to " . $enabled);
                $result = $controller->toggleStatus($method_id, $enabled);
            } else {
                error_log("Update request for method $method_id");
                $result = $controller->update($method_id, $input);
            }
            
            error_log("PUT Result: " . json_encode($result));
            break;
            
        case 'DELETE':
            // Delete payment method (admin only)
            $token = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
            $token = str_replace('Bearer ', '', $token);
            
            if (empty($token)) {
                http_response_code(401);
                echo json_encode(['success' => false, 'message' => 'Unauthorized']);
                exit;
            }
            
            if (!$method_id) {
                http_response_code(400);
                echo json_encode(['success' => false, 'message' => 'Method ID required']);
                exit;
            }
            
            $result = $controller->delete($method_id);
            break;
            
        default:
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            exit;
    }
    
    http_response_code($result['success'] ? 200 : 400);
    echo json_encode($result);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error: ' . $e->getMessage()
    ]);
}
?>
