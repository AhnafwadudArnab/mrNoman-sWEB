<?php
/**
 * Email Service Factory
 * Handles instantiation of email services with dependency injection
 */

// Prevent direct access
if (!defined('SECURE_ACCESS')) {
    http_response_code(403);
    die('Direct access not permitted');
}

class EmailServiceFactory {
    private static $instance = null;
    private $config;
    
    private function __construct(array $config) {
        $this->config = $config;
    }
    
    /**
     * Get factory instance (singleton)
     */
    public static function getInstance(array $config = []): self {
        if (self::$instance === null) {
            self::$instance = new self($config);
        }
        return self::$instance;
    }
    
    /**
     * Create email service based on availability and configuration
     * 
     * @return EmailServiceInterface
     * @throws RuntimeException if no email service is available
     */
    public function createEmailService(): EmailServiceInterface {
        // Priority 1: PHPMailer (most reliable)
        if ($this->isPHPMailerAvailable()) {
            require_once __DIR__ . '/PHPMailerEmailService.php';
            return new PHPMailerEmailService($this->config);
        }
        
        // Priority 2: Production Email Service (SMTP)
        if ($this->isProductionServiceAvailable()) {
            require_once __DIR__ . '/ProductionEmailService.php';
            return new ProductionEmailService($this->config);
        }
        
        // Priority 3: Gmail Email Service (PHP mail())
        if ($this->isGmailServiceAvailable()) {
            require_once __DIR__ . '/GmailEmailService.php';
            return new GmailEmailService($this->config);
        }
        
        throw new RuntimeException('No email service available');
    }
    
    /**
     * Check if PHPMailer is available
     */
    private function isPHPMailerAvailable(): bool {
        // Composer-installed path
        $composerAutoload = __DIR__ . '/../vendor/autoload.php';
        return file_exists($composerAutoload);
    }
    
    /**
     * Check if Production Email Service is available
     */
    private function isProductionServiceAvailable(): bool {
        return !empty($this->config['smtp']['username']) &&
               !empty($this->config['smtp']['password']);
    }
    
    /**
     * Check if Gmail Email Service is available
     */
    private function isGmailServiceAvailable(): bool {
        return function_exists('mail');
    }
}
?>
