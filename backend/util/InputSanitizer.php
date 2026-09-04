<?php
/**
 * Input Sanitization Utility
 * Protects against XSS, SQL injection, and other attacks
 */

class InputSanitizer {
    
    /**
     * Sanitize string input (XSS protection)
     */
    public static function sanitizeString($input) {
        if ($input === null) {
            return null;
        }
        
        // Remove null bytes
        $input = str_replace(chr(0), '', $input);
        
        // Convert special characters to HTML entities
        return htmlspecialchars($input, ENT_QUOTES | ENT_HTML5, 'UTF-8');
    }
    
    /**
     * Sanitize email
     */
    public static function sanitizeEmail($email) {
        if ($email === null) {
            return null;
        }
        
        $email = filter_var($email, FILTER_SANITIZE_EMAIL);
        
        if (filter_var($email, FILTER_VALIDATE_EMAIL)) {
            return strtolower(trim($email));
        }
        
        return null;
    }
    
    /**
     * Sanitize integer
     */
    public static function sanitizeInt($input) {
        return filter_var($input, FILTER_SANITIZE_NUMBER_INT);
    }
    
    /**
     * Sanitize float
     */
    public static function sanitizeFloat($input) {
        return filter_var($input, FILTER_SANITIZE_NUMBER_FLOAT, FILTER_FLAG_ALLOW_FRACTION);
    }
    
    /**
     * Sanitize URL
     */
    public static function sanitizeUrl($url) {
        if ($url === null) {
            return null;
        }
        
        $url = filter_var($url, FILTER_SANITIZE_URL);
        
        if (filter_var($url, FILTER_VALIDATE_URL)) {
            return $url;
        }
        
        return null;
    }
    
    /**
     * Sanitize phone number (Bangladesh format)
     */
    public static function sanitizePhone($phone) {
        if ($phone === null) {
            return null;
        }
        
        // Remove all non-numeric characters
        $phone = preg_replace('/[^0-9]/', '', $phone);
        
        // Validate Bangladesh phone format (11 digits starting with 01)
        if (preg_match('/^01[0-9]{9}$/', $phone)) {
            return $phone;
        }
        
        return null;
    }
    
    /**
     * Sanitize array of inputs
     */
    public static function sanitizeArray($array, $type = 'string') {
        if (!is_array($array)) {
            return [];
        }
        
        $sanitized = [];
        foreach ($array as $key => $value) {
            $sanitizedKey = self::sanitizeString($key);
            
            if (is_array($value)) {
                $sanitized[$sanitizedKey] = self::sanitizeArray($value, $type);
            } else {
                switch ($type) {
                    case 'int':
                        $sanitized[$sanitizedKey] = self::sanitizeInt($value);
                        break;
                    case 'float':
                        $sanitized[$sanitizedKey] = self::sanitizeFloat($value);
                        break;
                    case 'email':
                        $sanitized[$sanitizedKey] = self::sanitizeEmail($value);
                        break;
                    case 'url':
                        $sanitized[$sanitizedKey] = self::sanitizeUrl($value);
                        break;
                    default:
                        $sanitized[$sanitizedKey] = self::sanitizeString($value);
                }
            }
        }
        
        return $sanitized;
    }
    
    /**
     * Sanitize filename for upload
     */
    public static function sanitizeFilename($filename) {
        if ($filename === null) {
            return null;
        }
        
        // Get file extension
        $ext = pathinfo($filename, PATHINFO_EXTENSION);
        $name = pathinfo($filename, PATHINFO_FILENAME);
        
        // Remove special characters from name
        $name = preg_replace('/[^a-zA-Z0-9_-]/', '_', $name);
        
        // Limit length
        $name = substr($name, 0, 100);
        
        // Sanitize extension
        $ext = preg_replace('/[^a-zA-Z0-9]/', '', $ext);
        $ext = strtolower($ext);
        
        return $name . '.' . $ext;
    }
    
    /**
     * Validate and sanitize JSON input
     */
    public static function sanitizeJson($json) {
        if ($json === null) {
            return null;
        }
        
        $decoded = json_decode($json, true);
        
        if (json_last_error() !== JSON_ERROR_NONE) {
            return null;
        }
        
        return $decoded;
    }
    
    /**
     * Strip all HTML tags (for plain text fields)
     */
    public static function stripHtml($input) {
        if ($input === null) {
            return null;
        }
        
        return strip_tags($input);
    }
    
    /**
     * Sanitize HTML (allow safe tags only)
     */
    public static function sanitizeHtml($input, $allowedTags = '<p><br><strong><em><u>') {
        if ($input === null) {
            return null;
        }
        
        // Strip all tags except allowed ones
        $input = strip_tags($input, $allowedTags);
        
        // Convert special characters
        return htmlspecialchars($input, ENT_QUOTES | ENT_HTML5, 'UTF-8');
    }
    
    /**
     * Validate CSRF token
     */
    public static function validateCsrfToken($token) {
        if (!isset($_SESSION['csrf_token'])) {
            return false;
        }
        
        return hash_equals($_SESSION['csrf_token'], $token);
    }
    
    /**
     * Generate CSRF token
     */
    public static function generateCsrfToken() {
        if (session_status() === PHP_SESSION_NONE) {
            session_start();
        }
        
        if (!isset($_SESSION['csrf_token'])) {
            $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
        }
        
        return $_SESSION['csrf_token'];
    }
    
    /**
     * Sanitize SQL input (use with PDO prepared statements)
     * This is an additional layer - always use PDO prepared statements
     */
    public static function sanitizeSql($input) {
        if ($input === null) {
            return null;
        }
        
        // Remove null bytes
        $input = str_replace(chr(0), '', $input);
        
        // Escape special characters
        return addslashes($input);
    }
    
    /**
     * Validate and sanitize password
     */
    public static function validatePassword($password) {
        if ($password === null || strlen($password) < 6) {
            return false;
        }
        
        // Check for minimum requirements
        // At least 6 characters (can be made stricter)
        return strlen($password) >= 6;
    }
    
    /**
     * Sanitize address input
     */
    public static function sanitizeAddress($address) {
        if ($address === null) {
            return null;
        }
        
        // Remove null bytes and excessive whitespace
        $address = str_replace(chr(0), '', $address);
        $address = preg_replace('/\s+/', ' ', trim($address));
        
        // Validate length on raw text (not HTML-encoded)
        if (strlen($address) < 10 || strlen($address) > 500) {
            return null;
        }
        
        return $address;
    }
}
?>
