<?php
/**
 * Password Reset Controller
 * Handles HTTP requests and delegates to business logic
 */

// Prevent direct access
if (!defined('SECURE_ACCESS')) {
    http_response_code(403);
    die('Direct access not permitted');
}

class PasswordResetController {
    private $passwordResetModel;
    private $emailService;
    
    public function __construct(PasswordReset $passwordResetModel, EmailServiceInterface $emailService) {
        $this->passwordResetModel = $passwordResetModel;
        $this->emailService = $emailService;
    }
    
    /**
     * Handle password reset request
     */
    public function requestReset(array $input): array {
        // Validate input
        $email = $input['email'] ?? '';
        
        if (empty($email)) {
            return [
                'success' => false,
                'message' => 'Email is required',
                'http_code' => 400
            ];
        }
        
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            return [
                'success' => false,
                'message' => 'Invalid email format',
                'http_code' => 400
            ];
        }
        
        // Create reset token
        $result = $this->passwordResetModel->createResetToken($email);
        
        // Send email if token created successfully
        if ($result['success']) {
            try {
                $emailResult = $this->emailService->sendPasswordResetEmail(
                    $email,
                    $result['code'],
                    $result['user_name'] ?? ''
                );
                
                if ($emailResult['success']) {
                    return [
                        'success' => true,
                        'message' => 'A 6-digit reset code has been sent to your email',
                        'http_code' => 200
                    ];
                } else {
                    return [
                        'success' => false,
                        'message' => 'Failed to send email. Please try again later.',
                        'http_code' => 500
                    ];
                }
            } catch (Exception $e) {
                error_log('Email Error: ' . $e->getMessage());
                return [
                    'success' => false,
                    'message' => 'Email service error. Please try again later.',
                    'http_code' => 500
                ];
            }
        }
        
        // Return generic success for security (don't reveal if email exists)
        return [
            'success' => true,
            'message' => 'If this email exists, a reset code has been sent',
            'http_code' => 200
        ];
    }
    
    /**
     * Handle token verification
     */
    public function verifyToken(array $input): array {
        $token = $input['token'] ?? '';
        
        if (empty($token)) {
            return [
                'success' => false,
                'message' => 'Token is required',
                'http_code' => 400
            ];
        }
        
        $result = $this->passwordResetModel->verifyToken($token);
        return array_merge($result, ['http_code' => $result['success'] ? 200 : 400]);
    }
    
    /**
     * Handle password reset
     */
    public function resetPassword(array $input): array {
        $token = $input['token'] ?? '';
        $code = $input['code'] ?? '';
        $newPassword = $input['new_password'] ?? '';
        
        // Validate input
        if ((empty($token) && empty($code)) || empty($newPassword)) {
            return [
                'success' => false,
                'message' => 'Reset code/token and new password are required',
                'http_code' => 400
            ];
        }
        
        if (strlen($newPassword) < 6) {
            return [
                'success' => false,
                'message' => 'Password must be at least 6 characters',
                'http_code' => 400
            ];
        }
        
        // Reset password using code or token
        if (!empty($code)) {
            $result = $this->passwordResetModel->resetPasswordWithCode($code, $newPassword);
        } else {
            $result = $this->passwordResetModel->resetPassword($token, $newPassword);
        }
        
        return array_merge($result, ['http_code' => $result['success'] ? 200 : 400]);
    }
}
?>
