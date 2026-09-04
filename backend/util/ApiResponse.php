<?php
/**
 * API Response Handler
 * Provides consistent JSON response formatting for all API endpoints
 */
class ApiResponse {
    
    /**
     * Send a success response
     */
    public static function success($data = null, $message = 'Operation completed successfully', $statusCode = 200) {
        http_response_code($statusCode);
        $response = [
            'success' => true,
            'message' => $message
        ];
        
        if ($data !== null) {
            $response['data'] = $data;
        }
        
        echo json_encode($response);
        exit;
    }
    
    /**
     * Send an error response
     */
    public static function error($message, $error = null, $statusCode = 400) {
        http_response_code($statusCode);
        $response = [
            'success' => false,
            'message' => $message
        ];
        
        if ($error !== null) {
            $response['error'] = $error;
        }
        
        echo json_encode($response);
        exit;
    }
    
    /**
     * Send a paginated response
     */
    public static function paginated($data, $currentPage, $totalPages, $perPage, $totalItems, $message = 'Data retrieved successfully') {
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => $message,
            'data' => $data,
            'pagination' => [
                'current_page' => (int)$currentPage,
                'total_pages' => (int)$totalPages,
                'per_page' => (int)$perPage,
                'total_items' => (int)$totalItems
            ]
        ]);
        exit;
    }
    
    /**
     * Send validation error response
     */
    public static function validationError($errors, $message = 'Validation failed') {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => $message,
            'errors' => $errors
        ]);
        exit;
    }
    
    /**
     * Send unauthorized response (401)
     */
    public static function unauthorized($message = 'Authentication required', $error = 'Invalid or expired token') {
        self::error($message, $error, 401);
    }
    
    /**
     * Send forbidden response (403)
     */
    public static function forbidden($message = 'Access denied', $error = 'Insufficient permissions') {
        self::error($message, $error, 403);
    }
    
    /**
     * Send not found response (404)
     */
    public static function notFound($message = 'Resource not found', $error = null) {
        self::error($message, $error, 404);
    }
    
    /**
     * Send internal server error response (500)
     */
    public static function serverError($message = 'Internal server error', $error = 'An unexpected error occurred') {
        self::error($message, $error, 500);
    }
}
?>
