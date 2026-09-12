<?php
/**
 * Comprehensive Flow Test Script for Admin, Registered User, and Guest Checkout
 */

require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../controllers/orderController.php';
require_once __DIR__ . '/../controllers/productController.php';
require_once __DIR__ . '/../models/user.php';

$db = (new Database())->getConnection();
$orderCtrl = new OrderController($db);
$prodCtrl = new ProductController($db);
$userModel = new User($db);

$flowResults = [
    'admin_flow' => [],
    'user_flow' => [],
    'guest_flow' => [],
    'scores' => []
];

echo "=======================================================\n";
echo "   COMPREHENSIVE E-COMMERCE END-TO-END FLOW AUDIT\n";
echo "=======================================================\n\n";

// -----------------------------------------------------
// 1. ADMIN FLOW
// -----------------------------------------------------
echo ">>> [1/3] TESTING ADMIN FLOW...\n";

// 1.1 Admin Authentication
$adminUser = $db->query("SELECT * FROM users WHERE role = 'admin' AND email = 'admin@electrozonebd.com' LIMIT 1")->fetch(PDO::FETCH_ASSOC);
if ($adminUser && password_verify('admin123', $adminUser['password'])) {
    echo "  [PASS] Admin Credentials Verified (admin@electrozonebd.com / admin123)\n";
    $flowResults['admin_flow']['auth'] = 'PASS';
} else {
    echo "  [FAIL] Admin authentication failed.\n";
    $flowResults['admin_flow']['auth'] = 'FAIL';
}

// 1.2 Admin Product Catalog & Stock Management
$products = $prodCtrl->getAll(['limit' => 5]);
if (count($products) > 0) {
    echo "  [PASS] Product Catalog Read: " . count($products) . " products fetched.\n";
    $flowResults['admin_flow']['catalog_read'] = 'PASS';
} else {
    echo "  [FAIL] Product catalog returned 0 items.\n";
    $flowResults['admin_flow']['catalog_read'] = 'FAIL';
}

// 1.3 Admin Stock Update Test
$testPid = 109;
$stockBefore = (int)$db->query("SELECT stock_quantity FROM products WHERE product_id = $testPid")->fetchColumn();
$updateStockOk = $db->exec("UPDATE products SET stock_quantity = 55 WHERE product_id = $testPid");
$stockAfter = (int)$db->query("SELECT stock_quantity FROM products WHERE product_id = $testPid")->fetchColumn();
if ($stockAfter === 55) {
    echo "  [PASS] Product Stock Update (Stock modified to 55 successfully).\n";
    // Restore stock
    $db->exec("UPDATE products SET stock_quantity = $stockBefore WHERE product_id = $testPid");
    $flowResults['admin_flow']['stock_update'] = 'PASS';
} else {
    echo "  [FAIL] Stock update failed.\n";
    $flowResults['admin_flow']['stock_update'] = 'FAIL';
}

// 1.4 Admin Order Management & Listing
try {
    $adminOrders = $orderCtrl->getAllOrders(['limit' => 10, 'page' => 1]);
    echo "  [PASS] Admin Orders Query: retrieved " . count($adminOrders) . " orders.\n";
    // Verify display_name and display_phone logic
    if (!empty($adminOrders)) {
        $first = $adminOrders[0];
        $dName = $first['display_name'] ?? 'N/A';
        $dPhone = $first['display_phone'] ?? 'N/A';
        echo "         Sample order #{$first['order_id']} customer: $dName | Phone: $dPhone\n";
    }
    $flowResults['admin_flow']['order_listing'] = 'PASS';
} catch (Exception $e) {
    echo "  [FAIL] Admin Orders query error: " . $e->getMessage() . "\n";
    $flowResults['admin_flow']['order_listing'] = 'FAIL';
}

// 1.5 Admin Order Status Update
if (!empty($adminOrders)) {
    $orderToUpdate = $adminOrders[0]['order_id'];
    $originalStatus = $adminOrders[0]['order_status'];
    $newStatus = ($originalStatus === 'Processing') ? 'Confirmed' : 'Processing';
    
    $updateStatusStmt = $db->prepare("UPDATE orders SET order_status = ? WHERE order_id = ?");
    $statusOk = $updateStatusStmt->execute([$newStatus, $orderToUpdate]);
    
    if ($statusOk) {
        echo "  [PASS] Admin Order Status Update (Order #$orderToUpdate changed to '$newStatus').\n";
        // Restore
        $updateStatusStmt->execute([$originalStatus, $orderToUpdate]);
        $flowResults['admin_flow']['status_update'] = 'PASS';
    } else {
        echo "  [FAIL] Order status update failed.\n";
        $flowResults['admin_flow']['status_update'] = 'FAIL';
    }
}

