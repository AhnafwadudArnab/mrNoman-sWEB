<?php
/**
 * Comprehensive E-Commerce Flow & cPanel Readiness Audit
 */

require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../controllers/orderController.php';
require_once __DIR__ . '/../middleware/authmiddleware.php';

$results = [
    'admin_flow' => [],
    'user_flow' => [],
    'guest_flow' => [],
    'database_schema' => [],
    'cpanel_server' => []
];

$db = (new Database())->getConnection();

echo "====================================================\n";
echo "1. DATABASE SCHEMA AUDIT FOR E-COMMERCE FLOWS\n";
echo "====================================================\n";

// Check orders table columns
$orderCols = $db->query("DESCRIBE orders")->fetchAll(PDO::FETCH_COLUMN);
$requiredOrderCols = ['order_id', 'user_id', 'customer_name', 'customer_phone', 'total_amount', 'subtotal_amount', 'delivery_charge', 'delivery_address', 'payment_method', 'order_status', 'transaction_id'];

$missingCols = [];
foreach ($requiredOrderCols as $rc) {
    if (!in_array($rc, $orderCols)) {
        $missingCols[] = $rc;
    }
}

if (empty($missingCols)) {
    echo "✓ Orders table has all required columns including customer_name and customer_phone.\n";
    $results['database_schema']['orders_columns'] = true;
} else {
    echo "✗ Orders table is missing columns: " . implode(', ', $missingCols) . "\n";
    $results['database_schema']['orders_columns'] = false;
    $results['database_schema']['missing_order_cols'] = $missingCols;
}

// Check if user_id is nullable in orders
$userIdCol = $db->query("SHOW COLUMNS FROM orders WHERE Field = 'user_id'")->fetch(PDO::FETCH_ASSOC);
$isNullable = ($userIdCol['Null'] === 'YES');
echo ($isNullable ? "✓" : "✗") . " orders.user_id is " . ($isNullable ? "NULLABLE (allows guest orders)" : "NOT NULL (blocks guest orders)") . "\n";
$results['database_schema']['user_id_nullable'] = $isNullable;

echo "\n====================================================\n";
echo "2. ADMIN FLOW AUDIT\n";
echo "====================================================\n";

// Check admin users
$admins = $db->query("SELECT user_id, full_name, email, password, role FROM users WHERE role = 'admin'")->fetchAll(PDO::FETCH_ASSOC);
echo "Found " . count($admins) . " admin account(s):\n";
$adminLoginOk = false;
foreach ($admins as $adm) {
    $pwTest = password_verify('admin123', $adm['password']);
    echo " - ID: {$adm['user_id']} | Email: {$adm['email']} | Password 'admin123': " . ($pwTest ? "VALID" : "DIFFERENT") . "\n";
    if ($pwTest) $adminLoginOk = true;
}
$results['admin_flow']['admin_accounts'] = count($admins) > 0;
$results['admin_flow']['default_password_matches'] = $adminLoginOk;

// Test getAllOrders method used by admin panel
try {
    $oc = new OrderController($db);
    $adminOrders = $oc->getAllOrders(['limit' => 5, 'page' => 1]);
    echo "✓ Admin getAllOrders query succeeded: returned " . count($adminOrders) . " orders.\n";
    $results['admin_flow']['get_all_orders'] = true;
} catch (Exception $e) {
    echo "✗ Admin getAllOrders query failed: " . $e->getMessage() . "\n";
    $results['admin_flow']['get_all_orders'] = false;
}

// Check admin endpoints exist
$adminEndpoints = [
    'backend/api/dashboard.php',
    'backend/api/products.php',
    'backend/api/categories.php',
    'backend/api/brands.php',
    'backend/api/banners.php',
    'backend/api/deals.php',
    'backend/api/flash_sales.php',
    'backend/api/orders.php',
    'backend/api/payment_methods.php',
    'backend/api/stock.php',
    'backend/api/Admin/admin_orders.php'
];

$missingEndpoints = [];
foreach ($adminEndpoints as $ep) {
    if (!file_exists(__DIR__ . '/../../' . $ep)) {
        $missingEndpoints[] = $ep;
    }
}
if (empty($missingEndpoints)) {
    echo "✓ All core admin backend endpoints are present.\n";
    $results['admin_flow']['endpoints'] = true;
} else {
    echo "⚠ Missing admin endpoints: " . implode(', ', $missingEndpoints) . "\n";
    $results['admin_flow']['endpoints'] = false;
}

echo "\n====================================================\n";
echo "3. USER (REGISTERED CUSTOMER) FLOW AUDIT\n";
echo "====================================================\n";

// Check user registration & auth endpoints
$userEndpoints = [
    'backend/api/Auth/login.php',
    'backend/api/Auth/register.php',
    'backend/api/Auth/profile.php',
    'backend/api/flutter_cart.php',
    'backend/api/wishlist.php'
];
$missingUserEp = [];
foreach ($userEndpoints as $ep) {
    if (!file_exists(__DIR__ . '/../../' . $ep)) {
        $missingUserEp[] = $ep;
    }
}
if (empty($missingUserEp)) {
    echo "✓ Customer auth, profile, cart, and wishlist endpoints are present.\n";
    $results['user_flow']['endpoints'] = true;
} else {
    echo "⚠ Missing user endpoints: " . implode(', ', $missingUserEp) . "\n";
    $results['user_flow']['endpoints'] = false;
}

