<?php
/**
 * Script to create a new admin user
 * Usage: php scripts/create_admin.php
 */

require_once __DIR__ . '/../api/bootstrap.php';

$db = db();

// Check if admin already exists
$check = $db->prepare("SELECT user_id FROM users WHERE LOWER(role) = 'admin' LIMIT 1");
$check->execute();

if ($check->rowCount() > 0) {
    $existing = $check->fetch(PDO::FETCH_ASSOC);
    echo "Admin already exists with user_id: " . $existing['user_id'] . "\n";
    echo "Updating password for existing admin...\n";
    
    $password = 'admin123';
    $hash = password_hash($password, PASSWORD_BCRYPT);
    
    $update = $db->prepare("UPDATE users SET password = :password WHERE user_id = :user_id");
    $update->bindParam(':password', $hash);
    $update->bindParam(':user_id', $existing['user_id'], PDO::PARAM_INT);
    $update->execute();
    
    echo "Password updated!\n";
    echo "Login credentials:\n";
    echo "  Email: " . getEmail($db, $existing['user_id']) . "\n";
    echo "  Password: $password\n";
    exit(0);
}

// Create new admin
$fullName = 'Admin';
$lastName = 'User';
$email = 'admin@electrozonebd.com';
$password = 'admin123';
$phone = '01700000000';
$hash = password_hash($password, PASSWORD_BCRYPT);

$insert = $db->prepare("
    INSERT INTO users (full_name, last_name, email, password, phone_number, role, gender)
    VALUES (:full_name, :last_name, :email, :password, :phone, 'admin', 'other')
");

$insert->bindParam(':full_name', $fullName);
$insert->bindParam(':last_name', $lastName);
$insert->bindParam(':email', $email);
$insert->bindParam(':password', $hash);
$insert->bindParam(':phone', $phone);

if ($insert->execute()) {
    echo "Admin user created successfully!\n\n";
    echo "Login credentials:\n";
    echo "  Username/Email: $email\n";
    echo "  Username/Name: $fullName\n";
    echo "  Password: $password\n";
} else {
    echo "Failed to create admin user\n";
    print_r($insert->errorInfo());
}

function getEmail($db, $userId) {
    $stmt = $db->prepare("SELECT email FROM users WHERE user_id = :id");
    $stmt->bindParam(':id', $userId, PDO::PARAM_INT);
    $stmt->execute();
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    return $result['email'] ?? 'unknown';
}
?>
