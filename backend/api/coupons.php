<?php
header('Content-Type: application/json');
require_once __DIR__ . '/bootstrap.php';
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../middleware/authmiddleware.php';

$db = db();
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

function get_active_coupon(PDO $db) {
    $stmt = $db->prepare('SELECT setting_value FROM site_settings WHERE setting_key = ?');
    $stmt->execute(['active_coupon']);
    $row = $stmt->fetch();
    if (!$row) return null;
    $data = json_decode($row['setting_value'] ?? '', true);
    if (!is_array($data)) return null;
    if (!($data['active'] ?? true)) return null;
    return [
        'code' => strtoupper(trim($data['code'] ?? '')),
        'percent' => (float)($data['percent'] ?? 0),
        'scope' => ($data['scope'] ?? 'cart') === 'item' ? 'item' : 'cart',
    ];
}

function set_active_coupon(PDO $db, array $data) {
    $payload = [
        'code' => strtoupper(trim($data['code'] ?? '')),
        'percent' => (float)($data['percent'] ?? 0),
        'scope' => ($data['scope'] ?? 'cart') === 'item' ? 'item' : 'cart',
        'active' => (bool)($data['active'] ?? true),
    ];
    $json = json_encode($payload, JSON_UNESCAPED_UNICODE);
    $stmt = $db->prepare('INSERT INTO site_settings (setting_key, setting_value) VALUES (?, ?) ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)');
    $stmt->execute(['active_coupon', $json]);
    return $payload;
}

if ($method === 'GET') {
    $coupon = get_active_coupon($db);
    echo json_encode(['active' => $coupon]);
    exit;
}

if ($method === 'POST') {
    // admin only: set coupon (replace any existing one)
    AuthMiddleware::authenticateAdmin();
    $data = json_decode(file_get_contents('php://input'), true) ?: [];
    if (empty($data['code']) || empty($data['percent'])) {
        http_response_code(400);
        echo json_encode(['message' => 'code and percent required']);
        exit;
    }
    $saved = set_active_coupon($db, $data);
    echo json_encode(['message' => 'Coupon saved', 'coupon' => $saved]);
    exit;
}

if ($method === 'PUT') {
    // admin: deactivate
    AuthMiddleware::authenticateAdmin();
    $data = json_decode(file_get_contents('php://input'), true) ?: [];
    $current = get_active_coupon($db);
    if (!$current) {
        echo json_encode(['message' => 'No active coupon']);
        exit;
    }
    $payload = [
        'code' => $current['code'],
        'percent' => $current['percent'],
        'scope' => $current['scope'],
        'active' => (bool)($data['active'] ?? false),
    ];
    set_active_coupon($db, $payload);
    echo json_encode(['message' => 'Coupon updated']);
    exit;
}

if ($method === 'DELETE') {
    // admin: remove coupon
    AuthMiddleware::authenticateAdmin();
    $stmt = $db->prepare('DELETE FROM site_settings WHERE setting_key = ?');
    $stmt->execute(['active_coupon']);
    echo json_encode(['message' => 'Coupon removed']);
    exit;
}

http_response_code(405);
echo json_encode(['message' => 'Method not allowed']);
