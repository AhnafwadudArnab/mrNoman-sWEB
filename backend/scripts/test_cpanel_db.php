<?php
$host = 'electrozonebd.com';
$port = 3306;
$db   = 'asiment3_zone_electrobd';
$user = 'asiment3_zone_electrobd';
$pass = 'YeR=zPWV5.L#Iv7M';

echo "1. Resolving hostname {$host}...\n";
$ip = gethostbyname($host);
echo "   IP: {$ip}\n";

echo "2. Testing TCP port {$port} on {$ip}...\n";
$connection = @fsockopen($ip, $port, $errno, $errstr, 5);
if (is_resource($connection)) {
    echo "   [SUCCESS] TCP port {$port} is open and reachable!\n";
    fclose($connection);
    
    echo "3. Attempting PDO MySQL connection...\n";
    try {
        $dsn = "mysql:host={$host};port={$port};dbname={$db};charset=utf8mb4";
        $pdo = new PDO($dsn, $user, $pass, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_TIMEOUT => 5
        ]);
        echo "   [SUCCESS] Connected to cPanel MySQL successfully!\n";
        
        $tables = $pdo->query("SHOW TABLES")->fetchAll(PDO::FETCH_COLUMN);
        echo "   Found " . count($tables) . " tables in `{$db}`:\n";
        foreach ($tables as $t) {
            echo "    - $t\n";
        }
    } catch (PDOException $e) {
        echo "   [PDO ERROR] " . $e->getMessage() . "\n";
    }
} else {
    echo "   [BLOCKED/CLOSED] Could not connect to {$host}:{$port} ($errno: $errstr)\n";
    echo "   Note: Most cPanel hosts block external remote MySQL port 3306 by default unless enabled in cPanel -> 'Remote MySQL'.\n";
}
