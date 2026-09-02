<?php
/**
 * Add CORS headers to all API files
 */

$cors_header = <<<'PHP'
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

PHP;

$api_files = [
    'api/brands.php',
    'api/banners.php',
    'api/collections.php',
    'api/deals.php',
    'api/deals_timer.php',
    'api/orders.php',
    'api/users.php',
    'api/health.php',
];

echo "Adding CORS headers to API files...\n\n";

foreach ($api_files as $file) {
    $path = __DIR__ . '/' . $file;
    
    if (!file_exists($path)) {
        echo "✗ $file - NOT FOUND\n";
        continue;
    }
    
    $content = file_get_contents($path);
    
    // Skip if already has CORS header
    if (strpos($content, 'Access-Control-Allow-Origin') !== false) {
        echo "⊘ $file - Already has CORS\n";
        continue;
    }
    
    // Find the opening <?php and add CORS headers after it
    $content = preg_replace(
        '/^<\?php\s*\n/',
        "<?php\n$cors_header",
        $content
    );
    
    file_put_contents($path, $content);
    echo "✓ $file - CORS added\n";
}

echo "\n✓ Done!\n";
?>
