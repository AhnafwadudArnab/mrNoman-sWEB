<?php
/**
 * Token Extractor Utility
 * 
 * Centralized Bearer token extraction from various header formats.
 * Handles different server configurations (Apache, Nginx, etc.)
 */
class TokenExtractor {
    
    /**
     * Extract Bearer token from request headers
     * 
     * Supports multiple header formats:
     * - getallheaders() (Apache)
     * - $_SERVER['HTTP_AUTHORIZATION'] (standard)
     * - $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] (Nginx rewrites)
     * - Case-insensitive "Bearer" prefix
     * 
     * @return string|null The JWT token or null if not found
     */
    public static function extract(): ?string {
        // Try to get headers using multiple methods
        $headers = [];
        
        // Method 1: getallheaders() function (Apache)
        if (function_exists('getallheaders')) {
            $headers = getallheaders();
        }
        
        // Method 2: $_SERVER array (works everywhere)
        if (isset($_SERVER['HTTP_AUTHORIZATION'])) {
            $headers['Authorization'] = $_SERVER['HTTP_AUTHORIZATION'];
        } elseif (isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
            $headers['Authorization'] = $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
        }
        
        // Look for Authorization header (case-insensitive key search)
        $auth = null;
        foreach ($headers as $key => $value) {
            if (strtolower($key) === 'authorization') {
                $auth = $value;
                break;
            }
        }
        
        // If still not found, try lowercase
        if (!$auth) {
            $auth = $headers['authorization'] ?? '';
        }
        
        if (empty($auth)) {
            return null;
        }
        
        // Extract Bearer token (case-insensitive "Bearer " prefix)
        // Supported formats:
        // - "Bearer eyJhbGc..."
        // - "bearer eyJhbGc..."
        // - "BEARER eyJhbGc..."
        if (stripos($auth, 'Bearer ') === 0) {
            $token = trim(substr($auth, 7));
            return !empty($token) ? $token : null;
        }
        
        return null;
    }
    
    /**
     * Extract Bearer token and validate it's not empty
     * Throws exception if no valid token found
     * 
     * @throws Exception If no Bearer token found in headers
     * @return string The JWT token
     */
    public static function extractRequired(): string {
        $token = self::extract();
        if (!$token) {
            throw new Exception('Authorization header with Bearer token required');
        }
        return $token;
    }
}
?>
