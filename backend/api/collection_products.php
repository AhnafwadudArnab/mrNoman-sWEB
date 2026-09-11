<?php
// ============================================
// COLLECTION PRODUCTS API
// GET /api/collection_products?collection_id=1
// POST /api/collection_products (collection_id, product_id)
// DELETE /api/collection_products?collection_id=1&product_id=2
// ============================================
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/bootstrap.php';

$db = db();
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

if ($method === 'POST') {
    requireAdmin();
    $data = getJsonBody();
    $colId = (int)($data['collection_id'] ?? 0);
    $prodId = (int)($data['product_id'] ?? 0);
    if ($colId <= 0 || $prodId <= 0) {
        errorResponse('collection_id and product_id required', 400);
    }
    $stmt = $db->prepare("INSERT IGNORE INTO collection_products (collection_id, product_id, added_at) VALUES (?, ?, NOW())");
    $stmt->execute([$colId, $prodId]);
    jsonResponse(['message' => 'Product linked to collection successfully'], 201);
}

if ($method === 'DELETE') {
    requireAdmin();
    $colId = (int)($_GET['collection_id'] ?? 0);
    $prodId = (int)($_GET['product_id'] ?? 0);
    if ($colId <= 0 || $prodId <= 0) {
        $data = getJsonBody();
        if ($colId <= 0) $colId = (int)($data['collection_id'] ?? 0);
        if ($prodId <= 0) $prodId = (int)($data['product_id'] ?? 0);
    }
    if ($colId <= 0 || $prodId <= 0) {
        errorResponse('collection_id and product_id required', 400);
    }
    $stmt = $db->prepare("DELETE FROM collection_products WHERE collection_id = ? AND product_id = ?");
    $stmt->execute([$colId, $prodId]);
    jsonResponse(['message' => 'Product removed from collection']);
}

if ($method === 'GET') {
    $collectionId = isset($_GET['collection_id']) ? (int)$_GET['collection_id'] : 0;
    if ($collectionId <= 0 && isset($_GET['id'])) {
        $collectionId = (int)$_GET['id'];
    }
    if ($collectionId <= 0) {
        errorResponse('collection_id required', 400);
    }

    try {
        // Products explicitly linked through collection_products
        $stmt = $db->prepare("
            SELECT p.product_id AS id, p.product_id, p.product_name AS name, p.product_name,
                   p.description, p.price, p.stock_quantity, p.image_url,
                   c.category_name, b.brand_name
            FROM collection_products cp
            INNER JOIN products p ON cp.product_id = p.product_id
            LEFT JOIN categories c ON p.category_id = c.category_id
            LEFT JOIN brands b ON p.brand_id = b.brand_id
            WHERE cp.collection_id = ?
            ORDER BY cp.added_at DESC
        ");
        $stmt->execute([$collectionId]);
        $products = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Fallback: older installs may only have collection_items (name list)
        if (empty($products)) {
            $stmt = $db->prepare("
                SELECT p.product_id AS id, p.product_id, p.product_name AS name, p.product_name,
                       p.description, p.price, p.stock_quantity, p.image_url,
                       c.category_name, b.brand_name
                FROM collection_items ci
                INNER JOIN products p ON LOWER(p.product_name) = LOWER(ci.item_name)
                LEFT JOIN categories c ON p.category_id = c.category_id
                LEFT JOIN brands b ON p.brand_id = b.brand_id
                WHERE ci.collection_id = ?
                ORDER BY ci.display_order ASC
            ");
            $stmt->execute([$collectionId]);
            $products = $stmt->fetchAll(PDO::FETCH_ASSOC);
        }

        echo json_encode($products);
        exit;
    } catch (Exception $e) {
        errorResponse('Failed to load collection products: ' . $e->getMessage(), 500);
    }
}

errorResponse('Method not allowed', 405);
