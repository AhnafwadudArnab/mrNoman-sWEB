<?php
/**
 * Flutter Orders API
 * Manages order creation and retrieval
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../services/DatabaseService.php';

try {
    $db = DatabaseService::getInstance();
    
    $method = $_SERVER['REQUEST_METHOD'];
    
    switch ($method) {
        case 'GET':
            handleGetOrders($db);
            break;
        case 'POST':
            handleCreateOrder($db);
            break;
        default:
            throw new Exception('Method not allowed');
    }

} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}

function handleGetOrders($db) {
    $user_id = $_GET['user_id'] ?? null;
    $order_id = $_GET['order_id'] ?? null;
    
    if ($order_id) {
        // একটি নির্দিষ্ট অর্ডার পান
        handleGetOrderDetails($db, (int)$order_id);
    } else if ($user_id) {
        // ব্যবহারকারীর সকল অর্ডার পান
        handleGetUserOrders($db, (int)$user_id);
    } else {
        throw new Exception('user_id or order_id is required');
    }
}

function handleGetOrderDetails($db, $order_id) {
    $query = "SELECT o.* FROM orders o WHERE o.order_id = $order_id";
    $result = $db->query($query);
    
    if (!$result || $result->num_rows === 0) {
        throw new Exception('Order not found');
    }
    
    $order = $result->fetch_assoc();
    
    // অর্ডার আইটেম পান
    $items_query = "SELECT oi.* FROM order_items oi WHERE oi.order_id = $order_id";
    $items_result = $db->query($items_query);
    $items = [];
    
    while ($item = $items_result->fetch_assoc()) {
        $items[] = [
            'item_id' => (int)$item['item_id'],
            'product_id' => (int)$item['product_id'],
            'product_name' => $item['product_name'],
            'quantity' => (int)$item['quantity'],
            'price_at_purchase' => (float)$item['price_at_purchase'],
            'image_url' => $item['image_url']
        ];
    }
    
    echo json_encode([
        'success' => true,
        'data' => formatOrder($order, $items)
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}

function handleGetUserOrders($db, $user_id) {
    $query = "SELECT o.* FROM orders o 
              WHERE o.user_id = $user_id
              ORDER BY o.order_date DESC";
    
    $result = $db->query($query);
    $orders = [];
    
    while ($order = $result->fetch_assoc()) {
        // প্রতিটি অর্ডারের জন্য আইটেম পান
        $order_id = (int)$order['order_id'];
        $items_query = "SELECT oi.* FROM order_items oi WHERE oi.order_id = $order_id";
        $items_result = $db->query($items_query);
        $items = [];
        
        while ($item = $items_result->fetch_assoc()) {
            $items[] = [
                'item_id' => (int)$item['item_id'],
                'product_id' => (int)$item['product_id'],
                'product_name' => $item['product_name'],
                'quantity' => (int)$item['quantity'],
                'price_at_purchase' => (float)$item['price_at_purchase'],
                'image_url' => $item['image_url']
            ];
        }
        
        $orders[] = formatOrder($order, $items);
    }
    
    echo json_encode([
        'success' => true,
        'data' => $orders
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}

function handleCreateOrder($db) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    // ইনপুট ভ্যালিডেট করুন
    $user_id = $input['user_id'] ?? null;
    $items = $input['items'] ?? [];
    $delivery_address = $input['delivery_address'] ?? null;
    $payment_method = $input['payment_method'] ?? 'Cash on Delivery';
    $customer_name = $input['customer_name'] ?? null;
    $customer_phone = $input['customer_phone'] ?? null;
    
    if (!$user_id || empty($items) || !$delivery_address) {
        throw new Exception('user_id, items, and delivery_address are required');
    }
    
    $user_id = (int)$user_id;
    $total_amount = 0;
    
    // ট্রানজ্যাকশন শুরু করুন
    $db->begin_transaction();
    
    try {
        // মোট পরিমাণ গণনা করুন
        foreach ($items as $item) {
            $product_id = (int)$item['product_id'];
            $quantity = (int)$item['quantity'];
            
            // স্টক চেক করুন
            $stock_query = "SELECT price, stock_quantity FROM products WHERE product_id = $product_id";
            $stock_result = $db->query($stock_query);
            $product = $stock_result->fetch_assoc();
            
            if ((int)$product['stock_quantity'] < $quantity) {
                throw new Exception("Insufficient stock for product $product_id");
            }
            
            $total_amount += (float)$product['price'] * $quantity;
        }
        
        // অর্ডার তৈরি করুন
        $delivery_address = $db->real_escape_string($delivery_address);
        $payment_method = $db->real_escape_string($payment_method);
        $customer_name = $customer_name ? $db->real_escape_string($customer_name) : null;
        $customer_phone = $customer_phone ? $db->real_escape_string($customer_phone) : null;
        
        $order_query = "INSERT INTO orders (user_id, total_amount, subtotal_amount, 
                        delivery_address, payment_method, customer_name, customer_phone, 
                        order_status, payment_status)
                        VALUES ($user_id, $total_amount, $total_amount,
                        '$delivery_address', '$payment_method', 
                        '$customer_name', '$customer_phone', 'pending', 'unpaid')";
        
        if (!$db->query($order_query)) {
            throw new Exception('Failed to create order');
        }
        
        $order_id = $db->insert_id;
        
        // অর্ডার আইটেম যোগ করুন
        foreach ($items as $item) {
            $product_id = (int)$item['product_id'];
            $quantity = (int)$item['quantity'];
            
            // পণ্যের তথ্য পান
            $product_query = "SELECT product_name, price FROM products WHERE product_id = $product_id";
            $product_result = $db->query($product_query);
            $product = $product_result->fetch_assoc();
            
            $product_name = $db->real_escape_string($product['product_name']);
            $price = (float)$product['price'];
            
            $item_query = "INSERT INTO order_items (order_id, product_id, product_name, 
                           quantity, price_at_purchase)
                           VALUES ($order_id, $product_id, '$product_name', $quantity, $price)";
            
            if (!$db->query($item_query)) {
                throw new Exception('Failed to add order item');
            }
            
            // স্টক কমান
            $update_stock = "UPDATE products SET stock_quantity = stock_quantity - $quantity 
                             WHERE product_id = $product_id";
            if (!$db->query($update_stock)) {
                throw new Exception('Failed to update stock');
            }
        }
        
        // কার্ট থেকে আইটেম মুছুন
        $clear_cart = "DELETE FROM cart WHERE user_id = $user_id";
        $db->query($clear_cart);
        
        // ট্রানজ্যাকশন কমিট করুন
        $db->commit();
        
        echo json_encode([
            'success' => true,
            'message' => 'Order created successfully',
            'data' => [
                'order_id' => (int)$order_id,
                'user_id' => $user_id,
                'total_amount' => $total_amount,
                'order_status' => 'pending',
                'payment_status' => 'unpaid',
                'created_at' => date('Y-m-d H:i:s')
            ]
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        
    } catch (Exception $e) {
        $db->rollback();
        throw $e;
    }
}

function formatOrder($order, $items) {
    return [
        'order_id' => (int)$order['order_id'],
        'user_id' => (int)$order['user_id'],
        'total_amount' => (float)$order['total_amount'],
        'subtotal_amount' => (float)$order['subtotal_amount'],
        'delivery_charge' => (float)$order['delivery_charge'],
        'coupon_discount' => (float)$order['coupon_discount'],
        'order_status' => $order['order_status'],
        'payment_status' => $order['payment_status'],
        'payment_method' => $order['payment_method'],
        'delivery_address' => $order['delivery_address'],
        'customer_name' => $order['customer_name'],
        'customer_phone' => $order['customer_phone'],
        'order_items' => $items,
        'order_date' => $order['order_date']
    ];
}
?>
