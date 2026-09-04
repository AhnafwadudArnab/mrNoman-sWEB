<?php
class Brand {
    private $conn;
    private $table_name = "brands";
    
    public $brand_id;
    public $brand_name;
    public $brand_logo;
    
    public function __construct($db) {
        $this->conn = $db;
    }
    
    public function getAll() {
        $query = "SELECT * FROM " . $this->table_name . " ORDER BY brand_name";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    public function getById($id) {
        $query = "SELECT * FROM " . $this->table_name . " WHERE brand_id = :id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }
    
    public function create() {
        $query = "INSERT INTO " . $this->table_name . "
                  (brand_name, brand_logo)
                  VALUES (:name, :logo)";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":name", $this->brand_name);
        $stmt->bindParam(":logo", $this->brand_logo);
        
        return $stmt->execute();
    }
    
    public function update() {
        $query = "UPDATE " . $this->table_name . "
                  SET brand_name = :name, brand_logo = :logo
                  WHERE brand_id = :id";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":name", $this->brand_name);
        $stmt->bindParam(":logo", $this->brand_logo);
        $stmt->bindParam(":id", $this->brand_id);
        
        return $stmt->execute();
    }
    
    public function delete() {
        $query = "DELETE FROM " . $this->table_name . " WHERE brand_id = :id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":id", $this->brand_id);
        
        return $stmt->execute();
    }
}
?>