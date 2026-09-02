<?php
header('Content-Type: application/json');
require_once __DIR__ . '/bootstrap.php';
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../middleware/authmiddleware.php';

$db = db();
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

function toDbDateOrNull($value) {
    if ($value === null) return null;
    $text = trim((string)$value);
    if ($text === '') return null;
    $ts = strtotime($text);
    if ($ts === false) return null;
    return date('Y-m-d H:i:s', $ts);
}

function toBoolInt($value, $default = 1) {
    if ($value === null) return $default;
    if (is_bool($value)) return $value ? 1 : 0;
    $text = strtolower(trim((string)$value));
    if ($text === 'true' || $text === '1' || $text === 'yes') return 1;
    if ($text === 'false' || $text === '0' || $text === 'no') return 0;
    return $default;
}

function syncPromotionStatuses(PDO $db): void {
    // Auto-maintain active flag according to configured date window.
    $db->exec("UPDATE promotions SET active = 0 WHERE end_date IS NOT NULL AND end_date < NOW()");
    $db->exec("UPDATE promotions SET active = 1 WHERE (start_date IS NULL OR start_date <= NOW()) AND (end_date IS NULL OR end_date >= NOW())");
}

function routeId(): int {
    if (isset($_GET['id'])) return (int)$_GET['id'];
    $path = parse_url($_SERVER['REQUEST_URI'] ?? '', PHP_URL_PATH) ?: '';
    if (preg_match('~/promotions/(\d+)~', $path, $m)) {
        return (int)$m[1];
    }
    return 0;
}

if ($method === 'OPTIONS') {
    http_response_code(200);
    echo json_encode(['ok' => true]);
    exit;
}

switch ($method) {
    case 'GET':
        try {
            syncPromotionStatuses($db);
            $adminAll = isset($_GET['all']) && $_GET['all'] === '1';

            if ($adminAll) {
                AuthMiddleware::authenticateAdmin();
                $stmt = $db->prepare('
                    SELECT promotion_id, title, description, discount_percent, start_date, end_date, active
                    FROM promotions
                    ORDER BY promotion_id DESC
                ');
                $stmt->execute();
                echo json_encode(['promotions' => $stmt->fetchAll(PDO::FETCH_ASSOC)]);
                exit;
            }

            // Public list: only active/current promotions.
            $stmt = $db->prepare('
                SELECT promotion_id, title, description, discount_percent, start_date, end_date, active
                FROM promotions
                WHERE active = TRUE
                AND (start_date IS NULL OR start_date <= NOW())
                AND (end_date IS NULL OR end_date >= NOW())
                ORDER BY discount_percent DESC
            ');
            $stmt->execute();
            $promotions = $stmt->fetchAll(PDO::FETCH_ASSOC);

            $offers = [];
            $images = [
                'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=900&q=60',
                'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?auto=format&fit=crop&w=900&q=60',
                'https://images.unsplash.com/photo-1493666438817-866a91353ca9?auto=format&fit=crop&w=900&q=60',
                'https://images.unsplash.com/photo-1521334884684-d80222895322?auto=format&fit=crop&w=900&q=60',
            ];

            foreach ($promotions as $index => $promo) {
                $offers[] = [
                    'label' => $promo['title'],
                    'image' => $images[$index % count($images)],
                    'discount' => $promo['discount_percent'] . '% OFF',
                    'description' => $promo['description']
                ];
            }

            echo json_encode([
                'promotions' => $promotions,
                'offers' => $offers
            ]);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => 'Failed to fetch promotions']);
        }
        exit;

    case 'POST':
        try {
            AuthMiddleware::authenticateAdmin();
            syncPromotionStatuses($db);
            $data = json_decode(file_get_contents('php://input'), true) ?: [];

            $title = trim((string)($data['title'] ?? ''));
            if ($title === '') {
                http_response_code(400);
                echo json_encode(['message' => 'title is required']);
                exit;
            }

            $description = trim((string)($data['description'] ?? ''));
            $discountPercent = isset($data['discount_percent']) && $data['discount_percent'] !== ''
                ? (float)$data['discount_percent']
                : null;
            $startDate = toDbDateOrNull($data['start_date'] ?? null);
            $endDate = toDbDateOrNull($data['end_date'] ?? null);
            $active = toBoolInt($data['active'] ?? 1, 1);

            $stmt = $db->prepare('INSERT INTO promotions (title, description, discount_percent, start_date, end_date, active) VALUES (?, ?, ?, ?, ?, ?)');
            $stmt->execute([$title, $description, $discountPercent, $startDate, $endDate, $active]);

            echo json_encode(['message' => 'Promotion created', 'promotion_id' => (int)$db->lastInsertId()]);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['message' => 'Failed to create promotion']);
        }
        exit;

    case 'PUT':
        try {
            AuthMiddleware::authenticateAdmin();
            syncPromotionStatuses($db);
            $id = routeId();
            if ($id <= 0) {
                http_response_code(400);
                echo json_encode(['message' => 'id required']);
                exit;
            }

            $data = json_decode(file_get_contents('php://input'), true) ?: [];
            $fields = [];
            $params = [];

            if (array_key_exists('title', $data)) {
                $fields[] = 'title = ?';
                $params[] = trim((string)$data['title']);
            }
            if (array_key_exists('description', $data)) {
                $fields[] = 'description = ?';
                $params[] = trim((string)($data['description'] ?? ''));
            }
            if (array_key_exists('discount_percent', $data)) {
                $fields[] = 'discount_percent = ?';
                $params[] = ($data['discount_percent'] === null || $data['discount_percent'] === '') ? null : (float)$data['discount_percent'];
            }
            if (array_key_exists('start_date', $data)) {
                $fields[] = 'start_date = ?';
                $params[] = toDbDateOrNull($data['start_date']);
            }
            if (array_key_exists('end_date', $data)) {
                $fields[] = 'end_date = ?';
                $params[] = toDbDateOrNull($data['end_date']);
            }
            if (array_key_exists('active', $data)) {
                $fields[] = 'active = ?';
                $params[] = toBoolInt($data['active'], 1);
            }

            if (empty($fields)) {
                http_response_code(400);
                echo json_encode(['message' => 'No fields to update']);
                exit;
            }

            $params[] = $id;
            $sql = 'UPDATE promotions SET ' . implode(', ', $fields) . ' WHERE promotion_id = ?';
            $stmt = $db->prepare($sql);
            $stmt->execute($params);

            echo json_encode(['message' => 'Promotion updated']);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['message' => 'Failed to update promotion']);
        }
        exit;

    case 'DELETE':
        try {
            AuthMiddleware::authenticateAdmin();
            $id = routeId();
            if ($id <= 0) {
                http_response_code(400);
                echo json_encode(['message' => 'id required']);
                exit;
            }

            $stmt = $db->prepare('DELETE FROM promotions WHERE promotion_id = ?');
            $stmt->execute([$id]);
            echo json_encode(['message' => 'Promotion deleted']);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['message' => 'Failed to delete promotion']);
        }
        exit;

    default:
        http_response_code(405);
        echo json_encode(['message' => 'Method not allowed']);
        exit;
}
