<?php
class Order {
    private $conn;
    private $table_name = "orders";
    
    public $order_id;
    public $user_id;
    public $total_amount;
    public $order_status;
    public $payment_method;
    public $payment_status;
    public $subtotal_amount;
    public $delivery_charge;
    public $coupon_discount;
    public $delivery_zone;
    public $coupon_code;
    public $delivery_address;
    public $transaction_id;
    public $estimated_delivery;
    public $customer_name;   // for guest orders
    public $customer_phone;  // for guest orders
    
    public function __construct($db) {
        $this->conn = $db;
    }
    
    public function create($cart_items) {
        try {
            $this->conn->beginTransaction();
            
            error_log("Creating order for user_id: {$this->user_id}, total: {$this->total_amount}");
            
            $columns = [
                'user_id',
                'total_amount',
                'payment_method',
                'delivery_address',
                'transaction_id',
                'estimated_delivery',
            ];
            $placeholders = [
                ':user_id',
                ':total',
                ':payment_method',
                ':address',
                ':transaction_id',
                ':estimated_delivery',
            ];
            $optionalColumns = [
                'customer_name' => ':customer_name',
                'customer_phone' => ':customer_phone',
                'subtotal_amount' => ':subtotal_amount',
                'delivery_charge' => ':delivery_charge',
                'coupon_discount' => ':coupon_discount',
                'delivery_zone' => ':delivery_zone',
                'coupon_code' => ':coupon_code',
            ];
            foreach ($optionalColumns as $column => $placeholder) {
                if ($this->columnExists($this->table_name, $column)) {
                    $columns[] = $column;
                    $placeholders[] = $placeholder;
                }
            }

            $query = "INSERT INTO " . $this->table_name . "
                      (" . implode(', ', $columns) . ")
                      VALUES (" . implode(', ', $placeholders) . ")";
            
            $stmt = $this->conn->prepare($query);
            $stmt->bindParam(":user_id", $this->user_id);
            $stmt->bindParam(":total", $this->total_amount);
            $stmt->bindParam(":payment_method", $this->payment_method);
            $stmt->bindParam(":address", $this->delivery_address);
            $stmt->bindParam(":transaction_id", $this->transaction_id);
            $stmt->bindParam(":estimated_delivery", $this->estimated_delivery);
            if (in_array('customer_name', $columns, true)) $stmt->bindParam(":customer_name", $this->customer_name);
            if (in_array('customer_phone', $columns, true)) $stmt->bindParam(":customer_phone", $this->customer_phone);
            if (in_array('subtotal_amount', $columns, true)) $stmt->bindParam(":subtotal_amount", $this->subtotal_amount);
            if (in_array('delivery_charge', $columns, true)) $stmt->bindParam(":delivery_charge", $this->delivery_charge);
            if (in_array('coupon_discount', $columns, true)) $stmt->bindParam(":coupon_discount", $this->coupon_discount);
            if (in_array('delivery_zone', $columns, true)) $stmt->bindParam(":delivery_zone", $this->delivery_zone);
            if (in_array('coupon_code', $columns, true)) $stmt->bindParam(":coupon_code", $this->coupon_code);
            
            if (!$stmt->execute()) {
                $errorInfo = $stmt->errorInfo();
                error_log("Order insert failed: " . json_encode($errorInfo));
                throw new Exception("Failed to create order: " . $errorInfo[2]);
            }
            
            $this->order_id = $this->conn->lastInsertId();
            error_log("Order created with ID: {$this->order_id}");
            
            // Insert order items
            foreach ($cart_items as $item) {
                $item_query = "INSERT INTO order_items
                              (order_id, product_id, product_name, quantity, price_at_purchase, image_url)
                              VALUES (?, ?, ?, ?, ?, ?)";
                
                $item_stmt = $this->conn->prepare($item_query);
                
                $price = $item['discounted_price'] ?? $item['price'];
                
                // Use NULL for product_id if 0 or invalid to avoid FK constraint violation
                $pid = isset($item['product_id']) && (int)$item['product_id'] > 0
                    ? (int)$item['product_id']
                    : null;

                // Final guard against stale/deleted products to avoid FK crashes.
                if ($pid !== null) {
                    $existsStmt = $this->conn->prepare("SELECT 1 FROM products WHERE product_id = ? LIMIT 1");
                    $existsStmt->execute([$pid]);
                    if (!$existsStmt->fetchColumn()) {
                        $pid = null;
                    }
                }

                // Use two different queries: with or without product_id
                // This avoids FK constraint failure when product_id is NULL
                // but the column is NOT NULL in the DB (run fix_order_items_nullable_product_id.sql to fix permanently)
                if ($pid !== null) {
                    $exec_ok = $item_stmt->execute([
                        $this->order_id,
                        $pid,
                        $item['product_name'],
                        $item['quantity'],
                        $price,
                        $item['image_url']
                    ]);
                } else {
                    $no_pid_query = "INSERT INTO order_items
                                  (order_id, product_name, quantity, price_at_purchase, image_url)
                                  VALUES (?, ?, ?, ?, ?)";
                    $no_pid_stmt = $this->conn->prepare($no_pid_query);
                    $exec_ok = $no_pid_stmt->execute([
                        $this->order_id,
                        $item['product_name'],
                        $item['quantity'],
                        $price,
                        $item['image_url']
                    ]);
                    if (!$exec_ok) $item_stmt = $no_pid_stmt; // for error reporting
                }

                if (!$exec_ok) {
                    $errorInfo = $item_stmt->errorInfo();
                    error_log("Order item insert failed: " . json_encode($errorInfo));
                    throw new Exception("Failed to create order items: " . $errorInfo[2]);
                }
                
                // Update stock only if product_id is valid
                if ($pid !== null) {
                    $stock_query = "UPDATE products SET stock_quantity = stock_quantity - ?
                                   WHERE product_id = ? AND stock_quantity >= ?";
                    $stock_stmt = $this->conn->prepare($stock_query);
                    $stock_stmt->execute([$item['quantity'], $pid, $item['quantity']]);
                    if ($stock_stmt->rowCount() === 0) {
                        throw new Exception("Insufficient stock during final checkout for product_id: " . $pid);
                    }
                }
                
                // Update best_sellers (with error handling)
                if ($pid !== null) {
                    try {
                        $best_query = "INSERT INTO best_sellers (product_id, sales_count) 
                                       VALUES (?, ?)
                                       ON DUPLICATE KEY UPDATE 
                                       sales_count = sales_count + VALUES(sales_count)";
                        $best_stmt = $this->conn->prepare($best_query);
                        $best_stmt->execute([$pid, $item['quantity']]);
                    } catch (Exception $e) {
                        error_log("Best sellers update failed (non-critical): " . $e->getMessage());
                    }
                }
                
                // Update trending score (with error handling)
                if ($pid !== null) {
                    try {
                        $trend_query = "INSERT INTO trending_products (product_id, trending_score) 
                                       VALUES (?, 1)
                                       ON DUPLICATE KEY UPDATE 
                                       trending_score = trending_score + 1";
                        $trend_stmt = $this->conn->prepare($trend_query);
                        $trend_stmt->execute([$pid]);
                    } catch (Exception $e) {
                        error_log("Trending products update failed (non-critical): " . $e->getMessage());
                    }
                }
            }
            
            // Clear cart - use direct query instead of Cart class to avoid dependency issues
            $clear_query = "DELETE FROM cart WHERE user_id = :user_id";
            $clear_stmt = $this->conn->prepare($clear_query);
            $clear_stmt->bindParam(":user_id", $this->user_id);
            $clear_stmt->execute();
            
            $this->conn->commit();
            error_log("Order transaction committed successfully");
            return true;
            
        } catch (Exception $e) {
            $this->conn->rollBack();
            error_log("Order creation failed: " . $e->getMessage());
            return false;
        }
    }
    