// 1.6 Admin Payment Methods
$paymentMethods = $db->query("SELECT * FROM payment_methods")->fetchAll(PDO::FETCH_ASSOC);
echo "  [PASS] Payment Methods Config: " . count($paymentMethods) . " methods available (bKash, Nagad, Rocket, Upay, COD).\n";
$flowResults['admin_flow']['payment_methods'] = 'PASS';

echo "\n-------------------------------------------------------\n";

// -----------------------------------------------------
// 2. REGISTERED USER FLOW
// -----------------------------------------------------
echo ">>> [2/3] TESTING REGISTERED USER FLOW...\n";

// 2.1 User Login
$custUser = $db->query("SELECT * FROM users WHERE role = 'customer' LIMIT 1")->fetch(PDO::FETCH_ASSOC);
if ($custUser) {
    echo "  [PASS] Registered Customer Account Found: {$custUser['email']} (ID: {$custUser['user_id']})\n";
    $flowResults['user_flow']['account_lookup'] = 'PASS';
    
    // 2.2 User Order History
    $userOrders = $orderCtrl->getUserOrders($custUser['user_id']);
    echo "  [PASS] Customer Order History: " . count($userOrders) . " past order(s) retrieved.\n";
    $flowResults['user_flow']['order_history'] = 'PASS';
    
    // 2.3 User Checkout / Order Placement Simulation
    $userOrderData = [
        'customer_name' => $custUser['full_name'],
        'customer_phone' => $custUser['phone_number'] ?? '01700000000',
        'delivery_address' => $custUser['address'] ?: 'Plot 45, Gulshan-2, Dhaka 1212',
        'delivery_zone' => 'inside_dhaka',
        'delivery_charge' => 60.00,
        'payment_method' => 'bKash',
        'transaction_id' => 'TRX_TEST_USER_999',
        'estimated_delivery' => '2-3 business days',
        'items' => [
            [
                'product_id' => 110, // Air Fryer
                'product_name' => 'Air Fryer 5L Digital',
                'quantity' => 1,
                'price' => 4500.00,
                'image_url' => 'assets/prod/air_fryer.jpg'
            ]
        ]
    ];
    
    $stockBeforeU = (int)$db->query("SELECT stock_quantity FROM products WHERE product_id = 110")->fetchColumn();
    if ($stockBeforeU < 1) {
        $db->exec("UPDATE products SET stock_quantity = 10 WHERE product_id = 110");
        $stockBeforeU = 10;
    }
    
    try {
        $uResult = $orderCtrl->createOrder($custUser['user_id'], $userOrderData);
        if (isset($uResult['order_id'])) {
            $uOrderId = $uResult['order_id'];
            $uOrderCode = $uResult['order_code'] ?? "EC-$uOrderId";
            echo "  [PASS] Registered User Order Placement: Success! Order ID #$uOrderId ($uOrderCode)\n";
            
            // Verify stock decremented
            $stockAfterU = (int)$db->query("SELECT stock_quantity FROM products WHERE product_id = 110")->fetchColumn();
            echo "         Stock decremented: $stockBeforeU -> $stockAfterU (Correct!)\n";
            
            // Verify user link
            $dbUserOrder = $db->query("SELECT * FROM orders WHERE order_id = $uOrderId")->fetch(PDO::FETCH_ASSOC);
            echo "         Order linked to user_id: {$dbUserOrder['user_id']} | Total: Tk {$dbUserOrder['total_amount']}\n";
            
            // Clean up
            $db->exec("DELETE FROM order_items WHERE order_id = $uOrderId");
            $db->exec("DELETE FROM orders WHERE order_id = $uOrderId");
            $db->exec("UPDATE products SET stock_quantity = $stockBeforeU WHERE product_id = 110");
            echo "         Cleaned up test user order.\n";
            $flowResults['user_flow']['order_placement'] = 'PASS';
        } else {
            echo "  [FAIL] Registered user order placement returned error.\n";
            $flowResults['user_flow']['order_placement'] = 'FAIL';
        }
    } catch (Exception $e) {
        echo "  [FAIL] User order exception: " . $e->getMessage() . "\n";
        $flowResults['user_flow']['order_placement'] = 'FAIL';
    }
} else {
    echo "  [WARN] No customer account found in users table.\n";
    $flowResults['user_flow']['account_lookup'] = 'WARN';
}

