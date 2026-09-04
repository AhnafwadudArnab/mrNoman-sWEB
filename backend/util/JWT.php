<?php
class JWT {
    private static $algorithm = 'HS256';
    
    private static function getSecretKey() {
        // Get secret from environment variable or config
        $secret = getenv('JWT_SECRET') ?: getenv('ECITY_JWT_SECRET');
        if (!$secret) {
            // Fallback to config file
            $config = require __DIR__ . '/../config.php';
            $secret = $config['auth']['jwt_secret'] ?? null;
        }
        
        // Validate in production - fail fast if secret not set
        if (!$secret || strlen(trim($secret)) === 0) {
            $env = getenv('APP_ENV') ?: 'development';
            if ($env === 'production') {
                error_log('CRITICAL: JWT_SECRET environment variable is not set in production mode');
                throw new Exception('JWT_SECRET not configured in production environment');
            }
            // Development fallback only
            $secret = 'ElectrocityBD_Secret_Key_2024_DEV_ONLY';
        }
        
        return $secret;
    }
    
    public static function generate($data) {
        $header = json_encode(['typ' => 'JWT', 'alg' => self::$algorithm]);
        $payload = json_encode($data);
        
        $base64UrlHeader = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($header));
        $base64UrlPayload = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($payload));
        
        $signature = hash_hmac('sha256', $base64UrlHeader . "." . $base64UrlPayload, self::getSecretKey(), true);
        $base64UrlSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));
        
        return $base64UrlHeader . "." . $base64UrlPayload . "." . $base64UrlSignature;
    }
    
    public static function verify($token) {
        $parts = explode('.', $token);
        if (count($parts) != 3) return false;
        
        $header = $parts[0];
        $payload = $parts[1];
        $signature = $parts[2];
        
        $base64UrlHeader = str_replace(['-', '_'], ['+', '/'], $header);
        $base64UrlPayload = str_replace(['-', '_'], ['+', '/'], $payload);
        $base64UrlSignature = str_replace(['-', '_'], ['+', '/'], $signature);
        
        $signature_check = hash_hmac('sha256', $header . "." . $payload, self::getSecretKey(), true);
        $base64UrlSignature_check = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature_check));
        
        if ($base64UrlSignature_check !== $signature) return false;
        
        $payload_data = json_decode(base64_decode($base64UrlPayload), true);
        if (isset($payload_data['exp']) && $payload_data['exp'] < time()) return false;
        
        return $payload_data;
    }
}
?>