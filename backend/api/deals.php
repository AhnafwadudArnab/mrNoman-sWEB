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
$method = $_SERVER['REQUEST_METHOD'];

function requestDealId(array $data = []): int {
    if (isset($_GET['id']) && is_numeric($_GET['id'])) {
        return (int)$_GET['id'];
    }
    if (isset($data['deal_id']) && is_numeric($data['deal_id'])) {
        return (int)$data['deal_id'];
    }
    $path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
    $segments = array_values(array_filter(explode('/', trim($path, '/'))));
    $last = end($segments);
    return is_numeric($last) ? (int)$last : 0;
}

if ($method === 'OPTIONS') { http_response_code(200); exit; }

switch ($method) {
    case 'GET':
        $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 24;
        $includeExpired = isset($_GET['include_expired']) && $_GET['include_expired'] === '1';
        $where = $includeExpired ? '' : 'WHERE (d.end_date IS NULL OR d.end_date >= NOW())';
        $stmt = $db->prepare("
            SELECT d.deal_id, d.product_id, d.deal_price, d.start_date, d.end_date,
                   p.product_name, p.price, p.image_url, p.description, p.stock_quantity,
                   c.category_name, b.brand_name
            FROM deals_of_the_day d
            INNER JOIN products p ON d.product_id = p.product_id
            LEFT JOIN categories c ON p.category_id = c.category_id
            LEFT JOIN brands b ON p.brand_id = b.brand_id
            $where
            ORDER BY d.created_at DESC
            LIMIT ?
        ");
        $stmt->execute([$limit]);
        $deals = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode($deals);
        break;

    case 'POST':
        AuthMiddleware::authenticateAdmin();
        $data = getJsonBody();
        if (empty($data['product_id'])) {
            http_response_code(400);
            echo json_encode(['error' => 'product_id required']);
            exit;
        }
        $pid = (int)$data['product_id'];
        // Get base price if deal_price not provided
        if (empty($data['deal_price'])) {
            $s = $db->prepare("SELECT price FROM products WHERE product_id = ?");
            $s->execute([$pid]);
            $row = $s->fetch();
            $data['deal_price'] = $row ? round((float)$row['price'] * 0.85, 2) : 0;
        }
        $stmt = $db->prepare("
            INSERT INTO deals_of_the_day (product_id, deal_price, start_date, end_date)
            VALUES (?, ?, COALESCE(?, NOW()), COALESCE(?, DATE_ADD(NOW(), INTERVAL 365 DAY)))
            ON DUPLICATE KEY UPDATE
                deal_price = VALUES(deal_price),
                start_date = VALUES(start_date),
                end_date = VALUES(end_date)
        ");
        $stmt->execute([
            $pid,
            (float)$data['deal_price'],
            $data['start_date'] ?? null,
            $data['end_date'] ?? null,
        ]);
        http_response_code(201);
        echo json_encode(['message' => 'Deal created', 'deal_id' => $db->lastInsertId()]);
        break;

    case 'PUT':
        AuthMiddleware::authenticateAdmin();
        $data = getJsonBody();
        $id = requestDealId($data);
        if (!$id) { http_response_code(400); echo json_encode(['error' => 'id required']); exit; }
        $fields = []; $params = [];
        if (isset($data['deal_price']))  { $fields[] = 'deal_price = ?';  $params[] = (float)$data['deal_price']; }
        if (isset($data['start_date'])) { $fields[] = 'start_date = ?'; $params[] = $data['start_date']; }
        if (isset($data['end_date']))   { $fields[] = 'end_date = ?';   $params[] = $data['end_date']; }
        if (empty($fields)) { http_response_code(400); echo json_encode(['error' => 'No fields to update']); exit; }
        $params[] = $id;
        $db->prepare("UPDATE deals_of_the_day SET " . implode(', ', $fields) . " WHERE deal_id = ?")->execute($params);
        echo json_encode(['message' => 'Deal updated']);
        break;

    case 'DELETE':
        AuthMiddleware::authenticateAdmin();
        $data = getJsonBody();
        $id = requestDealId($data);
        if (!$id) { http_response_code(400); echo json_encode(['error' => 'id required']); exit; }
        $db->prepare("DELETE FROM deals_of_the_day WHERE deal_id = ?")->execute([$id]);
        echo json_encode(['message' => 'Deal deleted']);
        break;

    default:
        http_response_code(405);
        echo json_encode(['message' => 'Method not allowed']);
}
