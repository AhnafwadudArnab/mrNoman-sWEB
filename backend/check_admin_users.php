<?php
require_once __DIR__ . '/config/env.php';

$db_host = getenv('DB_HOST') ?: 'localhost';
$db_name = getenv('DB_NAME') ?: 'electrobd';
$db_user = getenv('DB_USER') ?: 'root';
$db_port = getenv('DB_PORT') ?: '3306';
$db_pass = getenv('DB_PASSWORD') ?: '';

try {
    $dsn = "mysql:host=$db_host;port=$db_port;dbname=$db_name;charset=utf8mb4";
    $pdo = new PDO($dsn, $db_user, $db_pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    ]);
    
    echo "=== Checking Admin Users in Database ===\n\n";
    
    // Check all users with role='admin'
    echo "1. ALL ADMIN USERS:\n";
    $stmt = $pdo->query("SELECT user_id, full_name, last_name, email, role, password FROM users WHERE role = 'admin'");
    $admins = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (empty($admins)) {
        echo "❌ NO ADMIN USERS FOUND!\n\n";
    } else {
        echo "✅ Found " . count($admins) . " admin user(s):\n\n";
        foreach ($admins as $admin) {
            echo "- ID: {$admin['user_id']}\n";
            echo "  Name: {$admin['full_name']} {$admin['last_name']}\n";
            echo "  Email: {$admin['email']}\n";
            echo "  Role: {$admin['role']}\n";
            echo "  Password Hash: " . substr($admin['password'], 0, 30) . "...\n";
            echo "  Hash Type: " . (strpos($admin['password'], '$2b$') === 0 ? 'Bcrypt' : 'Other') . "\n\n";
        }
    }
    
    // Expected admin credentials
    echo "2. EXPECTED ADMIN CREDENTIALS:\n";
    $expected = [
        ['email' => 'adminNoman@electrozonebd.com', 'password' => 'ElectroAdmin@2026'],
        ['email' => 'superadmin_roz@electrozonebd.com', 'password' => 'ZoneAdmin@2026'],
        ['email' => 'superadmin@ez.com', 'password' => 'ZoneAdmin@2078']
    ];
    
    foreach ($expected as $exp) {
        $stmt = $pdo->prepare("SELECT user_id, email, role FROM users WHERE email = ? AND role = 'admin'");
        $stmt->execute([$exp['email']]);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($result) {
            echo "✅ {$exp['email']}\n";
            echo "   Password: {$exp['password']}\n";
        } else {
            echo "❌ {$exp['email']} - NOT FOUND\n";
            echo "   Password: {$exp['password']}\n";
        }
    }
    
    // Test password verification
    echo "\n3. PASSWORD VERIFICATION TEST:\n";
    if (!empty($admins)) {
        $admin = $admins[0];
        $test_password = 'ElectroAdmin@2026'; // Try first expected password
        
        echo "Testing with: " . $admin['email'] . "\n";
        echo "Hash: " . $admin['password'] . "\n";
        echo "Testing password: $test_password\n";
        
        $valid = password_verify($test_password, $admin['password']);
        echo "Result: " . ($valid ? '✅ VALID' : '❌ INVALID') . "\n\n";
    }
    
    // Check users table structure
    echo "4. USERS TABLE STRUCTURE:\n";
    $columns = $pdo->query("DESCRIBE users")->fetchAll(PDO::FETCH_ASSOC);
    foreach ($columns as $col) {
        echo "  {$col['Field']}: {$col['Type']}\n";
    }
    
} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage();
    exit(1);
}
?>
