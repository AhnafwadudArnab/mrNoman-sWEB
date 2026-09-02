<?php
// DB Connection Debug Tool
// Upload to: electrozonebd.com/backend/public/dbcheck.php
// Then visit: https://electrozonebd.com/api/dbcheck.php

header('Content-Type: application/json');

// Check all possible .env locations
$possiblePaths = [
    __DIR__ . '/../.env',           // backend/.env  ← correct
    __DIR__ . '/../../.env',        // root/.env
    __DIR__ . '/.env',              // backend/public/.env
    '/home/asiment1/electrozonebd.com/backend/.env',   // absolute
    '/home/asiment1/electrozonebd.com/.env',           // absolute root
];

$pathsChecked = [];
foreach ($possiblePaths as $p) {
    $pathsChecked[$p] = file_exists($p) ? 'EXISTS ✅' : 'NOT FOUND ❌';
}

// Read .env file — try each path
$envPath = null;
foreach ($possiblePaths as $p) {
    if (file_exists($p)) { $envPath = $p; break; }
}

$envData = [];

if ($envPath && file_exists($envPath)) {
    $lines = file($envPath, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        if (strpos(trim($line), '#') === 0) continue;
        if (strpos($line, '=') !== false) {
            list($key, $val) = explode('=', $line, 2);
            $envData[trim($key)] = trim($val);
        }
    }
    $envFound = true;
} else {
    $envFound = false;
}

$host = $envData['DB_HOST'] ?? 'localhost';
$dbname = $envData['DB_NAME'] ?? '';
$user = $envData['DB_USER'] ?? '';
$pass = $envData['DB_PASSWORD'] ?? '';
$port = $envData['DB_PORT'] ?? '3306';

// Try connection
$error = null;
$connected = false;
$tables = [];

try {
    $dsn = "mysql:host=$host;port=$port;dbname=$dbname;charset=utf8mb4";
    $pdo = new PDO($dsn, $user, $pass, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
    $connected = true;
    $stmt = $pdo->query("SHOW TABLES");
    $tables = $stmt->fetchAll(PDO::FETCH_COLUMN);
} catch (Exception $e) {
    $error = $e->getMessage();
}

echo json_encode([
    'paths_checked' => $pathsChecked,
    'env_file_found' => $envFound,
    'env_path_used' => $envPath,
    'db_host' => $host,
    'db_name' => $dbname,
    'db_user' => $user,
    'db_pass_length' => strlen($pass),
    'db_port' => $port,
    'connected' => $connected,
    'error' => $error,
    'tables_count' => count($tables),
    'sample_tables' => array_slice($tables, 0, 5),
], JSON_PRETTY_PRINT);
