<?php
require_once __DIR__ . '/bootstrap.php';
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../middleware/authmiddleware.php';

$db = db();
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

if ($method === 'OPTIONS') { http_response_code(200); exit; }

$user = AuthMiddleware::authenticateAdmin();
$userId = (int)$user['user_id'];

switch ($method) {
    case 'GET':
        $stmt = $db->query("
            SELECT r.*, u.full_name as admin_name
            FROM reports r
            LEFT JOIN users u ON r.admin_id = u.user_id
            ORDER BY r.created_at DESC
        ");
        echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        break;
        
    case 'POST':
        $data = json_decode(file_get_contents('php://input'), true);
        $stmt = $db->prepare("
            INSERT INTO reports (admin_id, report_type, details)
            VALUES (?, ?, ?)
        ");
        $stmt->execute([
            $userId,
            $data['report_type'],
            $data['details'] ?? ''
        ]);
        echo json_encode(['message' => 'Report created', 'id' => $db->lastInsertId()]);
        break;
}
