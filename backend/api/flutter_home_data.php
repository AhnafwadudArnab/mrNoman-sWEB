<?php
/**
 * Flutter Home Screen Data API
 * Returns all data needed for Flutter home screen
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS, POST');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/bootstrap.php';

try {
    $db = db();
    $response = [
        'success' => true,
        'data' => []
    ];

    // ১. Banners
    $response['data']['banners'] = getBanners($db);

    // २. Flash Sales with Timer
    $response['data']['flash_sales'] = getFlashSales($db);
    $response['data']['flash_sales_timer'] = getFlashSalesTimer($db);

    // ३. Best Sellers
    $response['data']['best_sellers'] = getBestSellers($db);

    // ४. Trending Products
    $response['data']['trending_products'] = getTrendingProducts($db);

    // ५. Deals of the Day
    $response['data']['deals_of_the_day'] = getDealsOfTheDay($db);

    // ६. Categories
    $response['data']['categories'] = getCategories($db);

    // ७. Collections
    $response['data']['collections'] = getCollections($db);

    echo json_encode($response, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage(),
        'error' => isset($_ENV['APP_DEBUG']) && $_ENV['APP_DEBUG'] ? $e->getTrace() : null
    ]);
}

// Helper Functions

function getBanners($db) {
    $query = "SELECT banner_id, image_url, link_url, title, description, button_text, banner_type 
              FROM banners 
              WHERE active = 1 
              ORDER BY display_order ASC";
    
    $stmt = $db->query($query);
    $banners = [];
    
    while ($row = $stmt->fetch()) {
        $banners[] = [
            'banner_id' => (int)$row['banner_id'],
            'image_url' => $row['image_url'],
            'link_url' => $row['link_url'],
            'title' => $row['title'],
            'description' => $row['description'],
            'button_text' => $row['button_text'],
            'banner_type' => $row['banner_type']
        ];
    }
    
    return $banners;
}

function getFlashSales($db) {
    $query = "SELECT fs.flash_sale_id, fs.title, fs.start_time, fs.end_time,
              fsp.product_id, fsp.flash_price, fsp.image_path, fsp.display_order,
              p.product_name, p.price as original_price, p.stock_quantity
              FROM flash_sales fs
              LEFT JOIN flash_sale_products fsp ON fs.flash_sale_id = fsp.flash_sale_id
              LEFT JOIN products p ON fsp.product_id = p.product_id
              WHERE fs.active = 1
              ORDER BY fsp.display_order ASC";
    
    $stmt = $db->query($query);
    $sales = [];
    
    while ($row = $stmt->fetch()) {
        $sales[] = [
            'flash_sale_id' => (int)$row['flash_sale_id'],
            'product_id' => (int)$row['product_id'],
            'product_name' => $row['product_name'],
            'flash_price' => (float)$row['flash_price'],
            'original_price' => (float)$row['original_price'],
            'image_url' => $row['image_path'] ?? $row['product_id'],
            'discount_percent' => round((1 - ((float)$row['flash_price'] / (float)$row['original_price'])) * 100),
            'stock_quantity' => (int)$row['stock_quantity']
        ];
    }
    
    return $sales;
}

function getFlashSalesTimer($db) {
    $query = "SELECT days, hours, minutes, seconds FROM deals_timer LIMIT 1";
    $stmt = $db->query($query);
    
    if ($row = $stmt->fetch()) {
        return [
            'days' => (int)$row['days'],
            'hours' => (int)$row['hours'],
            'minutes' => (int)$row['minutes'],
            'seconds' => (int)$row['seconds']
        ];
    }
    
    return ['days' => 0, 'hours' => 0, 'minutes' => 0, 'seconds' => 0];
}

function getBestSellers($db) {
    $query = "SELECT p.product_id, p.product_name, p.price, p.image_url,
              p.description, p.stock_quantity, bs.sales_count,
              COALESCE(pr.rating_avg, 0) as rating, 
              COALESCE(pr.review_count, 0) as review_count
              FROM best_sellers bs
              JOIN products p ON bs.product_id = p.product_id
              LEFT JOIN product_ratings pr ON p.product_id = pr.product_id
              ORDER BY bs.sales_count DESC
              LIMIT 5";
    
    return fetchProducts($db, $query);
}

function getTrendingProducts($db) {
    $query = "SELECT p.product_id, p.product_name, p.price, p.image_url,
              p.description, p.stock_quantity,
              COALESCE(pr.rating_avg, 0) as rating,
              COALESCE(pr.review_count, 0) as review_count
              FROM trending_products tp
              JOIN products p ON tp.product_id = p.product_id
              LEFT JOIN product_ratings pr ON p.product_id = pr.product_id
              ORDER BY tp.display_order ASC
              LIMIT 10";
    
    return fetchProducts($db, $query);
}

function getDealsOfTheDay($db) {
    $query = "SELECT p.product_id, p.product_name, p.price, p.image_url,
              p.description, p.stock_quantity, d.deal_price,
              COALESCE(pr.rating_avg, 0) as rating,
              COALESCE(pr.review_count, 0) as review_count
              FROM deals_of_the_day d
              JOIN products p ON d.product_id = p.product_id
              LEFT JOIN product_ratings pr ON p.product_id = pr.product_id
              WHERE d.end_date >= NOW()
              LIMIT 6";
    
    $stmt = $db->query($query);
    $products = [];
    
    while ($row = $stmt->fetch()) {
        $products[] = formatProduct($row, (float)$row['deal_price']);
    }
    
    return $products;
}

function getCategories($db) {
    $query = "SELECT c.category_id, c.category_name, c.category_image,
              COUNT(p.product_id) as product_count
              FROM categories c
              LEFT JOIN products p ON c.category_id = p.category_id
              GROUP BY c.category_id
              ORDER BY c.category_id ASC";
    
    $stmt = $db->query($query);
    $categories = [];
    
    while ($row = $stmt->fetch()) {
        $categories[] = [
            'category_id' => (int)$row['category_id'],
            'category_name' => $row['category_name'],
            'image_url' => $row['category_image'],
            'product_count' => (int)$row['product_count']
        ];
    }
    
    return $categories;
}

function getCollections($db) {
    $query = "SELECT collection_id, name, slug, description, icon, image_url, display_order
              FROM collections
              WHERE is_active = 1
              ORDER BY display_order ASC";
    
    $stmt = $db->query($query);
    $collections = [];
    
    while ($row = $stmt->fetch()) {
        $collections[] = [
            'collection_id' => (int)$row['collection_id'],
            'name' => $row['name'],
            'slug' => $row['slug'],
            'description' => $row['description'],
            'icon' => $row['icon'],
            'image_url' => $row['image_url'],
            'display_order' => (int)$row['display_order']
        ];
    }
    
    return $collections;
}

function fetchProducts($db, $query) {
    $stmt = $db->query($query);
    $products = [];
    
    while ($row = $stmt->fetch()) {
        $products[] = formatProduct($row);
    }
    
    return $products;
}

function formatProduct($row, $price = null) {
    return [
        'product_id' => (int)$row['product_id'],
        'product_name' => $row['product_name'],
        'price' => (float)($price ?? $row['price']),
        'original_price' => (float)$row['price'],
        'image_url' => $row['image_url'],
        'description' => $row['description'],
        'stock_quantity' => (int)$row['stock_quantity'],
        'rating' => (float)$row['rating'],
        'review_count' => (int)$row['review_count'],
        'in_stock' => (int)$row['stock_quantity'] > 0
    ];
}
?>
