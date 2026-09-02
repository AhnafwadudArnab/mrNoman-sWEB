<?php
require_once __DIR__ . '/../models/user.php';
require_once __DIR__ . '/../util/JWT.php';

class AuthController {
    private $db;
    private $user;
    
    public function __construct($db) {
        $this->db = $db;
        $this->user = new User($db);
    }
    
    public function register($data) {
        if (!isset($data['full_name']) || !isset($data['email']) || !isset($data['password'])) {
            http_response_code(400);
            return ['message' => 'Missing required fields'];
        }
        
        // Validate email format
        if (!filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
            http_response_code(400);
            return ['message' => 'Invalid email format'];
        }
        
        // Validate password strength
        if (strlen($data['password']) < 6) {
            http_response_code(400);
            return ['message' => 'Password must be at least 6 characters'];
        }
        
        // Check if email exists
        $this->user->email = $data['email'];
        if ($this->user->emailExists()) {
            http_response_code(400);
            return ['message' => 'Email already exists'];
        }
        
        // Create user
        $this->user->full_name = $data['full_name'];
        $this->user->last_name = $data['last_name'] ?? '';
        $this->user->email = $data['email'];
        $this->user->password = $data['password'];
        $this->user->phone_number = $data['phone'] ?? '';
        $this->user->address = $data['address'] ?? '';
        $this->user->gender = $data['gender'] ?? 'Male';
        $this->user->role = 'customer';
        
        if ($this->user->create()) {
            // Generate token
            $token_data = [
                'user_id' => $this->user->user_id,
                'email' => $this->user->email,
                'role' => $this->user->role,
                'exp' => time() + (7 * 24 * 60 * 60) // 7 days
            ];
            
            $token = JWT::generate($token_data);
            
            return [
                'message' => 'Registration successful',
                'token' => $token,
                'user' => [
                    'user_id' => $this->user->user_id,
                    'full_name' => $this->user->full_name,
                    'email' => $this->user->email,
                    'role' => $this->user->role
                ]
            ];
        }
        
        http_response_code(500);
        return ['message' => 'Registration failed'];
    }
    
    public function login($data) {
        if (!isset($data['email']) || !isset($data['password'])) {
            http_response_code(400);
            return ['message' => 'Email and password required'];
        }
        
        $this->user->email = $data['email'];
        
        if (!$this->user->emailExists()) {
            http_response_code(401);
            return ['message' => 'Invalid email or password'];
        }
        
        // Verify password
        if (!password_verify($data['password'], $this->user->password)) {
            http_response_code(401);
            return ['message' => 'Invalid email or password'];
        }
        
        // Generate token
        $token_data = [
            'user_id' => $this->user->user_id,
            'email' => $this->user->email,
            'role' => $this->user->role,
            'exp' => time() + (7 * 24 * 60 * 60) // 7 days
        ];
        
        $token = JWT::generate($token_data);
        
        $user_info = $this->user->getById($this->user->user_id);
        
        return [
            'message' => 'Login successful',
            'token' => $token,
            'user' => $user_info
        ];
    }
    
    public function adminLogin($data) {
        if (!isset($data['username']) || !isset($data['password'])) {
            http_response_code(400);
            return ['message' => 'Username and password required'];
        }
        
        // Admin login - only allow email-based login for security
        $email = trim($data['username']);
        
        $query = "SELECT user_id, full_name, last_name, email, password, phone_number, address, gender, role
                  FROM users
                  WHERE role = 'admin' AND email = :email
                  LIMIT 1";
        $stmt = $this->db->prepare($query);
        $stmt->bindParam(':email', $email);
        $stmt->execute();

                if ($stmt->rowCount() === 0) {
            http_response_code(401);
            return ['message' => 'Invalid admin credentials'];
        }

                $admin = $stmt->fetch(PDO::FETCH_ASSOC);

                $this->user->user_id = $admin['user_id'];
                $this->user->full_name = $admin['full_name'];
                $this->user->last_name = $admin['last_name'];
                $this->user->email = $admin['email'];
                $this->user->password = $admin['password'];
                $this->user->phone_number = $admin['phone_number'];
                $this->user->address = $admin['address'];
                $this->user->gender = $admin['gender'];
                $this->user->role = $admin['role'];
        
        // Verify admin password
        if (!password_verify($data['password'], $this->user->password)) {
            http_response_code(401);
            return ['message' => 'Invalid admin credentials'];
        }
        
        // Generate token
        $token_data = [
            'user_id' => $this->user->user_id,
            'email' => $this->user->email,
            'role' => $this->user->role,
            'exp' => time() + (7 * 24 * 60 * 60)
        ];
        
        $token = JWT::generate($token_data);
        
        $user_info = $this->user->getById($this->user->user_id);
        
        return [
            'message' => 'Admin login successful',
            'token' => $token,
            'user' => $user_info
        ];
    }
}
?>
