<?php
require_once __DIR__ . '/../vendor/autoload.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

/**
 * Email Service
 * Handles all email notifications
 */
class EmailService {
    private $mailer;
    private $config;
    
    public function __construct() {
        $this->config = require __DIR__ . '/../config.php';
        $this->mailer = new PHPMailer(true);
        $this->configure();
    }
    
    private function configure() {
        $mailConfig = $this->config['mail'];
        
        // Skip SMTP setup if credentials are placeholder/not configured
        if (empty($mailConfig['username']) || 
            $mailConfig['username'] === 'your-email@gmail.com' ||
            empty($mailConfig['password']) ||
            $mailConfig['password'] === 'your-16-digit-app-password') {
            $this->mailer = null;
            return;
        }
        
        try {
            $this->mailer->isSMTP();
            $this->mailer->Host = $mailConfig['host'];
            $this->mailer->SMTPAuth = true;
            $this->mailer->Username = $mailConfig['username'];
            $this->mailer->Password = $mailConfig['password'];
            $this->mailer->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
            $this->mailer->Port = $mailConfig['port'];
            $this->mailer->setFrom($mailConfig['from_address'], $mailConfig['from_name']);
            $this->mailer->CharSet = 'UTF-8';
            $this->mailer->SMTPOptions = [
                'ssl' => [
                    'verify_peer' => false,
                    'verify_peer_name' => false,
                    'allow_self_signed' => true,
                ],
            ];
        } catch (Exception $e) {
            error_log("Email configuration error: " . $e->getMessage());
            $this->mailer = null;
        }
    }
    
    /**
     * Send order confirmation email
     */
    public function sendOrderConfirmation($userEmail, $orderData) {
        if (!$this->mailer) return false; // SMTP not configured
        try {
            $this->mailer->clearAddresses();
            $this->mailer->addAddress($userEmail);
            
            $this->mailer->isHTML(true);
            $this->mailer->Subject = 'Order Confirmation - ' . $orderData['order_id'];
            
            $body = $this->getOrderConfirmationTemplate($orderData);
            $this->mailer->Body = $body;
            $this->mailer->AltBody = strip_tags($body);
            
            $this->mailer->send();
            return true;
        } catch (Exception $e) {
            error_log("Failed to send order confirmation email: " . $e->getMessage());
            return false;
        }
    }
    
    /**
     * Send password reset email
     */
    public function sendPasswordReset($userEmail, $resetToken, $userName) {
        if (!$this->mailer) return false; // SMTP not configured
        try {
            $this->mailer->clearAddresses();
            $this->mailer->addAddress($userEmail);
            
            $this->mailer->isHTML(true);
            $this->mailer->Subject = 'Password Reset Request - ElectrocityBD';
            
            $resetLink = $this->config['app']['url'] . '/reset-password?token=' . $resetToken;
            $body = $this->getPasswordResetTemplate($userName, $resetLink);
            $this->mailer->Body = $body;
            $this->mailer->AltBody = strip_tags($body);
            
            $this->mailer->send();
            return true;
        } catch (Exception $e) {
            error_log("Failed to send password reset email: " . $e->getMessage());
            return false;
        }
    }
    
    /**
     * Send order status update email
     */
    public function sendOrderStatusUpdate($userEmail, $orderData, $newStatus) {
        if (!$this->mailer) return false; // SMTP not configured
        try {
            $this->mailer->clearAddresses();
            $this->mailer->addAddress($userEmail);
            
            $this->mailer->isHTML(true);
            $this->mailer->Subject = 'Order Status Update - ' . $orderData['order_id'];
            
            $body = $this->getOrderStatusTemplate($orderData, $newStatus);
            $this->mailer->Body = $body;
            $this->mailer->AltBody = strip_tags($body);
            
            $this->mailer->send();
            return true;
        } catch (Exception $e) {
            error_log("Failed to send order status email: " . $e->getMessage());
            return false;
        }
    }
    
    /**
     * Send welcome email
     */
    public function sendWelcomeEmail($userEmail, $userName) {
        if (!$this->mailer) return false; // SMTP not configured
        try {
            $this->mailer->clearAddresses();
            $this->mailer->addAddress($userEmail);
            
            $this->mailer->isHTML(true);
            $this->mailer->Subject = 'Welcome to ElectrocityBD!';
            
            $body = $this->getWelcomeTemplate($userName);
            $this->mailer->Body = $body;
            $this->mailer->AltBody = strip_tags($body);
            
            $this->mailer->send();
            return true;
        } catch (Exception $e) {
            error_log("Failed to send welcome email: " . $e->getMessage());
            return false;
        }
    }
    
    // Email Templates
    
