<?php
/**
 * Email Service Wrapper
 * Automatically uses SimpleEmailService (no PHPMailer required)
 */

// Prevent direct access
if (!defined('SECURE_ACCESS')) {
    http_response_code(403);
    die('Direct access not permitted');
}

// Use SimpleEmailService
require_once __DIR__ . '/SimpleEmailService.php';

/**
 * Send Password Reset Email
 * This function is called by the API
 */
function sendPasswordResetEmail($email, $code, $userName = '') {
    $emailService = new SimpleEmailService();
    return $emailService->sendPasswordResetEmail($email, $code, $userName);
}
?>