    public function getUserOrders($user_id) {
        $query = "SELECT o.*, 
                         COUNT(oi.order_item_id) as item_count
                  FROM " . $this->table_name . " o
                  LEFT JOIN order_items oi ON o.order_id = oi.order_id
                  WHERE o.user_id = :user_id
                  GROUP BY o.order_id
                  ORDER BY o.order_date DESC";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->execute();
        
        $orders = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Get items for each order
        foreach ($orders as &$order) {
            $item_query = "SELECT * FROM order_items WHERE order_id = :order_id";
            $item_stmt = $this->conn->prepare($item_query);
            $item_stmt->bindParam(':order_id', $order['order_id']);
            $item_stmt->execute();
            $order['items'] = $item_stmt->fetchAll(PDO::FETCH_ASSOC);
        }
        
        return $orders;
    }
    
    public function getOrderDetails($order_id, $user_id = null) {
        $query = "SELECT o.* FROM " . $this->table_name . " o WHERE o.order_id = :order_id";
        
        if ($user_id) {
            $query .= " AND o.user_id = :user_id";
        }
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':order_id', $order_id);
        
        if ($user_id) {
            $stmt->bindParam(':user_id', $user_id);
        }
        
        $stmt->execute();
        $order = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($order) {
            // Get items
            $item_query = "SELECT * FROM order_items WHERE order_id = :order_id";
            $item_stmt = $this->conn->prepare($item_query);
            $item_stmt->bindParam(':order_id', $order_id);
            $item_stmt->execute();
            $order['items'] = $item_stmt->fetchAll(PDO::FETCH_ASSOC);
        }
        
