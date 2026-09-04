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
        $stmt = $db->query("
            SELECT p.*, tp.display_order
            FROM products p
            INNER JOIN tech_part_products tp ON p.product_id = tp.product_id
            ORDER BY tp.display_order
        ");
        echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        break;
        
    case 'POST':
        $data = json_decode(file_get_contents('php://input'), true);
        $stmt = $db->prepare("
            INSERT INTO tech_part_products (product_id, display_order)
            VALUES (?, ?)
            ON DUPLICATE KEY UPDATE display_order = VALUES(display_order)
        ");
        $stmt->execute([
            $data['product_id'],
            $data['display_order'] ?? 0
        ]);
        echo json_encode(['message' => 'Tech part product added']);
        break;
}
