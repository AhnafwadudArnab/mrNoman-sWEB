<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../../bootstrap.php';
require_once __DIR__ . '/../../../config/cors.php';
require_once __DIR__ . '/../../../util/JWT.php';

$db = db();

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);
    
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
?>
