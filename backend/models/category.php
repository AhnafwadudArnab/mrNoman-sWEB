<?php
class Category {
    private $conn;
    private $table_name = "categories";
    
    public $category_id;
    public $category_name;
    public $category_image;
    
    public function __construct($db) {
        $this->conn = $db;
    }
    
    public function getAll() {
        $query = "SELECT * FROM " . $this->table_name . " ORDER BY category_name";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    public function getById($id) {
        $query = "SELECT * FROM " . $this->table_name . " WHERE category_id = :id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }
    
    public function create() {
        $query = "INSERT INTO " . $this->table_name . "
                  (category_name, category_image)
                  VALUES (:name, :image)";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":name", $this->category_name);
        $stmt->bindParam(":image", $this->category_image);
        
        return $stmt->execute();
    }
    
    public function update() {
        $query = "UPDATE " . $this->table_name . "
                  SET category_name = :name, category_image = :image
                  WHERE category_id = :id";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":name", $this->category_name);
        $stmt->bindParam(":image", $this->category_image);
        $stmt->bindParam(":id", $this->category_id);
        
        return $stmt->execute();
    }
    
    public function delete() {
        $query = "DELETE FROM " . $this->table_name . " WHERE category_id = :id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":id", $this->category_id);
        
        return $stmt->execute();
    }
}
?>