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
    
    echo "=== Testing Admin Login Simulation ===\n\n";
    
    // Test credentials
    $test_cases = [
        ['email' => 'adminNoman@electrozonebd.com', 'password' => 'ElectroAdmin@2026', 'expected' => 'PASS'],
        ['email' => 'superadmin_roz@electrozonebd.com', 'password' => 'ZoneAdmin@2026', 'expected' => 'PASS'],
        ['email' => 'superadmin@ez.com', 'password' => 'ZoneAdmin@2078', 'expected' => 'PASS'],
        ['email' => 'adminNoman@electrozonebd.com', 'password' => 'WrongPassword', 'expected' => 'FAIL'],
        ['email' => 'nonexistent@example.com', 'password' => 'AnyPassword', 'expected' => 'FAIL'],
    ];
    
    foreach ($test_cases as $test) {
        echo "Test: {$test['email']} / {$test['password']}\n";
        
        // Step 1: Find admin user
        $query = "SELECT user_id, full_name, last_name, email, password, phone_number, gender, role
                  FROM users
                  WHERE role = 'admin' AND LOWER(email) = LOWER(?)
                  LIMIT 1";
        
        $stmt = $pdo->prepare($query);
        $stmt->execute([$test['email']]);
        
        if ($stmt->rowCount() === 0) {
            echo "  Result: ❌ FAIL - User not found\n";
            echo "  Expected: {$test['expected']}\n\n";
            continue;
        }
        
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        
        // Step 2: Verify password
        $passwordOk = password_verify($test['password'], $user['password']);
        
        if (!$passwordOk) {
            echo "  Result: ❌ FAIL - Invalid password\n";
            echo "  Expected: {$test['expected']}\n\n";
            continue;
        }
        
        echo "  Result: ✅ PASS - Login successful\n";
        echo "  User: {$user['full_name']} {$user['last_name']}\n";
        echo "  Email: {$user['email']}\n";
        echo "  Expected: {$test['expected']}\n\n";
    }
    
} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage();
    exit(1);
}
?>