// Test user order history query
$testCustomer = $db->query("SELECT user_id FROM users WHERE role = 'customer' LIMIT 1")->fetch(PDO::FETCH_ASSOC);
if ($testCustomer) {
    $custOrders = $oc->getUserOrders($testCustomer['user_id']);
    echo "✓ User order history query succeeded: " . count($custOrders) . " order(s) for customer ID {$testCustomer['user_id']}.\n";
    $results['user_flow']['order_history'] = true;
} else {
    echo "⚠ No customer account found to test order history query.\n";
    $results['user_flow']['order_history'] = false;
}

echo "\n====================================================\n";
echo "4. NON-USER (GUEST CHECKOUT) FLOW AUDIT\n";
echo "====================================================\n";

// Test placing a guest order programmatically
$testGuestData = [
    'customer_name' => 'Guest Tester',
    'customer_phone' => '01712345678',
    'delivery_address' => 'House 12, Road 4, Sector 7, Uttara, Dhaka',
    'delivery_zone' => 'inside_dhaka',
    'delivery_charge' => 60.00,
    'payment_method' => 'Cash on Delivery',
    'estimated_delivery' => '2-3 business days',
    'items' => [
        [
            'product_id' => 109, // Miyoko Blender
            'product_name' => 'Miyoko Blender 600W',
            'quantity' => 1,
            'price' => 1800.00,
            'image_url' => 'assets/prod/blender.jpg'
        ]
    ]
];

// Check stock of 109 before
$stockBefore = (int)$db->query("SELECT stock_quantity FROM products WHERE product_id = 109")->fetchColumn();
echo "Product 109 stock before order: $stockBefore\n";

// Temporarily ensure stock > 0 for test
if ($stockBefore <= 0) {
    $db->exec("UPDATE products SET stock_quantity = 5 WHERE product_id = 109");
    echo "Set product 109 stock to 5 for simulation test.\n";
}

try {
    $orderResult = $oc->createOrder(null, $testGuestData); // null user_id = guest
    if (isset($orderResult['order_code']) || isset($orderResult['order_id'])) {
        $createdId = $orderResult['order_id'];
        $createdCode = $orderResult['order_code'];
        echo "✓ Guest order created successfully! ID: $createdId | Code: $createdCode\n";
        $results['guest_flow']['place_order'] = true;

        // Verify how it was stored in database
        $storedOrder = $db->query("SELECT * FROM orders WHERE order_id = $createdId")->fetch(PDO::FETCH_ASSOC);
        echo "   Stored user_id: " . ($storedOrder['user_id'] === null ? "NULL (CORRECT FOR GUEST)" : $storedOrder['user_id']) . "\n";
        echo "   Stored customer_name: " . ($storedOrder['customer_name'] ?? 'NOT IN DB') . "\n";
        echo "   Stored customer_phone: " . ($storedOrder['customer_phone'] ?? 'NOT IN DB') . "\n";
        echo "   Stored delivery_address: " . substr($storedOrder['delivery_address'] ?? '', 0, 30) . "...\n";
        echo "   Stored total_amount: " . $storedOrder['total_amount'] . "\n";

        // Check order items
        $storedItems = $db->query("SELECT * FROM order_items WHERE order_id = $createdId")->fetchAll(PDO::FETCH_ASSOC);
        echo "   Stored " . count($storedItems) . " order item(s).\n";

        // Clean up test order so database stays clean
        $db->exec("DELETE FROM order_items WHERE order_id = $createdId");
        $db->exec("DELETE FROM orders WHERE order_id = $createdId");
        // Restore stock
        $db->exec("UPDATE products SET stock_quantity = $stockBefore WHERE product_id = 109");
        echo "✓ Cleaned up test guest order and restored product stock.\n";
    } else {
        echo "✗ Guest order creation returned error: " . json_encode($orderResult) . "\n";
        $results['guest_flow']['place_order'] = false;
    }
} catch (Exception $e) {
    echo "✗ Guest order creation failed with exception: " . $e->getMessage() . "\n";
    $results['guest_flow']['place_order'] = false;
}

echo "\n====================================================\n";
echo "5. CPANEL HOSTING READINESS AUDIT\n";
echo "====================================================\n";

$cpanelFiles = [
    'cpanel_electrocitybd_latest.sql' => 'Root production SQL dump for phpMyAdmin',
    'backend/.htaccess' => 'Apache rewrite rules for PHP API routing on cPanel',
    'backend/public/.htaccess' => 'Public document root rewrite rules',
    'backend/config/cors.php' => 'CORS headers for Flutter Web',
    'backend/config/env.php' => 'Environment loader (.env)',
    'backend/router.php' => 'Local fallback router',
    'backend/config.php' => 'Central configuration file'
];

foreach ($cpanelFiles as $file => $desc) {
    $exists = file_exists(__DIR__ . '/../../' . $file);
    echo ($exists ? "✓" : "✗") . " $file: " . ($exists ? "FOUND ($desc)" : "MISSING") . "\n";
    $results['cpanel_server'][$file] = $exists;
}

// Uploads directory check
$uploadsDir = __DIR__ . '/../public/uploads';
$uploadsExist = is_dir($uploadsDir);
echo ($uploadsExist ? "✓" : "⚠") . " Uploads directory: " . ($uploadsExist ? "EXISTS ($uploadsDir)" : "MISSING") . "\n";
$results['cpanel_server']['uploads_dir'] = $uploadsExist;

file_put_contents(__DIR__ . '/audit_summary.json', json_encode($results, JSON_PRETTY_PRINT));
echo "\nAudit complete. Summary saved to backend/scripts/audit_summary.json\n";
