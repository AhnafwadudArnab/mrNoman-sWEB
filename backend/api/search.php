<?php
require_once __DIR__ . '/bootstrap.php';
require_once __DIR__ . '/../models/product.php';
require_once __DIR__ . '/../util/JWT.php';

$db = db();
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

if ($method === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Get user ID if authenticated (optional — search works without login too)
$user_id = null;
$token = bearerToken();
if ($token) {
    $payload = JWT::verify($token);
    if ($payload) {
        $user_id = $payload['user_id'] ?? null;
    }
}

switch ($method) {
    case 'GET':
        if (isset($_GET['suggestions'])) {
            // Get search suggestions (autocomplete)
            $query = $_GET['q'] ?? '';
            if (strlen($query) < 2) {
                echo json_encode(['suggestions' => []]);
                exit;
            }
            
            $query = '%' . $query . '%';
            
            // Get product name suggestions
            $stmt = $db->prepare("
                SELECT DISTINCT product_name as suggestion, 'product' as type
                FROM products
                WHERE product_name LIKE ?
                LIMIT 5
            ");
            $stmt->execute([$query]);
            $products = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Get category suggestions
            $stmt = $db->prepare("
                SELECT DISTINCT category_name as suggestion, 'category' as type
                FROM categories
                WHERE category_name LIKE ?
                LIMIT 3
            ");
            $stmt->execute([$query]);
            $categories = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Get brand suggestions
            $stmt = $db->prepare("
                SELECT DISTINCT brand_name as suggestion, 'brand' as type
                FROM brands
                WHERE brand_name LIKE ?
                LIMIT 3
            ");
            $stmt->execute([$query]);
            $brands = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            $suggestions = array_merge($products, $categories, $brands);
            
            echo json_encode(['suggestions' => $suggestions]);
            
        } elseif (isset($_GET['popular'])) {
            // Get popular searches
            $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 10;
            
            $stmt = $db->prepare("
                SELECT search_query, COUNT(*) as search_count
                FROM search_history
                WHERE searched_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
                GROUP BY search_query
                ORDER BY search_count DESC
                LIMIT ?
            ");
            $stmt->execute([$limit]);
            $popular = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            echo json_encode(['popular' => $popular]);
            
        } elseif (isset($_GET['history']) && $user_id) {
            // Get user's search history
            $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 10;
            
            $stmt = $db->prepare("
                SELECT DISTINCT search_query, MAX(searched_at) as last_searched
                FROM search_history
                WHERE user_id = ?
                GROUP BY search_query
                ORDER BY last_searched DESC
                LIMIT ?
            ");
            $stmt->execute([$user_id, $limit]);
            $history = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            echo json_encode(['history' => $history]);
            
        } else {
            // Perform actual search
            $query = $_GET['q'] ?? '';
            
            if (empty($query)) {
                echo json_encode(['products' => [], 'count' => 0]);
                exit;
            }
            
            // Search products
            $searchQuery = '%' . $query . '%';
            
            $stmt = $db->prepare("
                SELECT p.*, c.category_name, b.brand_name,
                       d.discount_percent,
                       CASE 
                           WHEN d.discount_percent IS NOT NULL 
                           THEN p.price * (1 - d.discount_percent/100)
                           ELSE p.price 
                       END as discounted_price,
                       CASE
                           WHEN p.product_name LIKE ? THEN 1
                           WHEN p.description LIKE ? THEN 2
                           WHEN c.category_name LIKE ? THEN 3
                           WHEN b.brand_name LIKE ? THEN 4
                           ELSE 5
                       END as relevance
                FROM products p
                LEFT JOIN categories c ON p.category_id = c.category_id
                LEFT JOIN brands b ON p.brand_id = b.brand_id
                LEFT JOIN discounts d ON p.product_id = d.product_id 
                    AND CURDATE() BETWEEN d.valid_from AND d.valid_to
                WHERE p.product_name LIKE ?
                   OR p.description LIKE ?
                   OR c.category_name LIKE ?
                   OR b.brand_name LIKE ?
                ORDER BY relevance ASC, p.product_name ASC
                LIMIT 100
            ");
            
            $stmt->execute([
                $searchQuery, $searchQuery, $searchQuery, $searchQuery,
                $searchQuery, $searchQuery, $searchQuery, $searchQuery
            ]);
            
            $products = $stmt->fetchAll(PDO::FETCH_ASSOC);
            $count = count($products);
            
            // Save search history
            $stmt = $db->prepare("
                INSERT INTO search_history (user_id, search_query, results_count)
                VALUES (?, ?, ?)
            ");
            $stmt->execute([$user_id, $query, $count]);
            
            echo json_encode([
                'products' => $products,
                'count' => $count,
                'query' => $query
            ]);
        }
        break;
        
    case 'DELETE':
        // Clear search history
        if (!$user_id) {
            http_response_code(401);
            echo json_encode(['message' => 'Unauthorized']);
            exit;
        }
        
        if (isset($_GET['query'])) {
            // Delete specific search
            $query = $_GET['query'];
            $stmt = $db->prepare("DELETE FROM search_history WHERE user_id = ? AND search_query = ?");
            $stmt->execute([$user_id, $query]);
        } else {
            // Clear all history
            $stmt = $db->prepare("DELETE FROM search_history WHERE user_id = ?");
            $stmt->execute([$user_id]);
        }
        
        echo json_encode(['message' => 'Search history cleared']);
        break;
        
    default:
        http_response_code(405);
        echo json_encode(['message' => 'Method not allowed']);
}
