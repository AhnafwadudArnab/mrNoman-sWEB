<?php
header('Content-Type: application/json');
require_once __DIR__ . '/bootstrap.php';
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../middleware/authmiddleware.php';

$db = db();
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if ($method === 'PUT') {
    // Authenticate admin
    $admin = AuthMiddleware::authenticateAdmin();
    
    if (!isset($_GET['id'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Product ID required']);
        exit;
    }
    
    $productId = (int)$_GET['id'];
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!$data || !is_array($data)) {
        http_response_code(400);
        echo json_encode(['error' => 'Invalid request body']);
        exit;
    }
    
    try {
        $db->beginTransaction();
        
        // Handle each section
        foreach ($data as $section => $enabled) {
            if (!is_bool($enabled)) continue;
            
            switch ($section) {
                case 'best_sellers':
                    if ($enabled) {
                        $stmt = $db->prepare("
                            INSERT INTO best_sellers (product_id, sales_count, created_at)
                            VALUES (?, 0, NOW())
                            ON DUPLICATE KEY UPDATE product_id = product_id
                        ");
                        $stmt->execute([$productId]);
                    } else {
                        $stmt = $db->prepare("DELETE FROM best_sellers WHERE product_id = ?");
                        $stmt->execute([$productId]);
                    }
                    break;
                    
                case 'trending':
                    if ($enabled) {
                        $stmt = $db->prepare("
                            INSERT INTO trending_products (product_id, trending_score, created_at)
                            VALUES (?, 0, NOW())
                            ON DUPLICATE KEY UPDATE product_id = product_id
                        ");
                        $stmt->execute([$productId]);
                    } else {
                        $stmt = $db->prepare("DELETE FROM trending_products WHERE product_id = ?");
                        $stmt->execute([$productId]);
                    }
                    break;
                    
                case 'deals':
                    if ($enabled) {
                        // Get product price
                        $stmt = $db->prepare("SELECT price FROM products WHERE product_id = ?");
                        $stmt->execute([$productId]);
                        $product = $stmt->fetch(PDO::FETCH_ASSOC);
                        
                        if ($product) {
                            $dealPrice = $product['price'] * 0.85; // 15% discount
                            $stmt = $db->prepare("
                                INSERT INTO deals_of_the_day (product_id, deal_price, start_date, end_date, created_at)
                                VALUES (?, ?, NOW(), DATE_ADD(NOW(), INTERVAL 365 DAY), NOW())
                                ON DUPLICATE KEY UPDATE 
                                    deal_price = VALUES(deal_price),
                                    start_date = VALUES(start_date),
                                    end_date = DATE_ADD(NOW(), INTERVAL 365 DAY)
                            ");
                            $stmt->execute([$productId, $dealPrice]);
                        }
                    } else {
                        $stmt = $db->prepare("DELETE FROM deals_of_the_day WHERE product_id = ?");
                        $stmt->execute([$productId]);
                    }
                    break;
                    
                case 'flash_sale':
                    if ($enabled) {
                        // Get or create active flash sale
                        $stmt = $db->query("
                            SELECT flash_sale_id FROM flash_sales 
                            WHERE active = 1 AND end_time > NOW() 
                            ORDER BY flash_sale_id DESC 
                            LIMIT 1
                        ");
                        $flashSale = $stmt->fetch(PDO::FETCH_ASSOC);
                        
                        if (!$flashSale) {
                            // Create new flash sale
                            $stmt = $db->prepare("
                                INSERT INTO flash_sales (title, start_time, end_time, active, created_at)
                                VALUES ('Flash Sale 2026', NOW(), DATE_ADD(NOW(), INTERVAL 7 DAY), 1, NOW())
                            ");
                            $stmt->execute();
                            $flashSaleId = $db->lastInsertId();
                        } else {
                            $flashSaleId = $flashSale['flash_sale_id'];
                        }
                        
                        // Get product price
                        $stmt = $db->prepare("SELECT price FROM products WHERE product_id = ?");
                        $stmt->execute([$productId]);
                        $product = $stmt->fetch(PDO::FETCH_ASSOC);
                        
                        if ($product) {
                            $flashPrice = $product['price'] * 0.80; // 20% discount
                            $stmt = $db->prepare("
                                INSERT INTO flash_sale_products (flash_sale_id, product_id, flash_price, created_at)
                                VALUES (?, ?, ?, NOW())
                                ON DUPLICATE KEY UPDATE 
                                    flash_price = VALUES(flash_price),
                                    created_at = NOW()
                            ");
                            $stmt->execute([$flashSaleId, $productId, $flashPrice]);
                        }
                    } else {
                        $stmt = $db->prepare("DELETE FROM flash_sale_products WHERE product_id = ?");
                        $stmt->execute([$productId]);
                    }
                    break;
                    
                case 'tech_part':
                    if ($enabled) {
                        $stmt = $db->prepare("
                            INSERT INTO tech_part_products (product_id, display_order, created_at)
                            VALUES (?, 0, NOW())
                            ON DUPLICATE KEY UPDATE product_id = product_id
                        ");
                        $stmt->execute([$productId]);
                    } else {
                        $stmt = $db->prepare("DELETE FROM tech_part_products WHERE product_id = ?");
                        $stmt->execute([$productId]);
                    }
                    break;
            }
        }
        
        $db->commit();
        
        echo json_encode([
            'success' => true,
            'message' => 'Product sections updated successfully',
            'product_id' => $productId
        ]);
        
    } catch (Exception $e) {
        $db->rollBack();
        error_log("Error updating product sections: " . $e->getMessage());
        http_response_code(500);
        echo json_encode([
            'error' => 'Failed to update product sections',
            'message' => $e->getMessage()
        ]);
    }
    
    exit;
}

http_response_code(405);
echo json_encode(['error' => 'Method not allowed']);
