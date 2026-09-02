<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../bootstrap.php';
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../util/JWT.php';

$db = db();

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);
    
    $firstName = $data['firstName'] ?? '';
    $lastName = $data['lastName'] ?? '';
    $email = $data['email'] ?? '';
    $password = $data['password'] ?? '';
    $phone = $data['phone'] ?? '';
    $gender = $data['gender'] ?? 'Male';
    
    if (empty($firstName) || empty($email) || empty($password)) {
        http_response_code(400);
        echo json_encode(['message' => 'First name, email and password required']);
        exit;
    }
    
    // Check if email exists
    $checkQuery = "SELECT user_id FROM users WHERE email = :email";
    $checkStmt = $db->prepare($checkQuery);
    $checkStmt->bindParam(':email', $email);
    $checkStmt->execute();
    
    if ($checkStmt->rowCount() > 0) {
        http_response_code(400);
        echo json_encode(['message' => 'Email already exists']);
        exit;
    }
    
    // Hash password
    $hashedPassword = password_hash($password, PASSWORD_BCRYPT);
    
    // Insert user
    $query = "INSERT INTO users (full_name, last_name, email, password, phone_number, gender, role) 
              VALUES (:full_name, :last_name, :email, :password, :phone, :gender, 'customer')";
    
    $stmt = $db->prepare($query);
    $stmt->bindParam(':full_name', $firstName);
    $stmt->bindParam(':last_name', $lastName);
    $stmt->bindParam(':email', $email);
    $stmt->bindParam(':password', $hashedPassword);
    $stmt->bindParam(':phone', $phone);
    $stmt->bindParam(':gender', $gender);
    
    if ($stmt->execute()) {
        $userId = $db->lastInsertId();
        
        $profileQuery = "INSERT INTO user_profile (user_id, full_name, last_name, phone_number, gender) 
                         VALUES (:user_id, :full_name, :last_name, :phone, :gender)";
        $profileStmt = $db->prepare($profileQuery);
        $profileStmt->bindParam(':user_id', $userId);
        $profileStmt->bindParam(':full_name', $firstName);
        $profileStmt->bindParam(':last_name', $lastName);
        $profileStmt->bindParam(':phone', $phone);
        $profileStmt->bindParam(':gender', $gender);
        $profileStmt->execute();
        
        $token = JWT::generate([
            'user_id' => (int)$userId,
            'email' => $email,
            'role' => 'customer',
            'exp' => time() + (7 * 24 * 60 * 60)
        ]);
        
        echo json_encode([
            'token' => $token,
            'user' => [
                'user_id' => $userId,
                'firstName' => $firstName,
                'lastName' => $lastName,
                'email' => $email,
                'phone' => $phone,
                'gender' => $gender,
                'role' => 'customer'
            ]
        ]);
    } else {
        http_response_code(500);
        echo json_encode(['message' => 'Registration failed']);
    }
    
} else {
    http_response_code(405);
    echo json_encode(['message' => 'Method not allowed']);
}
?>
