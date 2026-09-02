<?php
require_once __DIR__ . '/config/env.php';

return [
    'db' => [
        'host' => Env::get('DB_HOST', 'localhost'),
        'port' => Env::get('DB_PORT', '3306'),
        'name' => Env::get('DB_NAME', 'electrobd'),
        'user' => Env::get('DB_USER', 'root'),
        'pass' => Env::get('DB_PASSWORD', ''),
        'charset' => 'utf8mb4',
    ],
    'auth' => [
        'jwt_secret' => Env::get('JWT_SECRET', 'CHANGE_THIS_SECRET_KEY_IN_PRODUCTION'),
        'jwt_issuer' => 'electrocitybd',
        'jwt_ttl_seconds' => 60 * 60 * 24 * 7, // 7 days
    ],
    'uploads' => [
        'dir' => __DIR__ . '/public/uploads',
        'base_path' => '/api/public/uploads',
        'max_size_bytes' => (int)Env::get('MAX_FILE_SIZE', 5 * 1024 * 1024), // 5MB default
        'allowed_exts' => explode(',', Env::get('ALLOWED_IMAGE_TYPES', 'jpg,jpeg,png,webp')),
        'max_width' => (int)Env::get('MAX_IMAGE_WIDTH', 2000),
        'max_height' => (int)Env::get('MAX_IMAGE_HEIGHT', 2000),
    ],
    'mail' => [
        'host' => Env::get('SMTP_HOST', Env::get('MAIL_HOST', 'smtp.gmail.com')),
        'port' => (int)Env::get('SMTP_PORT', Env::get('MAIL_PORT', 587)),
        'username' => Env::get('SMTP_USERNAME', Env::get('MAIL_USERNAME', '')),
        'password' => Env::get('SMTP_PASSWORD', Env::get('MAIL_PASSWORD', '')),
        'from_address' => Env::get('MAIL_FROM_ADDRESS', 'noreply@electrocitybd.com'),
        'from_name' => Env::get('MAIL_FROM_NAME', 'ElectrocityBD'),
        'encryption' => Env::get('SMTP_SECURE', 'tls'),
    ],
    'security' => [
        'rate_limit_requests' => (int)Env::get('RATE_LIMIT_REQUESTS', 100),
        'rate_limit_window' => (int)Env::get('RATE_LIMIT_WINDOW', 60), // seconds
        'max_login_attempts' => (int)Env::get('MAX_LOGIN_ATTEMPTS', 5),
        'login_lockout_time' => (int)Env::get('LOGIN_LOCKOUT_TIME', 900), // 15 minutes
    ],
    'app' => [
        'env' => Env::get('APP_ENV', 'development'),
        'debug' => Env::get('APP_DEBUG', 'true') === 'true',
        'url' => Env::get('APP_URL', 'http://localhost:8000'),
    ],
];

