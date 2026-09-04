<?php
/**
 * Rate Limiting Middleware
 * Prevents brute force attacks and API abuse
 */

class RateLimitMiddleware {
    private static $storage = [];
    private static $storageFile = __DIR__ . '/../storage/rate_limits.json';
    
    /**
     * Check rate limit for an identifier (IP address or user ID)
     * @param string $identifier Unique identifier (IP, user ID, etc.)
     * @param int $maxRequests Maximum requests allowed
     * @param int $windowSeconds Time window in seconds
     * @return bool True if allowed, false if rate limited
     */
    public static function check($identifier, $maxRequests = null, $windowSeconds = null) {
        $config = require __DIR__ . '/../config.php';
        
        if ($maxRequests === null) {
            $maxRequests = $config['security']['rate_limit_requests'];
        }
        if ($windowSeconds === null) {
            $windowSeconds = $config['security']['rate_limit_window'];
        }
        
        self::loadStorage();
        
        $now = time();
        $key = md5($identifier);
        
        // Initialize if not exists
        if (!isset(self::$storage[$key])) {
            self::$storage[$key] = [
                'requests' => [],
                'blocked_until' => 0
            ];
        }
        
        $data = &self::$storage[$key];
        
        // Check if currently blocked
        if ($data['blocked_until'] > $now) {
            $remainingTime = $data['blocked_until'] - $now;
            http_response_code(429);
            header('Retry-After: ' . $remainingTime);
            echo json_encode([
                'message' => 'Too many requests. Please try again later.',
                'retry_after' => $remainingTime
            ]);
            self::saveStorage();
            exit;
        }
        
        // Remove old requests outside the window
        $data['requests'] = array_filter($data['requests'], function($timestamp) use ($now, $windowSeconds) {
            return $timestamp > ($now - $windowSeconds);
        });
        
        // Check if limit exceeded
        if (count($data['requests']) >= $maxRequests) {
            // Block for the window duration
            $data['blocked_until'] = $now + $windowSeconds;
            
            http_response_code(429);
            header('Retry-After: ' . $windowSeconds);
            echo json_encode([
                'message' => 'Rate limit exceeded. Too many requests.',
                'retry_after' => $windowSeconds
            ]);
            self::saveStorage();
            exit;
        }
        
        // Add current request
        $data['requests'][] = $now;
        self::saveStorage();
        
        return true;
    }
    
    /**
     * Check login attempts for brute force protection
     */
    public static function checkLoginAttempts($identifier) {
        $config = require __DIR__ . '/../config.php';
        $maxAttempts = $config['security']['max_login_attempts'];
        $lockoutTime = $config['security']['login_lockout_time'];
        
        self::loadStorage();
        
        $now = time();
        $key = 'login_' . md5($identifier);
        
        if (!isset(self::$storage[$key])) {
            self::$storage[$key] = [
                'attempts' => 0,
                'first_attempt' => $now,
                'locked_until' => 0
            ];
        }
        
        $data = &self::$storage[$key];
        
        // Check if locked
        if ($data['locked_until'] > $now) {
            $remainingTime = $data['locked_until'] - $now;
            http_response_code(429);
            echo json_encode([
                'message' => 'Account temporarily locked due to too many failed login attempts.',
                'retry_after' => $remainingTime,
                'locked_until' => date('Y-m-d H:i:s', $data['locked_until'])
            ]);
            self::saveStorage();
            exit;
        }
        
        // Reset if window expired (15 minutes)
        if ($now - $data['first_attempt'] > 900) {
            $data['attempts'] = 0;
            $data['first_attempt'] = $now;
        }
        
        // Check attempts
        if ($data['attempts'] >= $maxAttempts) {
            $data['locked_until'] = $now + $lockoutTime;
            http_response_code(429);
            echo json_encode([
                'message' => 'Too many failed login attempts. Account locked temporarily.',
                'retry_after' => $lockoutTime
            ]);
            self::saveStorage();
            exit;
        }
        
        return true;
    }
    
    /**
     * Record failed login attempt
     */
    public static function recordFailedLogin($identifier) {
        self::loadStorage();
        
        $key = 'login_' . md5($identifier);
        $now = time();
        
        if (!isset(self::$storage[$key])) {
            self::$storage[$key] = [
                'attempts' => 0,
                'first_attempt' => $now,
                'locked_until' => 0
            ];
        }
        
        self::$storage[$key]['attempts']++;
        self::saveStorage();
    }
    
    /**
     * Reset login attempts on successful login
     */
    public static function resetLoginAttempts($identifier) {
        self::loadStorage();
        
        $key = 'login_' . md5($identifier);
        if (isset(self::$storage[$key])) {
            unset(self::$storage[$key]);
            self::saveStorage();
        }
    }
    
    /**
     * Get client IP address
     */
    public static function getClientIP() {
        $ip = '';
        
        if (!empty($_SERVER['HTTP_CLIENT_IP'])) {
            $ip = $_SERVER['HTTP_CLIENT_IP'];
        } elseif (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
            $ip = $_SERVER['HTTP_X_FORWARDED_FOR'];
        } else {
            $ip = $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
        }
        
        // Handle multiple IPs (take first one)
        if (strpos($ip, ',') !== false) {
            $ip = trim(explode(',', $ip)[0]);
        }
        
        return $ip;
    }
    
    /**
     * Load storage from file
     */
    private static function loadStorage() {
        $dir = dirname(self::$storageFile);
        if (!is_dir($dir)) {
            mkdir($dir, 0755, true);
        }
        
        if (file_exists(self::$storageFile)) {
            $content = file_get_contents(self::$storageFile);
            self::$storage = json_decode($content, true) ?: [];
        }
        
        // Clean old entries (older than 1 hour)
        $now = time();
        foreach (self::$storage as $key => $data) {
            if (isset($data['requests'])) {
                $data['requests'] = array_filter($data['requests'], function($timestamp) use ($now) {
                    return $timestamp > ($now - 3600);
                });
                if (empty($data['requests']) && $data['blocked_until'] < $now) {
                    unset(self::$storage[$key]);
                }
            }
        }
    }
    
    /**
     * Save storage to file
     */
    private static function saveStorage() {
        $dir = dirname(self::$storageFile);
        if (!is_dir($dir)) {
            mkdir($dir, 0755, true);
        }
        
        file_put_contents(self::$storageFile, json_encode(self::$storage));
    }
}
?>
