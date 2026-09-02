<?php
/**
 * Test direct admin login - simulates what Flutter sends
 */

echo "=== Simulating Direct HTTP Admin Login ===\n\n";

// Simulate POST request
$_SERVER['REQUEST_METHOD'] = 'POST';
$_SERVER['CONTENT_TYPE'] = 'application/json';

// Test data
$test_data = [
    'username' => 'adminNoman@electrozonebd.com',
    'password' => 'ElectroAdmin@2026'
];

// Simulate input stream
$_SERVER['CONTENT'] = json_encode($test_data);

// Now run the actual endpoint
echo "Requesting: POST /api/auth/admin-login\n";
echo "Data: " . json_encode($test_data) . "\n\n";

// Start output buffering to capture the response
ob_start();

// Set up fake input stream
$fakeInput = fopen('php://memory', 'r+');
fwrite($fakeInput, json_encode($test_data));
rewind($fakeInput);

// Override file_get_contents temporarily
$oldGetContents = 'file_get_contents';

// Manually process the request
require_once __DIR__ . '/api/bootstrap.php';
require_once __DIR__ . '/util/JWT.php';
require_once __DIR__ . '/config/cors.php';

$db = db();
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'POST') {
    $data = $test_data;
    
    $username = $data['username'] ?? ($data['email'] ?? '');
    $password = $data['password'] ?? '';
    
    if (empty($username) || empty($password)) {
        http_response_code(400);
        echo json_encode(['message' => 'Username and password required']);
        exit;
    }
    
    $normalizedUsername = strtolower(trim($username));
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
        http_response_code(401);
        echo json_encode(['message' => 'Invalid admin credentials']);
        exit;
    }
    
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    $passwordOk = password_verify($password, $user['password']) || hash_equals((string)$user['password'], (string)$password);
    if (!$passwordOk) {
        http_response_code(401);
        echo json_encode(['message' => 'Invalid admin credentials']);
        exit;
    }

    if (!password_get_info((string)$user['password'])['algo']) {
        $rehash = $db->prepare('UPDATE users SET password = :password WHERE user_id = :user_id');
        $newHash = password_hash($password, PASSWORD_BCRYPT);
        $rehash->bindParam(':password', $newHash);
        $rehash->bindParam(':user_id', $user['user_id'], PDO::PARAM_INT);
        $rehash->execute();
    }
    
    $token = JWT::generate([
        'user_id' => (int)$user['user_id'],
        'email' => $user['email'],
        'role' => $user['role'],
        'exp' => time() + (7 * 24 * 60 * 60)
    ]);
    
    unset($user['password']);
    
    echo json_encode([
        'token' => $token,
        'user' => [
            'user_id' => $user['user_id'],
            'firstName' => $user['full_name'],
            'lastName' => $user['last_name'],
            'email' => $user['email'],
            'phone' => $user['phone_number'],
            'gender' => $user['gender'],
            'role' => $user['role']
        ]
    ]);
    
} else {
    http_response_code(405);
    echo json_encode(['message' => 'Method not allowed']);
}

// Get output
$response = ob_get_clean();

echo "Response:\n";
echo $response . "\n\n";

// Parse and display
$data = json_decode($response, true);
if ($data) {
    if (isset($data['token'])) {
        echo "✅ LOGIN SUCCESSFUL\n";
        echo "Token: " . substr($data['token'], 0, 40) . "...\n";
        echo "User: " . $data['user']['firstName'] . " " . $data['user']['lastName'] . "\n";
        echo "Email: " . $data['user']['email'] . "\n";
    } else {
        echo "❌ LOGIN FAILED\n";
        echo "Error: " . ($data['message'] ?? 'Unknown error') . "\n";
    }
}
?>
