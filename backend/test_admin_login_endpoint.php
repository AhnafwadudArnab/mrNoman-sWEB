<?php
require_once __DIR__ . '/api/bootstrap.php';
require_once __DIR__ . '/util/JWT.php';

echo "=== Testing Admin Login Endpoint ===\n\n";

// Test credentials
$test_cases = [
    [
        'name' => 'Valid Admin #1',
        'email' => 'adminNoman@electrozonebd.com',
        'password' => 'ElectroAdmin@2026'
    ],
    [
        'name' => 'Valid Admin #2',
        'email' => 'superadmin_roz@electrozonebd.com',
        'password' => 'ZoneAdmin@2026'
    ],
    [
        'name' => 'Wrong Password',
        'email' => 'adminNoman@electrozonebd.com',
        'password' => 'WrongPassword123'
    ]
];

$db = db();

foreach ($test_cases as $test) {
    echo "Test: {$test['name']}\n";
    echo "  Email: {$test['email']}\n";
    echo "  Password: {$test['password']}\n";
    
    // Step 1: Query for user
    $normalizedUsername = strtolower(trim($test['email']));
    $compactUsername = str_replace(' ', '', $normalizedUsername);
    
    $query = "SELECT user_id, full_name, last_name, email, password, phone_number, address, gender, role
              FROM users
              WHERE LOWER(role) = 'admin'
                  AND (
                      LOWER(email) = :login_email
                      OR LOWER(full_name) = :login_full_name
                      OR LOWER(REPLACE(full_name, ' ', '')) = :login_compact_name
                  )
              LIMIT 1";
    
    $stmt = $db->prepare($query);
    $stmt->bindParam(':login_email', $normalizedUsername);
    $stmt->bindParam(':login_full_name', $normalizedUsername);
    $stmt->bindParam(':login_compact_name', $compactUsername);
    $stmt->execute();
    
    if ($stmt->rowCount() === 0) {
        echo "  Result: ❌ User not found\n\n";
        continue;
    }
    
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    echo "  ✅ User found: {$user['full_name']} {$user['last_name']}\n";
    
    // Step 2: Verify password
    $passwordOk = password_verify($test['password'], $user['password']) || hash_equals((string)$user['password'], (string)$test['password']);
    
    if (!$passwordOk) {
        echo "  Result: ❌ Password verification failed\n";
        echo "    Hash in DB: " . substr($user['password'], 0, 20) . "...\n";
        echo "    password_verify: " . (password_verify($test['password'], $user['password']) ? 'true' : 'false') . "\n";
        echo "    hash_equals: " . (hash_equals((string)$user['password'], (string)$test['password']) ? 'true' : 'false') . "\n\n";
        continue;
    }
    
    echo "  ✅ Password verified\n";
    
    // Step 3: Generate token
    try {
        $token = JWT::generate([
            'user_id' => (int)$user['user_id'],
            'email' => $user['email'],
            'role' => $user['role'],
            'exp' => time() + (7 * 24 * 60 * 60)
        ]);
        
        echo "  ✅ Token generated: " . substr($token, 0, 30) . "...\n";
        echo "  Result: ✅ LOGIN SUCCESS\n\n";
    } catch (Exception $e) {
        echo "  ❌ Token generation failed: " . $e->getMessage() . "\n\n";
    }
}

echo "\n=== End of Test ===\n";
?>
