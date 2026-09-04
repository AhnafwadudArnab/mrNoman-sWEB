<?php
/**
 * Simple Email Service (No PHPMailer Required)
 * Uses PHP's built-in mail() function
 */

// Prevent direct access
if (!defined('SECURE_ACCESS')) {
    http_response_code(403);
    die('Direct access not permitted');
}

class SimpleEmailService {
    private $fromEmail;
    private $fromName;
    
    public function __construct() {
        $this->fromEmail = getenv('MAIL_FROM_ADDRESS') ?: 'noreply@electrocitybd.com';
        $this->fromName = getenv('MAIL_FROM_NAME') ?: 'ElectroCityBD';
    }
    
    /**
     * Send Password Reset Email
     */
    public function sendPasswordResetEmail($toEmail, $code, $userName = '') {
        try {
            $subject = 'Password Reset Code - ElectroCityBD';
            
            // HTML email body
            $htmlBody = $this->getEmailTemplate($code, $userName);
            
            // Plain text alternative
            $textBody = $this->getTextTemplate($code, $userName);
            
            // Email headers
            $headers = $this->getHeaders($htmlBody, $textBody);
            
            // Send email
            $sent = mail($toEmail, $subject, $htmlBody, $headers);
            
            if ($sent) {
                return [
                    'success' => true,
                    'message' => 'Reset code sent to your email'
                ];
            } else {
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
     * Get email headers
     */
    private function getHeaders($htmlBody, $textBody) {
        $boundary = md5(time());
        
        $headers = [];
        $headers[] = "From: {$this->fromName} <{$this->fromEmail}>";
        $headers[] = "Reply-To: {$this->fromEmail}";
        $headers[] = "MIME-Version: 1.0";
        $headers[] = "Content-Type: multipart/alternative; boundary=\"{$boundary}\"";
        
        return implode("\r\n", $headers);
    }
    
    /**
     * HTML Email Template
     */
    private function getEmailTemplate($code, $userName) {
        $greeting = $userName ? "Hello $userName," : "Hello,";
        
        return <<<HTML
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .code-box { background: #fff; border: 3px solid #667eea; padding: 20px; margin: 30px 0; border-radius: 10px; text-align: center; }
        .code { font-size: 48px; font-weight: bold; color: #667eea; letter-spacing: 10px; font-family: monospace; }
        .warning { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔐 Password Reset Code</h1>
        </div>
        <div class="content">
            <p>$greeting</p>
            
            <p>We received a request to reset your password for your ElectroCityBD account.</p>
            
            <p><strong>Your 6-digit reset code is:</strong></p>
            
            <div class="code-box">
                <div class="code">$code</div>
            </div>
            
            <div class="warning">
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
    </div>
</body>
</html>
HTML;
    }
    
    /**
     * Plain Text Email Template
     */
    private function getTextTemplate($code, $userName) {
        $greeting = $userName ? "Hello $userName," : "Hello,";
        
        return <<<TEXT
$greeting

We received a request to reset your password for your ElectroCityBD account.

Your 6-digit Reset Code: $code

This code will expire in 1 hour.

If you didn't request this password reset, please ignore this email.

Best regards,
ElectroCityBD Team
TEXT;
    }
}

/**
 * Send Password Reset Email (Helper Function)
 */
function sendPasswordResetEmail($email, $code, $userName = '') {
    $emailService = new SimpleEmailService();
    return $emailService->sendPasswordResetEmail($email, $code, $userName);
}
?>
