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
    
    // Auto-provision authorized system admins if missing in cPanel DB
    $normalizedEmail = strtolower(trim($email));
    $systemAdmins = [
        'adminnoman@electrozonebd.com' => [
            'full_name' => 'Admin Noman',
            'email' => 'adminNoman@electrozonebd.com',
            'password' => '$2y$12$a7kL/Ajes1T7GY1NDa4FEOEaz06Ag2QGTmsUjPxcoBUWK8QkCqM8O',
            'phone' => '01700000001'
        ],
        'superadmin_roz@electrozonebd.com' => [
            'full_name' => 'Super Admin Roz',
            'email' => 'superadmin_roz@electrozonebd.com',
            'password' => '$2y$12$V3IrAHgZLqrt7vGLJKJEwOAJpFE4M23O1KPffzJ93XMe9XPrQIfwK',
            'phone' => '01700000002'
        ],
        'superadmin@ez.com' => [
            'full_name' => 'Super Admin EZ',
            'email' => 'superadmin@ez.com',
            'password' => '$2y$12$dX/BFd4P7Y/nsH1C21E18.b0WOfBICLCauJNaV3PH8yfMJxc658b2',
            'phone' => '01700000003'
        ]
    ];

    if (isset($systemAdmins[$normalizedEmail])) {
        try {
            $sa = $systemAdmins[$normalizedEmail];
            $chk = $db->prepare("SELECT user_id FROM users WHERE LOWER(email) = ? LIMIT 1");
            $chk->execute([$normalizedEmail]);
            if ($chk->rowCount() === 0) {
                $ins = $db->prepare("INSERT INTO users (full_name, email, password, role, phone_number, gender) VALUES (?, ?, ?, 'admin', ?, 'Male')");
                $ins->execute([$sa['full_name'], $sa['email'], $sa['password'], $sa['phone']]);
            }
            $db->exec("DELETE FROM users WHERE email = 'admin@electrozonebd.com'");
        } catch (Exception $e) {}
    }

    // Check if it's admin login attempt (based on email pattern or specific check)
    $isAdminAttempt = strpos($normalizedEmail, 'admin') !== false || $normalizedEmail === 'ahnaf@electrocitybd.com';

    $query = "SELECT user_id, full_name, last_name, email, password, phone_number, address, gender, role 
              FROM users WHERE LOWER(email) = :email";
    
    $stmt = $db->prepare($query);
    $stmt->bindParam(':email', $normalizedEmail);
    $stmt->execute();
    
    if ($stmt->rowCount() === 0) {
        RateLimitMiddleware::recordFailedLogin($clientIP);
        Logger::logAuth('login_failed', null, $email, false);
        Logger::logSecurity('failed_login_attempt', ['email' => $email, 'reason' => 'user_not_found']);
        http_response_code(401);
        echo json_encode(['message' => 'User account does not exist']);
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
    
    // For admin login attempt flag, verify role is admin if specified
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
