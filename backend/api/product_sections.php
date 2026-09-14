ob_start();
header('Content-Type: application/json');
header('Cache-Control: no-cache, no-store, must-revalidate');
header('Pragma: no-cache');
require_once __DIR__ . '/bootstrap.php';
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../middleware/authmiddleware.php';

$db = db();
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if ($method === 'PUT' || $method === 'POST') {
    // Authenticate admin
    $admin = AuthMiddleware::authenticateAdmin();
    
    $productId = isset($_GET['id']) ? (int)$_GET['id'] : null;
    $input = file_get_contents('php://input');
    $data = !empty($input) ? json_decode($input, true) : $_POST;
    
    if (!$productId && isset($data['id'])) {
        $productId = (int)$data['id'];
    }
    if (!$productId && isset($data['product_id'])) {
        $productId = (int)$data['product_id'];
    }
    
    if (!$productId) {
        http_response_code(400);
        ob_clean();
        echo json_encode(['error' => 'Product ID required']);
        exit;
    }
    
    if (!$data || !is_array($data)) {
        http_response_code(400);
        ob_clean();
        echo json_encode(['error' => 'Invalid request body']);
        exit;
    }
    
    try {
        $db->beginTransaction();
        
        // Handle each section
        foreach ($data as $section => $enabled) {
            $s = strtolower(trim((string)$section));
            $isBool = is_bool($enabled) ? $enabled : ($enabled === 1 || $enabled === '1' || $enabled === 'true' || $enabled === true);
            
            switch ($s) {
                case 'best_sellers':
                case 'bestsellers':
                case 'best_selling':
                case 'best sellings':
                    if ($isBool) {
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
                case 'trendings':
                case 'trending_products':
                case 'trending items':
                    if ($isBool) {
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
                case 'deals_of_the_day':
                case 'dealsoftheday':
                    if ($isBool) {
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
                case 'flashsale':
                case 'flash sale':
                    if ($isBool) {
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
                case 'techpart':
                case 'tech part':
                    if ($isBool) {
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
        
        ob_clean();
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
