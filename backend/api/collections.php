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

$db = db();
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

if ($method === 'OPTIONS') { http_response_code(200); exit; }

switch ($method) {
    case 'GET':
        $id = isset($_GET['id']) ? (int)$_GET['id'] : null;

        if ($id) {
            $stmt = $db->prepare("SELECT * FROM collections WHERE collection_id = ?");
            $stmt->execute([$id]);
            $col = $stmt->fetch();
            if (!$col) jsonResponse(['message' => 'Not found'], 404);

            $stmt2 = $db->prepare("SELECT * FROM collection_items WHERE collection_id = ? ORDER BY display_order ASC");
            $stmt2->execute([$id]);
            $col['items'] = $stmt2->fetchAll();
            jsonResponse($col);
        }

        $stmt = $db->query("SELECT * FROM collections WHERE is_active = 1 ORDER BY display_order ASC, created_at DESC");
        $collections = $stmt->fetchAll();

        foreach ($collections as &$col) {
            $stmt2 = $db->prepare("SELECT * FROM collection_items WHERE collection_id = ? ORDER BY display_order ASC");
            $stmt2->execute([$col['collection_id']]);
            $col['items'] = $stmt2->fetchAll();
        }
        jsonResponse(['collections' => $collections]);
        break;

    case 'POST':
        requireAdmin();
        $data = getJsonBody();
        if (empty($data['name'])) errorResponse('Collection name required', 400);

        $slug = strtolower(preg_replace('/[^a-zA-Z0-9]+/', '-', $data['name']));
        $stmt = $db->prepare("INSERT INTO collections (name, slug, description, icon, image_url, display_order) VALUES (?, ?, ?, ?, ?, ?)");
        $stmt->execute([$data['name'], $data['slug'] ?? $slug, $data['description'] ?? '', $data['icon'] ?? null, $data['image_url'] ?? null, (int)($data['display_order'] ?? 0)]);
        jsonResponse(['message' => 'Collection created', 'collection_id' => $db->lastInsertId()], 201);
        break;

    case 'PUT':
        requireAdmin();
        $id = (int)($_GET['id'] ?? 0);
        if (!$id) errorResponse('Collection ID required', 400);

        $data = getJsonBody();
        $updates = []; $params = [];
        if (isset($data['name']))          { $updates[] = "name = ?";          $params[] = $data['name']; }
        if (isset($data['description']))   { $updates[] = "description = ?";   $params[] = $data['description']; }
        if (isset($data['icon']))          { $updates[] = "icon = ?";          $params[] = $data['icon']; }
        if (isset($data['image_url']))     { $updates[] = "image_url = ?";     $params[] = $data['image_url']; }
        if (isset($data['is_active']))     { $updates[] = "is_active = ?";     $params[] = (int)$data['is_active']; }
        if (isset($data['display_order'])) { $updates[] = "display_order = ?"; $params[] = (int)$data['display_order']; }
        if (empty($updates)) errorResponse('No fields to update', 400);

        $params[] = $id;
        $db->prepare("UPDATE collections SET " . implode(', ', $updates) . " WHERE collection_id = ?")->execute($params);
        jsonResponse(['message' => 'Collection updated']);
        break;

    case 'DELETE':
        requireAdmin();
        $id = (int)($_GET['id'] ?? 0);
        if (!$id) errorResponse('Collection ID required', 400);

        $db->prepare("DELETE FROM collection_items WHERE collection_id = ?")->execute([$id]);
        $db->prepare("DELETE FROM collections WHERE collection_id = ?")->execute([$id]);
        jsonResponse(['message' => 'Collection deleted']);
        break;

    default:
        errorResponse('Method not allowed', 405);
}
