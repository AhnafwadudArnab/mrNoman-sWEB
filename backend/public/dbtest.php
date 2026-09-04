<?php
// This file is disabled in production.
// Remove or rename this file after verifying your deployment.
require_once __DIR__ . '/../config/env.php';

if (Env::get('APP_ENV') !== 'development') {
    http_response_code(404);
    echo json_encode(['message' => 'Not found']);
    exit;
}

echo "<h3>Path Debug + DB Test (DEV ONLY)</h3>";

$candidates = [
    __DIR__ . '/../.env',
    dirname(__DIR__, 2) . '/.env',
    dirname(__DIR__, 3) . '/.env',
    getcwd() . '/.env',
];
echo "<b>Looking for .env in:</b><br>";
foreach ($candidates as $c) {
    $real = realpath($c) ?: $c;
    echo ($real && file_exists($real) ? "✅" : "❌") . " $real<br>";
}

echo "<br><b>__DIR__:</b> " . __DIR__ . "<br>";
echo "<b>getcwd():</b> " . getcwd() . "<br><br>";

$dbHost = Env::get('DB_HOST');
$dbName = Env::get('DB_NAME');
$dbUser = Env::get('DB_USER');
echo "<b>Env loaded - DB_HOST:</b> " . ($dbHost ?: '(empty)') . "<br>";
echo "<b>DB_NAME:</b> " . ($dbName ?: '(empty)') . "<br>";
echo "<b>DB_USER:</b> " . ($dbUser ?: '(empty)') . "<br><br>";

try {
    $pdo = new PDO(
        "mysql:host={$dbHost};dbname={$dbName};charset=utf8mb4",
        $dbUser,
        Env::get('DB_PASSWORD'),
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
    echo "<b style='color:green'>✅ DB Connected!</b><br>";
    $count = $pdo->query("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='{$dbName}'")->fetchColumn();
    echo "Tables: " . $count;
} catch (PDOException $e) {
    echo "<b style='color:red'>❌ " . htmlspecialchars($e->getMessage()) . "</b>";
}
