<?php
require_once __DIR__ . '/../util/JWT.php';
require_once __DIR__ . '/../util/ApiResponse.php';

/**
 * AuthMiddleware — unified JWT authentication.
 *
 * Tokens are issued by JWT::generate() in login/register/admin-login.
 * JWT::verify() validates them here.
 * bootstrap.php's jwt_encode/jwt_decode are NOT used for auth — they exist
 * as helpers but all actual token issuance goes through JWT class.
 */
class AuthMiddleware {

    public static function authenticate() {
        $token = self::_extractToken();
        if (!$token) {
            ApiResponse::unauthorized('Authentication required', 'No token provided');
        }

        $user_data = JWT::verify($token);
        if (!$user_data) {
            ApiResponse::unauthorized('Authentication required', 'Invalid or expired token');
        }

        return $user_data;
    }

    public static function authenticateAdmin() {
        $user_data = self::authenticate();

        if (!isset($user_data['role']) || strtolower($user_data['role']) !== 'admin') {
            ApiResponse::forbidden('Access denied', 'Admin privileges required');
        }

        return $user_data;
    }

    /**
     * Returns the authenticated user or null (no hard exit).
     * Useful for optional auth endpoints.
     */
    public static function optionalAuth(): ?array {
        $token = self::_extractToken();
        if (!$token) return null;
        return JWT::verify($token) ?: null;
    }

    private static function _extractToken(): ?string {
        $headers = function_exists('getallheaders') ? getallheaders() : [];
        $auth = $headers['Authorization'] ?? $headers['authorization'] ?? '';
        if (!$auth) {
            $auth = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
        }
        if ($auth && stripos($auth, 'Bearer ') === 0) {
            return trim(substr($auth, 7));
        }
        return null;
    }
}
?>