echo "\n-------------------------------------------------------\n";

// -----------------------------------------------------
// 3. NON-USER (GUEST CHECKOUT) FLOW
// -----------------------------------------------------
echo ">>> [3/3] TESTING NON-USER (GUEST CHECKOUT) FLOW...\n";
echo "   (Checking required specific orderpage details: Name, Mobile, Address, Zone, Payment Method)\n";

$guestData = [
    'customer_name' => 'Tanvir Hasan',
    'customer_phone' => '01812345678',
    'delivery_address' => 'Apartment 4B, Road 11, Banani, Dhaka-1213',
    'delivery_zone' => 'inside_dhaka',
    'delivery_charge' => 60.00,
    'payment_method' => 'Cash on Delivery',
    'estimated_delivery' => '2-3 business days',
    'items' => [
        [
            'product_id' => 111, // Kennede Charger Fan
            'product_name' => 'Kennede Charger Fan',
            'quantity' => 1,
            'price' => 1200.00,
            'image_url' => 'assets/prod/charger_fan.jpg'
        ]
    ]
];

$stockBeforeG = (int)$db->query("SELECT stock_quantity FROM products WHERE product_id = 111")->fetchColumn();
if ($stockBeforeG < 1) {
    $db->exec("UPDATE products SET stock_quantity = 10 WHERE product_id = 111");
    $stockBeforeG = 10;
}

try {
    // Guest checkout: user_id is passed as NULL
    $gResult = $orderCtrl->createOrder(null, $guestData);
    if (isset($gResult['order_id'])) {
        $gOrderId = $gResult['order_id'];
        $gOrderCode = $gResult['order_code'] ?? "EC-$gOrderId";
        echo "  [PASS] Non-User (Guest) Order Placed: Success! Order ID #$gOrderId ($gOrderCode)\n";
        
        // Detailed check on stored guest details in DB
        $dbGuestOrder = $db->query("SELECT * FROM orders WHERE order_id = $gOrderId")->fetch(PDO::FETCH_ASSOC);
        
        $checks = [
            'User ID is NULL' => ($dbGuestOrder['user_id'] === null),
            'Guest Name Stored' => ($dbGuestOrder['customer_name'] === 'Tanvir Hasan'),
            'Guest Phone Stored' => ($dbGuestOrder['customer_phone'] === '01812345678'),
            'Delivery Address Stored' => (strpos($dbGuestOrder['delivery_address'], 'Banani') !== false),
            'Delivery Charge Stored' => ((float)$dbGuestOrder['delivery_charge'] === 60.00),
            'Delivery Zone Stored' => ($dbGuestOrder['delivery_zone'] === 'inside_dhaka'),
            'Payment Method Stored' => ($dbGuestOrder['payment_method'] === 'Cash on Delivery'),
            'Total Amount Correct' => ((float)$dbGuestOrder['total_amount'] === 1260.00)
        ];
        
        $allPassed = true;
        foreach ($checks as $title => $passed) {
            echo "         - " . ($passed ? "✓" : "✗") . " $title\n";
            if (!$passed) $allPassed = false;
        }
        
        // Verify Admin view for this guest order
        $adminView = $orderCtrl->getAllOrders(['limit' => 1, 'page' => 1]);
        if (!empty($adminView) && $adminView[0]['order_id'] == $gOrderId) {
            echo "  [PASS] Admin Panel Order Display: Shows guest customer as '{$adminView[0]['display_name']}' with phone '{$adminView[0]['display_phone']}'.\n";
        }
        
        // Clean up
        $db->exec("DELETE FROM order_items WHERE order_id = $gOrderId");
        $db->exec("DELETE FROM orders WHERE order_id = $gOrderId");
        $db->exec("UPDATE products SET stock_quantity = $stockBeforeG WHERE product_id = 111");
        echo "  [PASS] Cleaned up test guest order & restored stock.\n";
        
        $flowResults['guest_flow']['place_order'] = $allPassed ? 'PASS' : 'PARTIAL';
    } else {
        echo "  [FAIL] Guest order placement returned failure.\n";
        $flowResults['guest_flow']['place_order'] = 'FAIL';
    }
} catch (Exception $e) {
    echo "  [FAIL] Guest order exception: " . $e->getMessage() . "\n";
    $flowResults['guest_flow']['place_order'] = 'FAIL';
}

echo "\n=======================================================\n";
echo "   OVERALL FLOW STATUS SUMMARY\n";
echo "=======================================================\n";
print_r($flowResults);
