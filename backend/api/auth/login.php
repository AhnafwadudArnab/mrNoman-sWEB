<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../bootstrap.php';
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../util/JWT.php';
require_once __DIR__ . '/../../middleware/RateLimitMiddleware.php';
require_once __DIR__ . '/../../util/InputSanitizer.php';
require_once __DIR__ . '/../../util/Logger.php';

$db = db();

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'POST') {
    // Rate limiting - check login attempts
    $clientIP = RateLimitMiddleware::getClientIP();
    RateLimitMiddleware::checkLoginAttempts($clientIP);
    
    // General rate limiting
    RateLimitMiddleware::check($clientIP, 10, 60); // 10 requests per minute
    
    $data = json_decode(file_get_contents('php://input'), true);
    
    $email = InputSanitizer::sanitizeEmail($data['email'] ?? '');
    $password = $data['password'] ?? '';
    
    if (empty($email) || empty($password)) {
        Logger::logAuth('login_attempt', null, $email, false);
        http_response_code(400);
        echo json_encode(['message' => 'Email and password required']);
        exit;
    }
    
    // Check if it's admin login attempt (based on email pattern or specific check)
    $isAdminAttempt = strpos($email, 'admin') !== false || $email === 'ahnaf@electrocitybd.com';
    
    $query = "SELECT user_id, full_name, last_name, email, password, phone_number, address, gender, role 
              FROM users WHERE email = :email";
    
    $stmt = $db->prepare($query);
    $stmt->bindParam(':email', $email);
    $stmt->execute();
    
    if ($stmt->rowCount() === 0) {
        RateLimitMiddleware::recordFailedLogin($clientIP);
        Logger::logAuth('login_failed', null, $email, false);
        Logger::logSecurity('failed_login_attempt', ['email' => $email, 'reason' => 'user_not_found']);
        http_response_code(401);
        echo json_encode(['message' => 'Invalid email or password']);
        exit;
    }
    
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // Verify password — bcrypt only. Plaintext passwords are no longer accepted.
    $passwordOk = password_verify($password, $user['password']);
    if (!$passwordOk) {
        RateLimitMiddleware::recordFailedLogin($clientIP);
        Logger::logAuth('login_failed', $user['user_id'], $email, false);
        Logger::logSecurity('failed_login_attempt', ['email' => $email, 'reason' => 'invalid_password']);
        http_response_code(401);
        echo json_encode(['message' => 'Invalid email or password']);
        exit;
    }

    if (!password_get_info((string)$user['password'])['algo']) {
        $rehash = $db->prepare('UPDATE users SET password = :password WHERE user_id = :user_id');
        $newHash = password_hash($password, PASSWORD_BCRYPT);
        $rehash->bindParam(':password', $newHash);
        $rehash->bindParam(':user_id', $user['user_id'], PDO::PARAM_INT);
        $rehash->execute();
    }
    
    // Block admin accounts from using regular login — they must use /auth/admin-login
    if ($user['role'] === 'admin') {
        RateLimitMiddleware::recordFailedLogin($clientIP);
        Logger::logAuth('admin_login_via_regular', $user['user_id'], $email, false);
        Logger::logSecurity('admin_blocked_regular_login', ['email' => $email]);
        http_response_code(403);
        echo json_encode(['message' => 'Admin accounts must use the Admin Login button.']);
        exit;
    }

    // For admin login, verify role is admin
    if ($isAdminAttempt && $user['role'] !== 'admin') {
        RateLimitMiddleware::recordFailedLogin($clientIP);
        Logger::logAuth('admin_login_denied', $user['user_id'], $email, false);
        Logger::logSecurity('unauthorized_admin_access', ['email' => $email]);
        http_response_code(403);
        echo json_encode(['message' => 'Access denied. Admin only.']);
        exit;
    }
    
    // Reset login attempts on successful login
    RateLimitMiddleware::resetLoginAttempts($clientIP);
    
    $token = JWT::generate([
        'user_id' => (int)$user['user_id'],
        'email' => $user['email'],
        'role' => $user['role'],
        'exp' => time() + (7 * 24 * 60 * 60)
    ]);
    
    // Log successful login
    Logger::logAuth('login_success', $user['user_id'], $email, true);
    
    // Return user data (without password)
    unset($user['password']);
    
    echo json_encode([
        'token' => $token,
        'user' => [
            'user_id' => $user['user_id'],
            'firstName' => $user['full_name'],
            'lastName' => $user['last_name'],
            'email' => $user['email'],
            'phone' => $user['phone_number'],
            'gender' => $user['gender'],
            'role' => $user['role']
        ]
    ]);
    
} else {
    http_response_code(405);
    echo json_encode(['message' => 'Method not allowed']);
}
?>
