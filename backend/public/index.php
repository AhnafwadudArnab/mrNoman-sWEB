<?php
ini_set('display_errors', '0');
ini_set('display_startup_errors', '0');
ini_set('html_errors', '0');
error_reporting(0);
header('Content-Type: application/json');
require_once __DIR__ . '/../config/cors.php';

$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$segments = array_values(array_filter(explode('/', trim($path, '/'))));

// Helper: serve a file as an image response
function serveImage(string $filePath): void {
    $ext = strtolower(pathinfo($filePath, PATHINFO_EXTENSION));
    $types = [
        'jpg'  => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'png'  => 'image/png',
        'webp' => 'image/webp',
        'gif'  => 'image/gif',
    ];
    header('Content-Type: ' . ($types[$ext] ?? 'application/octet-stream'));
    header('Cache-Control: public, max-age=31536000');
    readfile($filePath);
    exit;
}

// Allow direct access to installer if rewrite rules don't catch it
if (!empty($segments[0]) && $segments[0] === 'install.php') {
    $installer = __DIR__ . '/install.php';
    if (is_file($installer)) {
        require_once $installer;
        exit;
    }
}

// Allow direct access to .php files in public/ (e.g. dbtest.php)
if (!empty($segments[0]) && substr($segments[0], -4) === '.php') {
    $directFile = __DIR__ . '/' . basename($segments[0]);
    if (is_file($directFile)) {
        require_once $directFile;
        exit;
    }
}

// Also handle /api/dbtest.php style access
if (!empty($segments[0]) && $segments[0] === 'api' && !empty($segments[1]) && substr($segments[1], -4) === '.php') {
    $directFile = __DIR__ . '/' . basename($segments[1]);
    if (is_file($directFile)) {
        require_once $directFile;
        exit;
    }
}

// ─── Serve uploaded images ────────────────────────────────────────────────────
// Handles ALL these URL patterns:
//   /uploads/img_xxx.png
//   /api/uploads/img_xxx.png
//   /api/public/uploads/img_xxx.png   ← Flutter app sends this
//   /public/uploads/img_xxx.png

$uploadsDir = __DIR__ . '/uploads/';

function serveMidBannerAsset(string $filename): void {
    if (strpos($filename, 'mid_banner_') !== 0) {
        return;
    }
    $assetName = basename(substr($filename, strlen('mid_banner_')));
    if ($assetName === '') {
        return;
    }
    $assetPath = __DIR__ . '/../../assets/assets/mid-banner-products/' . $assetName;
    if (is_file($assetPath)) {
        serveImage($assetPath);
    }
    $altAssetPath = __DIR__ . '/../../assets/mid-banner-products/' . $assetName;
    if (is_file($altAssetPath)) {
        serveImage($altAssetPath);
    }
}

// Pattern 1: /uploads/filename
if (!empty($segments[0]) && $segments[0] === 'uploads' && !empty($segments[1])) {
    $filename = basename($segments[1]);
    $local = $uploadsDir . $filename;
    if (is_file($local)) serveImage($local);
    serveMidBannerAsset($filename);
}

// Pattern 2: /api/uploads/filename
if (!empty($segments[0]) && $segments[0] === 'api'
    && !empty($segments[1]) && $segments[1] === 'uploads'
    && !empty($segments[2])) {
    $filename = basename($segments[2]);
    $local = $uploadsDir . $filename;
    if (is_file($local)) serveImage($local);
    serveMidBannerAsset($filename);
}

// Pattern 3: /api/public/uploads/filename  ← Flutter sends this
if (!empty($segments[0]) && $segments[0] === 'api'
    && !empty($segments[1]) && $segments[1] === 'public'
    && !empty($segments[2]) && $segments[2] === 'uploads'
    && !empty($segments[3])) {
    $filename = basename($segments[3]);
    $local = $uploadsDir . $filename;
    if (is_file($local)) serveImage($local);
    serveMidBannerAsset($filename);
}

// Pattern 4: /public/uploads/filename
if (!empty($segments[0]) && $segments[0] === 'public'
    && !empty($segments[1]) && $segments[1] === 'uploads'
    && !empty($segments[2])) {
    $filename = basename($segments[2]);
    $local = $uploadsDir . $filename;
    if (is_file($local)) serveImage($local);
    serveMidBannerAsset($filename);
}
// ─────────────────────────────────────────────────────────────────────────────

// Serve images from assets folder (for Flutter web assets)
// On cPanel: assets are at /home/asiment1/electrozonebd.com/assets/
// __DIR__ is /home/asiment1/electrozonebd.com/api/public
// So ../../assets/ = /home/asiment1/electrozonebd.com/assets/
$assetSegments = null;
if (!empty($segments[0]) && $segments[0] === 'assets') {
    $assetSegments = array_slice($segments, 1);
} elseif (!empty($segments[0]) && $segments[0] === 'api'
    && !empty($segments[1]) && $segments[1] === 'assets') {
    $assetSegments = array_slice($segments, 2);
}
if ($assetSegments !== null) {
    // Build safe path — join with DIRECTORY_SEPARATOR, no path traversal
    $safeParts = array_map('basename', $assetSegments);
    // Preserve subdirectory structure but sanitize each part
    $safeRelative = implode(DIRECTORY_SEPARATOR, array_map(function($p) {
        return preg_replace('/[^a-zA-Z0-9_\-\. ]/', '', $p);
    }, $assetSegments));
    $assetsPath = __DIR__ . '/../../assets/' . $safeRelative;
    if (is_file($assetsPath)) serveImage($assetsPath);
}

if (empty($segments[0])) {
    echo json_encode([
        'name'      => 'electrozonebd',
        'version'   => '1.0.0',
        'endpoints' => [
            '/api/auth/login'    => 'User login',
            '/api/auth/register' => 'User registration',
            '/api/products'      => 'Product endpoints',
            '/api/cart'          => 'Cart endpoints',
            '/api/orders'        => 'Order endpoints',
            '/api/users'         => 'User endpoints',
        ],
    ]);
    exit;
}

if ($segments[0] === 'api') {
    // Support /api and /api/ as a valid root endpoint.
    if (count($segments) === 1) {
        echo json_encode(['status' => 'ok', 'message' => 'API is running']);
        exit;
    }

    if (isset($segments[1]) && $segments[1] === 'health') {
        echo json_encode(['status' => 'ok']);
        exit;
    }

    // Skip /api/uploads — already handled above; if we reach here the file wasn't found
    if (isset($segments[1]) && $segments[1] === 'uploads') {
        http_response_code(404);
        echo json_encode(['message' => 'Image not found']);
        exit;
    }

    $apiBase = __DIR__ . '/../api';
    $file = null;

    // Handle routes with IDs (e.g., /api/payment_methods/1 or /api/products/123)
    if (count($segments) >= 3 && is_numeric($segments[2])) {
        $_GET['id'] = $segments[2];
        $file = $apiBase . '/' . $segments[1] . '.php';
    } elseif (count($segments) >= 3) {
        $file = $apiBase . '/' . $segments[1] . '/' . $segments[2] . '.php';
    } elseif (count($segments) >= 2) {
        $file = $apiBase . '/' . $segments[1] . '.php';
    }

    if ($file && file_exists($file)) {
        $_GET = array_merge($_GET, $_REQUEST);
        require_once $file;
        exit;
    }
    http_response_code(404);
    echo json_encode(['message' => 'Endpoint not found: /' . implode('/', array_slice($segments, 1))]);
    exit;
}

http_response_code(404);
echo json_encode(['message' => 'Endpoint not found']);
