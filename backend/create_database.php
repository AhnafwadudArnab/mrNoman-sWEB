<?php
echo "=== Creating Database ===\n\n";

try {
    // Connect to MySQL without database
    $pdo = new PDO(
        'mysql:host=localhost;port=3306;charset=utf8mb4',
        'root',
        '',
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        ]
    );
    
    echo "✓ Connected to MySQL server\n\n";
    
    $db_name = 'asiment3_electrobd';
    $db_user = 'asiment3_zones';
    $db_pass = 'zlBzyXMNNeeh';
    
    // Create database
    echo "Creating database: $db_name\n";
    $pdo->exec("CREATE DATABASE IF NOT EXISTS `$db_name` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
    echo "✓ Database created\n\n";
    
    // Create user
    echo "Creating user: $db_user\n";
    try {
        $pdo->exec("CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_pass'");
        echo "✓ User created\n";
    } catch (Exception $e) {
        echo "⚠ User already exists: " . $e->getMessage() . "\n";
    }
    
    // Grant privileges
    echo "Granting privileges...\n";
    $pdo->exec("GRANT ALL PRIVILEGES ON `$db_name`.* TO '$db_user'@'localhost'");
    $pdo->exec("FLUSH PRIVILEGES");
    echo "✓ Privileges granted\n\n";
    
    // Test connection with new user
    echo "Testing connection with new user...\n";
    $pdo2 = new PDO(
        "mysql:host=localhost;port=3306;dbname=$db_name;charset=utf8mb4",
        $db_user,
        $db_pass,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        ]
    );
    echo "✓ Successfully connected with $db_user\n\n";
    
    echo "✓ Setup completed!\n";
    echo "You can now use:\n";
    echo "  DB_USER=$db_user\n";
    echo "  DB_PASSWORD=$db_pass\n";
    
} catch (Exception $e) {
    echo "✗ Error: " . $e->getMessage() . "\n";
    exit(1);
}
?>
