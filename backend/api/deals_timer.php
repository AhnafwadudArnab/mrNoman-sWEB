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

if ($method === 'OPTIONS') {
    http_response_code(200);
    echo json_encode(['ok' => true]);
    exit;
}

// Parse ID from URL: /deals_timer/{id}
$uri = $_SERVER['REQUEST_URI'] ?? '';
$parts = explode('/', trim(parse_url($uri, PHP_URL_PATH), '/'));
$lastPart = end($parts);
$urlId = is_numeric($lastPart) ? (int)$lastPart : null;

// ── GET ──────────────────────────────────────────────────────────────────────
if ($method === 'GET') {
    try {
        // Check if table has multi-timer columns (title, end_time)
        $cols = $db->query("SHOW COLUMNS FROM deals_timer")->fetchAll(PDO::FETCH_COLUMN);
        $hasTitle = in_array('title', $cols);

        if ($hasTitle) {
            $rows = $db->query('SELECT * FROM deals_timer ORDER BY timer_id ASC')->fetchAll(PDO::FETCH_ASSOC);
            echo json_encode(['success' => true, 'timers' => $rows]);
        } else {
            // Legacy single-timer mode
            $stmt = $db->prepare('SELECT * FROM deals_timer WHERE timer_id = 1');
            $stmt->execute();
            $timer = $stmt->fetch(PDO::FETCH_ASSOC);
            if (!is_array($timer)) {
                $timer = [
                    'timer_id' => 1,
                    'title' => 'Deals Timer',
                    'description' => '',
                    'end_time' => null,
                    'days' => 3,
                    'hours' => 11,
                    'minutes' => 15,
                    'seconds' => 0,
                    'is_active' => 1,
                ];
            }
            echo json_encode(['success' => true, 'timer' => $timer, 'timers' => [$timer]]);
        }
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => $e->getMessage()]);
    }
    exit;
}

// ── POST (create) ─────────────────────────────────────────────────────────────
if ($method === 'POST') {
    try { AuthMiddleware::authenticateAdmin(); }
    catch (Exception $e) { http_response_code(401); echo json_encode(['error' => 'Unauthorized']); exit; }

    $data = json_decode(file_get_contents('php://input'), true);
    if (!is_array($data)) { http_response_code(400); echo json_encode(['error' => 'Invalid data']); exit; }

    try {
        // Ensure multi-timer columns exist
        _ensureMultiTimerSchema($db);

        $title       = trim($data['title'] ?? 'Timer');
        $description = trim($data['description'] ?? '');
        $end_time    = !empty($data['end_time']) ? $data['end_time'] : null;
        $days        = isset($data['days'])    ? (int)$data['days']    : 0;
        $hours       = isset($data['hours'])   ? (int)$data['hours']   : 0;
        $minutes     = isset($data['minutes']) ? (int)$data['minutes'] : 0;
        $seconds     = isset($data['seconds']) ? (int)$data['seconds'] : 0;
        $is_active   = isset($data['is_active']) ? ($data['is_active'] ? 1 : 0) : 1;

        $stmt = $db->prepare('
            INSERT INTO deals_timer (title, description, end_time, days, hours, minutes, seconds, is_active)
            VALUES (:title, :description, :end_time, :days, :hours, :minutes, :seconds, :is_active)
        ');
        $stmt->execute([
            ':title'       => $title,
            ':description' => $description,
            ':end_time'    => $end_time,
            ':days'        => $days,
            ':hours'       => $hours,
            ':minutes'     => $minutes,
            ':seconds'     => $seconds,
            ':is_active'   => $is_active,
        ]);
        $id = $db->lastInsertId();
        echo json_encode(['success' => true, 'id' => $id, 'message' => 'Timer created']);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => $e->getMessage()]);
    }
    exit;
}

// ── PUT (update) ──────────────────────────────────────────────────────────────
if ($method === 'PUT') {
    try { AuthMiddleware::authenticateAdmin(); }
    catch (Exception $e) { http_response_code(401); echo json_encode(['error' => 'Unauthorized']); exit; }

    if (!$urlId) { http_response_code(400); echo json_encode(['error' => 'Timer ID required']); exit; }

    $data = json_decode(file_get_contents('php://input'), true);
    if (!is_array($data)) { http_response_code(400); echo json_encode(['error' => 'Invalid data']); exit; }

    try {
        _ensureMultiTimerSchema($db);

        $fields = [];
        $params = [':id' => $urlId];

        if (isset($data['title']))       { $fields[] = 'title = :title';             $params[':title']       = trim($data['title']); }
        if (isset($data['description'])) { $fields[] = 'description = :description'; $params[':description'] = trim($data['description']); }
        if (isset($data['end_time']))    { $fields[] = 'end_time = :end_time';        $params[':end_time']    = $data['end_time'] ?: null; }
        if (isset($data['days']))        { $fields[] = 'days = :days';               $params[':days']        = (int)$data['days']; }
        if (isset($data['hours']))       { $fields[] = 'hours = :hours';             $params[':hours']       = (int)$data['hours']; }
        if (isset($data['minutes']))     { $fields[] = 'minutes = :minutes';         $params[':minutes']     = (int)$data['minutes']; }
        if (isset($data['seconds']))     { $fields[] = 'seconds = :seconds';         $params[':seconds']     = (int)$data['seconds']; }
        if (isset($data['is_active']))   { $fields[] = 'is_active = :is_active';     $params[':is_active']   = $data['is_active'] ? 1 : 0; }

        if (empty($fields)) { echo json_encode(['success' => true, 'message' => 'Nothing to update']); exit; }

        $stmt = $db->prepare('UPDATE deals_timer SET ' . implode(', ', $fields) . ' WHERE timer_id = :id');
        $stmt->execute($params);
        echo json_encode(['success' => true, 'message' => 'Timer updated']);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => $e->getMessage()]);
    }
    exit;
}

// ── DELETE ────────────────────────────────────────────────────────────────────
if ($method === 'DELETE') {
    try { AuthMiddleware::authenticateAdmin(); }
    catch (Exception $e) { http_response_code(401); echo json_encode(['error' => 'Unauthorized']); exit; }

    if (!$urlId) { http_response_code(400); echo json_encode(['error' => 'Timer ID required']); exit; }

    try {
        $stmt = $db->prepare('DELETE FROM deals_timer WHERE timer_id = :id');
        $stmt->execute([':id' => $urlId]);
        echo json_encode(['success' => true, 'message' => 'Timer deleted']);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => $e->getMessage()]);
    }
    exit;
}

http_response_code(405);
echo json_encode(['error' => 'Method not allowed']);

// ── Helper: add multi-timer columns if missing ────────────────────────────────
function _ensureMultiTimerSchema(PDO $db): void {
    $cols = $db->query("SHOW COLUMNS FROM deals_timer")->fetchAll(PDO::FETCH_COLUMN);
    if (!in_array('title', $cols)) {
        $db->exec("ALTER TABLE deals_timer
            MODIFY timer_id INT AUTO_INCREMENT,
            ADD COLUMN title VARCHAR(100) NOT NULL DEFAULT 'Timer' AFTER timer_id,
            ADD COLUMN description TEXT AFTER title,
            ADD COLUMN end_time DATETIME NULL AFTER description
        ");
        // Remove the fixed PRIMARY KEY constraint so AUTO_INCREMENT works
        // (timer_id = 1 seed row stays, new rows get 2, 3, ...)
    }
}
