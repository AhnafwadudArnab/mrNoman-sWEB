<?php
define('SECURE_ACCESS', true);
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

require_once __DIR__ . '/bootstrap.php';
require_once __DIR__ . '/../models/password_reset.php';

$input = json_decode(file_get_contents('php://input'), true) ?? [];
$action = $input['action'] ?? '';

$conn = db();
$model = new PasswordReset($conn);

switch ($action) {
    case 'request_reset':
        $email = trim($input['email'] ?? '');
        if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Valid email required']);
            exit;
        }
        $result = $model->createResetToken($email);
        if ($result['success']) {
            try {
                require_once __DIR__ . '/../services/EmailServiceInterface.php';
                require_once __DIR__ . '/../services/EmailServiceFactory.php';
                $config = [
                    'smtp' => [
                        'host'     => getenv('SMTP_HOST') ?: (getenv('MAIL_HOST') ?: 'smtp.gmail.com'),
                        'port'     => (int)(getenv('SMTP_PORT') ?: (getenv('MAIL_PORT') ?: 587)),
                        'secure'   => getenv('SMTP_SECURE') ?: 'tls',
                        'username' => getenv('SMTP_USERNAME') ?: (getenv('MAIL_USERNAME') ?: ''),
                        'password' => getenv('SMTP_PASSWORD') ?: (getenv('MAIL_PASSWORD') ?: ''),
                    ],
                    'mail' => [
                        'from_address' => getenv('MAIL_FROM_ADDRESS') ?: (getenv('SMTP_USERNAME') ?: (getenv('MAIL_USERNAME') ?: 'noreply@electrocitybd.com')),
                        'from_name'    => getenv('MAIL_FROM_NAME') ?: 'ElectroCityBD',
                    ],
                ];
                $factory = EmailServiceFactory::getInstance($config);
                $emailService = $factory->createEmailService();
                $mailResult = $emailService->sendPasswordResetEmail($email, $result['code'], $result['user_name'] ?? '');

                if (empty($mailResult['success'])) {
                    error_log('Password reset mail send failed: ' . ($mailResult['message'] ?? 'unknown error'));
                    http_response_code(500);
                    echo json_encode([
                        'success' => false,
                        'message' => 'Failed to send reset code email. Please verify SMTP credentials.',
                    ]);
                    break;
                }

                echo json_encode([
                    'success' => true,
                    'message' => 'A 6-digit reset code has been sent to your email',
                ]);
            } catch (Throwable $e) {
                error_log('Email send failed: ' . $e->getMessage());
                http_response_code(500);
                echo json_encode([
                    'success' => false,
                    'message' => 'Failed to send reset code email. Please verify SMTP credentials.',
                ]);
            }
        } else {
            echo json_encode(['success' => true, 'message' => 'If this email exists, a reset code has been sent']);
        }
        break;

    case 'verify_code':
        $code = trim($input['code'] ?? '');
        if (empty($code)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Code required']);
            exit;
        }
        $result = $model->verifyCode($code);
        echo json_encode($result);
        break;

    case 'reset_password':
        $code = trim($input['code'] ?? '');
        $token = trim($input['token'] ?? '');
        $newPassword = $input['new_password'] ?? '';

        if (empty($newPassword) || strlen($newPassword) < 6) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Password must be at least 6 characters']);
            exit;
        }

        if (!empty($code)) {
            $result = $model->resetPasswordWithCode($code, $newPassword);
        } elseif (!empty($token)) {
            $result = $model->resetPassword($token, $newPassword);
        } else {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Reset code or token required']);
            exit;
        }

        http_response_code($result['success'] ? 200 : 400);
        echo json_encode($result);
        break;

    default:
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Invalid action. Use: request_reset, verify_code, reset_password']);
        break;
}
