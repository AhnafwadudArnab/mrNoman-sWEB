<?php
class PaymentMethod {
    private $conn;
    private $table_name = "payment_methods";
    
    public $method_id;
    public $method_name;
    public $method_type;
    public $is_enabled;
    public $account_number;
    public $display_order;
    public $icon_url;
    
    public function __construct($db) {
        $this->conn = $db;
    }
    
    public function getAll() {
        $query = "SELECT * FROM " . $this->table_name . " ORDER BY display_order ASC, method_id ASC";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    public function getEnabled() {
        $query = "SELECT * FROM " . $this->table_name . " WHERE is_enabled = 1 ORDER BY display_order ASC";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    public function getById($id) {
        $query = "SELECT * FROM " . $this->table_name . " WHERE method_id = :id LIMIT 1";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }
    
    public function create() {
        $query = "INSERT INTO " . $this->table_name . "
                  (method_name, method_type, is_enabled, account_number, display_order, icon_url)
                  VALUES (:name, :type, :enabled, :account, :order, :icon)";
        
        $stmt = $this->conn->prepare($query);
        
        $stmt->bindParam(':name', $this->method_name);
        $stmt->bindParam(':type', $this->method_type);
        $stmt->bindParam(':enabled', $this->is_enabled);
        $stmt->bindParam(':account', $this->account_number);
        $stmt->bindParam(':order', $this->display_order);
        $stmt->bindParam(':icon', $this->icon_url);
        
        if ($stmt->execute()) {
            $this->method_id = $this->conn->lastInsertId();
            return true;
        }
        return false;
    }
    
    public function update() {
        $query = "UPDATE " . $this->table_name . "
                  SET method_name = :name,
                      method_type = :type,
                      is_enabled = :enabled,
                      account_number = :account,
                      display_order = :order,
                      icon_url = :icon
                  WHERE method_id = :id";
        
        $stmt = $this->conn->prepare($query);
        
        $stmt->bindParam(':name', $this->method_name);
        $stmt->bindParam(':type', $this->method_type);
        $stmt->bindParam(':enabled', $this->is_enabled);
        $stmt->bindParam(':account', $this->account_number);
        $stmt->bindParam(':order', $this->display_order);
        $stmt->bindParam(':icon', $this->icon_url);
        $stmt->bindParam(':id', $this->method_id);
        
        return $stmt->execute();
    }
    
    public function delete() {
        $query = "DELETE FROM " . $this->table_name . " WHERE method_id = :id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $this->method_id);
        return $stmt->execute();
    }
    
    public function toggleStatus($id, $status) {
        $query = "UPDATE " . $this->table_name . " SET is_enabled = :status WHERE method_id = :id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':status', $status, PDO::PARAM_INT);
        $stmt->bindParam(':id', $id);
        return $stmt->execute();
    }
}
?>
