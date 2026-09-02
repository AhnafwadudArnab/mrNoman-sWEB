<?php
/**
 * Input Validation Utility
 * Provides validation functions for API inputs
 */
class Validator {
    private $errors = [];
    
    /**
     * Validate required field
     */
    public function required($field, $value, $fieldName = null) {
        $name = $fieldName ?? $field;
        if (empty($value) && $value !== '0' && $value !== 0) {
            $this->errors[$field] = "{$name} is required";
            return false;
        }
        return true;
    }
    
    /**
     * Validate string length
     */
    public function length($field, $value, $min = null, $max = null, $fieldName = null) {
        $name = $fieldName ?? $field;
        $len = strlen($value);
        
        if ($min !== null && $len < $min) {
            $this->errors[$field] = "{$name} must be at least {$min} characters";
            return false;
        }
        
        if ($max !== null && $len > $max) {
            $this->errors[$field] = "{$name} must not exceed {$max} characters";
            return false;
        }
        
        return true;
    }
    
    /**
     * Validate email format
     */
    public function email($field, $value, $fieldName = null) {
        $name = $fieldName ?? $field;
        if (!filter_var($value, FILTER_VALIDATE_EMAIL)) {
            $this->errors[$field] = "{$name} must be a valid email address";
            return false;
        }
        return true;
    }
    
    /**
     * Validate numeric value
     */
    public function numeric($field, $value, $fieldName = null) {
        $name = $fieldName ?? $field;
        if (!is_numeric($value)) {
            $this->errors[$field] = "{$name} must be a valid number";
            return false;
        }
        return true;
    }
    
    /**
     * Validate integer value
     */
    public function integer($field, $value, $fieldName = null) {
        $name = $fieldName ?? $field;
        if (!filter_var($value, FILTER_VALIDATE_INT) && $value !== 0) {
            $this->errors[$field] = "{$name} must be a valid integer";
            return false;
        }
        return true;
    }
    
    /**
     * Validate value is within range
     */
    public function range($field, $value, $min, $max, $fieldName = null) {
        $name = $fieldName ?? $field;
        if ($value < $min || $value > $max) {
            $this->errors[$field] = "{$name} must be between {$min} and {$max}";
            return false;
        }
        return true;
    }
    
    /**
     * Validate value is in allowed list
     */
    public function inArray($field, $value, $allowed, $fieldName = null) {
        $name = $fieldName ?? $field;
        if (!in_array($value, $allowed)) {
            $allowedStr = implode(', ', $allowed);
            $this->errors[$field] = "{$name} must be one of: {$allowedStr}";
            return false;
        }
        return true;
    }
    
    /**
     * Validate slug format (kebab-case)
     */
    public function slug($field, $value, $fieldName = null) {
        $name = $fieldName ?? $field;
        if (!preg_match('/^[a-z0-9]+(?:-[a-z0-9]+)*$/', $value)) {
            $this->errors[$field] = "{$name} must be in kebab-case format (lowercase letters, numbers, and hyphens)";
            return false;
        }
        return true;
    }
    
    /**
     * Get all validation errors
     */
    public function getErrors() {
        return $this->errors;
    }
    
    /**
     * Check if validation has errors
     */
    public function hasErrors() {
        return !empty($this->errors);
    }
    
    /**
     * Clear all errors
     */
    public function clearErrors() {
        $this->errors = [];
    }
}
?>
