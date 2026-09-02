<?php
// ============================================
// CORS HEADERS FOR FLUTTER WEB
// ============================================
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Access-Control-Max-Age: 3600');
header('Content-Type: application/json');

// Handle OPTIONS preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}
header('Content-Type: application/json');
require_once __DIR__ . '/bootstrap.php';
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../middleware/authmiddleware.php';

$db = db();
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

if ($method === 'OPTIONS') { http_response_code(200); exit; }

switch ($method) {
    case 'GET':
        if (isset($_GET['id'])) {
            $id = (int)$_GET['id'];
            $stmt = $db->prepare("
                SELECT b.*, 
                    (SELECT COUNT(*) FROM products WHERE brand_id = b.brand_id) as product_count
                FROM brands b 
                WHERE b.brand_id = ?
            ");
            $stmt->execute([$id]);
            $brand = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$brand) {
                http_response_code(404);
                echo json_encode(['error' => 'Brand not found']);
                exit;
            }
            
            echo json_encode($brand);
        } else {
            // If category_id provided, return only brands that have products in that category
            if (!empty($_GET['category_id'])) {
                $catId = (int)$_GET['category_id'];
                $stmt = $db->prepare("
                    SELECT DISTINCT b.brand_id, b.brand_name, b.brand_logo,
                        COUNT(p.product_id) as product_count
                    FROM brands b
                    JOIN products p ON p.brand_id = b.brand_id
                    WHERE p.category_id = ?
                    GROUP BY b.brand_id, b.brand_name, b.brand_logo
                    ORDER BY b.brand_name
                ");
                $stmt->execute([$catId]);
            } else {
                $stmt = $db->query("
                    SELECT b.*, 
                        (SELECT COUNT(*) FROM products WHERE brand_id = b.brand_id) as product_count
                    FROM brands b
                    ORDER BY b.brand_name
                ");
            }
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        }
        break;

    case 'POST':
        AuthMiddleware::authenticateAdmin();
        // Support both JSON body and multipart form (with image upload)
        $logoPath = '';
        if (!empty($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
            $uploaded = saveUploadedImage($_FILES['image']);
            if ($uploaded) $logoPath = $uploaded;
            $brandName = trim($_POST['brand_name'] ?? '');
        } else {
            $data = json_decode(file_get_contents('php://input'), true) ?? [];
            $brandName = trim($data['brand_name'] ?? '');
            $logoPath  = trim($data['brand_logo'] ?? '');
        }

        if (empty($brandName)) {
            http_response_code(400);
            echo json_encode(['error' => 'brand_name is required']);
            exit;
        }

        try {
            $stmt = $db->prepare("INSERT INTO brands (brand_name, brand_logo) VALUES (?, ?)");
            $stmt->execute([$brandName, $logoPath]);
            echo json_encode(['message' => 'Brand created', 'id' => $db->lastInsertId(), 'brand_logo' => $logoPath]);
        } catch (PDOException $e) {
            if (($e->errorInfo[1] ?? 0) === 1062) {
                http_response_code(409);
                echo json_encode(['error' => 'Brand already exists']);
                exit;
            }
            throw $e;
        }
        break;

    case 'PUT':
        AuthMiddleware::authenticateAdmin();
        $id = (int)($_GET['id'] ?? 0);
        if (!$id) { http_response_code(400); echo json_encode(['error' => 'id required']); exit; }

        // Support both JSON body and multipart form (with image upload)
        $logoPath = null;
        if (!empty($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
            $uploaded = saveUploadedImage($_FILES['image']);
            if ($uploaded) $logoPath = $uploaded;
            $brandName = trim($_POST['brand_name'] ?? '');
        } else {
            $data = json_decode(file_get_contents('php://input'), true) ?? [];
            $brandName = trim($data['brand_name'] ?? '');
            $logoPath  = isset($data['brand_logo']) ? trim($data['brand_logo']) : null;
        }

        if (empty($brandName)) {
            http_response_code(400);
            echo json_encode(['error' => 'brand_name is required']);
            exit;
        }

        try {
            if ($logoPath !== null) {
                $stmt = $db->prepare("UPDATE brands SET brand_name = ?, brand_logo = ? WHERE brand_id = ?");
                $stmt->execute([$brandName, $logoPath, $id]);
            } else {
                $stmt = $db->prepare("UPDATE brands SET brand_name = ? WHERE brand_id = ?");
                $stmt->execute([$brandName, $id]);
            }
        } catch (PDOException $e) {
            if (($e->errorInfo[1] ?? 0) === 1062) {
                http_response_code(409);
                echo json_encode(['error' => 'Brand name already in use']);
                exit;
            }
            throw $e;
        }
        echo json_encode(['message' => 'Brand updated', 'brand_logo' => $logoPath]);
        break;

    case 'DELETE':
        AuthMiddleware::authenticateAdmin();
        $id = (int)($_GET['id'] ?? 0);
        if (!$id) { http_response_code(400); echo json_encode(['error' => 'id required']); exit; }
        $stmt = $db->prepare("DELETE FROM brands WHERE brand_id = ?");
        $stmt->execute([$id]);
        echo json_encode(['message' => 'Brand deleted']);
        break;
}
