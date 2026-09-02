<?php
declare(strict_types=1);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

require_once __DIR__ . '/db_connection.php';

function jsonError(int $statusCode, string $message): void
{
    http_response_code($statusCode);
    echo json_encode(['success' => false, 'message' => $message]);
    exit;
}

try {
    $payload = json_decode(file_get_contents('php://input') ?: '', true);

    if (!is_array($payload)) {
        jsonError(400, 'Invalid JSON body');
    }

    $token = trim((string)($payload['token'] ?? ''));
    $newPassword = (string)($payload['new_password'] ?? '');

    if ($token === '' || $newPassword === '') {
        jsonError(422, 'token and new_password are required');
    }

    if (strlen($newPassword) < 8) {
        jsonError(422, 'new_password must be at least 8 characters');
    }

    $pdo = getDatabaseConnection();

    // Remove expired tokens first as a security cleanup.
    $expiredCleanup = $pdo->prepare('DELETE FROM password_resets WHERE expires_at <= NOW()');
    $expiredCleanup->execute();

    // Security: prepared statement prevents SQL injection.
    $tokenStmt = $pdo->prepare('SELECT email, expires_at FROM password_resets WHERE token = :token LIMIT 1');
    $tokenStmt->execute([':token' => $token]);
    $resetRow = $tokenStmt->fetch();

    if (!$resetRow) {
        jsonError(400, 'Invalid or expired token');
    }

    if (strtotime((string)$resetRow['expires_at']) < time()) {
        $deleteExpiredToken = $pdo->prepare('DELETE FROM password_resets WHERE token = :token');
        $deleteExpiredToken->execute([':token' => $token]);
        jsonError(400, 'Invalid or expired token');
    }

    $email = (string)$resetRow['email'];

    // Fetch existing hash so password_verify() can be used securely.
    $currentPasswordStmt = $pdo->prepare('SELECT password FROM users WHERE email = :email LIMIT 1');
    $currentPasswordStmt->execute([':email' => $email]);
    $userRow = $currentPasswordStmt->fetch();

    if (!$userRow) {
        jsonError(404, 'User account not found');
    }

    // Security: use password_verify() to prevent reusing the same password.
    if (password_verify($newPassword, (string)$userRow['password'])) {
        jsonError(422, 'New password must be different from current password');
    }

    // Security: password_hash() stores only a strong one-way hash.
    $newPasswordHash = password_hash($newPassword, PASSWORD_DEFAULT);
    if ($newPasswordHash === false) {
        jsonError(500, 'Failed to secure password');
    }

    $pdo->beginTransaction();

    $updateUserStmt = $pdo->prepare('UPDATE users SET password = :password WHERE email = :email');
    $updateUserStmt->execute([
        ':password' => $newPasswordHash,
        ':email' => $email,
    ]);

    // Security: always delete used token after successful reset.
    $deleteTokenStmt = $pdo->prepare('DELETE FROM password_resets WHERE token = :token');
    $deleteTokenStmt->execute([':token' => $token]);

    $pdo->commit();

    http_response_code(200);
    echo json_encode(['success' => true, 'message' => 'Password updated']);
} catch (RuntimeException $runtimeException) {
    jsonError(500, 'Server configuration error');
} catch (Throwable $throwable) {
    if (isset($pdo) && $pdo instanceof PDO && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    jsonError(500, 'Internal server error');
}
