<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../bootstrap.php';
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../middleware/authmiddleware.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $payload = AuthMiddleware::authenticate();
    $stmt = db()->prepare('SELECT user_id, full_name, last_name, email, phone_number, gender, role FROM users WHERE user_id = ?');
    $stmt->execute([(int)$payload['user_id']]);
    $u = $stmt->fetch();
    echo json_encode([
        'user_id' => $u['user_id'] ?? (int)$payload['user_id'],
        'firstName' => $u['full_name'] ?? '',
        'lastName' => $u['last_name'] ?? '',
        'email' => $u['email'] ?? ($payload['email'] ?? ''),
        'phone' => $u['phone_number'] ?? '',
        'gender' => $u['gender'] ?? 'Male',
        'role' => $u['role'] ?? ($payload['role'] ?? 'customer'),
    ]);
    exit;
}

if ($method === 'PUT') {
    $payload = AuthMiddleware::authenticate();
    $stmt0 = db()->prepare('SELECT user_id, full_name, last_name, email, phone_number, gender, role, address FROM users WHERE user_id = ?');
    $stmt0->execute([(int)$payload['user_id']]);
    $u = $stmt0->fetch();
    $data = getJsonBody();
    $db = db();

    $firstName = $data['firstName'] ?? $data['full_name'] ?? $u['full_name'];
    $lastName = $data['lastName'] ?? $data['last_name'] ?? $u['last_name'];
    $phone = $data['phone'] ?? $data['phone_number'] ?? $u['phone_number'];
    $address = $data['address'] ?? ($u['address'] ?? '');
    $gender = $data['gender'] ?? $u['gender'];

    $stmt = $db->prepare('UPDATE users SET full_name = ?, last_name = ?, phone_number = ?, address = ?, gender = ? WHERE user_id = ?');
    $stmt->execute([$firstName, $lastName, $phone, $address, $gender, $u['user_id']]);

    $stmt2 = $db->prepare('UPDATE user_profile SET full_name = ?, last_name = ?, phone_number = ?, address = ?, gender = ? WHERE user_id = ?');
    $stmt2->execute([$firstName, $lastName, $phone, $address, $gender, $u['user_id']]);

    $stmt3 = $db->prepare('SELECT user_id, full_name, last_name, email, phone_number, gender, role FROM users WHERE user_id = ?');
    $stmt3->execute([$u['user_id']]);
    $row = $stmt3->fetch();
    echo json_encode([
        'user_id' => $row['user_id'],
        'firstName' => $row['full_name'],
        'lastName' => $row['last_name'],
        'email' => $row['email'],
        'phone' => $row['phone_number'],
        'gender' => $row['gender'],
        'role' => $row['role'],
    ]);
    exit;
}

http_response_code(405);
echo json_encode(['message' => 'Method not allowed']);
?>
