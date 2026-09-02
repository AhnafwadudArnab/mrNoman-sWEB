<?php
/**
 * CSRF Protection Middleware
 */
class CSRF {
    private static $db = null;
    
    public static function setDatabase($database) {
        self::$db = $database;
    }
    
    /**
     * Generate CSRF token
     */
    public static function generateToken($user_id = null, $session_id = null) {
        if (!self::$db) {
            throw new Exception('Database not set for CSRF');
        }
        
        // Generate random token
        $token = bin2hex(random_bytes(32));
        $expires_at = date('Y-m-d H:i:s', time() + 3600); // 1 hour
        
        // Store in database
        $stmt = self::$db->prepare("
            INSERT INTO csrf_tokens (token, user_id, session_id, expires_at)
            VALUES (?, ?, ?, ?)
        ");
        $stmt->execute([$token, $user_id, $session_id, $expires_at]);
        
        return $token;
    }
    
    /**
     * Validate CSRF token
     */
    public static function validateToken($token, $user_id = null) {
        if (!self::$db) {
            throw new Exception('Database not set for CSRF');
        }
        
        if (empty($token)) {
            return false;
        }
        
        // Check token in database
        $stmt = self::$db->prepare("
            SELECT token_id FROM csrf_tokens
            WHERE token = ? 
            AND expires_at > NOW()
            AND (user_id = ? OR user_id IS NULL)
        ");
        $stmt->execute([$token, $user_id]);
        
        if ($stmt->rowCount() === 0) {
            return false;
        }
        
        // Delete used token (one-time use)
        $stmt = self::$db->prepare("DELETE FROM csrf_tokens WHERE token = ?");
        $stmt->execute([$token]);
        
        return true;
    }
    
    /**
     * Clean expired tokens
     */
    public static function cleanExpiredTokens() {
        if (!self::$db) {
            return;
        }
        
        $stmt = self::$db->prepare("DELETE FROM csrf_tokens WHERE expires_at < NOW()");
        $stmt->execute();
    }
    
    /**
     * Middleware to check CSRF token on state-changing requests
     */
    public static function protect($user_id = null) {
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
        
        // Only check for state-changing methods
        if (!in_array($method, ['POST', 'PUT', 'DELETE', 'PATCH'])) {
            return true;
        }
        
        // Get token from header
        $token = $_SERVER['HTTP_X_CSRF_TOKEN'] ?? $_POST['csrf_token'] ?? null;
        
        if (!$token) {
            http_response_code(403);
            echo json_encode(['message' => 'CSRF token missing']);
            exit;
        }
        
        if (!self::validateToken($token, $user_id)) {
            http_response_code(403);
            echo json_encode(['message' => 'Invalid CSRF token']);
            exit;
        }
        
        return true;
    }
}
