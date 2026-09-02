<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../bootstrap.php';
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../controllers/productController.php';
require_once __DIR__ . '/../../middleware/authmiddleware.php';

$db = db();
$product = new ProductController($db);

$method = $_SERVER['REQUEST_METHOD'];
$data = $_GET;

switch ($method) {
    case 'GET':
        if (isset($_GET['id'])) {
            echo json_encode($product->getById($_GET['id']));
        } elseif (isset($_GET['action'])) {
            switch ($_GET['action']) {
                case 'best-sellers':
                    echo json_encode(['products' => $product->getBestSellers($data)]);
                    break;
                case 'trending':
                    echo json_encode(['products' => $product->getTrending($data)]);
                    break;
                case 'deals':
                    echo json_encode(['products' => $product->getDealsOfDay($data)]);
                    break;
                case 'flash-sale':
                    echo json_encode(['products' => $product->getFlashSale($data)]);
                    break;
                case 'search':
                    echo json_encode(['products' => $product->search($data)]);
                    break;
                case 'categories':
                    echo json_encode($product->getCategories());
                    break;
                case 'brands':
                    echo json_encode($product->getBrands());
                    break;
                default:
                    echo json_encode($product->getAll($data));
            }
        } else {
            echo json_encode($product->getAll($data));
        }
        break;
        
    case 'POST':
        $user = AuthMiddleware::authenticateAdmin();
        if (!empty($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
            $imagePath = saveUploadedImage($_FILES['image']);
            $post_data = $_POST;
            if ($imagePath) $post_data['image_url'] = $imagePath;
        } else {
            $contentType = $_SERVER['CONTENT_TYPE'] ?? '';
            if (stripos($contentType, 'application/json') !== false) {
                $post_data = json_decode(file_get_contents('php://input'), true) ?? [];
            } else {
                $post_data = $_POST;
            }
            $post_data['image_url'] = $post_data['image_url'] ?? '';
        }
        echo json_encode($product->create($post_data));
        break;
        
    case 'PUT':
        $user = AuthMiddleware::authenticateAdmin();
        if (!isset($_GET['id'])) {
            http_response_code(400);
            echo json_encode(['message' => 'Product ID required']);
            break;
        }
        if (!empty($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
            $imagePath = saveUploadedImage($_FILES['image']);
            $put_data = $_POST;
            if ($imagePath) $put_data['image_url'] = $imagePath;
        } else {
            $put_data = json_decode(file_get_contents('php://input'), true) ?? [];
        }
        echo json_encode($product->update($_GET['id'], $put_data));
        break;
        
    case 'DELETE':
        $user = AuthMiddleware::authenticateAdmin();
        if (!isset($_GET['id'])) {
            http_response_code(400);
            echo json_encode(['message' => 'Product ID required']);
            break;
        }
        echo json_encode($product->delete($_GET['id']));
        break;
        
    default:
        http_response_code(405);
        echo json_encode(['message' => 'Method not allowed']);
}
?>
