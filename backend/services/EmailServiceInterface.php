<?php
/**
 * Email Service Interface
 * Defines contract for all email service implementations
 */

// Prevent direct access
if (!defined('SECURE_ACCESS')) {
    http_response_code(403);
    die('Direct access not permitted');
}

interface EmailServiceInterface {
    /**
     * Check if email service is available and configured
     * 
     * @return bool
     */
    public function isAvailable(): bool;
    
    /**
     * Send password reset email with code
     * 
     * @param string $toEmail Recipient email address
     * @param string $code 6-digit reset code
     * @param string $userName Optional user name for personalization
     * @return array ['success' => bool, 'message' => string]
     */
    public function sendPasswordResetEmail(string $toEmail, string $code, string $userName = ''): array;
}
?>
