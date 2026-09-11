<?php
/**
 * Router for PHP Built-in Development Server
 * This file handles URL routing for the API
 * 
 * Usage: php -S localhost:8000 router.php
 */

// Get the requested URI - use REQUEST_URI directly without stripping SCRIPT_NAME
// (PHP built-in server sets SCRIPT_NAME to the actual PHP file when it exists,
// which would incorrectly strip the entire path)
$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
if ($uri === false) {
    $uri = '/';
}

// Remove leading slash
$uri = ltrim($uri, '/');

// Global CORS headers so Flutter Web (cross-origin localhost) can load images & API
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// 1. Intercept uploaded images (e.g. /public/uploads/xxx, /api/public/uploads/xxx, /uploads/xxx)
if (preg_match('#(?:^|/)(?:api/)?(?:public/)?uploads/([^?]+)#i', $uri, $matches)) {
    $filename = basename($matches[1]);
    $filePath = __DIR__ . '/public/uploads/' . $filename;
    if (file_exists($filePath) && is_file($filePath)) {
        $ext = strtolower(pathinfo($filePath, PATHINFO_EXTENSION));
        $mimeTypes = [
            'jpg' => 'image/jpeg',
            'jpeg' => 'image/jpeg',
            'png' => 'image/png',
            'gif' => 'image/gif',
            'webp' => 'image/webp',
            'svg' => 'image/svg+xml',
            'ico' => 'image/x-icon',
        ];
        $contentType = $mimeTypes[$ext] ?? 'application/octet-stream';
        header('Content-Type: ' . $contentType);
        header('Content-Length: ' . filesize($filePath));
        header('Cache-Control: public, max-age=86400');
        readfile($filePath);
        exit;
    }
}

// 2. Intercept public assets (e.g. /public/assets/xxx, /api/public/assets/xxx, /assets/xxx)
if (preg_match('#(?:^|/)(?:api/)?(?:public/)?assets/([^?]+)#i', $uri, $matches)) {
    $assetSubpath = $matches[1];
    $filePath = __DIR__ . '/public/assets/' . $assetSubpath;
    if (file_exists($filePath) && is_file($filePath)) {
        $ext = strtolower(pathinfo($filePath, PATHINFO_EXTENSION));
        $mimeTypes = [
            'jpg' => 'image/jpeg',
            'jpeg' => 'image/jpeg',
            'png' => 'image/png',
            'gif' => 'image/gif',
            'webp' => 'image/webp',
            'svg' => 'image/svg+xml',
            'css' => 'text/css',
            'js' => 'application/javascript',
        ];
        $contentType = $mimeTypes[$ext] ?? 'application/octet-stream';
        header('Content-Type: ' . $contentType);
        header('Content-Length: ' . filesize($filePath));
        header('Cache-Control: public, max-age=86400');
        readfile($filePath);
        exit;
    }
}

// 3. Clean up leading 'public/' if present for root static files
$cleanStaticUri = preg_replace('#^public/#i', '', $uri);
if (!empty($cleanStaticUri) && file_exists(__DIR__ . '/public/' . $cleanStaticUri) && is_file(__DIR__ . '/public/' . $cleanStaticUri)) {
    return false; // Let the server handle root static files
}

// Handle API routes
if (strpos($uri, 'api/') === 0) {
    require_once __DIR__ . '/config/cors.php';

    // Extract the endpoint (everything after 'api/')
    $endpoint = substr($uri, 4); // Remove 'api/' prefix
    
    // Route to the appropriate API file
    $routes = [
        // Admin routes
        'admin/dashboard' => 'api/admin/dashboard.php',
        'admin/customers' => 'api/admin/customers.php',
        'admin/reports' => 'api/admin/reports.php',
        'admin/section-filters' => 'api/admin/section-filters.php',
        // Public & Admin routes
        'products' => 'api/products.php',
        'orders' => 'api/orders.php',
        'users' => 'api/user.php',
        'categories' => 'api/categories.php',
        'brands' => 'api/brands.php',
        'banners' => 'api/banners.php',
        'collections' => 'api/collections.php',
        'collection_products' => 'api/collection_products.php',
        'collection-products' => 'api/collection_products.php',
        'collection-items' => 'api/collection_items.php',
        'deals' => 'api/deals.php',
        'deals_timer' => 'api/deals_timer.php',
        'flash_sales' => 'api/flash_sales.php',
        'reviews' => 'api/reviews.php',
        'cart' => 'api/cart.php',
        'wishlist' => 'api/wishlist.php',
        'payments' => 'api/payments.php',
        'payment_methods' => 'api/payment_methods.php',
        'discounts' => 'api/discounts.php',
        'promotions' => 'api/promotions.php',
        'reports' => 'api/reports.php',
        'upload' => 'api/upload.php',
        'coupons' => 'api/coupons.php',
        'product_sections' => 'api/product_sections.php',
        'ratings' => 'api/ratings.php',
        'notifications' => 'api/notifications.php',
        'best_sellers' => 'api/best_sellers.php',
        'trending' => 'api/trending.php',
        'customer_support' => 'api/customer_support.php',
        'auth/admin-login' => 'api/auth/admin-login.php',
        'auth/login' => 'api/auth/login.php',
        'auth/register' => 'api/auth/register.php',
        'auth/me' => 'api/auth/me.php',
        'auth/profile' => 'api/auth/profile.php',
        'auth/change-password' => 'api/auth/change-password.php',
        'search' => 'api/search.php',
        'health' => 'api/health.php',
        'site_settings' => 'api/site_settings.php',
        'tech_part' => 'api/tech_part.php',
        'migrate_regular_price' => 'api/migrate_regular_price.php',
        'public/uploads' => 'public/uploads',
    ];
    
    // Normalize endpoint: strip query string FIRST, then strip .php suffix
    $endpoint_clean = preg_replace('/\?.*$/', '', $endpoint); // Remove query string first
    $endpoint_clean = preg_replace('/\.php$/', '', $endpoint_clean); // Then remove .php suffix

    // Sort routes by length (longest first) to match more specific routes first
    uasort($routes, function($a, $b) {
        return strlen($b) - strlen($a);
    });

    $endpoint_lower = strtolower($endpoint_clean);

    // Check for route matches
    foreach ($routes as $route => $file) {
        $route_lower = strtolower($route);
        $is_exact = ($endpoint_lower === $route_lower);
        $has_subpath = (strpos($endpoint_lower, $route_lower . '/') === 0);

        if ($is_exact || $has_subpath) {
            // If there is a subpath (e.g., /payment_methods/1 or /deals_timer/5)
            if ($has_subpath) {
                $sub = substr($endpoint_clean, strlen($route) + 1);
                $sub = preg_replace('/\.php$/', '', $sub);
                if (is_numeric($sub) && !isset($_GET['id'])) {
                    $_GET['id'] = $sub;
                }
            }

            $_SERVER['REQUEST_URI'] = '/api/' . $endpoint_clean . (empty($_SERVER['QUERY_STRING']) ? '' : '?' . $_SERVER['QUERY_STRING']);
            
            // Handle static file serving
            if (strpos($file, 'public/uploads') === 0) {
                $file_path = __DIR__ . '/' . substr($endpoint_clean, strlen($route));
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
