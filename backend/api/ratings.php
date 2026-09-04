<?php
header('Content-Type: application/json');
require_once __DIR__ . '/bootstrap.php';
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../middleware/authmiddleware.php';

$db = db();
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

function ensure_table(PDO $db) {
  $sql = "CREATE TABLE IF NOT EXISTS product_ratings (
            product_id INT PRIMARY KEY,
            rating_avg DECIMAL(3,2) DEFAULT 0,
            review_count INT DEFAULT 0,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            CONSTRAINT fk_ratings_product FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
          ) ENGINE=InnoDB";
  $db->exec($sql);
}

switch (strtoupper($method)) {
  case 'GET':
    ensure_table($db);
    if (isset($_GET['product_id'])) {
      $pid = (int)$_GET['product_id'];
      $stmt = $db->prepare("SELECT product_id, rating_avg, review_count FROM product_ratings WHERE product_id = ?");
      $stmt->execute([$pid]);
      $row = $stmt->fetch(PDO::FETCH_ASSOC);
      echo json_encode($row ?: ['product_id' => $pid, 'rating_avg' => 0, 'review_count' => 0]);
      break;
    }
    $stmt = $db->query("SELECT product_id, rating_avg, review_count FROM product_ratings ORDER BY updated_at DESC");
    echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
    break;

  case 'POST':
  case 'PUT':
    $u = AuthMiddleware::authenticateAdmin();
    ensure_table($db);
    $data = json_decode(file_get_contents('php://input'), true);
    $pid = (int)($data['product_id'] ?? 0);
    $avg = (float)($data['rating_avg'] ?? 0);
    $count = (int)($data['review_count'] ?? 0);
    if ($pid <= 0) {
      http_response_code(400);
      echo json_encode(['message' => 'product_id required']);
      break;
    }
    if ($avg < 0 || $avg > 5) {
      http_response_code(400);
      echo json_encode(['message' => 'rating_avg must be between 0 and 5']);
      break;
    }
    if ($count < 0) $count = 0;
    $sql = "INSERT INTO product_ratings (product_id, rating_avg, review_count)
            VALUES (:pid, :avg, :cnt)
            ON DUPLICATE KEY UPDATE rating_avg = VALUES(rating_avg), review_count = VALUES(review_count)";
    $stmt = $db->prepare($sql);
    $ok = $stmt->execute([':pid' => $pid, ':avg' => $avg, ':cnt' => $count]);
    if ($ok) {
      echo json_encode(['message' => 'Rating updated', 'product_id' => $pid, 'rating_avg' => $avg, 'review_count' => $count]);
    } else {
      http_response_code(500);
      echo json_encode(['message' => 'Failed to update rating']);
    }
    break;

  default:
    http_response_code(405);
    echo json_encode(['message' => 'Method not allowed']);
}

