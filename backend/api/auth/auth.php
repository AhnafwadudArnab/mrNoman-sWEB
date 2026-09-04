<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../bootstrap.php';
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../controllers/authControllers.php';

$db = db();
$auth = new AuthController($db);

$method = $_SERVER['REQUEST_METHOD'];
$data = json_decode(file_get_contents('php://input'), true) ?? $_POST;

switch ($method) {
    case 'POST':
        if (isset($_GET['action'])) {
            switch ($_GET['action']) {
                case 'register':
                    if (!isset($data['full_name'])) {
                        $first = $data['firstName'] ?? '';
                        $last = $data['lastName'] ?? '';
                        $full = trim($first . ' ' . $last);
                        if (!empty($full)) $data['full_name'] = $full;
                    }
                    echo json_encode($auth->register($data));
                    break;
                case 'login':
                    echo json_encode($auth->login($data));
                    break;
                case 'admin-login':
                    echo json_encode($auth->adminLogin($data));
                    break;
                default:
                    http_response_code(404);
                    echo json_encode(['message' => 'Action not found']);
            }
        }
        break;
        
    default:
        http_response_code(405);
        echo json_encode(['message' => 'Method not allowed']);
}
?>
