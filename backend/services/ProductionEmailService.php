<?php
/**
 * Production Email Service using SMTP
 * Uses Gmail App Password for sending emails
 */

// Prevent direct access
if (!defined('SECURE_ACCESS')) {
    http_response_code(403);
    die('Direct access not permitted');
}

class ProductionEmailService implements EmailServiceInterface {
    private $smtpHost;
    private $smtpPort;
    private $smtpUsername;
    private $smtpPassword;
    private $fromEmail;
    private $fromName;
    private $config;
    
    public function __construct(array $config = []) {
        $this->config = $config;
        // Load configuration from config array
        $this->smtpHost = $config['smtp']['host'] ?? 'smtp.gmail.com';
        $this->smtpPort = $config['smtp']['port'] ?? 587;
        $this->smtpUsername = $config['smtp']['username'] ?? '';
        $this->smtpPassword = $config['smtp']['password'] ?? '';
        $this->fromEmail = $config['mail']['from_address'] ?? $this->smtpUsername;
        $this->fromName = $config['mail']['from_name'] ?? 'ElectroCityBD';
    }
    
    /**
     * Check if service is available
     */
    public function isAvailable(): bool {
        return !empty($this->smtpUsername) && !empty($this->smtpPassword);
    }
    
    /**
     * Send Password Reset Email via SMTP
     */
    public function sendPasswordResetEmail(string $toEmail, string $code, string $userName = ''): array {
        try {
            // Validate SMTP configuration
            if (empty($this->smtpUsername) || empty($this->smtpPassword)) {
                error_log('SMTP credentials not configured');
                return [
                    'success' => false,
                    'message' => 'Email service not configured'
                ];
            }
            
            // Create email content
            $subject = 'Password Reset Code - ElectroCityBD';
            $htmlBody = $this->getEmailTemplate($code, $userName);
            $textBody = $this->getTextTemplate($code, $userName);
            
            // Send via SMTP
            $result = $this->sendViaSMTP(
                $toEmail,
                $subject,
                $htmlBody,
                $textBody
            );
            
            return $result;
            
        } catch (Exception $e) {
            error_log('Email Error: ' . $e->getMessage());
            return [
                'success' => false,
                'message' => 'Failed to send email'
            ];
        }
    }
    
    /**
     * Send email via SMTP using fsockopen
     */
    private function sendViaSMTP(string $to, string $subject, string $htmlBody, string $textBody): array {
        try {
            // Connect to SMTP server
            $smtp = fsockopen(
                'tls://' . $this->smtpHost,
                $this->smtpPort,
                $errno,
                $errstr,
                30
            );
            
            if (!$smtp) {
                error_log("SMTP Connection failed: $errstr ($errno)");
                return ['success' => false, 'message' => 'Connection failed'];
            }
            
            // Read server response
            $response = fgets($smtp, 515);
            if (substr($response, 0, 3) != '220') {
                fclose($smtp);
                return ['success' => false, 'message' => 'Server not ready'];
            }
            
            // Send EHLO
            fputs($smtp, "EHLO " . $this->smtpHost . "\r\n");
            $response = fgets($smtp, 515);
            
            // Read all EHLO responses
            while (substr($response, 3, 1) == '-') {
                $response = fgets($smtp, 515);
            }
            
            // Send AUTH LOGIN
            fputs($smtp, "AUTH LOGIN\r\n");
            $response = fgets($smtp, 515);
            
            // Send username
            fputs($smtp, base64_encode($this->smtpUsername) . "\r\n");
            $response = fgets($smtp, 515);
            
            // Send password
            fputs($smtp, base64_encode($this->smtpPassword) . "\r\n");
            $response = fgets($smtp, 515);
            
            if (substr($response, 0, 3) != '235') {
                fclose($smtp);
                error_log('SMTP Auth failed: ' . $response);
                return ['success' => false, 'message' => 'Authentication failed'];
            }
            
            // Send MAIL FROM
            fputs($smtp, "MAIL FROM: <{$this->fromEmail}>\r\n");
            $response = fgets($smtp, 515);
            
            // Send RCPT TO
            fputs($smtp, "RCPT TO: <$to>\r\n");
            $response = fgets($smtp, 515);
            
            // Send DATA
            fputs($smtp, "DATA\r\n");
            $response = fgets($smtp, 515);
            
            // Send email headers and body
            $boundary = md5(time());
            
            $headers = "From: {$this->fromName} <{$this->fromEmail}>\r\n";
            $headers .= "To: $to\r\n";
            $headers .= "Subject: $subject\r\n";
            $headers .= "MIME-Version: 1.0\r\n";
            $headers .= "Content-Type: multipart/alternative; boundary=\"$boundary\"\r\n";
            $headers .= "\r\n";
            
            // Plain text part
            $body = "--$boundary\r\n";
            $body .= "Content-Type: text/plain; charset=UTF-8\r\n";
            $body .= "Content-Transfer-Encoding: 7bit\r\n\r\n";
            $body .= $textBody . "\r\n\r\n";
            
            // HTML part
            $body .= "--$boundary\r\n";
            $body .= "Content-Type: text/html; charset=UTF-8\r\n";
            $body .= "Content-Transfer-Encoding: 7bit\r\n\r\n";
            $body .= $htmlBody . "\r\n\r\n";
            
            $body .= "--$boundary--\r\n";
            
            // Send email
            fputs($smtp, $headers . $body . "\r\n.\r\n");
            $response = fgets($smtp, 515);
            
            // Send QUIT
            fputs($smtp, "QUIT\r\n");
            fclose($smtp);
            
            if (substr($response, 0, 3) == '250') {
                return [
                    'success' => true,
                    'message' => 'Email sent successfully'
                ];
            } else {
                error_log('SMTP Send failed: ' . $response);
                return [
                    'success' => false,
                    'message' => 'Failed to send email'
                ];
            }
            
        } catch (Exception $e) {
            error_log('SMTP Error: ' . $e->getMessage());
            return [
                'success' => false,
                'message' => 'SMTP error'
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
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; }
        .container { max-width: 600px; margin: 20px auto; background: #ffffff; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; }
        .content { padding: 30px; background: #f9f9f9; }
        .code-box { background: #fff; border: 3px solid #667eea; padding: 20px; margin: 30px 0; border-radius: 10px; text-align: center; }
        .code { font-size: 48px; font-weight: bold; color: #667eea; letter-spacing: 10px; font-family: monospace; }
        .warning { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }
        .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
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
        <div class="footer">
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
