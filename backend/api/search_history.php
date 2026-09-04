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
        if (isset($_GET['popular'])) {
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
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        } else {
            $stmt = $db->query("
                SELECT * FROM search_history
                ORDER BY searched_at DESC
                LIMIT 100
            ");
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        }
        break;
}
