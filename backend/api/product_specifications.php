<?php
require_once __DIR__ . '/bootstrap.php';

$db = db();
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

if ($method === 'OPTIONS') {
    http_response_code(200);
    exit;
}

switch ($method) {
    case 'GET':
        if (isset($_GET['product_id'])) {
            $productId = (int)$_GET['product_id'];
            $stmt = $db->prepare("
                SELECT * FROM product_specifications
                WHERE product_id = ?
                ORDER BY display_order
            ");
            $stmt->execute([$productId]);
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        }
        break;
        
    case 'POST':
        $data = json_decode(file_get_contents('php://input'), true);
        $stmt = $db->prepare("
            INSERT INTO product_specifications (product_id, spec_key, spec_value, display_order)
            VALUES (?, ?, ?, ?)
        ");
        $stmt->execute([
            $data['product_id'],
            $data['spec_key'],
            $data['spec_value'],
            $data['display_order'] ?? 0
        ]);
        echo json_encode(['message' => 'Specification added', 'id' => $db->lastInsertId()]);
        break;
}
