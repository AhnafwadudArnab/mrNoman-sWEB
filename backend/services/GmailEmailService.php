<?php
/**
 * Gmail Email Service using PHP mail() with SMTP configuration
 * Simple and reliable email sending
 */

// Prevent direct access
if (!defined('SECURE_ACCESS')) {
    http_response_code(403);
    die('Direct access not permitted');
}

class GmailEmailService implements EmailServiceInterface {
    private $fromEmail;
    private $fromName;
    private $config;
    
    public function __construct(array $config = []) {
        $this->config = $config;
        $this->fromEmail = $config['mail']['from_address'] ?? 'noreply@electrocitybd.com';
        $this->fromName = $config['mail']['from_name'] ?? 'ElectroCityBD';
    }
    
    /**
     * Check if service is available
     */
    public function isAvailable(): bool {
        return function_exists('mail');
    }
    
    /**
     * Send Password Reset Email
     */
    public function sendPasswordResetEmail(string $toEmail, string $code, string $userName = ''): array {
        try {
            $subject = 'Password Reset Code - ElectroCityBD';
            
            // Create email content
            $htmlBody = $this->getEmailTemplate($code, $userName);
            $textBody = $this->getTextTemplate($code, $userName);
            
            // Create boundary for multipart email
            $boundary = md5(time());
            
            // Email headers
            $headers = "From: {$this->fromName} <{$this->fromEmail}>\r\n";
            $headers .= "Reply-To: {$this->fromEmail}\r\n";
            $headers .= "MIME-Version: 1.0\r\n";
            $headers .= "Content-Type: multipart/alternative; boundary=\"{$boundary}\"\r\n";
            
            // Email body
            $message = "--{$boundary}\r\n";
            $message .= "Content-Type: text/plain; charset=UTF-8\r\n";
            $message .= "Content-Transfer-Encoding: 7bit\r\n\r\n";
            $message .= $textBody . "\r\n\r\n";
            
            $message .= "--{$boundary}\r\n";
            $message .= "Content-Type: text/html; charset=UTF-8\r\n";
            $message .= "Content-Transfer-Encoding: 7bit\r\n\r\n";
            $message .= $htmlBody . "\r\n\r\n";
            
            $message .= "--{$boundary}--";
            
            // Send email
            $sent = @mail($toEmail, $subject, $message, $headers);
            
            if ($sent) {
                return [
                    'success' => true,
                    'message' => 'Email sent successfully'
                ];
            } else {
                // Log error
                error_log('Mail function failed for: ' . $toEmail);
                return [
                    'success' => false,
                    'message' => 'Failed to send email'
                ];
            }
            
        } catch (Exception $e) {
            error_log('Email Error: ' . $e->getMessage());
            return [
                'success' => false,
                'message' => 'Email service error'
            ];
        }
    }
    
    /**
     * HTML Email Template
     */
    private function getEmailTemplate(string $code, string $userName): string {
        $greeting = $userName ? "Hello $userName," : "Hello,";
        
        return <<<HTML
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0;">
    <div style="max-width: 600px; margin: 20px auto; background: #ffffff;">
        <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center;">
            <h1 style="margin: 0;">🔐 Password Reset Code</h1>
        </div>
        <div style="padding: 30px; background: #f9f9f9;">
            <p>$greeting</p>
            
            <p>We received a request to reset your password for your ElectroCityBD account.</p>
            
            <p><strong>Your 6-digit reset code is:</strong></p>
            
            <div style="background: #fff; border: 3px solid #667eea; padding: 20px; margin: 30px 0; border-radius: 10px; text-align: center;">
                <div style="font-size: 48px; font-weight: bold; color: #667eea; letter-spacing: 10px; font-family: monospace;">$code</div>
            </div>
            
            <div style="background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0;">
                <strong>⚠️ Security Notice:</strong>
                <ul style="margin: 10px 0; padding-left: 20px;">
                    <li>This code will expire in <strong>1 hour</strong></li>
                    <li>If you didn't request this, please ignore this email</li>
                    <li>Never share this code with anyone</li>
                </ul>
            </div>
            
            <p>Best regards,<br>
            <strong>ElectroCityBD Team</strong></p>
        </div>
        <div style="text-align: center; padding: 20px; color: #666; font-size: 12px;">
            <p>© 2026 ElectroCityBD. All rights reserved.</p>
            <p>This is an automated email. Please do not reply.</p>
        </div>
    </div>
</body>
</html>
HTML;
    }
    
    /**
     * Plain Text Email Template
     */
    private function getTextTemplate(string $code, string $userName): string {
        $greeting = $userName ? "Hello $userName," : "Hello,";
        
        return <<<TEXT
$greeting

We received a request to reset your password for your ElectroCityBD account.

Your 6-digit Reset Code: $code

This code will expire in 1 hour.

If you didn't request this password reset, please ignore this email.

Best regards,
ElectroCityBD Team

---
© 2026 ElectroCityBD. All rights reserved.
This is an automated email. Please do not reply.
TEXT;
    }
}
?>
