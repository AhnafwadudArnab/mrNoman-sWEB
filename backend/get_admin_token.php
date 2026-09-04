<?php
header('Content-Type: application/json');
require_once 'config/env.php';
require_once 'api/bootstrap.php';
require_once 'util/JWT.php';

try {
    $pdo = db();
    
    // Get first admin user
    $stmt = $pdo->query("SELECT user_id, full_name, email, role FROM users WHERE role = 'admin' LIMIT 1");
    $admin = $stmt->fetch();
    
    if (!$admin) {
        throw new Exception('No admin found in database');
    }
    
    // Generate JWT token for admin
    $token = JWT::generate([
        'user_id' => (int)$admin['user_id'],
        'email' => $admin['email'],
        'role' => $admin['role'],
        'exp' => time() + (7 * 24 * 60 * 60)
    ]);
    
    echo json_encode([
        'status' => 'success',
        'message' => 'Admin token generated',
        'admin_id' => $admin['user_id'],
        'admin_name' => $admin['full_name'],
        'admin_email' => $admin['email'],
        'token' => $token,
        'token_valid_for' => '7 days',
        'usage' => 'Add this token to Authorization header: Authorization: Bearer ' . $token
    ], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    
} catch (Exception $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage()
    ], JSON_PRETTY_PRINT);
}
?>
