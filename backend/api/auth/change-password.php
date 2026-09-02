<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../bootstrap.php';
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../middleware/authmiddleware.php';
$method = $_SERVER['REQUEST_METHOD'];
if ($method !== 'PUT') {
    http_response_code(405);
    echo json_encode(['message' => 'Method not allowed']);
    exit;
}

$u = AuthMiddleware::authenticate();
$data = getJsonBody();
$current = $data['currentPassword'] ?? '';
$new = $data['newPassword'] ?? '';
if ($current === '' || $new === '') {
    http_response_code(400);
    echo json_encode(['message' => 'currentPassword and newPassword required']);
    exit;
}

$db = db();
$stmt = $db->prepare('SELECT password FROM users WHERE user_id = ?');
$stmt->execute([$u['user_id']]);
$row = $stmt->fetch();
if (
    !$row ||
    (
        $current !== $row['password'] &&
        !password_verify($current, $row['password'])
    )
) {
    http_response_code(401);
    echo json_encode(['message' => 'Invalid current password']);
    exit;
}

$upd = $db->prepare('UPDATE users SET password = ? WHERE user_id = ?');
$upd->execute([password_hash($new, PASSWORD_BCRYPT), $u['user_id']]);
echo json_encode(['message' => 'Password changed']);
?>
