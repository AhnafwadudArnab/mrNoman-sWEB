<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../bootstrap.php';
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../middleware/authmiddleware.php';

$method = $_SERVER['REQUEST_METHOD'];
$user = AuthMiddleware::authenticateAdmin();

// In-memory defaults (can be stored in site_settings if needed)
$defaults = [
    'trending'     => ['sort' => 'newest', 'limit' => 12, 'min_price' => 0, 'max_price' => 50000],
    'flash-sale'   => ['sort' => 'featured', 'limit' => 20, 'min_price' => 0, 'max_price' => 50000],
    'best-sellers' => ['sort' => 'featured', 'limit' => 10, 'min_price' => 0, 'max_price' => 50000],
    'deals'        => ['sort' => 'featured', 'limit' => 16, 'min_price' => 0, 'max_price' => 50000],
    'tech-part'    => ['sort' => 'featured', 'limit' => 20, 'min_price' => 0, 'max_price' => 50000],
];

$db = db();

// Load from site_settings
$stmt = $db->query("SELECT setting_key, setting_value FROM site_settings WHERE setting_key LIKE 'section_filter_%'");
$rows = $stmt->fetchAll();
foreach ($rows as $row) {
    $section = str_replace('section_filter_', '', $row['setting_key']);
    $val = json_decode($row['setting_value'], true);
    if (is_array($val)) $defaults[$section] = array_merge($defaults[$section] ?? [], $val);
}

if ($method === 'GET') {
    // Check if specific section requested via URL segment
    $path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
    $segments = array_values(array_filter(explode('/', trim($path, '/'))));
    // /api/admin/section-filters/trending → segments[3] = 'trending'
    $section = $segments[3] ?? null;

    if ($section && isset($defaults[$section])) {
        echo json_encode($defaults[$section]);
    } else {
        echo json_encode($defaults);
    }
    exit;
}

if ($method === 'PUT') {
    $path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
    $segments = array_values(array_filter(explode('/', trim($path, '/'))));
    $section = $segments[3] ?? null;

    if (!$section) { http_response_code(400); echo json_encode(['error' => 'Section required']); exit; }

    $data = getJsonBody();
    $current = $defaults[$section] ?? [];
    $merged = array_merge($current, array_filter($data, fn($v) => $v !== null));

    // Save to site_settings
    $key = "section_filter_$section";
    $val = json_encode($merged);
    $stmt = $db->prepare("INSERT INTO site_settings (setting_key, setting_value) VALUES (?, ?) ON DUPLICATE KEY UPDATE setting_value = ?");
    $stmt->execute([$key, $val, $val]);

    echo json_encode(['success' => true, 'section' => $section, 'filters' => $merged]);
    exit;
}

http_response_code(405);
echo json_encode(['error' => 'Method not allowed']);
