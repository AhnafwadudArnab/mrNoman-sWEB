<?php
declare(strict_types=1);

// Set Content-Type header early to ensure JSON responses
header('Content-Type: application/json');

if (!function_exists('str_starts_with')) {
    function str_starts_with(string $haystack, string $needle): bool {
        return $needle === '' || strncmp($haystack, $needle, strlen($needle)) === 0;
    }
}
if (!function_exists('str_ends_with')) {
    function str_ends_with(string $haystack, string $needle): bool {
        if ($needle === '') return true;
        $len = strlen($needle);
        return substr($haystack, -$len) === $needle;
    }
}
if (!function_exists('getallheaders')) {
    function getallheaders(): array {
        $headers = [];
        foreach ($_SERVER as $name => $value) {
            if (strpos($name, 'HTTP_') === 0) {
                $key = str_replace(' ', '-', ucwords(strtolower(str_replace('_', ' ', substr($name, 5)))));
                $headers[$key] = $value;
            }
        }
        return $headers;
    }
}
ini_set('display_errors', '0');
ini_set('display_startup_errors', '0');
ini_set('html_errors', '0');
error_reporting(E_ALL);
ini_set('log_errors', '1');
ini_set('error_log', __DIR__ . '/../error.log');

function loadEnv(string $file): void {
    if (!is_file($file)) return;
    $lines = file($file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        $line = trim($line);
        if ($line === '' || str_starts_with($line, '#')) continue;
        $pos = strpos($line, '=');
        if ($pos === false) continue;
        $key = trim(substr($line, 0, $pos));
        $val = trim(substr($line, $pos + 1));
        if ((str_starts_with($val, '"') && str_ends_with($val, '"')) ||
            (str_starts_with($val, "'") && str_ends_with($val, "'"))) {
            $val = substr($val, 1, -1);
        }
        putenv("$key=$val");
        $_ENV[$key] = $val;
        $_SERVER[$key] = $val;
    }
}

loadEnv(__DIR__ . '/../.env');

$CONFIG = require __DIR__ . '/../config.php';

function db(): PDO {
    static $pdo = null;
    global $CONFIG;
    if ($pdo) return $pdo;

    // Support fallback hosts: DB_HOST can be a comma-separated list.
    $hosts = array_filter(array_map('trim', explode(',', (string)$CONFIG['db']['host'])));
    if (empty($hosts)) {
        $hosts = ['localhost'];
    }

    $options = [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ];

    $lastError = null;
    foreach ($hosts as $host) {
        $dsn = sprintf(
            'mysql:host=%s;port=%s;dbname=%s;charset=%s',
            $host,
            $CONFIG['db']['port'],
            $CONFIG['db']['name'],
            $CONFIG['db']['charset']
        );
        try {
            $pdo = new PDO($dsn, $CONFIG['db']['user'], $CONFIG['db']['pass'], $options);
            break;
        } catch (Throwable $e) {
            $lastError = $e;
            error_log('DB Connection error on host ' . $host . ': ' . $e->getMessage());
        }
    }

    if (!$pdo) {
        http_response_code(500);
        echo json_encode(['message' => 'Database connection failed'], JSON_UNESCAPED_UNICODE);
        exit;
    }

    return $pdo;
}

function baseHeaders(): void {
    header('Content-Type: application/json');
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Headers: Content-Type, Authorization');
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
}

function jsonResponse($data, int $code = 200): void {
    // Clean output buffer to prevent any accidental output from corrupting JSON
    if (ob_get_level() > 0) ob_clean();
    http_response_code($code);
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit;
}

function errorResponse(string $message, int $code = 400): void {
    jsonResponse(['error' => $message], $code);
}

function getJsonBody(): array {
    $raw = file_get_contents('php://input') ?: '';
    if ($raw === '') return [];
    $decoded = json_decode($raw, true);
    if (!is_array($decoded)) return [];
    return $decoded;
}

function bearerToken(): ?string {
    $headers = function_exists('getallheaders') ? getallheaders() : [];
    $auth = $headers['Authorization'] ?? $headers['authorization'] ?? '';
    if (!$auth) {
        $auth = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
    }
    if ($auth && stripos($auth, 'Bearer ') === 0) {
        return trim(substr($auth, 7));
    }
    return null;
}

function base64url_encode(string $data): string {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}
function base64url_decode(string $data): string {
    return base64_decode(strtr($data, '-_', '+/'));
}

function jwt_encode(array $payload): string {
    global $CONFIG;
    $header = ['alg' => 'HS256', 'typ' => 'JWT'];
    $segments = [
        base64url_encode(json_encode($header)),
        base64url_encode(json_encode($payload)),
    ];
    $signing_input = implode('.', $segments);
    $signature = hash_hmac('sha256', $signing_input, $CONFIG['auth']['jwt_secret'], true);
    $segments[] = base64url_encode($signature);
    return implode('.', $segments);
}

function jwt_decode(string $token): ?array {
    global $CONFIG;
    $parts = explode('.', $token);
    if (count($parts) !== 3) return null;
    [$h, $p, $s] = $parts;
    $signing_input = $h . '.' . $p;
    $calc = base64url_encode(hash_hmac('sha256', $signing_input, $CONFIG['auth']['jwt_secret'], true));
    if (!hash_equals($calc, $s)) return null;
    $payload = json_decode(base64url_decode($p), true);
    if (!is_array($payload)) return null;
    $exp = $payload['exp'] ?? 0;
    if ($exp && time() > $exp) return null;
    return $payload;
}

function issueToken(int $userId, string $role): string {
    global $CONFIG;
    $payload = [
        'iss' => $CONFIG['auth']['jwt_issuer'],
        'sub' => $userId,
        'role' => $role,
        'iat' => time(),
        'exp' => time() + $CONFIG['auth']['jwt_ttl_seconds'],
    ];
    return jwt_encode($payload);
}

function currentUser(): ?array {
    $token = bearerToken();
    if (!$token) return null;
    $payload = jwt_decode($token);
    if (!$payload) return null;
    $uid = (int)($payload['sub'] ?? 0);
    if ($uid <= 0) return null;
    $stmt = db()->prepare('SELECT user_id, full_name, last_name, email, phone_number, gender, role FROM users WHERE user_id = ?');
    $stmt->execute([$uid]);
    $row = $stmt->fetch();
    return $row ?: null;
}

function requireAuth(): array {
    $u = currentUser();
    if (!$u) errorResponse('Unauthorized', 401);
    return $u;
}

function requireAdmin(): array {
    $u = requireAuth();
    if (($u['role'] ?? 'customer') !== 'admin') errorResponse('Forbidden', 403);
    return $u;
}

function ensureUploadsDir(): void {
    global $CONFIG;
    $dir = $CONFIG['uploads']['dir'];
    if (!is_dir($dir)) {
        @mkdir($dir, 0777, true);
    }
}

function saveUploadedImage(array $file): ?string {
    global $CONFIG;
    ensureUploadsDir();
    if (($file['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) return null;
    if (($file['size'] ?? 0) > $CONFIG['uploads']['max_size_bytes']) errorResponse('File too large', 413);
    $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    if (!in_array($ext, $CONFIG['uploads']['allowed_exts'], true)) errorResponse('Invalid file type', 415);
    $name = uniqid('img_', true) . '.' . $ext;
    $dest = $CONFIG['uploads']['dir'] . DIRECTORY_SEPARATOR . $name;
    if (!move_uploaded_file($file['tmp_name'], $dest)) errorResponse('Failed to save image', 500);
    return $CONFIG['uploads']['base_path'] . '/' . $name;
}
