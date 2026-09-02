<?php
/**
 * Password Migration Script
 * Converts any plaintext passwords to bcrypt hashes
 * Run once: php backend/scripts/migrate_passwords.php
 */

require_once __DIR__ . '/../config/database.php';

function db() {
    return Database::getInstance()->getConnection();
}

$db = db();

echo "Starting password migration...\n";

try {
    // Get all users
    $query = "SELECT user_id, email, password FROM users";
    $stmt = $db->query($query);
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $migrated = 0;
    $skipped = 0;
    
    foreach ($users as $user) {
        $userId = $user['user_id'];
        $email = $user['email'];
        $password = $user['password'];
        
        // Check if password is already hashed (bcrypt starts with $2y$)
        if (substr($password, 0, 4) === '$2y$' || substr($password, 0, 4) === '$2a$' || substr($password, 0, 4) === '$2b$') {
            echo "✓ Skipping user $email (already hashed)\n";
            $skipped++;
            continue;
        }
        
        // Hash the plaintext password
        $hashedPassword = password_hash($password, PASSWORD_BCRYPT);
        
        // Update the database
        $updateQuery = "UPDATE users SET password = :password WHERE user_id = :user_id";
        $updateStmt = $db->prepare($updateQuery);
        $updateStmt->bindParam(':password', $hashedPassword);
        $updateStmt->bindParam(':user_id', $userId);
        
        if ($updateStmt->execute()) {
            echo "✓ Migrated password for user: $email\n";
            $migrated++;
        } else {
            echo "✗ Failed to migrate password for user: $email\n";
        }
    }
    
    echo "\n=== Migration Complete ===\n";
    echo "Migrated: $migrated users\n";
    echo "Skipped: $skipped users (already hashed)\n";
    echo "Total: " . count($users) . " users\n";
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
    exit(1);
}
?>
