<?php
/**
 * Input Validator
 * Validates and sanitizes user input
 */

class Validator {
    /**
     * Validate and sanitize email
     */
    public static function email($email) {
        $email = trim($email);
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new Exception('Invalid email format');
        }
        return filter_var($email, FILTER_SANITIZE_EMAIL);
    }
    
    /**
     * Validate Bangladesh phone number
     * Format: 01XXXXXXXXX (11 digits)
     */
    public static function phone($phone) {
        $phone = preg_replace('/[^0-9]/', '', $phone);
        if (!preg_match('/^01[0-9]{9}$/', $phone)) {
            throw new Exception('Invalid phone number. Format: 01XXXXXXXXX');
        }
        return $phone;
    }
    
    /**
     * Validate and sanitize string
     */
    public static function string($str, $minLength = 1, $maxLength = 255) {
        $str = trim($str);
        $length = mb_strlen($str);
        
        if ($length < $minLength) {
            throw new Exception("String must be at least $minLength characters");
        }
        
        if ($length > $maxLength) {
            throw new Exception("String must not exceed $maxLength characters");
        }
        
        return htmlspecialchars($str, ENT_QUOTES, 'UTF-8');
    }
    
    /**
     * Validate number
     */
    public static function number($num, $min = null, $max = null) {
        if (!is_numeric($num)) {
            throw new Exception('Invalid number format');
        }
        
        $num = floatval($num);
        
        if ($min !== null && $num < $min) {
            throw new Exception("Number must be at least $min");
        }
        
        if ($max !== null && $num > $max) {
            throw new Exception("Number must not exceed $max");
        }
        
        return $num;
    }
    
    /**
     * Validate integer
     */
    public static function integer($num, $min = null, $max = null) {
        if (!is_numeric($num) || floor($num) != $num) {
            throw new Exception('Invalid integer format');
        }
        
        $num = intval($num);
        
        if ($min !== null && $num < $min) {
            throw new Exception("Integer must be at least $min");
        }
        
        if ($max !== null && $num > $max) {
            throw new Exception("Integer must not exceed $max");
        }
        
        return $num;
    }
    
    /**
     * Validate boolean
     */
    public static function boolean($value) {
        if (is_bool($value)) {
            return $value;
        }
        
        if (is_numeric($value)) {
            return (bool)$value;
        }
        
        if (is_string($value)) {
            $value = strtolower(trim($value));
            if (in_array($value, ['true', '1', 'yes', 'on'])) {
                return true;
            }
            if (in_array($value, ['false', '0', 'no', 'off'])) {
                return false;
            }
        }
        
        throw new Exception('Invalid boolean value');
    }
    
    /**
     * Validate date (YYYY-MM-DD)
     */
    public static function date($date) {
        $d = DateTime::createFromFormat('Y-m-d', $date);
        if (!$d || $d->format('Y-m-d') !== $date) {
            throw new Exception('Invalid date format. Use YYYY-MM-DD');
        }
        return $date;
    }
    
    /**
     * Validate datetime (YYYY-MM-DD HH:mm:ss)
     */
    public static function datetime($datetime) {
        $d = DateTime::createFromFormat('Y-m-d H:i:s', $datetime);
        if (!$d || $d->format('Y-m-d H:i:s') !== $datetime) {
            // Try without seconds
            $d = DateTime::createFromFormat('Y-m-d H:i', $datetime);
            if (!$d || $d->format('Y-m-d H:i') !== $datetime) {
                throw new Exception('Invalid datetime format. Use YYYY-MM-DD HH:mm:ss');
            }
            return $d->format('Y-m-d H:i:s');
        }
        return $datetime;
    }
    
    /**
     * Sanitize HTML (remove dangerous tags)
     */
    public static function sanitizeHtml($html) {
        // Allow only safe tags
        $allowed = '<p><br><strong><em><u><a><ul><ol><li><h1><h2><h3><h4><h5><h6>';
        return strip_tags($html, $allowed);
    }
    
    /**
     * Validate URL
     */
    public static function url($url) {
        if (!filter_var($url, FILTER_VALIDATE_URL)) {
            throw new Exception('Invalid URL format');
        }
        return filter_var($url, FILTER_SANITIZE_URL);
    }
    
    /**
     * Validate array
     */
    public static function array($value, $minItems = null, $maxItems = null) {
        if (!is_array($value)) {
            throw new Exception('Value must be an array');
        }
        
        $count = count($value);
        
        if ($minItems !== null && $count < $minItems) {
            throw new Exception("Array must have at least $minItems items");
        }
        
        if ($maxItems !== null && $count > $maxItems) {
            throw new Exception("Array must not exceed $maxItems items");
        }
        
        return $value;
    }
}
