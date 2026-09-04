<?php
/**
 * Main Router - SIMPLIFIED & FIXED
 * Routes /api/* to correct endpoint files with proper query parameter handling
 */

// ============================================
// CORS HEADERS - CRITICAL FOR FLUTTER WEB
// ============================================
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Access-Control-Max-Age: 3600');
header('Content-Type: application/json; charset=utf-8');

// Handle OPTIONS requests (preflight)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit(0);
}

// ============================================
// GET THE REQUEST PATH (WITHOUT QUERY STRING)
// ============================================

$request_path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$request_path = ltrim($request_path, '/');
$request_path = str_replace('index.php', '', $request_path);
$request_path = ltrim($request_path, '/');

// ============================================
// SIMPLE ROUTE MATCHING
// ============================================

$route_map = [
    'api/products' => 'api/products.php',
    'api/categories' => 'api/categories.php',
    'api/brands' => 'api/brands.php',
    'api/banners' => 'api/banners.php',
    'api/collections' => 'api/collections.php',
    'api/deals' => 'api/deals.php',
    'api/deals_timer' => 'api/deals_timer.php',
    'api/orders' => 'api/orders.php',
    'api/users' => 'api/users.php',
    'api/health' => 'api/health.php',
];

// Match routes (exact or with .php)
foreach ($route_map as $route => $file) {
    if ($request_path === $route || $request_path === $route . '.php') {
        $file_path = __DIR__ . '/' . $file;
        
        if (file_exists($file_path)) {
            // Include the file - it will handle query parameters
            include $file_path;
            exit;
        }
    }
}

// Health check
if ($request_path === '' || $request_path === 'health' || $request_path === 'health.php') {
    http_response_code(200);
    echo json_encode([
        'status' => 'ok',
        'message' => 'ElectrocityBD API is running',
        'time' => time()
    ]);
    exit;
}

// 404 - Not Found
http_response_code(404);
echo json_encode([
    'error' => 'Not Found',
    'path' => $request_path,
    'message' => 'The requested endpoint does not exist'
]);
exit;
?>
