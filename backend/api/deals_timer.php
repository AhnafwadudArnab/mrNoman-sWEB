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
header('Cache-Control: no-cache, no-store, must-revalidate');
header('Pragma: no-cache');
header('Expires: 0');
require_once __DIR__ . '/bootstrap.php';
if (file_exists(__DIR__ . '/../config/cors.php')) {
    require_once __DIR__ . '/../config/cors.php';
} elseif (file_exists(__DIR__ . '/config/cors.php')) {
    require_once __DIR__ . '/config/cors.php';
}
if (file_exists(__DIR__ . '/../middleware/authmiddleware.php')) {
    require_once __DIR__ . '/../middleware/authmiddleware.php';
} elseif (file_exists(__DIR__ . '/middleware/authmiddleware.php')) {
    require_once __DIR__ . '/middleware/authmiddleware.php';
}

$db = db();
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

if ($method === 'OPTIONS') {
    http_response_code(200);
    echo json_encode(['ok' => true]);
    exit;
}

// Parse ID from $_GET or URL path: /deals_timer/{id}
$urlId = null;
if (!empty($_GET['id']) && is_numeric($_GET['id'])) {
    $urlId = (int)$_GET['id'];
} else {
    $uri = $_SERVER['REQUEST_URI'] ?? '';
    $pathOnly = parse_url($uri, PHP_URL_PATH);
    $parts = explode('/', trim($pathOnly, '/'));
    $lastPart = preg_replace('/\.php$/i', '', end($parts));
    if (is_numeric($lastPart)) {
        $urlId = (int)$lastPart;
    }
}


// ── GET ──────────────────────────────────────────────────────────────────────
if ($method === 'GET') {
    try {
        _ensureMultiTimerSchema($db);
        $rows = $db->query('SELECT * FROM deals_timer ORDER BY timer_id ASC')->fetchAll(PDO::FETCH_ASSOC);

        // If no timer exists at all, seed a default active one
        if (empty($rows)) {
            $db->exec("INSERT INTO deals_timer (title, description, end_time, days, hours, minutes, seconds, is_active)
                       VALUES ('Deals of the Day', 'Special daily offers', DATE_ADD(NOW(), INTERVAL 7 DAY), 7, 0, 0, 0, 1)");
            $rows = $db->query('SELECT * FROM deals_timer ORDER BY timer_id ASC')->fetchAll(PDO::FETCH_ASSOC);
        }

        // Identify the active timer (or first timer)
        $activeTimer = null;
        foreach ($rows as $r) {
            if (!empty($r['is_active'])) {
                $activeTimer = $r;
                break;
            }
        }
        if (!$activeTimer && !empty($rows)) {
            $activeTimer = $rows[0];
        }

        echo json_encode([
            'success' => true,
            'is_active' => $activeTimer ? (int)$activeTimer['is_active'] : 1,
            'timer' => $activeTimer,
            'timers' => $rows,
        ]);
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

    if (!$urlId) {
        $first = $db->query('SELECT timer_id FROM deals_timer ORDER BY is_active DESC, timer_id ASC LIMIT 1')->fetch(PDO::FETCH_ASSOC);
        if ($first) {
            $urlId = (int)$first['timer_id'];
        } else {
            http_response_code(400);
            echo json_encode(['error' => 'No timer found to update']);
            exit;
        }
    }

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
