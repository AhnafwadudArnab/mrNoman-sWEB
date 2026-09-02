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
    
    echo "=== Fixing Admin User Passwords ===\n\n";
    
    // Admin credentials to set
    $admins = [
        [
            'full_name' => 'Admin',
            'last_name' => 'ElectroZone',
            'email' => 'adminNoman@electrozonebd.com',
            'password' => 'ElectroAdmin@2026',
            'phone' => '01700000001'
        ],
        [
            'full_name' => 'Super',
            'last_name' => 'Admin',
            'email' => 'superadmin_roz@electrozonebd.com',
            'password' => 'ZoneAdmin@2026',
            'phone' => '01700000002'
        ],
        [
            'full_name' => 'Super',
            'last_name' => 'Admin',
            'email' => 'superadmin@ez.com',
            'password' => 'ZoneAdmin@2078',
            'phone' => '01700000003'
        ]
    ];
    
    echo "Generating bcrypt hashes with cost factor 12...\n\n";
    
    foreach ($admins as $admin) {
        $hash = password_hash($admin['password'], PASSWORD_BCRYPT, ['cost' => 12]);
        
        echo "Admin: {$admin['email']}\n";
        echo "  Password: {$admin['password']}\n";
        echo "  Hash: $hash\n";
        
        // Update or insert the admin user
        $stmt = $pdo->prepare("
            INSERT INTO users (full_name, last_name, email, password, phone_number, gender, role)
            VALUES (?, ?, ?, ?, ?, 'Male', 'admin')
            ON DUPLICATE KEY UPDATE
                password = ?,
                full_name = ?,
                last_name = ?,
                phone_number = ?,
                role = 'admin'
        ");
        
        $stmt->execute([
            $admin['full_name'],
            $admin['last_name'],
            $admin['email'],
            $hash,
            $admin['phone'],
            // Duplicate key update values
            $hash,
            $admin['full_name'],
            $admin['last_name'],
            $admin['phone']
        ]);
        
        echo "  ✅ Updated/Inserted\n\n";
    }
    
    // Verify the passwords now work
    echo "=== VERIFICATION ===\n\n";
    
    foreach ($admins as $admin) {
        $stmt = $pdo->prepare("SELECT password FROM users WHERE email = ? AND role = 'admin'");
        $stmt->execute([$admin['email']]);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($result) {
            $valid = password_verify($admin['password'], $result['password']);
            echo "✅ {$admin['email']}: " . ($valid ? 'PASSWORD WORKS' : 'PASSWORD FAILED') . "\n";
        } else {
            echo "❌ {$admin['email']}: User not found\n";
        }
    }
    
} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage();
    exit(1);
}
?>
