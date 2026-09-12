<?php
require_once __DIR__ . '/../config/db.php';

$db = (new Database())->getConnection();

echo "=== UPDATING ADMIN ACCOUNTS ===\n";

// 1. Check existing users
$existingAdmins = $db->query("SELECT user_id, full_name, email, role FROM users WHERE role = 'admin'")->fetchAll(PDO::FETCH_ASSOC);
echo "Existing admins:\n";
foreach ($existingAdmins as $a) {
    echo " - ID: {$a['user_id']} | {$a['email']} | {$a['full_name']}\n";
}

// Prepare password hashes
$hash1 = password_hash('ElectroAdmin@2026', PASSWORD_BCRYPT);
$hash2 = password_hash('ZoneAdmin@2026', PASSWORD_BCRYPT);
$hash3 = password_hash('ZoneAdmin@2078', PASSWORD_BCRYPT);

$newAdmins = [
    [
        'full_name' => 'Admin Noman',
        'email' => 'adminNoman@electrozonebd.com',
        'password' => $hash1,
        'phone' => '01700000001'
    ],
    [
        'full_name' => 'Super Admin Roz',
        'email' => 'superadmin_roz@electrozonebd.com',
        'password' => $hash2,
        'phone' => '01700000002'
    ],
    [
        'full_name' => 'Super Admin EZ',
        'email' => 'superadmin@ez.com',
        'password' => $hash3,
        'phone' => '01700000003'
    ]
];

// Insert new admins
$nomanId = null;
foreach ($newAdmins as $na) {
    $checkStmt = $db->prepare("SELECT user_id FROM users WHERE email = ?");
    $checkStmt->execute([$na['email']]);
    $uid = $checkStmt->fetchColumn();
    if ($uid) {
        $updateStmt = $db->prepare("UPDATE users SET full_name = ?, password = ?, role = 'admin' WHERE user_id = ?");
        $updateStmt->execute([$na['full_name'], $na['password'], $uid]);
        echo "✓ Updated existing user to admin: {$na['email']} (ID: $uid)\n";
        if ($na['email'] === 'adminNoman@electrozonebd.com') $nomanId = $uid;
    } else {
        $insertStmt = $db->prepare("INSERT INTO users (full_name, email, password, role, phone_number, gender) VALUES (?, ?, ?, 'admin', ?, 'Male')");
        $insertStmt->execute([$na['full_name'], $na['email'], $na['password'], $na['phone']]);
        $newId = $db->lastInsertId();
        echo "✓ Created new admin: {$na['email']} (ID: $newId)\n";
        if ($na['email'] === 'adminNoman@electrozonebd.com') $nomanId = $newId;
    }
}

// 2. Reassign any orders owned by old default admin (admin@electrozonebd.com, user_id=1) to adminNoman
if ($nomanId) {
    $db->exec("UPDATE orders SET user_id = $nomanId WHERE user_id = 1");
    echo "✓ Reassigned old admin orders to adminNoman (ID: $nomanId).\n";
}

// 3. Remove old admin account with admin123
$deleteOld = $db->prepare("DELETE FROM users WHERE email = 'admin@electrozonebd.com'");
$deleteOld->execute();
echo "✓ Deleted old default admin (admin@electrozonebd.com / admin123).\n";

// Final check
$finalAdmins = $db->query("SELECT user_id, full_name, email, role FROM users WHERE role = 'admin'")->fetchAll(PDO::FETCH_ASSOC);
echo "\nFinal active admin accounts in DB:\n";
foreach ($finalAdmins as $fa) {
    echo " - ID: {$fa['user_id']} | Email: {$fa['email']} | Name: {$fa['full_name']} | Role: {$fa['role']}\n";
}

// Generate cPanel SQL snippet for phpMyAdmin
$sqlSnippet = "-- ============================================================\n";
$sqlSnippet .= "-- Run this SQL in cPanel phpMyAdmin -> SQL tab\n";
$sqlSnippet .= "-- ============================================================\n\n";

$sqlSnippet .= "-- 1. Reassign any existing orders from old admin to prevent FK error\n";
$sqlSnippet .= "UPDATE `orders` SET `user_id` = NULL WHERE `user_id` IN (SELECT `user_id` FROM (SELECT `user_id` FROM `users` WHERE `email` = 'admin@electrozonebd.com') AS tmp);\n\n";

$sqlSnippet .= "-- 2. Delete old default admin (admin@electrozonebd.com)\n";
$sqlSnippet .= "DELETE FROM `users` WHERE `email` = 'admin@electrozonebd.com';\n\n";

$sqlSnippet .= "-- 3. Add or update the 3 new admin accounts\n";
foreach ($newAdmins as $na) {
    $sqlSnippet .= "INSERT INTO `users` (`full_name`, `email`, `password`, `role`, `phone_number`, `gender`)\n";
    $sqlSnippet .= "VALUES ('{$na['full_name']}', '{$na['email']}', '{$na['password']}', 'admin', '{$na['phone']}', 'Male')\n";
    $sqlSnippet .= "ON DUPLICATE KEY UPDATE `password` = '{$na['password']}', `role` = 'admin', `full_name` = '{$na['full_name']}';\n\n";
}

file_put_contents(__DIR__ . '/update_cpanel_admins.sql', $sqlSnippet);
echo "\n✓ Created update_cpanel_admins.sql for phpMyAdmin!\n";
