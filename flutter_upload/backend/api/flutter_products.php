<?php
/**
 * Flutter Products API
 * Handles product listing, filtering, and search
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS, POST');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../services/DatabaseService.php';

try {
    $db = DatabaseService::getInstance();
    
    $method = $_SERVER['REQUEST_METHOD'];
    
    if ($method === 'GET') {
        handleGetRequest($db);
    } else {
        throw new Exception('Method not allowed');
    }

} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}

function handleGetRequest($db) {
    $response = [
        'success' => true,
        'data' => []
    ];

    // রিকোয়েস্ট প্যারামিটার পান
    $action = $_GET['action'] ?? 'list';
    $product_id = $_GET['product_id'] ?? null;
    $category_id = $_GET['category_id'] ?? null;
    $search = $_GET['search'] ?? null;
    $page = max(1, (int)($_GET['page'] ?? 1));
    $limit = min(50, (int)($_GET['limit'] ?? 20));
    $offset = ($page - 1) * $limit;
    $sort = $_GET['sort'] ?? 'newest'; // newest, popular, price_low, price_high
    
    switch ($action) {
        case 'details':
            if (!$product_id) {
                throw new Exception('product_id required');
            }
            $response['data'] = getProductDetails($db, $product_id);
            break;
            
        case 'by_category':
            if (!$category_id) {
                throw new Exception('category_id required');
            }
            $response['data'] = getProductsByCategory($db, $category_id, $offset, $limit, $sort);
            break;
            
        case 'search':
            if (!$search) {
                throw new Exception('search query required');
            }
            $response['data'] = searchProducts($db, $search, $offset, $limit);
            // সার্চ হিস্টরি সংরক্ষণ করুন
            saveSearchHistory($db, $search, count($response['data']));
            break;
            
        case 'list':
        default:
            $response['data'] = getAllProducts($db, $offset, $limit, $sort);
    }

    echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}

function getAllProducts($db, $offset, $limit, $sort) {
    $orderBy = getOrderByClause($sort);
    
    $query = "SELECT p.product_id, p.product_name, p.price, p.image_url,
              p.description, p.stock_quantity, p.category_id, b.brand_id, b.brand_name,
              COALESCE(pr.rating_avg, 0) as rating,
              COALESCE(pr.review_count, 0) as review_count
              FROM products p
              LEFT JOIN product_ratings pr ON p.product_id = pr.product_id
              LEFT JOIN brands b ON p.brand_id = b.brand_id
              WHERE p.stock_quantity > 0
              $orderBy
              LIMIT $offset, $limit";
    
    return formatProductList($db, $query);
}

function getProductsByCategory($db, $category_id, $offset, $limit, $sort) {
    $category_id = (int)$category_id;
    $orderBy = getOrderByClause($sort);
    
    $query = "SELECT p.product_id, p.product_name, p.price, p.image_url,
              p.description, p.stock_quantity, p.category_id, b.brand_id, b.brand_name,
              COALESCE(pr.rating_avg, 0) as rating,
              COALESCE(pr.review_count, 0) as review_count
              FROM products p
              LEFT JOIN product_ratings pr ON p.product_id = pr.product_id
              LEFT JOIN brands b ON p.brand_id = b.brand_id
              WHERE p.category_id = $category_id
              $orderBy
              LIMIT $offset, $limit";
    
    return formatProductList($db, $query);
}

function searchProducts($db, $search, $offset, $limit) {
    $search = $db->real_escape_string($search);
    
    $query = "SELECT p.product_id, p.product_name, p.price, p.image_url,
              p.description, p.stock_quantity, p.category_id, b.brand_id, b.brand_name,
              COALESCE(pr.rating_avg, 0) as rating,
              COALESCE(pr.review_count, 0) as review_count
              FROM products p
              LEFT JOIN product_ratings pr ON p.product_id = pr.product_id
              LEFT JOIN brands b ON p.brand_id = b.brand_id
              WHERE p.product_name LIKE '%$search%' 
              OR p.description LIKE '%$search%'
              OR b.brand_name LIKE '%$search%'
              ORDER BY p.product_name ASC
              LIMIT $offset, $limit";
    
    return formatProductList($db, $query);
}

function getProductDetails($db, $product_id) {
    $product_id = (int)$product_id;
    
    $query = "SELECT p.*, b.brand_name, c.category_name,
              COALESCE(pr.rating_avg, 0) as rating_avg,
              COALESCE(pr.review_count, 0) as review_count
              FROM products p
              LEFT JOIN brands b ON p.brand_id = b.brand_id
              LEFT JOIN categories c ON p.category_id = c.category_id
              LEFT JOIN product_ratings pr ON p.product_id = pr.product_id
              WHERE p.product_id = $product_id";
    
    $result = $db->query($query);
    if (!$result || $result->num_rows === 0) {
        throw new Exception('Product not found');
    }
    
    $product = $result->fetch_assoc();
    
    // স্পেসিফিকেশন পান
    $specs_query = "SELECT spec_key, spec_value FROM product_specifications WHERE product_id = $product_id";
    $specs_result = $db->query($specs_query);
    $specs = [];
    while ($spec = $specs_result->fetch_assoc()) {
        $specs[$spec['spec_key']] = $spec['spec_value'];
    }
    
    // রিভিউ পান
    $reviews_query = "SELECT r.review_id, r.rating, r.review_text, r.created_at 
                      FROM reviews r 
                      WHERE r.product_id = $product_id 
                      ORDER BY r.created_at DESC 
                      LIMIT 5";
    $reviews_result = $db->query($reviews_query);
    $reviews = [];
    while ($review = $reviews_result->fetch_assoc()) {
        $reviews[] = [
            'review_id' => (int)$review['review_id'],
            'rating' => (int)$review['rating'],
            'review_text' => $review['review_text'],
            'created_at' => $review['created_at']
        ];
    }
    
    return [
        'product_id' => (int)$product['product_id'],
        'product_name' => $product['product_name'],
        'description' => $product['description'],
        'price' => (float)$product['price'],
        'image_url' => $product['image_url'],
        'stock_quantity' => (int)$product['stock_quantity'],
        'category_id' => (int)$product['category_id'],
        'category_name' => $product['category_name'],
        'brand_id' => (int)$product['brand_id'],
        'brand_name' => $product['brand_name'],
        'rating' => (float)$product['rating_avg'],
        'review_count' => (int)$product['review_count'],
        'in_stock' => (int)$product['stock_quantity'] > 0,
        'specifications' => (object)$specs,
        'reviews' => $reviews,
        'created_at' => $product['created_at']
    ];
}

function formatProductList($db, $query) {
    $result = $db->query($query);
    if (!$result) {
        throw new Exception($db->error);
    }
    
    $products = [];
    while ($row = $result->fetch_assoc()) {
        $products[] = [
            'product_id' => (int)$row['product_id'],
            'product_name' => $row['product_name'],
            'price' => (float)$row['price'],
            'image_url' => $row['image_url'],
            'description' => $row['description'],
            'stock_quantity' => (int)$row['stock_quantity'],
            'category_id' => (int)$row['category_id'],
            'brand_id' => $row['brand_id'] ? (int)$row['brand_id'] : null,
            'brand_name' => $row['brand_name'],
            'rating' => (float)$row['rating'],
            'review_count' => (int)$row['review_count'],
            'in_stock' => (int)$row['stock_quantity'] > 0
        ];
    }
    
    return $products;
}

function getOrderByClause($sort) {
    switch ($sort) {
        case 'popular':
            return "ORDER BY pr.review_count DESC";
        case 'price_low':
            return "ORDER BY p.price ASC";
        case 'price_high':
            return "ORDER BY p.price DESC";
        case 'newest':
        default:
            return "ORDER BY p.created_at DESC";
    }
}

function saveSearchHistory($db, $search, $results_count) {
    $search = $db->real_escape_string($search);
    $user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : null;
    
    $user_id_sql = $user_id ? $user_id : 'NULL';
    
    $query = "INSERT INTO search_history (user_id, search_query, results_count) 
              VALUES ($user_id_sql, '$search', $results_count)";
    
    $db->query($query);
}
?>
