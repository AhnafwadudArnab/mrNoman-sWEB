<?php
/**
 * CORS Configuration - Production Ready
 * Handles Cross-Origin Resource Sharing with security
 */

// Load .env if not already loaded (cors.php may be included before bootstrap.php)
if (!function_exists('_cors_load_env')) {
    function _cors_load_env(): void {
        $candidates = [
            __DIR__ . '/../.env',
            dirname(__DIR__, 2) . '/api/.env',
            dirname(__DIR__, 2) . '/backend/.env',
            dirname(__DIR__, 2) . '/.env',
            dirname(__DIR__, 3) . '/.env',
            '/home/' . (getenv('USER') ?: 'asiment1') . '/electrozonebd.com/api/.env',
        ];
        foreach ($candidates as $f) {
            if (!is_file($f)) continue;
            $lines = file($f, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
            foreach ($lines as $line) {
                $line = trim($line);
                if ($line === '' || $line[0] === '#') continue;
                $pos = strpos($line, '=');
                if ($pos === false) continue;
                $key = trim(substr($line, 0, $pos));
                $val = trim(substr($line, $pos + 1));
                if (strlen($val) >= 2 &&
                    (($val[0] === '"' && $val[-1] === '"') || ($val[0] === "'" && $val[-1] === "'"))) {
                    $val = substr($val, 1, -1);
                }
                if (!getenv($key)) {
                    putenv("$key=$val");
                    $_ENV[$key] = $val;
                }
            }
            break;
        }
    }
}
_cors_load_env();

// Build allowed origins list
$allowedOriginsEnv = getenv('ALLOWED_ORIGINS');
$allowed_origins = [];

if ($allowedOriginsEnv) {
    $allowed_origins = array_map('trim', explode(',', $allowedOriginsEnv));
}

// Always include the production domain as fallback
$appUrl = getenv('APP_URL') ?: 'https://electrozonebd.com';
$appOrigin = rtrim($appUrl, '/');
if (!in_array($appOrigin, $allowed_origins)) {
    $allowed_origins[] = $appOrigin;
}
// Also add www variant
$wwwVariant = preg_replace('#^(https?://)(?!www\.)#', '$1www.', $appOrigin);
if ($wwwVariant !== $appOrigin && !in_array($wwwVariant, $allowed_origins)) {
    $allowed_origins[] = $wwwVariant;
}

$origin = $_SERVER['HTTP_ORIGIN'] ?? '';

$originAllowed = false;
if ($origin) {
    if (in_array($origin, $allowed_origins)) {
        $originAllowed = true;
    } elseif (
        strpos($origin, 'localhost') !== false ||
        strpos($origin, '127.0.0.1') !== false
    ) {
        // Allow any localhost/127.0.0.1 origin (Flutter Web dev)
        $originAllowed = true;
    }
}

if ($originAllowed && $origin) {
    header("Access-Control-Allow-Origin: $origin");
    header('Access-Control-Allow-Credentials: true');
} else {
    // No origin header (mobile app, Postman, same-origin) — allow
    header("Access-Control-Allow-Origin: *");
}

header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, X-API-Key');
header('Access-Control-Max-Age: 3600');

// Security headers
header("X-Content-Type-Options: nosniff");
header("X-Frame-Options: SAMEORIGIN");
header("X-XSS-Protection: 1; mode=block");
header("Referrer-Policy: strict-origin-when-cross-origin");

// Handle OPTIONS preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit(0);
}

header('Content-Type: application/json');
