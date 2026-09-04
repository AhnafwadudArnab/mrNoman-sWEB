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

require_once __DIR__ . '/bootstrap.php';

$db = db();
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

if ($method === 'OPTIONS') {
    http_response_code(200);
    exit;
}

switch ($method) {
    case 'GET':
        if (isset($_GET['id'])) {
            $id = (int)$_GET['id'];
            $stmt = $db->prepare("
                SELECT c.*, 
                    (SELECT COUNT(*) FROM products WHERE category_id = c.category_id) as product_count
                FROM categories c 
                WHERE c.category_id = ?
            ");
            $stmt->execute([$id]);
            $category = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$category) {
                http_response_code(404);
                echo json_encode(['error' => 'Category not found']);
                exit;
            }
            
            echo json_encode($category);
        } else {
            $stmt = $db->query("
                SELECT c.*, 
                    (SELECT COUNT(*) FROM products WHERE category_id = c.category_id) as product_count
                FROM categories c
                ORDER BY c.category_name
            ");
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        }
        break;
        
    case 'POST':
        $data = json_decode(file_get_contents('php://input'), true);
        $stmt = $db->prepare("
            INSERT INTO categories (category_name, category_image)
            VALUES (?, ?)
        ");
        $stmt->execute([
            $data['category_name'],
            $data['category_image'] ?? ''
        ]);
        echo json_encode(['message' => 'Category created', 'id' => $db->lastInsertId()]);
        break;
        
    case 'PUT':
        $id = (int)$_GET['id'];
        $data = json_decode(file_get_contents('php://input'), true);
        $stmt = $db->prepare("
            UPDATE categories 
            SET category_name = ?, category_image = ?
            WHERE category_id = ?
        ");
        $stmt->execute([
            $data['category_name'],
            $data['category_image'] ?? '',
            $id
        ]);
        echo json_encode(['message' => 'Category updated']);
        break;
        
    case 'DELETE':
        $id = (int)$_GET['id'];
        $stmt = $db->prepare("DELETE FROM categories WHERE category_id = ?");
        $stmt->execute([$id]);
        echo json_encode(['message' => 'Category deleted']);
        break;
}
