<?php
class Cart {
    private $conn;
    private $table_name = "cart";
    
    public $cart_id;
    public $user_id;
    public $product_id;
    public $quantity;
    
    public function __construct($db) {
        $this->conn = $db;
    }
    
    public function getUserCart($user_id) {
        $query = "SELECT c.*, p.product_name, p.price, p.image_url,
                         CASE 
                             WHEN d.discount_percent IS NOT NULL 
                             THEN p.price * (1 - d.discount_percent/100)
                             ELSE p.price 
                         END as discounted_price,
                         p.stock_quantity
                  FROM " . $this->table_name . " c
                  JOIN products p ON c.product_id = p.product_id
                  LEFT JOIN discounts d ON p.product_id = d.product_id 
                      AND CURDATE() BETWEEN d.valid_from AND d.valid_to
                  WHERE c.user_id = :user_id
                  ORDER BY c.added_at DESC";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->execute();
        
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    public function addItem() {
        // Check if item already exists
        $check_query = "SELECT cart_id, quantity FROM " . $this->table_name . "
                        WHERE user_id = :user_id AND product_id = :product_id";
        
        $check_stmt = $this->conn->prepare($check_query);
        $check_stmt->bindParam(':user_id', $this->user_id);
        $check_stmt->bindParam(':product_id', $this->product_id);
        $check_stmt->execute();
        
        if ($check_stmt->rowCount() > 0) {
            // Update quantity
            $row = $check_stmt->fetch(PDO::FETCH_ASSOC);
            $new_quantity = $row['quantity'] + $this->quantity;
            
            $update_query = "UPDATE " . $this->table_name . "
                            SET quantity = :quantity
                            WHERE cart_id = :cart_id";
            
            $update_stmt = $this->conn->prepare($update_query);
            $update_stmt->bindParam(':quantity', $new_quantity);
            $update_stmt->bindParam(':cart_id', $row['cart_id']);
            
            return $update_stmt->execute();
        } else {
            // Insert new item
            $insert_query = "INSERT INTO " . $this->table_name . "
                            (user_id, product_id, quantity)
                            VALUES (:user_id, :product_id, :quantity)";
            
            $insert_stmt = $this->conn->prepare($insert_query);
            $insert_stmt->bindParam(':user_id', $this->user_id);
            $insert_stmt->bindParam(':product_id', $this->product_id);
            $insert_stmt->bindParam(':quantity', $this->quantity);
            
            return $insert_stmt->execute();
        }
    }
    
    public function updateQuantity() {
        $query = "UPDATE " . $this->table_name . "
                  SET quantity = :quantity
                  WHERE cart_id = :cart_id AND user_id = :user_id";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':quantity', $this->quantity);
        $stmt->bindParam(':cart_id', $this->cart_id);
        $stmt->bindParam(':user_id', $this->user_id);
        
        return $stmt->execute();
    }
    
    public function removeItem() {
        $query = "DELETE FROM " . $this->table_name . "
                  WHERE cart_id = :cart_id AND user_id = :user_id";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':cart_id', $this->cart_id);
        $stmt->bindParam(':user_id', $this->user_id);
        
        return $stmt->execute();
    }
    
    public function clearCart($user_id) {
        $query = "DELETE FROM " . $this->table_name . " WHERE user_id = :user_id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':user_id', $user_id);
        return $stmt->execute();
    }
    
    public function getCartTotal($user_id) {
        $query = "SELECT SUM(
                        CASE 
                            WHEN d.discount_percent IS NOT NULL 
                            THEN p.price * (1 - d.discount_percent/100) * c.quantity
                            ELSE p.price * c.quantity
                        END
                    ) as total
                  FROM " . $this->table_name . " c
                  JOIN products p ON c.product_id = p.product_id
                  LEFT JOIN discounts d ON p.product_id = d.product_id 
                      AND CURDATE() BETWEEN d.valid_from AND d.valid_to
                  WHERE c.user_id = :user_id";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->execute();
        
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        return $row['total'] ?? 0;
    }
}
?>