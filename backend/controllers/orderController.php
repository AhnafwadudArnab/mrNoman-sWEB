<?php
require_once __DIR__ . '/../models/orders.php';
require_once __DIR__ . '/../models/carts.php';
require_once __DIR__ . '/../util/InputSanitizer.php';
require_once __DIR__ . '/../util/Logger.php';
// EmailService is optional — only load if vendor/autoload.php exists
if (file_exists(__DIR__ . '/../vendor/autoload.php')) {
    require_once __DIR__ . '/../services/EmailService.php';
}

class OrderController {
    private $db;
    private $order;
    
    public function __construct($db) {
        $this->db = $db;
        $this->order = new Order($db);
    }
    
    public function createOrder($user_id, $data) {
        // Log the incoming request for debugging
        Logger::info("Order creation attempt", ['user_id' => $user_id ?? 'guest']);
        
        // Sanitize inputs
        $rawAddress = $data['delivery_address'] ?? '';
        $data['delivery_address'] = InputSanitizer::sanitizeAddress($rawAddress);
        $data['payment_method'] = InputSanitizer::sanitizeString($data['payment_method'] ?? '');
        
        // Validate required fields
        if (!isset($data['payment_method']) || !isset($data['delivery_address'])) {
            http_response_code(400);
            Logger::warning("Order creation failed: Missing required fields", ['user_id' => $user_id ?? 'guest']);
            return ['message' => 'Payment method and delivery address required'];
        }
        
        // Validate delivery address
        $address = $data['delivery_address'];
        if ($address === null) {
            http_response_code(400);
            $len = strlen($rawAddress);
            if ($len < 10) {
                return ['message' => 'Delivery address is too short (minimum 10 characters required)'];
            }
            if ($len > 500) {
                return ['message' => 'Delivery address is too long (maximum 500 characters allowed)'];
            }
            return ['message' => 'Invalid delivery address format'];
        }
        
        // Prefer items provided by client; fallback to server cart
        $cart_items = [];
        $total = 0.0;
        if (isset($data['items']) && is_array($data['items']) && count($data['items']) > 0) {
            foreach ($data['items'] as $it) {
                $pid = isset($it['product_id']) ? (int)$it['product_id'] : 0;
                $name = ($it['product_name'] ?? $it['name'] ?? '');
                $qty = (int)($it['quantity'] ?? 1);
                $price = (float)($it['price'] ?? 0);
                $disc = isset($it['discounted_price']) ? (float)$it['discounted_price'] : null;
                $img = ($it['image_url'] ?? $it['imageUrl'] ?? '');
                if ($qty <= 0) continue;
                
                // ✅ Stock Validation - Check if product has enough stock
                if ($pid > 0) {
                    $stock_query = "SELECT stock_quantity FROM products WHERE product_id = ?";
                    $stmt = $this->db->prepare($stock_query);
                    $stmt->execute([$pid]);
                    $product = $stmt->fetch(PDO::FETCH_ASSOC);
                    
                    if (!$product) {
                        http_response_code(400);
                        error_log("Order creation failed: Product not found for product_id $pid");
                        return [
                            'message' => "Product no longer exists: $name",
                            'error_type' => 'invalid_product',
                            'product_id' => $pid,
                            'product_name' => $name,
                        ];
                    }

                    $available_stock = (int)$product['stock_quantity'];
                    if ($available_stock < $qty) {
                        http_response_code(400);
                        error_log("Order creation failed: Insufficient stock for product $pid. Requested: $qty, Available: $available_stock");
                        return [
                            'message' => "Insufficient stock for $name. Available: $available_stock, Requested: $qty",
                            'error_type' => 'insufficient_stock',
                            'product_id' => $pid,
                            'product_name' => $name,
                            'available_stock' => $available_stock,
                            'requested_quantity' => $qty
                        ];
                    }
                }
                
                $cart_items[] = [
                    'product_id' => $pid, // 0 allowed for non-DB items
                    'product_name' => $name,
                    'quantity' => $qty,
                    'price' => $price,
                    'discounted_price' => $disc,
                    'image_url' => $img,
                ];
                $line = ($disc !== null ? $disc : $price) * $qty;
                $total += $line;
            }
            if (empty($cart_items)) {
                http_response_code(400);
                error_log("Order creation failed: No valid items in request");
                return ['message' => 'No valid items in request'];
            }
        } else {
            // Fallback: use server-side cart with stock validation
            $cart = new Cart($this->db);
            $cart_items = $cart->getUserCart($user_id);
            if (empty($cart_items)) {
                http_response_code(400);
                error_log("Order creation failed: Cart is empty for user $user_id");
                return ['message' => 'Cart is empty'];
            }
            
            // ✅ Validate stock for cart items
            foreach ($cart_items as $item) {
                $pid = (int)$item['product_id'];
                $qty = (int)$item['quantity'];
                
                if ($pid > 0) {
                    $stock_query = "SELECT stock_quantity, product_name FROM products WHERE product_id = ?";
                    $stmt = $this->db->prepare($stock_query);
                    $stmt->execute([$pid]);
                    $product = $stmt->fetch(PDO::FETCH_ASSOC);
                    
                    if (!$product) {
                        http_response_code(400);
                        error_log("Order creation failed: Product not found in cart for product_id $pid");
                        return [
                            'message' => "A product in your cart is no longer available. Please refresh cart.",
                            'error_type' => 'invalid_product',
                            'product_id' => $pid,
                        ];
                    }

                    $available_stock = (int)$product['stock_quantity'];
                    if ($available_stock < $qty) {
                        http_response_code(400);
                        error_log("Order creation failed: Insufficient stock for product $pid");
                        return [
                            'message' => "Insufficient stock for {$product['product_name']}. Available: $available_stock, Requested: $qty",
                            'error_type' => 'insufficient_stock',
                            'product_id' => $pid,
                            'product_name' => $product['product_name'],
                            'available_stock' => $available_stock,
                            'requested_quantity' => $qty
                        ];
                    }
                }
            }
            
            $total = $cart->getCartTotal($user_id);
        }
        
        $subtotal = (float)$total;
        $couponDiscount = 0.0;
        if (isset($data['coupon_discount'])) {
            $couponDiscount = max(0.0, (float)$data['coupon_discount']);
        }
        $deliveryCharge = 0.0;
        if (isset($data['delivery_charge'])) {
            $deliveryCharge = max(0.0, (float)$data['delivery_charge']);
        }
        $total = max(0.0, $subtotal - $couponDiscount + $deliveryCharge);
        
        $this->order->user_id = $user_id; // null for guest orders
        $this->order->subtotal_amount = $subtotal;
        $this->order->delivery_charge = $deliveryCharge;
        $this->order->coupon_discount = $couponDiscount;
        $this->order->delivery_zone = $data['delivery_zone'] ?? null;
        $this->order->coupon_code = $data['coupon_code'] ?? null;
        $this->order->total_amount = $total;
        $this->order->payment_method = $data['payment_method'];
        $this->order->delivery_address = $data['delivery_address'];
        $this->order->transaction_id = $data['transaction_id'] ?? null;
        $this->order->estimated_delivery = $data['estimated_delivery'] ?? '7-10 business days';
        $this->order->customer_name = $data['customer_name'] ?? null;
        $this->order->customer_phone = $data['customer_phone'] ?? null;
        
        // ✅ Prevent duplicate orders with same transaction_id
        $txnId = $this->order->transaction_id;
        if (!empty($txnId)) {
            if ($user_id !== null) {
                $dupCheck = $this->db->prepare("SELECT order_id FROM orders WHERE transaction_id = ? AND user_id = ? LIMIT 1");
                $dupCheck->execute([$txnId, $user_id]);
            } else {
                // Guest: check by transaction_id only
                $dupCheck = $this->db->prepare("SELECT order_id FROM orders WHERE transaction_id = ? AND user_id IS NULL LIMIT 1");
                $dupCheck->execute([$txnId]);
            }
            if ($dupCheck->fetch()) {
                http_response_code(409);
                return ['message' => 'Order with this transaction ID already exists'];
            }
        }
        
        if ($this->order->create($cart_items)) {
            $orderId = $this->order->order_id;
            $code = 'EC-' . date('Ymd') . '-' . $orderId;
            Logger::logOrder('order_created', $code, $user_id ?? 'guest', $total);
            
            // Send order confirmation email (non-blocking — never fails the order)
            try {
                $userEmail = null;
                $userName = $data['customer_name'] ?? null;
                
                if ($user_id !== null) {
                    $userQuery = "SELECT email, full_name FROM users WHERE user_id = ?";
                    $userStmt = $this->db->prepare($userQuery);
                    $userStmt->execute([$user_id]);
                    $userData = $userStmt->fetch(PDO::FETCH_ASSOC);
                    if ($userData) {
                        $userEmail = $userData['email'];
                        $userName = $userData['full_name'];
                    }
                }
                
                if ($userEmail && class_exists('EmailService')) {
                    $emailService = new EmailService();
                    $orderData = [
                        'order_id' => $code,
                        'total_amount' => $total,
                        'payment_method' => $data['payment_method'],
                        'delivery_address' => $data['delivery_address'],
                        'estimated_delivery' => $data['estimated_delivery'] ?? '5-7 business days'
                    ];
                    $emailService->sendOrderConfirmation($userEmail, $orderData);
                }
            } catch (Throwable $e) {
                Logger::error("Failed to send order confirmation email", ['order_id' => $code, 'error' => $e->getMessage()]);
                // Order already created — email failure must never roll it back
            }
            
            return [
                'message' => 'Order created successfully',
                'order_id' => $orderId,
                'order_code' => $code,
            ];
        }
        
        http_response_code(500);
        Logger::error("Order creation failed: Database error", ['user_id' => $user_id]);
        return ['message' => 'Failed to create order', 'debug' => 'Order model create() returned false — check server error_log for details'];
    }
    
