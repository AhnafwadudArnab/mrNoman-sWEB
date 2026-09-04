<?php
class Product {
    private $conn;
    private $table_name = "products";
    
    public $product_id;
    public $category_id;
    public $brand_id;
    public $product_name;
    public $description;
    public $price;
    public $stock_quantity;
    public $image_url;
    public $specs;
    
    public function __construct($db) {
        $this->conn = $db;
    }
    
    public function getAll($limit = 100, $offset = 0, $category = null, $brand = null) {
        $query = "SELECT p.*, c.category_name, b.brand_name,
                         d.discount_percent, 
                         pr.rating_avg, pr.review_count,
                         CASE 
                             WHEN d.discount_percent IS NOT NULL 
                             THEN p.price * (1 - d.discount_percent/100)
                             ELSE p.price 
                         END as discounted_price
                  FROM " . $this->table_name . " p
                  LEFT JOIN categories c ON p.category_id = c.category_id
                  LEFT JOIN brands b ON p.brand_id = b.brand_id
                  LEFT JOIN discounts d ON p.product_id = d.product_id 
                      AND CURDATE() BETWEEN d.valid_from AND d.valid_to
                  LEFT JOIN product_ratings pr ON pr.product_id = p.product_id";
        
        $conditions = [];
        $params = [];
        
        if ($category) {
            // Support category_id (integer > 0), category name (string), or collection slug (string)
            if (is_numeric($category) && (int)$category > 0) {
                $conditions[] = "p.category_id = :category";
                $params[':category'] = (int)$category;
            } elseif (!is_numeric($category)) {
                // Try category name first, then collection slug
                $conditions[] = "(c.category_name = :category_name OR p.product_id IN (
                    SELECT cp.product_id 
                    FROM collection_products cp
                    JOIN collections col ON cp.collection_id = col.collection_id
                    WHERE col.slug = :category_slug
                ))";
                $params[':category_name'] = $category;
                $params[':category_slug'] = $category;
            }
            // category_id = 0 → no filter (return all)
        }
        
        if ($brand) {
            $conditions[] = "p.brand_id = :brand";
            $params[':brand'] = $brand;
        }
        
        if (!empty($conditions)) {
            $query .= " WHERE " . implode(" AND ", $conditions);
        }
        
        $query .= " ORDER BY p.created_at DESC LIMIT :limit OFFSET :offset";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':limit', $limit, PDO::PARAM_INT);
        $stmt->bindParam(':offset', $offset, PDO::PARAM_INT);
        
        foreach ($params as $key => $value) {
            $stmt->bindValue($key, $value);
        }
        
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    public function getById($id) {
        $query = "SELECT p.*, c.category_name, b.brand_name,
                         d.discount_percent, d.valid_from, d.valid_to,
                         pr.rating_avg, pr.review_count,
                         CASE 
                             WHEN d.discount_percent IS NOT NULL 
                             THEN p.price * (1 - d.discount_percent/100)
                             ELSE p.price 
                         END as discounted_price
                  FROM " . $this->table_name . " p
                  LEFT JOIN categories c ON p.category_id = c.category_id
                  LEFT JOIN brands b ON p.brand_id = b.brand_id
                  LEFT JOIN discounts d ON p.product_id = d.product_id 
                      AND CURDATE() BETWEEN d.valid_from AND d.valid_to
                  LEFT JOIN product_ratings pr ON pr.product_id = p.product_id
                  WHERE p.product_id = :id";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }
    
    public function getBestSellers($limit = 10) {
        $query = "SELECT p.*, c.category_name, b.brand_name,
                         bs.sales_count, bs.selling_point, bs.sales_strategy,
                         bs.created_at as bestseller_added_at
                  FROM products p
                  JOIN best_sellers bs ON p.product_id = bs.product_id
                  LEFT JOIN categories c ON p.category_id = c.category_id
                  LEFT JOIN brands b ON p.brand_id = b.brand_id
                  ORDER BY bs.created_at DESC, bs.sales_count DESC
                  LIMIT :limit";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':limit', $limit, PDO::PARAM_INT);
        $stmt->execute();
        
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    public function getTrending($limit = 10) {
        $query = "SELECT p.*, c.category_name, b.brand_name,
                         tp.trending_score,
                         COALESCE(tp.image_path, p.image_url) as image_url,
                         tp.display_order,
                         tp.created_at as trending_added_at
                  FROM products p
                  JOIN trending_products tp ON p.product_id = tp.product_id
                  LEFT JOIN categories c ON p.category_id = c.category_id
                  LEFT JOIN brands b ON p.brand_id = b.brand_id
                  ORDER BY tp.created_at DESC, tp.display_order ASC, tp.trending_score DESC
                  LIMIT :limit";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':limit', $limit, PDO::PARAM_INT);
        $stmt->execute();
        
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    public function getDealsOfDay($limit = 10) {
        $query = "SELECT p.*, c.category_name, b.brand_name,
                         d.deal_price, d.end_date,
                         d.created_at as deal_added_at
                  FROM products p
                  JOIN deals_of_the_day d ON p.product_id = d.product_id
                  LEFT JOIN categories c ON p.category_id = c.category_id
                  LEFT JOIN brands b ON p.brand_id = b.brand_id
                  ORDER BY d.created_at DESC, d.end_date ASC
                  LIMIT :limit";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':limit', $limit, PDO::PARAM_INT);
        $stmt->execute();
        
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    public function getFlashSale($limit = 10) {
        $query = "SELECT p.*, c.category_name, b.brand_name,
                         fs.title as flash_sale_title,
                         fs.end_time,
                         fsp.flash_price,
                         COALESCE(fsp.image_path, p.image_url) as image_url,
                         fsp.display_order,
                         fsp.created_at as flash_added_at
                  FROM products p
                  JOIN flash_sale_products fsp ON p.product_id = fsp.product_id
                  JOIN flash_sales fs ON fsp.flash_sale_id = fs.flash_sale_id
                  LEFT JOIN categories c ON p.category_id = c.category_id
                  LEFT JOIN brands b ON p.brand_id = b.brand_id
                  WHERE fs.active = 1 AND fs.end_time >= NOW()
                  ORDER BY fsp.created_at DESC, fsp.display_order ASC, fs.end_time ASC
                  LIMIT :limit";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':limit', $limit, PDO::PARAM_INT);
        $stmt->execute();
        
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    public function getTechPart($limit = 10) {
        $query = "SELECT p.*, c.category_name, b.brand_name,
                         tp.display_order,
                         tp.created_at as techpart_added_at
                  FROM products p
                  JOIN tech_part_products tp ON p.product_id = tp.product_id
                  LEFT JOIN categories c ON p.category_id = c.category_id
                  LEFT JOIN brands b ON p.brand_id = b.brand_id
                  ORDER BY tp.created_at DESC, tp.display_order ASC
                  LIMIT :limit";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':limit', $limit, PDO::PARAM_INT);
        $stmt->execute();
        
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    public function search($keyword) {
        $query = "SELECT p.*, c.category_name, b.brand_name
                  FROM " . $this->table_name . " p
                  LEFT JOIN categories c ON p.category_id = c.category_id
                  LEFT JOIN brands b ON p.brand_id = b.brand_id
                  WHERE p.product_name LIKE :keyword_name
                     OR p.description LIKE :keyword_description
                     OR c.category_name LIKE :keyword_category
                     OR b.brand_name LIKE :keyword_brand
                  ORDER BY 
                    CASE WHEN p.product_name LIKE :exact THEN 0 ELSE 1 END,
                    p.created_at DESC";
        
        $stmt = $this->conn->prepare($query);
        $searchTerm = "%{$keyword}%";
        $exactTerm = "{$keyword}%";
        $stmt->bindValue(':keyword_name', $searchTerm);
        $stmt->bindValue(':keyword_description', $searchTerm);
        $stmt->bindValue(':keyword_category', $searchTerm);
        $stmt->bindValue(':keyword_brand', $searchTerm);
        $stmt->bindParam(':exact', $exactTerm);
        $stmt->execute();
        
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    
    public function create() {
        $query = "INSERT INTO " . $this->table_name . "
                  (category_id, brand_id, product_name, description, price, stock_quantity, image_url, specs_json)
                  VALUES (:category_id, :brand_id, :product_name, :description, :price, :stock, :image, :specs)";
        
        $stmt = $this->conn->prepare($query);
        
        $stmt->bindParam(":category_id", $this->category_id);
        $stmt->bindParam(":brand_id", $this->brand_id);
        $stmt->bindParam(":product_name", $this->product_name);
        $stmt->bindParam(":description", $this->description);
        $stmt->bindParam(":price", $this->price);
        $stmt->bindParam(":stock", $this->stock_quantity);
        $stmt->bindParam(":image", $this->image_url);
        $stmt->bindParam(":specs", $this->specs);
        
        try {
            if ($stmt->execute()) {
                $this->product_id = $this->conn->lastInsertId();
                error_log("Product created successfully with ID: " . $this->product_id);
                return true;
            }
            error_log("Failed to execute product insert query");
            return false;
        } catch (PDOException $e) {
            error_log("Database error in product creation: " . $e->getMessage());
            return false;
        }
    }
    
    public function update() {
        $query = "UPDATE " . $this->table_name . "
                  SET category_id = :category_id,
                      brand_id = :brand_id,
                      product_name = :product_name,
                      description = :description,
                      price = :price,
                      stock_quantity = :stock,
                      image_url = :image
                  WHERE product_id = :product_id";
        
        $stmt = $this->conn->prepare($query);
        
        $stmt->bindParam(":category_id", $this->category_id);
        $stmt->bindParam(":brand_id", $this->brand_id);
        $stmt->bindParam(":product_name", $this->product_name);
        $stmt->bindParam(":description", $this->description);
        $stmt->bindParam(":price", $this->price);
        $stmt->bindParam(":stock", $this->stock_quantity);
        $stmt->bindParam(":image", $this->image_url);
        $stmt->bindParam(":product_id", $this->product_id);
        
        return $stmt->execute();
    }
    
    public function delete() {
        $query = "DELETE FROM " . $this->table_name . " WHERE product_id = :product_id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":product_id", $this->product_id);
        return $stmt->execute();
    }
}
