<?php
// ⚠️ DELETE THIS FILE AFTER TESTING!

$host = 'localhost';
$db   = 'asiment1_electrobd';
$user = 'asiment1_electrobd001';
$pass = 'iV6d6az0fD5Ft';
?>
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>DB Test</title>
<style>
  body { font-family: monospace; padding: 30px; background: #111; color: #eee; }
  .ok  { color: #4caf50; font-size: 1.3em; }
  .err { color: #f44336; font-size: 1.3em; }
  table { border-collapse: collapse; margin-top: 20px; }
  td { padding: 6px 16px; border: 1px solid #333; }
  td:first-child { color: #aaa; }
</style>
</head>
<body>
<h2>ElectroZoneBD — DB Connection Test</h2>

<?php
try {
    $pdo = new PDO("mysql:host=$host;dbname=$db;charset=utf8mb4", $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
    ]);

    $tables   = $pdo->query("SHOW TABLES")->fetchAll(PDO::FETCH_COLUMN);
    $userCount = $pdo->query("SELECT COUNT(*) FROM users")->fetchColumn();
    $prodCount = $pdo->query("SELECT COUNT(*) FROM products")->fetchColumn();

    echo '<p class="ok">✅ Database Connected!</p>';
    echo '<table>';
    echo "<tr><td>PHP Version</td><td>" . phpversion() . "</td></tr>";
    echo "<tr><td>Database</td><td>$db</td></tr>";
    echo "<tr><td>User</td><td>$user</td></tr>";
    echo "<tr><td>Tables found</td><td>" . count($tables) . "</td></tr>";
    echo "<tr><td>Users</td><td>$userCount</td></tr>";
    echo "<tr><td>Products</td><td>$prodCount</td></tr>";
    echo '</table>';

} catch (Exception $e) {
    echo '<p class="err">❌ Connection Failed!</p>';
    echo '<table>';
    echo "<tr><td>Error</td><td>" . htmlspecialchars($e->getMessage()) . "</td></tr>";
    echo "<tr><td>Database</td><td>$db</td></tr>";
    echo "<tr><td>User</td><td>$user</td></tr>";
    echo "<tr><td>PHP Version</td><td>" . phpversion() . "</td></tr>";
    echo '</table>';
}
?>
<p style="color:#f44336; margin-top:30px">⚠️ DELETE this file after testing!</p>
</body>
</html>
