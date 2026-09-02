<?php
// ============================================
// CORS HEADERS FOR FLUTTER WEB
// ============================================
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Access-Control-Max-Age: 3600');

// Handle OPTIONS preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// ============================================
// PRODUCTS API
// ============================================

ob_start(); // Start output buffering to capture any accidental output
header('Content-Type: application/json');
require_once __DIR__ . '/bootstrap.php';
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../controllers/productController.php';
require_once __DIR__ . '/../middleware/authmiddleware.php';

$db = db();
$product = new ProductController($db);
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    // Cache public product listings for 5 minutes in browser/CDN
    header('Cache-Control: public, max-age=300, stale-while-revalidate=60');
    header('Vary: Accept-Encoding');

    if (isset($_GET['id'])) {
        echo json_encode($product->getById($_GET['id']));
        exit;
    }
    if (isset($_GET['action'])) {
        switch ($_GET['action']) {
            case 'best-sellers':
                echo json_encode($product->getBestSellers($_GET));
                exit;
            case 'trending':
                echo json_encode($product->getTrending($_GET));
                exit;
            case 'deals':
                echo json_encode($product->getDealsOfDay($_GET));
                exit;
            case 'flash-sale':
                echo json_encode($product->getFlashSale($_GET));
                exit;
            case 'tech-part':
                echo json_encode($product->getTechPart($_GET));
                exit;
            case 'search':
                echo json_encode($product->search($_GET));
                exit;
            case 'categories':
                echo json_encode($product->getCategories());
                exit;
            case 'brands':
                echo json_encode($product->getBrands());
                exit;
        }
    }
    
    // Get all products - with simple category filtering
    $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 500;
    $offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;
    
    $query = 'SELECT * FROM products LIMIT ? OFFSET ?';
    $stmt = $db->prepare($query);
    $stmt->execute([$limit, $offset]);
    $products = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode($products);
    exit;
}

if ($method === 'POST') {
    $admin = AuthMiddleware::authenticateAdmin();
    
    // Handle both JSON and form data
    $input = file_get_contents('php://input');
    $data = !empty($input) ? json_decode($input, true) : $_POST;
    
    if (!empty($_FILES['image'])) {
        $path = saveUploadedImage($_FILES['image']);
        if ($path) $data['image_url'] = $path;
    }
    
    // Debug log
    error_log("Product creation data: " . json_encode($data));
    
    $created = $product->create($data);
    if (is_array($created) && isset($created['product_id'])) {
        $pid = (int)$created['product_id'];
        $created['product_id'] = $pid;
        $created['productId'] = $pid;
        $created['product'] = $product->getById($pid);
    }
    ob_clean(); // Discard any accidental output before sending JSON
    
    // Validate JSON encoding before sending response
    $json = json_encode($created);
    if (json_last_error() !== JSON_ERROR_NONE) {
        error_log("JSON encoding error in product creation: " . json_last_error_msg());
        error_log("Failed to encode data: " . print_r($created, true));
        http_response_code(500);
        echo json_encode(['error' => 'Internal server error']);
        ob_end_flush();
        exit;
    }
    
    echo $json;
    ob_end_flush();
    exit;
}

if ($method === 'PUT') {
    $admin = AuthMiddleware::authenticateAdmin();
    if (!isset($_GET['id'])) {
        http_response_code(400);
        echo json_encode(['message' => 'Product ID required']);
        exit;
    }
    // Support multipart (with image) or JSON
    if (!empty($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
        $imagePath = saveUploadedImage($_FILES['image']);
        $data = $_POST;
        if ($imagePath) $data['image_url'] = $imagePath;
    } else {
        $data = getJsonBody();
    }
    echo json_encode($product->update($_GET['id'], $data));
    exit;
}

if ($method === 'DELETE') {
    $admin = AuthMiddleware::authenticateAdmin();
    if (!isset($_GET['id'])) {
        http_response_code(400);
        echo json_encode(['message' => 'Product ID required']);
        exit;
    }
    echo json_encode($product->delete($_GET['id']));
    exit;
}

http_response_code(405);
echo json_encode(['message' => 'Method not allowed']);
