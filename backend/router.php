<?php
/**
 * Router for PHP Built-in Development Server
 * This file handles URL routing for the API
 * 
 * Usage: php -S localhost:8000 router.php
 */

// Get the requested URI
$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$script = parse_url($_SERVER['SCRIPT_NAME'], PHP_URL_PATH);

// Remove the script name from the URI
if (strpos($uri, $script) === 0) {
    $uri = substr($uri, strlen($script));
}

// Remove leading slash
$uri = ltrim($uri, '/');

// Remove query string if present
$uri = strtok($uri, '?');

// Serve static files directly
if (!empty($uri) && file_exists(__DIR__ . '/' . $uri)) {
    return false; // Let the server handle static files
}

// Handle API routes
if (strpos($uri, 'api/') === 0) {
    // Extract the endpoint
    $endpoint = substr($uri, 4); // Remove 'api/' prefix
    
    // Route to the appropriate API file
    $routes = [
        'products' => 'api/products.php',
        'orders' => 'api/orders.php',
        'users' => 'api/users.php',
        'categories' => 'api/categories.php',
        'brands' => 'api/brands.php',
        'banners' => 'api/banners.php',
        'collections' => 'api/collections.php',
        'deals' => 'api/deals.php',
        'deals_timer' => 'api/deals_timer.php',
        'flash_sales' => 'api/flash_sales.php',
        'flash_sale_products' => 'api/flash_sale_products.php',
        'reviews' => 'api/reviews.php',
        'cart' => 'api/cart.php',
        'wishlist' => 'api/wishlist.php',
        'payments' => 'api/payments.php',
        'auth' => 'api/auth.php',
        'search' => 'api/search.php',
        'health' => 'api/health.php',
        'site_settings' => 'api/site_settings.php',
        'tech_part' => 'api/tech_part.php',
        'public/uploads' => 'public/uploads',
    ];
    
    // Check for exact route match
    foreach ($routes as $route => $file) {
        if (strpos($endpoint, $route) === 0) {
            $_SERVER['REQUEST_URI'] = '/api/' . $endpoint . (empty($_SERVER['QUERY_STRING']) ? '' : '?' . $_SERVER['QUERY_STRING']);
            
            // Handle static file serving
            if (strpos($file, 'public/uploads') === 0) {
                $file_path = __DIR__ . '/' . substr($endpoint, strlen($route));
                if (file_exists($file_path) && is_file($file_path)) {
                    return false; // Serve static file
                }
            }
            
            // Serve PHP file
            if (file_exists(__DIR__ . '/' . $file)) {
                include __DIR__ . '/' . $file;
                exit;
            }
        }
    }
}

// Default 404
http_response_code(404);
header('Content-Type: application/json');
echo json_encode(['error' => 'Not Found', 'path' => $uri]);
exit;
?>
