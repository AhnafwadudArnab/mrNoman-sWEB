<?php
/**
 * Flutter Cart API
 * Manages shopping cart operations
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
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
    $user_id = $_GET['user_id'] ?? $_POST['user_id'] ?? null;
    
    if (!$user_id) {
        throw new Exception('user_id is required');
    }
    
    $user_id = (int)$user_id;
    
    switch ($method) {
        case 'GET':
            handleGetCart($db, $user_id);
            break;
        case 'POST':
            handleAddToCart($db, $user_id);
            break;
        case 'PUT':
            handleUpdateCart($db, $user_id);
            break;
        case 'DELETE':
            handleRemoveFromCart($db, $user_id);
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

function handleGetCart($db, $user_id) {
    $query = "SELECT c.cart_id, c.product_id, c.quantity, c.added_at,
              p.product_name, p.price, p.image_url, p.stock_quantity
              FROM cart c
              JOIN products p ON c.product_id = p.product_id
              WHERE c.user_id = $user_id
              ORDER BY c.added_at DESC";
    
    $result = $db->query($query);
    $items = [];
    $total = 0;
    
    while ($row = $result->fetch_assoc()) {
        $item_total = (float)$row['price'] * (int)$row['quantity'];
        $total += $item_total;
        
        $items[] = [
            'cart_id' => (int)$row['cart_id'],
            'product_id' => (int)$row['product_id'],
            'product_name' => $row['product_name'],
            'quantity' => (int)$row['quantity'],
            'unit_price' => (float)$row['price'],
            'total_price' => $item_total,
            'image_url' => $row['image_url'],
            'stock_available' => (int)$row['stock_quantity'],
            'added_at' => $row['added_at']
        ];
    }
    
    echo json_encode([
        'success' => true,
        'data' => [
            'user_id' => $user_id,
            'items' => $items,
            'item_count' => count($items),
            'subtotal' => $total,
            'delivery_charge' => 0,
            'total_amount' => $total
        ]
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}

function handleAddToCart($db, $user_id) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $product_id = $input['product_id'] ?? null;
    $quantity = $input['quantity'] ?? 1;
    
    if (!$product_id) {
        throw new Exception('product_id is required');
    }
    
    $product_id = (int)$product_id;
    $quantity = max(1, (int)$quantity);
    
    // স্টক চেক করুন
    $stock_query = "SELECT stock_quantity FROM products WHERE product_id = $product_id";
    $stock_result = $db->query($stock_query);
    if (!$stock_result || $stock_result->num_rows === 0) {
        throw new Exception('Product not found');
    }
    
    $stock_row = $stock_result->fetch_assoc();
    if ((int)$stock_row['stock_quantity'] < $quantity) {
        throw new Exception('Insufficient stock available');
    }
    
    // চেক করুন পণ্য ইতিমধ্যে কার্টে আছে কিনা
    $check_query = "SELECT cart_id, quantity FROM cart 
                    WHERE user_id = $user_id AND product_id = $product_id";
    $check_result = $db->query($check_query);
    
    if ($check_result->num_rows > 0) {
        // পরিমাণ আপডেট করুন
        $check_row = $check_result->fetch_assoc();
        $new_quantity = (int)$check_row['quantity'] + $quantity;
        
        if ($new_quantity > (int)$stock_row['stock_quantity']) {
            throw new Exception('Cannot add: Exceeds available stock');
        }
        
        $cart_id = $check_row['cart_id'];
        $update_query = "UPDATE cart SET quantity = $new_quantity WHERE cart_id = $cart_id";
        $db->query($update_query);
    } else {
        // নতুন আইটেম যোগ করুন
        $insert_query = "INSERT INTO cart (user_id, product_id, quantity) 
                         VALUES ($user_id, $product_id, $quantity)";
        $db->query($insert_query);
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Product added to cart',
        'data' => [
            'product_id' => $product_id,
            'quantity' => $quantity
        ]
    ]);
}

function handleUpdateCart($db, $user_id) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $product_id = $input['product_id'] ?? null;
    $quantity = $input['quantity'] ?? null;
    
    if (!$product_id || $quantity === null) {
        throw new Exception('product_id and quantity are required');
    }
    
    $product_id = (int)$product_id;
    $quantity = max(1, (int)$quantity);
    
    // স্টক চেক করুন
    $stock_query = "SELECT stock_quantity FROM products WHERE product_id = $product_id";
    $stock_result = $db->query($stock_query);
    if (!$stock_result || $stock_result->num_rows === 0) {
        throw new Exception('Product not found');
    }
    
    $stock_row = $stock_result->fetch_assoc();
    if ((int)$stock_row['stock_quantity'] < $quantity) {
        throw new Exception('Insufficient stock available');
    }
    
    // আপডেট করুন
    $update_query = "UPDATE cart SET quantity = $quantity 
                     WHERE user_id = $user_id AND product_id = $product_id";
    
    if (!$db->query($update_query)) {
        throw new Exception('Failed to update cart');
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Cart updated successfully',
        'data' => [
            'product_id' => $product_id,
            'quantity' => $quantity
        ]
    ]);
}

function handleRemoveFromCart($db, $user_id) {
    $product_id = $_GET['product_id'] ?? null;
    
    if (!$product_id) {
        throw new Exception('product_id is required');
    }
    
    $product_id = (int)$product_id;
    
    $delete_query = "DELETE FROM cart WHERE user_id = $user_id AND product_id = $product_id";
    
    if (!$db->query($delete_query)) {
        throw new Exception('Failed to remove from cart');
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Product removed from cart',
        'data' => [
            'product_id' => $product_id
        ]
    ]);
}
?>
