<?php
/**
 * Logging System
 * Structured logging with rotation and levels
 */

class Logger {
    const DEBUG = 'DEBUG';
    const INFO = 'INFO';
    const WARNING = 'WARNING';
    const ERROR = 'ERROR';
    const CRITICAL = 'CRITICAL';
    
    private static $logDir = __DIR__ . '/../storage/logs';
    private static $maxFileSize = 10485760; // 10MB
    private static $maxFiles = 10;
    
    /**
     * Log a message
     */
    public static function log($level, $message, $context = []) {
        $config = require __DIR__ . '/../config.php';
        
        // Don't log debug messages in production
        if ($level === self::DEBUG && $config['app']['env'] === 'production') {
            return;
        }
        
        // Ensure log directory exists
        if (!is_dir(self::$logDir)) {
            mkdir(self::$logDir, 0755, true);
        }
        
        // Determine log file
        $logFile = self::$logDir . '/' . date('Y-m-d') . '.log';
        
        // Check file size and rotate if needed
        if (file_exists($logFile) && filesize($logFile) > self::$maxFileSize) {
            self::rotateLog($logFile);
        }
        
        // Format log entry
        $timestamp = date('Y-m-d H:i:s');
        $contextStr = !empty($context) ? ' ' . json_encode($context) : '';
        $logEntry = "[{$timestamp}] [{$level}] {$message}{$contextStr}" . PHP_EOL;
        
        // Write to file
        file_put_contents($logFile, $logEntry, FILE_APPEND | LOCK_EX);
        
        // Also log to PHP error log for critical errors
        if ($level === self::CRITICAL || $level === self::ERROR) {
            error_log("[{$level}] {$message}");
        }
    }
    
    /**
     * Log debug message
     */
    public static function debug($message, $context = []) {
        self::log(self::DEBUG, $message, $context);
    }
    
    /**
     * Log info message
     */
    public static function info($message, $context = []) {
        self::log(self::INFO, $message, $context);
    }
    
    /**
     * Log warning message
     */
    public static function warning($message, $context = []) {
        self::log(self::WARNING, $message, $context);
    }
    
    /**
     * Log error message
     */
    public static function error($message, $context = []) {
        self::log(self::ERROR, $message, $context);
    }
    
    /**
     * Log critical message
     */
    public static function critical($message, $context = []) {
        self::log(self::CRITICAL, $message, $context);
    }
    
    /**
     * Log API request
     */
    public static function logRequest($method, $endpoint, $userId = null, $ip = null) {
        $context = [
            'method' => $method,
            'endpoint' => $endpoint,
            'user_id' => $userId,
            'ip' => $ip ?? $_SERVER['REMOTE_ADDR'] ?? 'unknown',
            'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? 'unknown'
        ];
        
        self::info("API Request: {$method} {$endpoint}", $context);
    }
    
    /**
     * Log API response
     */
    public static function logResponse($endpoint, $statusCode, $duration = null) {
        $context = [
            'endpoint' => $endpoint,
            'status_code' => $statusCode,
            'duration_ms' => $duration
        ];
        
        $level = $statusCode >= 500 ? self::ERROR : ($statusCode >= 400 ? self::WARNING : self::INFO);
        self::log($level, "API Response: {$endpoint} - {$statusCode}", $context);
    }
    
    /**
     * Log database query
     */
    public static function logQuery($query, $params = [], $duration = null) {
        $context = [
            'query' => $query,
            'params' => $params,
            'duration_ms' => $duration
        ];
        
        self::debug("Database Query", $context);
    }
    
    /**
     * Log authentication event
     */
    public static function logAuth($event, $userId = null, $email = null, $success = true) {
        $context = [
            'event' => $event,
            'user_id' => $userId,
            'email' => $email,
            'success' => $success,
            'ip' => $_SERVER['REMOTE_ADDR'] ?? 'unknown'
        ];
        
        $level = $success ? self::INFO : self::WARNING;
        self::log($level, "Auth Event: {$event}", $context);
    }
    
    /**
     * Log order event
     */
    public static function logOrder($event, $orderId, $userId, $amount = null) {
        $context = [
            'event' => $event,
            'order_id' => $orderId,
            'user_id' => $userId,
            'amount' => $amount
        ];
        
        self::info("Order Event: {$event}", $context);
    }
    
    /**
     * Log payment event
     */
    public static function logPayment($event, $orderId, $method, $amount, $transactionId = null) {
        $context = [
            'event' => $event,
            'order_id' => $orderId,
            'method' => $method,
            'amount' => $amount,
            'transaction_id' => $transactionId
        ];
        
        self::info("Payment Event: {$event}", $context);
    }
    
    /**
     * Log security event
     */
    public static function logSecurity($event, $details = []) {
        $context = array_merge([
            'event' => $event,
            'ip' => $_SERVER['REMOTE_ADDR'] ?? 'unknown',
            'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? 'unknown'
        ], $details);
        
        self::warning("Security Event: {$event}", $context);
    }
    
    /**
     * Rotate log file
     */
    private static function rotateLog($logFile) {
        $basename = basename($logFile, '.log');
        $dirname = dirname($logFile);
        
        // Shift existing rotated files
        for ($i = self::$maxFiles - 1; $i > 0; $i--) {
            $oldFile = "{$dirname}/{$basename}.{$i}.log";
            $newFile = "{$dirname}/{$basename}." . ($i + 1) . ".log";
            
            if (file_exists($oldFile)) {
                if ($i === self::$maxFiles - 1) {
                    unlink($oldFile); // Delete oldest
                } else {
                    rename($oldFile, $newFile);
                }
            }
        }
        
        // Rotate current file
        rename($logFile, "{$dirname}/{$basename}.1.log");
    }
    
    /**
     * Clean old log files
     */
    public static function cleanOldLogs($daysToKeep = 30) {
        if (!is_dir(self::$logDir)) {
            return;
        }
        
        $files = glob(self::$logDir . '/*.log');
        $cutoffTime = time() - ($daysToKeep * 24 * 60 * 60);
        
        foreach ($files as $file) {
            if (filemtime($file) < $cutoffTime) {
                unlink($file);
            }
        }
    }
    
    /**
     * Get recent logs
     */
    public static function getRecentLogs($lines = 100) {
        $logFile = self::$logDir . '/' . date('Y-m-d') . '.log';
        
        if (!file_exists($logFile)) {
            return [];
        }
        
        $content = file($logFile);
        return array_slice($content, -$lines);
    }
}
?>
