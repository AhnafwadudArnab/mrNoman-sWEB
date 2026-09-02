<?php
require_once __DIR__ . '/bootstrap.php';

$db = db();
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

if ($method === 'OPTIONS') {
    http_response_code(200);
    exit;
}

switch ($method) {
    case 'GET':
        if (isset($_GET['product_id'])) {
            // Get reviews for a product
            $productId = (int)$_GET['product_id'];
            $stmt = $db->prepare("
                SELECT r.*, u.full_name, u.email
                FROM reviews r
                LEFT JOIN users u ON r.user_id = u.user_id
                WHERE r.product_id = ?
                ORDER BY r.created_at DESC
            ");
            $stmt->execute([$productId]);
            $reviews = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Calculate average rating
            $stmt = $db->prepare("
                SELECT AVG(rating) as avg_rating, COUNT(*) as review_count
                FROM reviews
                WHERE product_id = ?
            ");
            $stmt->execute([$productId]);
            $stats = $stmt->fetch(PDO::FETCH_ASSOC);
            
            echo json_encode([
                'reviews' => $reviews,
                'avg_rating' => round($stats['avg_rating'], 1),
                'review_count' => $stats['review_count']
            ]);
        } elseif (isset($_GET['id'])) {
            // Get single review
            $id = (int)$_GET['id'];
            $stmt = $db->prepare("
                SELECT r.*, u.full_name, u.email
                FROM reviews r
                LEFT JOIN users u ON r.user_id = u.user_id
                WHERE r.review_id = ?
            ");
            $stmt->execute([$id]);
            echo json_encode($stmt->fetch(PDO::FETCH_ASSOC));
        } else {
            // Get all reviews
            $stmt = $db->query("
                SELECT r.*, u.full_name, u.email, p.product_name
                FROM reviews r
                LEFT JOIN users u ON r.user_id = u.user_id
                LEFT JOIN products p ON r.product_id = p.product_id
                ORDER BY r.created_at DESC
            ");
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        }
        break;
        
    case 'POST':
        $data = json_decode(file_get_contents('php://input'), true);
        $userId = $data['user_id'] ?? null;
        
        $stmt = $db->prepare("
            INSERT INTO reviews (product_id, user_id, rating, review_text)
            VALUES (?, ?, ?, ?)
        ");
        $stmt->execute([
            $data['product_id'],
            $userId,
            $data['rating'],
            $data['review_text'] ?? ''
        ]);
        echo json_encode(['message' => 'Review created', 'id' => $db->lastInsertId()]);
        break;
        
    case 'PUT':
        $id = (int)$_GET['id'];
        $data = json_decode(file_get_contents('php://input'), true);
        $stmt = $db->prepare("
            UPDATE reviews 
            SET rating = ?, review_text = ?
            WHERE review_id = ?
        ");
        $stmt->execute([
            $data['rating'],
            $data['review_text'] ?? '',
            $id
        ]);
        echo json_encode(['message' => 'Review updated']);
        break;
        
    case 'DELETE':
        $id = (int)$_GET['id'];
        $stmt = $db->prepare("DELETE FROM reviews WHERE review_id = ?");
        $stmt->execute([$id]);
        echo json_encode(['message' => 'Review deleted']);
        break;
}
