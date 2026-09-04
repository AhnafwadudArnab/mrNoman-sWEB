<?php
require_once __DIR__ . '/bootstrap.php';

$db = db();
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

if ($method === 'OPTIONS') { http_response_code(200); exit; }

requireAdmin();

switch ($method) {
    case 'POST':
        $data = getJsonBody();
        if (empty($data['collection_id']) || empty($data['item_name'])) errorResponse('collection_id and item_name required', 400);

        $db->prepare("INSERT INTO collection_items (collection_id, item_name, display_order) VALUES (?, ?, ?)")
           ->execute([(int)$data['collection_id'], $data['item_name'], (int)($data['display_order'] ?? 0)]);
        jsonResponse(['message' => 'Item added to collection'], 201);
        break;

    case 'PUT':
        $id = (int)($_GET['id'] ?? 0);
        if (!$id) errorResponse('Item ID required', 400);
        $data = getJsonBody();
        $updates = []; $params = [];
        if (isset($data['item_name']))     { $updates[] = "item_name = ?";     $params[] = $data['item_name']; }
        if (isset($data['display_order'])) { $updates[] = "display_order = ?"; $params[] = (int)$data['display_order']; }
        if (empty($updates)) errorResponse('No fields to update', 400);
        $params[] = $id;
        $db->prepare("UPDATE collection_items SET " . implode(', ', $updates) . " WHERE item_id = ?")->execute($params);
        jsonResponse(['message' => 'Item updated']);
        break;

    case 'DELETE':
        $id = (int)($_GET['id'] ?? 0);
        if (!$id) errorResponse('Item ID required', 400);
        $db->prepare("DELETE FROM collection_items WHERE item_id = ?")->execute([$id]);
        jsonResponse(['message' => 'Item removed from collection']);
        break;

    default:
        errorResponse('Method not allowed', 405);
}
