<?php
/**
 * Input validation middleware
 */
class Validator {
    
    /**
     * Validate email format
     */
    public static function validateEmail($email) {
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            return ['valid' => false, 'message' => 'Invalid email format'];
        }
        return ['valid' => true];
    }
    
    /**
     * Validate price
     */
    public static function validatePrice($price) {
        $price = floatval($price);
        if ($price <= 0) {
            return ['valid' => false, 'message' => 'Price must be greater than 0'];
        }
        if ($price > 999999.99) {
            return ['valid' => false, 'message' => 'Price is too high'];
        }
        return ['valid' => true, 'value' => $price];
    }
    
    /**
     * Validate quantity
     */
    public static function validateQuantity($quantity) {
        $quantity = intval($quantity);
        if ($quantity < 0) {
            return ['valid' => false, 'message' => 'Quantity cannot be negative'];
        }
        if ($quantity > 999999) {
            return ['valid' => false, 'message' => 'Quantity is too high'];
        }
        return ['valid' => true, 'value' => $quantity];
    }
    
    /**
     * Validate phone number (Bangladesh format)
     */
    public static function validatePhone($phone) {
        $phone = preg_replace('/[^0-9]/', '', $phone);
        if (strlen($phone) !== 11 || !preg_match('/^01[0-9]{9}$/', $phone)) {
            return ['valid' => false, 'message' => 'Invalid phone number format (must be 01XXXXXXXXX)'];
        }
        return ['valid' => true, 'value' => $phone];
    }
    
    /**
     * Validate delivery address
     */
    public static function validateAddress($address) {
        $address = trim($address);
        if (strlen($address) < 10) {
            return ['valid' => false, 'message' => 'Address is too short (minimum 10 characters)'];
        }
        if (strlen($address) > 500) {
            return ['valid' => false, 'message' => 'Address is too long (maximum 500 characters)'];
        }
        return ['valid' => true, 'value' => $address];
    }
    
    /**
     * Validate required fields
     */
    public static function validateRequired($data, $fields) {
        $missing = [];
        foreach ($fields as $field) {
            if (!isset($data[$field]) || empty($data[$field])) {
                $missing[] = $field;
            }
        }
        if (!empty($missing)) {
            return [
                'valid' => false, 
                'message' => 'Missing required fields: ' . implode(', ', $missing)
            ];
        }
        return ['valid' => true];
    }
    
    /**
     * Sanitize string input
     */
    public static function sanitizeString($input) {
        return htmlspecialchars(strip_tags(trim($input)), ENT_QUOTES, 'UTF-8');
    }
    
    /**
     * Validate password strength
     */
    public static function validatePassword($password) {
        if (strlen($password) < 6) {
            return ['valid' => false, 'message' => 'Password must be at least 6 characters'];
        }
        if (strlen($password) > 100) {
            return ['valid' => false, 'message' => 'Password is too long'];
        }
        return ['valid' => true];
    }
}
