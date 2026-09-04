<?php
/**
 * PHPMailer Email Service - Production Ready
 * Uses PHPMailer library for reliable SMTP email sending
 * No Composer required - uses direct file includes
 */

// Prevent direct access
if (!defined('SECURE_ACCESS')) {
    http_response_code(403);
    die('Direct access not permitted');
}

class PHPMailerEmailService implements EmailServiceInterface {
    private $mailer;
    private $fromEmail;
    private $fromName;
    private $available = false;
    private $config;
    
    public function __construct(array $config = []) {
        $this->config = $config;
        $this->fromEmail = $config['mail']['from_address'] ?? 'noreply@electrocitybd.com';
        $this->fromName = $config['mail']['from_name'] ?? 'ElectroCityBD';
        
        $composerAutoload = __DIR__ . '/../vendor/autoload.php';
        
        if (file_exists($composerAutoload)) {
            try {
                require_once $composerAutoload;
                
                $this->mailer = new PHPMailer\PHPMailer\PHPMailer(true);
                $this->configureSMTP();
                $this->available = true;
            } catch (Exception $e) {
                error_log('PHPMailer initialization error: ' . $e->getMessage());
                $this->available = false;
            }
        }
    }
    
    /**
     * Check if PHPMailer is available
     */
    public function isAvailable(): bool {
        return $this->available;
    }
    
    /**
     * Configure SMTP settings
     */
    private function configureSMTP(): void {
        $secure = strtolower((string)($this->config['smtp']['secure'] ?? 'tls'));

        $this->mailer->isSMTP();
        $this->mailer->Host       = $this->config['smtp']['host'] ?? 'smtp.gmail.com';
        $this->mailer->SMTPAuth   = true;
        $this->mailer->Username   = $this->config['smtp']['username'] ?? $this->fromEmail;
        $this->mailer->Password   = $this->config['smtp']['password'] ?? '';
        if ($secure === 'ssl' || $secure === 'smtps') {
            $this->mailer->SMTPSecure = PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_SMTPS;
        } elseif ($secure === 'none' || $secure === '') {
            $this->mailer->SMTPSecure = false;
        } else {
            $this->mailer->SMTPSecure = PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_STARTTLS;
        }
        $this->mailer->Port       = (int)($this->config['smtp']['port'] ?? 587);
        $this->mailer->CharSet    = 'UTF-8';
        $this->mailer->SMTPOptions = [
            'ssl' => [
                'verify_peer'       => false,
                'verify_peer_name'  => false,
                'allow_self_signed' => true,
            ],
        ];
        $this->mailer->Timeout = 10; // 10 second connection timeout
        $this->mailer->setFrom($this->fromEmail, $this->fromName);
    }
    
    /**
     * Send Password Reset Email
     */
    public function sendPasswordResetEmail(string $toEmail, string $code, string $userName = ''): array {
        if (!$this->available) {
            return [
                'success' => false,
                'message' => 'PHPMailer not available'
            ];
        }
        
        try {
            // Clear previous recipients
            $this->mailer->clearAddresses();
            $this->mailer->clearAttachments();
            
            // Set recipient
            $this->mailer->addAddress($toEmail);
            
            // Set email content
            $this->mailer->isHTML(true);
            $this->mailer->Subject = 'Password Reset Code - ElectroCityBD';
            $this->mailer->Body = $this->getEmailTemplate($code, $userName);
            $this->mailer->AltBody = $this->getTextTemplate($code, $userName);
            
            // Send email
            $this->mailer->send();
            
            return [
                'success' => true,
                'message' => 'Email sent successfully'
            ];
            
        } catch (Exception $e) {
            error_log('PHPMailer Error: ' . $e->getMessage() . ' [host=' . ($this->config['smtp']['host'] ?? 'smtp.gmail.com') . ', port=' . (string)($this->config['smtp']['port'] ?? 587) . ', secure=' . (string)($this->config['smtp']['secure'] ?? 'tls') . ', user=' . ($this->config['smtp']['username'] ?? '') . ']');
            return [
                'success' => false,
                'message' => 'Failed to send email: ' . $e->getMessage()
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