    public function getUserOrders($user_id) {
        return $this->order->getUserOrders($user_id);
    }
    
    public function getOrderDetails($order_id, $user_id = null) {
        $order = $this->order->getOrderDetails($order_id, $user_id);
        
        if (!$order) {
            http_response_code(404);
            return ['message' => 'Order not found'];
        }
        
        return $order;
    }
    
    public function getAllOrders($data) {
        $limit = $data['limit'] ?? 100;
        $page = $data['page'] ?? 1;
        $offset = ($page - 1) * $limit;
        
        return $this->order->getAllOrders($limit, $offset);
    }
    
    public function updateStatus($order_id, $data, $admin_id) {
        if (!isset($data['status'])) {
            http_response_code(400);
            return ['message' => 'Status required'];
        }
        
        if ($this->order->updateStatus($order_id, $data['status'], $admin_id)) {
            return ['message' => 'Order status updated'];
        }
        
        http_response_code(500);
        return ['message' => 'Failed to update order'];
    }
    
    public function deleteOrder($order_id, $admin_id) {
        // Verify admin is performing the action
        error_log("Order deletion attempt - Order ID: $order_id, Admin ID: $admin_id");
        
        // Check if order exists
        $check_query = "SELECT order_id FROM orders WHERE order_id = ?";
        $stmt = $this->db->prepare($check_query);
        $stmt->execute([$order_id]);
        
        if (!$stmt->fetch()) {
            http_response_code(404);
            error_log("Order deletion failed: Order $order_id not found");
            return ['message' => 'Order not found'];
        }
        
        try {
            // Start transaction
            $this->db->beginTransaction();
            
            // Delete order items first (foreign key constraint)
            $delete_items_query = "DELETE FROM order_items WHERE order_id = ?";
            $stmt = $this->db->prepare($delete_items_query);
            $stmt->execute([$order_id]);
            
            // Delete the order
            $delete_order_query = "DELETE FROM orders WHERE order_id = ?";
            $stmt = $this->db->prepare($delete_order_query);
            $stmt->execute([$order_id]);
            
            // Commit transaction
            $this->db->commit();
            
            error_log("Order deleted successfully - Order ID: $order_id by Admin ID: $admin_id");
            return [
                'message' => 'Order deleted successfully',
                'order_id' => $order_id
            ];
        } catch (Exception $e) {
            // Rollback on error
            $this->db->rollBack();
            http_response_code(500);
            error_log("Order deletion failed: " . $e->getMessage());
            return ['message' => 'Failed to delete order: ' . $e->getMessage()];
        }
    }
}
?>
