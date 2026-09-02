<?php
/**
 * Rate Limiter Middleware
 * Prevents brute force attacks and API abuse
 */

class RateLimiter {
    private $db;
    private $maxAttempts;
    private $decayMinutes;
    
    public function __construct($db) {
        $this->db = $db;
        $this->maxAttempts = (int)(getenv('RATE_LIMIT_MAX_ATTEMPTS') ?: 10);
        $this->decayMinutes = (int)(getenv('RATE_LIMIT_DECAY_MINUTES') ?: 1);
    }
    
    /**
     * Check rate limit for identifier and action
     * 
     * @param string $identifier IP address or user ID
     * @param string $action Action being performed (login, api, etc)
     * @throws Exception if rate limit exceeded
     */
    public function check($identifier, $action = 'api') {
        $windowStart = time() - ($this->decayMinutes * 60);
        
        // Clean old attempts
        $stmt = $this->db->prepare('
            DELETE FROM rate_limits 
            WHERE identifier = ? AND action = ? AND attempted_at < ?
        ');
        $stmt->execute([$identifier, $action, date('Y-m-d H:i:s', $windowStart)]);
        
        // Count recent attempts
        $stmt = $this->db->prepare('
            SELECT COUNT(*) as count 
            FROM rate_limits 
            WHERE identifier = ? AND action = ? AND attempted_at >= ?
        ');
        $stmt->execute([$identifier, $action, date('Y-m-d H:i:s', $windowStart)]);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($result['count'] >= $this->maxAttempts) {
            http_response_code(429);
            header('Retry-After: ' . ($this->decayMinutes * 60));
            echo json_encode([
                'error' => 'Too many requests. Please try again later.',
                'retry_after' => $this->decayMinutes * 60
            ]);
            exit;
        }
        
        // Log attempt
        $stmt = $this->db->prepare('
            INSERT INTO rate_limits (identifier, action, attempted_at) 
            VALUES (?, ?, NOW())
        ');
        $stmt->execute([$identifier, $action]);
    }
    
    /**
     * Get client IP address
     */
    public static function getClientIp() {
        $ip = $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
        
        // Check for proxy
        if (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
            $ips = explode(',', $_SERVER['HTTP_X_FORWARDED_FOR']);
            $ip = trim($ips[0]);
        } elseif (!empty($_SERVER['HTTP_CLIENT_IP'])) {
            $ip = $_SERVER['HTTP_CLIENT_IP'];
        }
        
        return $ip;
    }
}
