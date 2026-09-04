<?php
/**
 * Local Test Script — ElectroZoneBD
 * Access: http://localhost:8080/test_local.php
 * Tests: DB connection, site_settings save/load, admin login
 */
header('Content-Type: text/html; charset=utf-8');
ini_set('display_errors', '1');
error_reporting(E_ALL);

require_once __DIR__ . '/../api/bootstrap.php';

$results = [];

// ── 1. DB Connection ──────────────────────────────────────────
try {
    $db = db();
    $results[] = ['✅', 'DB Connection', 'Connected to MySQL successfully'];
} catch (Throwable $e) {
    $results[] = ['❌', 'DB Connection', $e->getMessage()];
}

// ── 2. site_settings table ────────────────────────────────────
try {
    $db = db();
    $db->exec("CREATE TABLE IF NOT EXISTS site_settings (
        id INT AUTO_INCREMENT PRIMARY KEY,
        setting_key VARCHAR(100) UNIQUE NOT NULL,
        setting_value TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
    $results[] = ['✅', 'site_settings table', 'Table exists / created'];
} catch (Throwable $e) {
    $results[] = ['❌', 'site_settings table', $e->getMessage()];
}

// ── 3. Save WhatsApp number ───────────────────────────────────
try {
    $db = db();
    $stmt = $db->prepare("INSERT INTO site_settings (setting_key, setting_value)
        VALUES (?, ?) ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)");
    $stmt->execute(['support_whatsapp_number', '8801712345678']);
    $results[] = ['✅', 'Save WhatsApp number', 'Saved: 8801712345678'];
} catch (Throwable $e) {
    $results[] = ['❌', 'Save WhatsApp number', $e->getMessage()];
}

// ── 4. Load WhatsApp number ───────────────────────────────────
try {
    $db = db();
    $stmt = $db->prepare("SELECT setting_value FROM site_settings WHERE setting_key = ?");
    $stmt->execute(['support_whatsapp_number']);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($row && $row['setting_value'] === '8801712345678') {
        $results[] = ['✅', 'Load WhatsApp number', 'Loaded: ' . $row['setting_value']];
    } else {
        $results[] = ['❌', 'Load WhatsApp number', 'Got: ' . json_encode($row)];
    }
} catch (Throwable $e) {
    $results[] = ['❌', 'Load WhatsApp number', $e->getMessage()];
}

// ── 5. users table ────────────────────────────────────────────
try {
    $db = db();
    $stmt = $db->query("SELECT COUNT(*) as cnt FROM users");
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    $results[] = ['✅', 'users table', 'Found ' . $row['cnt'] . ' users'];
} catch (Throwable $e) {
    $results[] = ['❌', 'users table', $e->getMessage()];
}

// ── 6. Admin user exists ──────────────────────────────────────
try {
    $db = db();
    $stmt = $db->query("SELECT email, role FROM users WHERE role = 'admin' LIMIT 1");
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($row) {
        $results[] = ['✅', 'Admin user', 'Found: ' . $row['email']];
    } else {
        $results[] = ['⚠️', 'Admin user', 'No admin user found — run seed SQL below'];
    }
} catch (Throwable $e) {
    $results[] = ['❌', 'Admin user', $e->getMessage()];
}

// ── 7. orders table ───────────────────────────────────────────
try {
    $db = db();
    $stmt = $db->query("SELECT COUNT(*) as cnt FROM orders");
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    $results[] = ['✅', 'orders table', 'Found ' . $row['cnt'] . ' orders'];
} catch (Throwable $e) {
    $results[] = ['❌', 'orders table', $e->getMessage()];
}

// ── 8. API endpoint test (site_settings GET) ──────────────────
$apiUrl = 'http://localhost:8080/api/site_settings?key=support_whatsapp_number';
try {
    $ctx = stream_context_create(['http' => ['timeout' => 3]]);
    $resp = @file_get_contents($apiUrl, false, $ctx);
    if ($resp !== false) {
        $json = json_decode($resp, true);
        if (isset($json['setting_value'])) {
            $results[] = ['✅', 'API GET site_settings', 'setting_value = ' . $json['setting_value']];
        } else {
            $results[] = ['⚠️', 'API GET site_settings', 'Response: ' . $resp];
        }
    } else {
        $results[] = ['⚠️', 'API GET site_settings', 'Could not reach API (server may not be running on 8080)'];
    }
} catch (Throwable $e) {
    $results[] = ['⚠️', 'API GET site_settings', $e->getMessage()];
}

?>
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>ElectroZoneBD — Local Test</title>
<style>
  body { font-family: monospace; background: #0b121e; color: #eee; padding: 30px; }
  h1 { color: #f59e0b; }
  table { border-collapse: collapse; width: 100%; margin-top: 20px; }
  th { background: #1e2a3a; color: #f59e0b; padding: 10px 16px; text-align: left; }
  td { padding: 10px 16px; border-bottom: 1px solid #1e2a3a; }
  tr:hover td { background: #1a2535; }
  .pass { color: #4ade80; }
  .fail { color: #f87171; }
  .warn { color: #fbbf24; }
  pre { background: #1e2a3a; padding: 16px; border-radius: 8px; color: #86efac; overflow-x: auto; }
  h2 { color: #f59e0b; margin-top: 40px; }
</style>
</head>
<body>
<h1>🔧 ElectroZoneBD — Local Test Results</h1>
<table>
  <tr><th>Status</th><th>Test</th><th>Result</th></tr>
  <?php foreach ($results as [$icon, $name, $msg]): ?>
  <tr>
    <td><?= $icon ?></td>
    <td><?= htmlspecialchars($name) ?></td>
    <td><?= htmlspecialchars($msg) ?></td>
  </tr>
  <?php endforeach; ?>
</table>

<h2>📋 Quick Setup (if tests fail)</h2>
<pre>
-- 1. Create DB (run in phpMyAdmin or MySQL CLI)
CREATE DATABASE IF NOT EXISTS electrobd CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 2. Import schema
-- phpMyAdmin → electrobd → Import → database_schema.sql

-- 3. Create admin user (password: admin123)
INSERT INTO users (full_name, email, password, role)
VALUES ('Admin', 'admin@electrobd.com',
  '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin')
ON DUPLICATE KEY UPDATE role='admin';
</pre>

<h2>🚀 Start PHP Server</h2>
<pre>cd <?= htmlspecialchars(dirname(__DIR__)) ?>

php -S 0.0.0.0:8080 -t public router.php</pre>

<h2>📱 Flutter Run</h2>
<pre>flutter run</pre>
<p style="color:#94a3b8">Android emulator automatically uses 10.0.2.2:8080 → your localhost:8080</p>
</body>
</html>
