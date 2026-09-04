<?php
class PasswordReset {
    private $conn;
    private $table_name = "password_reset_tokens";
    
    public function __construct($db) {
        $this->conn = $db;
    }
    
    /**
     * Generate reset token
     */
    public function createResetToken($email) {
        try {
            // Check if user exists
            $userQuery = "SELECT user_id, full_name FROM users WHERE email = :email LIMIT 1";
            $userStmt = $this->conn->prepare($userQuery);
            $userStmt->bindParam(':email', $email);
            $userStmt->execute();
            
            $user = $userStmt->fetch(PDO::FETCH_ASSOC);
            if (!$user) {
                return ['success' => false, 'message' => 'Email not found'];
            }
            
            // Generate 6-digit code instead of long token
            $code = sprintf('%06d', mt_rand(0, 999999));
            
            // For backward compatibility, also generate a token
            $token = bin2hex(random_bytes(32));
            
            // Delete old unused tokens for this user
            $deleteQuery = "DELETE FROM " . $this->table_name . " 
                           WHERE user_id = :user_id AND used = 0";
            $deleteStmt = $this->conn->prepare($deleteQuery);
            $deleteStmt->bindParam(':user_id', $user['user_id']);
            $deleteStmt->execute();
            
            // Insert new token with code (using MySQL NOW() + INTERVAL for correct timezone)
            $insertQuery = "INSERT INTO " . $this->table_name . " 
                           (user_id, email, token, reset_code, expires_at) 
                           VALUES (:user_id, :email, :token, :reset_code, DATE_ADD(NOW(), INTERVAL 1 HOUR))";
            $insertStmt = $this->conn->prepare($insertQuery);
            $insertStmt->bindParam(':user_id', $user['user_id']);
            $insertStmt->bindParam(':email', $email);
            $insertStmt->bindParam(':token', $token);
            $insertStmt->bindParam(':reset_code', $code);
            
            if ($insertStmt->execute()) {
                return [
                    'success' => true,
                    'token' => $token,
                    'code' => $code, // 6-digit code
                    'user_name' => $user['full_name'],
                    'message' => 'Reset code generated successfully'
                ];
            }
            
            return ['success' => false, 'message' => 'Failed to generate reset code'];
            
        } catch (Exception $e) {
            return ['success' => false, 'message' => 'Error: ' . $e->getMessage()];
        }
    }
    
    // Verify reset code (6-digit)
    public function verifyCode($code) {
        try {
            $query = "SELECT * FROM " . $this->table_name . " 
                     WHERE reset_code = :code AND used = 0 
                     AND expires_at > NOW() 
                     LIMIT 1";
            
            $stmt = $this->conn->prepare($query);
            $stmt->bindParam(':code', $code);
            $stmt->execute();
            
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if ($result) {
                return [
                    'success' => true,
                    'user_id' => $result['user_id'],
                    'email' => $result['email'],
                    'token' => $result['token']
                ];
            }
            
            return ['success' => false, 'message' => 'Invalid or expired code'];
            
        } catch (Exception $e) {
            return ['success' => false, 'message' => 'Error: ' . $e->getMessage()];
        }
    }
    
    // Reset password with code
    public function resetPasswordWithCode($code, $newPassword) {
        try {
            // Verify code first
            $verification = $this->verifyCode($code);
            if (!$verification['success']) {
                return $verification;
            }
            
            $userId = $verification['user_id'];
            
            // Hash new password
            $hashedPassword = password_hash($newPassword, PASSWORD_DEFAULT);
            
            // Update user password
            $updateQuery = "UPDATE users SET password = :password WHERE user_id = :user_id";
            $updateStmt = $this->conn->prepare($updateQuery);
            $updateStmt->bindParam(':password', $hashedPassword);
            $updateStmt->bindParam(':user_id', $userId);
            
            if ($updateStmt->execute()) {
                // Mark code as used
                $markQuery = "UPDATE " . $this->table_name . " 
                             SET used = 1 
                             WHERE reset_code = :code";
                $markStmt = $this->conn->prepare($markQuery);
                $markStmt->bindParam(':code', $code);
                $markStmt->execute();
                
                return [
                    'success' => true,
                    'message' => 'Password reset successfully'
                ];
            }
            
            return ['success' => false, 'message' => 'Failed to reset password'];
            
        } catch (Exception $e) {
            return ['success' => false, 'message' => 'Error: ' . $e->getMessage()];
        }
    }
    
    // Verify reset token
    public function verifyToken($token) {
        try {
            $query = "SELECT * FROM " . $this->table_name . " 
                     WHERE token = :token AND used = 0 
                     AND expires_at > NOW() 
                     LIMIT 1";
            
            $stmt = $this->conn->prepare($query);
            $stmt->bindParam(':token', $token);
            $stmt->execute();
            
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if ($result) {
                return [
                    'success' => true,
                    'user_id' => $result['user_id'],
                    'email' => $result['email']
                ];
            }
            
            return ['success' => false, 'message' => 'Invalid or expired token'];
            
        } catch (Exception $e) {
            return ['success' => false, 'message' => 'Error: ' . $e->getMessage()];
        }
    }
    
    // Reset password
    public function resetPassword($token, $newPassword) {
        try {
            // Verify token first
            $verification = $this->verifyToken($token);
            if (!$verification['success']) {
                return $verification;
            }
            
            $userId = $verification['user_id'];
            
            // Hash new password
            $hashedPassword = password_hash($newPassword, PASSWORD_DEFAULT);
            
            // Update user password
            $updateQuery = "UPDATE users SET password = :password WHERE user_id = :user_id";
            $updateStmt = $this->conn->prepare($updateQuery);
            $updateStmt->bindParam(':password', $hashedPassword);
            $updateStmt->bindParam(':user_id', $userId);
            
            if ($updateStmt->execute()) {
                // Mark token as used
                $markQuery = "UPDATE " . $this->table_name . " 
                             SET used = 1 
                             WHERE token = :token";
                $markStmt = $this->conn->prepare($markQuery);
                $markStmt->bindParam(':token', $token);
                $markStmt->execute();
                
                return [
                    'success' => true,
                    'message' => 'Password reset successfully'
                ];
            }
            
            return ['success' => false, 'message' => 'Failed to reset password'];
            
        } catch (Exception $e) {
            return ['success' => false, 'message' => 'Error: ' . $e->getMessage()];
        }
    }
    
    // Clean up expired tokens (can be called periodically)
    public function cleanupExpiredTokens() {
        try {
            $query = "DELETE FROM " . $this->table_name . " 
                     WHERE expires_at < NOW() OR used = 1";
            $stmt = $this->conn->prepare($query);
            return $stmt->execute();
        } catch (Exception $e) {
            return false;
        }
    }
}
?>
