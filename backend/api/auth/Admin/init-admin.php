<?php
// Run this file once to create admin user
require_once __DIR__ . '/../bootstrap.php';

$db = db();

// Admin credentials
$adminEmail = 'ahnaf@electrocitybd.com';
$adminPassword = '1234@';
$adminFullName = 'Ahnaf';
$adminLastName = 'Admin';

// Check if admin exists
$checkQuery = "SELECT user_id FROM users WHERE email = :email";
$checkStmt = $db->prepare($checkQuery);
$checkStmt->bindParam(':email', $adminEmail);
$checkStmt->execute();

if ($checkStmt->rowCount() === 0) {
    // Create admin user
    $hashedPassword = $adminPassword;
    
    $query = "INSERT INTO users (full_name, last_name, email, password, role) 
              VALUES (:full_name, :last_name, :email, :password, 'admin')";
    
    $stmt = $db->prepare($query);
    $stmt->bindParam(':full_name', $adminFullName);
    $stmt->bindParam(':last_name', $adminLastName);
    $stmt->bindParam(':email', $adminEmail);
    $stmt->bindParam(':password', $hashedPassword);
    
    if ($stmt->execute()) {
        $userId = $db->lastInsertId();
        
        // Create profile
        $profileQuery = "INSERT INTO user_profile (user_id, full_name, last_name) 
                         VALUES (:user_id, :full_name, :last_name)";
        $profileStmt = $db->prepare($profileQuery);
        $profileStmt->bindParam(':user_id', $userId);
        $profileStmt->bindParam(':full_name', $adminFullName);
        $profileStmt->bindParam(':last_name', $adminLastName);
        $profileStmt->execute();
        
        echo "Admin user created successfully!\n";
        echo "Email: $adminEmail\n";
        echo "Password: $adminPassword\n";
    } else {
        echo "Failed to create admin user\n";
    }
} else {
    echo "Admin user already exists\n";
    echo "Email: $adminEmail\n";
    echo "Password: $adminPassword\n";
}
?>
