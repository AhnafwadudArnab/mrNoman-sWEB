<?php
require_once __DIR__ . '/../config/db.php';
$db = (new Database())->getConnection();
$tests = [
    ["adminNoman@electrozonebd.com", "ElectroAdmin@2026"],
    ["superadmin_roz@electrozonebd.com", "ZoneAdmin@2026"],
    ["superadmin@ez.com", "ZoneAdmin@2078"]
];
foreach($tests as $t) {
    $stmt = $db->prepare("SELECT user_id, email, password, role FROM users WHERE email = ?");
    $stmt->execute([$t[0]]);
    $u = $stmt->fetch(PDO::FETCH_ASSOC);
    $ok = $u && password_verify($t[1], $u["password"]);
    echo "User: " . str_pad($t[0], 35) . " | Password: " . str_pad($t[1], 20) . " | Login: " . ($ok ? "SUCCESS (Role: " . $u["role"] . ")" : "FAILED") . "\n";
}

// Check old admin
$old = $db->query("SELECT * FROM users WHERE email = 'admin@electrozonebd.com'")->fetch();
echo "\nOld admin 'admin@electrozonebd.com' in DB: " . ($old ? "STILL EXISTS" : "DELETED (CONFIRMED)") . "\n";
