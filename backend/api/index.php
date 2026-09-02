<?php
// ============================================
// API Router for PHP Built-in Server
// ============================================
// This router handles requests like /api/products
// and routes them to products.php

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Access-Control-Max-Age: 3600');
header('Content-Type: application/json');

// Handle preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Get the request path (remove query string)
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$query = parse_url($_SERVER['REQUEST_URI'], PHP_URL_QUERY);

// Remove /api prefix
if (strpos($path, '/api/') === 0) {
    $path = substr($path, 5); // Remove '/api/'
}

// Trim trailing slash
$path = rtrim($path, '/');

// Map of routes to their handler files
$routes = [
    'health' => 'health.php',
    'site_settings' => 'site_settings.php',
    'products' => 'products.php',
    'categories' => 'categories.php',
    'brands' => 'brands.php',
    'collections' => 'collections.php',
    'banners' => 'banners.php',
    'deals' => 'deals.php',
    'deals_timer' => 'deals_timer.php',
    'cart' => 'cart.php',
    'orders' => 'orders.php',
    'wishlist' => 'wishlist.php',
    'discounts' => 'discounts.php',
    'ratings' => 'ratings.php',
    'coupons' => 'coupons.php',
    'auth/login' => 'auth/login.php',
    'auth/register' => 'auth/register.php',
    'auth/me' => 'auth/me.php',
    'flash_sales' => 'flash_sales.php',
    'trending' => 'trending.php',
    'best_sellers' => 'best_sellers.php',
    'tech_part' => 'tech_part.php',
    'promotions' => 'promotions.php',
];

// Check if route exists
if (isset($routes[$path]) && file_exists($routes[$path])) {
    // Set query string back into $_GET and $_SERVER
    if ($query) {
        $_SERVER['QUERY_STRING'] = $query;
        parse_str($query, $_GET);
    }
    
    // Include the handler file
    include $routes[$path];
    exit;
}

// If exact route not found, check if it's a file with .php extension
if (file_exists($path . '.php')) {
    if ($query) {
        $_SERVER['QUERY_STRING'] = $query;
        parse_str($query, $_GET);
    }
    include $path . '.php';
    exit;
}

// Route not found
http_response_code(404);
echo json_encode(['error' => 'Endpoint not found: /' . $path]);
