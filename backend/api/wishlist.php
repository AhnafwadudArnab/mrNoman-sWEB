<?php
require_once __DIR__ . '/bootstrap.php';

$db = db();
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

if ($method === 'OPTIONS') { http_response_code(200); exit; }

$u = requireAuth();
$user_id = $u['user_id'];

switch ($method) {
    case 'GET':
        $stmt = $db->prepare("
            SELECT w.*, p.product_name, p.price, p.image_url, c.category_name
            FROM wishlists w
            LEFT JOIN products p ON w.product_id = p.product_id
            LEFT JOIN categories c ON p.category_id = c.category_id
            WHERE w.user_id = ?
            ORDER BY w.added_at DESC
        ");
        $stmt->execute([$user_id]);
        jsonResponse(['items' => $stmt->fetchAll()]);
        break;

    case 'POST':
        $data = getJsonBody();
        if (empty($data['product_id'])) errorResponse('Product ID required', 400);
        $pid = (int)$data['product_id'];

        $chk = $db->prepare("SELECT wishlist_id FROM wishlists WHERE user_id = ? AND product_id = ?");
        $chk->execute([$user_id, $pid]);
        if ($chk->rowCount() > 0) jsonResponse(['message' => 'Already in wishlist']);

        $db->prepare("INSERT INTO wishlists (user_id, product_id) VALUES (?, ?)")->execute([$user_id, $pid]);
        jsonResponse(['message' => 'Added to wishlist'], 201);
        break;

    case 'DELETE':
        if (isset($_GET['product_id'])) {
            $db->prepare("DELETE FROM wishlists WHERE user_id = ? AND product_id = ?")->execute([$user_id, (int)$_GET['product_id']]);
            jsonResponse(['message' => 'Removed from wishlist']);
        } elseif (($_GET['clear'] ?? '') === 'true') {
            $db->prepare("DELETE FROM wishlists WHERE user_id = ?")->execute([$user_id]);
            jsonResponse(['message' => 'Wishlist cleared']);
        } else {
            errorResponse('Product ID required', 400);
        }
        break;

    default:
        errorResponse('Method not allowed', 405);
}