    private function getOrderConfirmationTemplate($orderData) {
        $orderId = htmlspecialchars($orderData['order_id']);
        $total = htmlspecialchars($orderData['total_amount']);
        $paymentMethod = htmlspecialchars($orderData['payment_method']);
        $deliveryAddress = htmlspecialchars($orderData['delivery_address']);
        $estimatedDelivery = htmlspecialchars($orderData['estimated_delivery'] ?? '5-7 business days');
        
        return <<<HTML
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #1B4D3E; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background: #f9f9f9; }
        .order-details { background: white; padding: 15px; margin: 15px 0; border-radius: 5px; }
        .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        .button { display: inline-block; padding: 10px 20px; background: #B8860B; color: white; text-decoration: none; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>✓ Order Confirmed!</h1>
        </div>
        <div class="content">
            <p>Thank you for your order! We're processing it now.</p>
            
            <div class="order-details">
                <h3>Order Details</h3>
                <p><strong>Order ID:</strong> {$orderId}</p>
                <p><strong>Total Amount:</strong> ৳{$total}</p>
                <p><strong>Payment Method:</strong> {$paymentMethod}</p>
                <p><strong>Delivery Address:</strong> {$deliveryAddress}</p>
                <p><strong>Estimated Delivery:</strong> {$estimatedDelivery}</p>
            </div>
            
            <p style="text-align: center;">
                <a href="{$this->config['app']['url']}/orders/{$orderId}" class="button">Track Your Order</a>
            </p>
        </div>
        <div class="footer">
            <p>ElectrocityBD - Your Trusted Electronics Store</p>
            <p>If you have any questions, contact us at support@electrocitybd.com</p>
        </div>
    </div>
</body>
</html>
HTML;
    }
    
    private function getPasswordResetTemplate($userName, $resetLink) {
        $name = htmlspecialchars($userName);
        
        return <<<HTML
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #1B4D3E; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background: #f9f9f9; }
        .button { display: inline-block; padding: 12px 30px; background: #B8860B; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
        .warning { background: #fff3cd; border-left: 4px solid #ffc107; padding: 10px; margin: 15px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Password Reset Request</h1>
        </div>
        <div class="content">
            <p>Hello {$name},</p>
            <p>We received a request to reset your password. Click the button below to create a new password:</p>
            
            <p style="text-align: center;">
                <a href="{$resetLink}" class="button">Reset Password</a>
            </p>
            
            <div class="warning">
                <strong>⚠️ Security Notice:</strong>
                <ul>
                    <li>This link expires in 1 hour</li>
                    <li>If you didn't request this, please ignore this email</li>
                    <li>Never share this link with anyone</li>
                </ul>
            </div>
            
            <p style="font-size: 12px; color: #666;">
                If the button doesn't work, copy and paste this link:<br>
                {$resetLink}
            </p>
        </div>
    </div>
</body>
</html>
HTML;
    }
    
    private function getOrderStatusTemplate($orderData, $newStatus) {
        $orderId = htmlspecialchars($orderData['order_id']);
        $status = htmlspecialchars($newStatus);
        
        $statusMessages = [
            'pending' => 'Your order is being processed.',
            'confirmed' => 'Your order has been confirmed!',
            'processing' => 'We are preparing your order for shipment.',
            'shipped' => 'Your order has been shipped!',
            'delivered' => 'Your order has been delivered. Thank you!',
            'cancelled' => 'Your order has been cancelled.',
        ];
        
        $message = $statusMessages[$newStatus] ?? 'Your order status has been updated.';
        
        return <<<HTML
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #1B4D3E; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background: #f9f9f9; }
        .status-badge { display: inline-block; padding: 8px 16px; background: #B8860B; color: white; border-radius: 20px; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Order Status Update</h1>
        </div>
        <div class="content">
            <p><strong>Order ID:</strong> {$orderId}</p>
            <p><strong>New Status:</strong> <span class="status-badge">{$status}</span></p>
            <p>{$message}</p>
            <p style="text-align: center; margin-top: 20px;">
                <a href="{$this->config['app']['url']}/orders/{$orderId}" style="color: #B8860B;">View Order Details</a>
            </p>
        </div>
    </div>
</body>
</html>
HTML;
    }
    
    private function getWelcomeTemplate($userName) {
        $name = htmlspecialchars($userName);
        
        return <<<HTML
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #1B4D3E; color: white; padding: 30px; text-align: center; }
        .content { padding: 20px; background: #f9f9f9; }
        .button { display: inline-block; padding: 12px 30px; background: #B8860B; color: white; text-decoration: none; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Welcome to ElectrocityBD! 🎉</h1>
        </div>
        <div class="content">
            <p>Hello {$name},</p>
            <p>Thank you for joining ElectrocityBD! We're excited to have you as part of our community.</p>
            
            <h3>What's Next?</h3>
            <ul>
                <li>Browse our wide range of electronics</li>
                <li>Enjoy exclusive deals and offers</li>
                <li>Track your orders easily</li>
                <li>Get fast and reliable delivery</li>
            </ul>
            
            <p style="text-align: center; margin-top: 30px;">
                <a href="{$this->config['app']['url']}" class="button">Start Shopping</a>
            </p>
            
            <p style="margin-top: 30px; font-size: 14px; color: #666;">
                Need help? Contact us at support@electrocitybd.com
            </p>
        </div>
    </div>
</body>
</html>
HTML;
    }
}
?>