        return $order;
    }
    
    public function updateStatus($order_id, $status, $admin_id) {
        $query = "UPDATE " . $this->table_name . "
                  SET order_status = :status
                  WHERE order_id = :order_id";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':status', $status);
        $stmt->bindParam(':order_id', $order_id);
        
        return $stmt->execute();
    }
    
    /**
     * Check if a column exists in a table (used for safe fallback queries)
     */
    private function columnExists($table, $column) {
        try {
            $stmt = $this->conn->prepare(
                "SELECT COUNT(*) FROM information_schema.COLUMNS
                 WHERE TABLE_SCHEMA = DATABASE()
                   AND TABLE_NAME = :table
                   AND COLUMN_NAME = :column"
            );
            $stmt->execute([':table' => $table, ':column' => $column]);
            return (int)$stmt->fetchColumn() > 0;
        } catch (Exception $e) {
            return false;
        }
    }

    public function getAllOrders($limit = 100, $offset = 0) {
        // Dynamically include guest-order columns only if they exist in the DB.
        // This prevents a fatal 500 when the DB schema is older than the code.
        $hasCustomerName  = $this->columnExists($this->table_name, 'customer_name');
        $hasCustomerPhone = $this->columnExists($this->table_name, 'customer_phone');

        $displayName  = $hasCustomerName
            ? "COALESCE(o.customer_name, u.full_name)"
            : "u.full_name";
        $displayPhone = $hasCustomerPhone
            ? "COALESCE(o.customer_phone, u.phone_number)"
            : "u.phone_number";

        $query = "SELECT o.*, 
                         u.full_name, 
                         u.last_name,
                         u.email, 
                         u.phone_number,
                         u.address as user_address,
                         u.gender,
                         u.role,
                         u.created_at as user_created_at,
                         $displayName  as display_name,
                         $displayPhone as display_phone
                  FROM " . $this->table_name . " o
                  LEFT JOIN users u ON o.user_id = u.user_id
                  ORDER BY o.order_date DESC
                  LIMIT :limit OFFSET :offset";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindValue(':limit', (int)$limit, PDO::PARAM_INT);
        $stmt->bindValue(':offset', (int)$offset, PDO::PARAM_INT);
        $stmt->execute();
        
        $orders = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Get items for each order
        foreach ($orders as &$order) {
            $item_query = "SELECT * FROM order_items WHERE order_id = :order_id";
            $item_stmt = $this->conn->prepare($item_query);
            $item_stmt->bindParam(':order_id', $order['order_id']);
            $item_stmt->execute();
            $order['items'] = $item_stmt->fetchAll(PDO::FETCH_ASSOC);
        }
        
        return $orders;
    }
}
?>
