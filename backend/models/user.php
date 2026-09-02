<?php
class User {
    private $conn;
    private $table_name = "users";
    
    public $user_id;
    public $full_name;
    public $last_name;
    public $email;
    public $password;
    public $phone_number;
    public $address;
    public $gender;
    public $role;
    public $created_at;
    
    public function __construct($db) {
        $this->conn = $db;
    }
    
    public function create() {
        $query = "INSERT INTO " . $this->table_name . "
                (full_name, last_name, email, password, phone_number, address, gender, role)
                VALUES (:full_name, :last_name, :email, :password, :phone, :address, :gender, :role)";
        
        $stmt = $this->conn->prepare($query);
        
        // Sanitize inputs
        $this->full_name = htmlspecialchars(strip_tags($this->full_name));
        $this->last_name = htmlspecialchars(strip_tags($this->last_name));
        $this->email = htmlspecialchars(strip_tags($this->email));
        $this->phone_number = htmlspecialchars(strip_tags($this->phone_number ?? ''));
        $this->address = htmlspecialchars(strip_tags($this->address ?? ''));
        $this->gender = htmlspecialchars(strip_tags($this->gender ?? 'Male'));
        $this->role = htmlspecialchars(strip_tags($this->role ?? 'customer'));
        
        // Hash password securely
        $hashed_password = password_hash($this->password, PASSWORD_BCRYPT);
        
        $stmt->bindParam(":full_name", $this->full_name);
        $stmt->bindParam(":last_name", $this->last_name);
        $stmt->bindParam(":email", $this->email);
        $stmt->bindParam(":password", $hashed_password);
        $stmt->bindParam(":phone", $this->phone_number);
        $stmt->bindParam(":address", $this->address);
        $stmt->bindParam(":gender", $this->gender);
        $stmt->bindParam(":role", $this->role);
        
        if ($stmt->execute()) {
            $this->user_id = $this->conn->lastInsertId();
            
            // Create profile entry
            $this->createProfile();
            return true;
        }
        return false;
    }
    
    private function createProfile() {
        $query = "INSERT INTO user_profile (user_id, full_name, last_name, phone_number, address, gender)
                  VALUES (:user_id, :full_name, :last_name, :phone, :address, :gender)";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":user_id", $this->user_id);
        $stmt->bindParam(":full_name", $this->full_name);
        $stmt->bindParam(":last_name", $this->last_name);
        $stmt->bindParam(":phone", $this->phone_number);
        $stmt->bindParam(":address", $this->address);
        $stmt->bindParam(":gender", $this->gender);
        $stmt->execute();
    }
    
    public function emailExists() {
        $query = "SELECT user_id, full_name, password, role FROM " . $this->table_name . " WHERE email = :email LIMIT 1";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":email", $this->email);
        $stmt->execute();
        
        if ($stmt->rowCount() > 0) {
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            $this->user_id = $row['user_id'];
            $this->full_name = $row['full_name'];
            $this->password = $row['password'];
            $this->role = $row['role'];
            return true;
        }
        return false;
    }
    
    public function getById($id) {
        $query = "SELECT u.*, up.updated_at 
                  FROM " . $this->table_name . " u
                  LEFT JOIN user_profile up ON u.user_id = up.user_id
                  WHERE u.user_id = :id LIMIT 1";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":id", $id);
        $stmt->execute();
        
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }
    
    public function update() {
        $query = "UPDATE " . $this->table_name . "
                  SET full_name = :full_name, last_name = :last_name, 
                      phone_number = :phone, address = :address, gender = :gender
                  WHERE user_id = :user_id";
        
        $stmt = $this->conn->prepare($query);
        
        $stmt->bindParam(":full_name", $this->full_name);
        $stmt->bindParam(":last_name", $this->last_name);
        $stmt->bindParam(":phone", $this->phone_number);
        $stmt->bindParam(":address", $this->address);
        $stmt->bindParam(":gender", $this->gender);
        $stmt->bindParam(":user_id", $this->user_id);
        
        if ($stmt->execute()) {
            // Update profile too
            $query2 = "UPDATE user_profile SET full_name = :full_name, last_name = :last_name,
                       phone_number = :phone, address = :address, gender = :gender
                       WHERE user_id = :user_id";
            $stmt2 = $this->conn->prepare($query2);
            $stmt2->bindParam(":full_name", $this->full_name);
            $stmt2->bindParam(":last_name", $this->last_name);
            $stmt2->bindParam(":phone", $this->phone_number);
            $stmt2->bindParam(":address", $this->address);
            $stmt2->bindParam(":gender", $this->gender);
            $stmt2->bindParam(":user_id", $this->user_id);
            $stmt2->execute();
            
            return true;
        }
        return false;
    }
}
?>
