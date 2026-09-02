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

// Use bootstrap for DB + env loading (same as all other endpoints)
require_once __DIR__ . '/bootstrap.php';
require_once __DIR__ . '/../vendor/autoload.php';

use PHPMailer\PHPMailer\Exception;
use PHPMailer\PHPMailer\PHPMailer;

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

    $email = strtolower(trim((string)($payload['email'] ?? '')));
    if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
        jsonError(422, 'Valid email is required');
    }

    $pdo = db();

    $userStmt = $pdo->prepare('SELECT user_id FROM users WHERE email = :email LIMIT 1');
    $userStmt->execute([':email' => $email]);
    $user = $userStmt->fetch();

    // Generic response to prevent account enumeration
    if (!$user) {
        http_response_code(200);
        echo json_encode(['success' => true, 'message' => 'If this email exists, a reset link has been sent']);
        exit;
    }

    // Remove previous tokens for this email
    $cleanupStmt = $pdo->prepare('DELETE FROM password_resets WHERE email = :email OR expires_at <= NOW()');
    $cleanupStmt->execute([':email' => $email]);

    $token = bin2hex(random_bytes(32));

    $insertStmt = $pdo->prepare(
        'INSERT INTO password_resets (email, token, expires_at, created_at) VALUES (:email, :token, DATE_ADD(NOW(), INTERVAL 15 MINUTE), NOW())'
    );
    $insertStmt->execute([':email' => $email, ':token' => $token]);

    // Read SMTP config from env (already loaded by bootstrap.php)
    $smtpHost     = getenv('SMTP_HOST')         ?: 'smtp.gmail.com';
    $smtpPort     = (int)(getenv('SMTP_PORT')   ?: 587);
    $smtpUser     = getenv('SMTP_USERNAME')      ?: '';
    $smtpPass     = getenv('SMTP_PASSWORD')      ?: '';
    $smtpSecure   = strtolower(getenv('SMTP_SECURE') ?: 'tls');
    $fromAddress  = getenv('MAIL_FROM_ADDRESS')  ?: $smtpUser;
    $fromName     = getenv('MAIL_FROM_NAME')     ?: 'ElectroCityBD';

    // Validate SMTP credentials are configured
    if (empty($smtpUser) || empty($smtpPass)) {
        // Rollback token — can't send email
        $pdo->prepare('DELETE FROM password_resets WHERE token = :token')->execute([':token' => $token]);
        jsonError(500, 'Email service not configured. Set SMTP_USERNAME and SMTP_PASSWORD in .env');
    }

    $appUrl    = rtrim((string)(getenv('APP_URL') ?: 'http://localhost:8080'), '/');
    $resetLink = $appUrl . '/reset_password.php?token=' . urlencode($token);

    $mailer = new PHPMailer(true);
    $mailer->isSMTP();
    $mailer->Host      = $smtpHost;
    $mailer->SMTPAuth  = true;
    $mailer->Username  = $smtpUser;
    $mailer->Password  = $smtpPass;
    $mailer->Port      = $smtpPort;
    $mailer->SMTPSecure = ($smtpSecure === 'ssl')
        ? PHPMailer::ENCRYPTION_SMTPS
        : PHPMailer::ENCRYPTION_STARTTLS;
    $mailer->CharSet   = 'UTF-8';

    $mailer->setFrom($fromAddress, $fromName);
    $mailer->addAddress($email);
    $mailer->isHTML(true);
    $mailer->Subject = 'Reset your ElectroCityBD password';
    $safeLink = htmlspecialchars($resetLink, ENT_QUOTES, 'UTF-8');
    $mailer->Body    = "<p>Click the link below to reset your password:</p><p><a href=\"{$safeLink}\">Reset Password</a></p><p>This link expires in 15 minutes.</p>";
    $mailer->AltBody = "Reset your password: {$resetLink}\nExpires in 15 minutes.";

    try {
        $mailer->send();
    } catch (Exception $mailException) {
        error_log('PHPMailer Error: ' . $mailException->getMessage());
        $pdo->prepare('DELETE FROM password_resets WHERE token = :token')->execute([':token' => $token]);
        jsonError(500, 'Failed to send reset email: ' . $mailer->ErrorInfo);
    }

    http_response_code(200);
    echo json_encode(['success' => true, 'message' => 'Reset link sent to your email']);

} catch (RuntimeException $e) {
    jsonError(500, 'Server configuration error: ' . $e->getMessage());
} catch (Throwable $e) {
    error_log('forgot_password error: ' . $e->getMessage());
    jsonError(500, 'Internal server error');
}
