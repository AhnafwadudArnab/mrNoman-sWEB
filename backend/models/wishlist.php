<?php
class Wishlist {
    private $conn;
    private $table_name = "wishlists";
    
    public $wishlist_id;
    public $user_id;
    public $product_id;
    
    public function __construct($db) {
        $this->conn = $db;
    }
    
    public function getUserWishlist($user_id) {
        $query = "SELECT w.*, p.product_name, p.price, p.image_url,
                         c.category_name, b.brand_name
                  FROM " . $this->table_name . " w
                  JOIN products p ON w.product_id = p.product_id
                  LEFT JOIN categories c ON p.category_id = c.category_id
                  LEFT JOIN brands b ON p.brand_id = b.brand_id
                  WHERE w.user_id = :user_id
                  ORDER BY w.added_at DESC";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->execute();
        
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    public function addItem() {
        // Check if already exists
        $check_query = "SELECT wishlist_id FROM " . $this->table_name . "
                        WHERE user_id = :user_id AND product_id = :product_id";
        
        $check_stmt = $this->conn->prepare($check_query);
        $check_stmt->bindParam(':user_id', $this->user_id);
        $check_stmt->bindParam(':product_id', $this->product_id);
        $check_stmt->execute();
        
        if ($check_stmt->rowCount() > 0) {
            return true; // Already exists
        }
        
        $query = "INSERT INTO " . $this->table_name . "
                  (user_id, product_id)
                  VALUES (:user_id, :product_id)";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':user_id', $this->user_id);
        $stmt->bindParam(':product_id', $this->product_id);
        
        return $stmt->execute();
    }
    
    public function removeItem() {
        $query = "DELETE FROM " . $this->table_name . "
                  WHERE user_id = :user_id AND product_id = :product_id";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':user_id', $this->user_id);
        $stmt->bindParam(':product_id', $this->product_id);
        
        return $stmt->execute();
    }
    
    public function isInWishlist($user_id, $product_id) {
        $query = "SELECT wishlist_id FROM " . $this->table_name . "
                  WHERE user_id = :user_id AND product_id = :product_id";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->bindParam(':product_id', $product_id);
        $stmt->execute();
        
        return $stmt->rowCount() > 0;
    }
}
?>