<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../bootstrap.php';
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../controllers/userController.php';
require_once __DIR__ . '/../../middleware/authmiddleware.php';

$db = db();
$userController = new UserController($db);

$method = $_SERVER['REQUEST_METHOD'];
$user = AuthMiddleware::authenticate();

switch ($method) {
    case 'GET':
        if (isset($_GET['action'])) {
            switch ($_GET['action']) {
                case 'profile':
                    echo json_encode($userController->getProfile($user['user_id']));
                    break;
                case 'wishlist':
                    echo json_encode($userController->getWishlist($user['user_id']));
                    break;
                case 'check-wishlist':
                    if (!isset($_GET['product_id'])) {
                        http_response_code(400);
                        echo json_encode(['message' => 'Product ID required']);
                        break;
                    }
                    echo json_encode($userController->checkWishlist($user['user_id'], $_GET['product_id']));
                    break;
                default:
                    echo json_encode($userController->getProfile($user['user_id']));
            }
        } else {
            echo json_encode($userController->getProfile($user['user_id']));
        }
        break;
        
    case 'POST':
        if (isset($_GET['action'])) {
            $post_data = json_decode(file_get_contents('php://input'), true);
            switch ($_GET['action']) {
                case 'update-profile':
                    echo json_encode($userController->updateProfile($user['user_id'], $post_data));
                    break;
                case 'add-to-wishlist':
                    echo json_encode($userController->addToWishlist($user['user_id'], $post_data));
                    break;
                case 'remove-from-wishlist':
                    echo json_encode($userController->removeFromWishlist($user['user_id'], $post_data));
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
