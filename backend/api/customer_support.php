<?php
require_once __DIR__ . '/bootstrap.php';
require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../middleware/authmiddleware.php';

$db = db();
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

if ($method === 'OPTIONS') { http_response_code(200); exit; }

$user    = AuthMiddleware::authenticate();
$userId  = (int)$user['user_id'];
$isAdmin = strtolower($user['role'] ?? '') === 'admin';

switch ($method) {
    case 'GET':
        if (isset($_GET['admin']) && $isAdmin) {
            // Admin: Get all tickets
            $stmt = $db->query("
                SELECT cs.*, u.full_name, u.email,
                    resolver.full_name as resolved_by_name
                FROM customer_support cs
                LEFT JOIN users u ON cs.user_id = u.user_id
                LEFT JOIN users resolver ON cs.resolved_by = resolver.user_id
                ORDER BY cs.created_at DESC
            ");
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        } elseif (isset($_GET['id'])) {
            // Get single ticket
            $id = (int)$_GET['id'];
            $stmt = $db->prepare("
                SELECT cs.*, u.full_name, u.email,
                    resolver.full_name as resolved_by_name
                FROM customer_support cs
                LEFT JOIN users u ON cs.user_id = u.user_id
                LEFT JOIN users resolver ON cs.resolved_by = resolver.user_id
                WHERE cs.ticket_id = ?
            ");
            $stmt->execute([$id]);
            echo json_encode($stmt->fetch(PDO::FETCH_ASSOC));
        } else {
            // Get user's tickets
            $stmt = $db->prepare("
                SELECT * FROM customer_support 
                WHERE user_id = ?
                ORDER BY created_at DESC
            ");
            $stmt->execute([$userId]);
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        }
        break;
        
    case 'POST':
        $data = json_decode(file_get_contents('php://input'), true);
        $stmt = $db->prepare("
            INSERT INTO customer_support (user_id, subject, message, status)
            VALUES (?, ?, ?, 'open')
        ");
        $stmt->execute([
            $userId,
            $data['subject'],
            $data['message']
        ]);
        echo json_encode(['message' => 'Ticket created', 'id' => $db->lastInsertId()]);
        break;
        
    case 'PUT':
        $id = (int)$_GET['id'];
        $data = json_decode(file_get_contents('php://input'), true);
        
        $fields = [];
        $values = [];
        
        if (isset($data['status'])) {
            $fields[] = 'status = ?';
            $values[] = $data['status'];
            
            if ($data['status'] === 'resolved' || $data['status'] === 'closed') {
                $fields[] = 'resolved_by = ?';
                $fields[] = 'resolved_at = NOW()';
                $values[] = $userId;
            }
        }
        
        if (isset($data['message'])) {
            $fields[] = 'message = ?';
            $values[] = $data['message'];
        }
        
        $values[] = $id;
        
        $stmt = $db->prepare("
            UPDATE customer_support 
            SET " . implode(', ', $fields) . "
            WHERE ticket_id = ?
        ");
        $stmt->execute($values);
        echo json_encode(['message' => 'Ticket updated']);
        break;
        
    case 'DELETE':
        $id = (int)$_GET['id'];
        $stmt = $db->prepare("DELETE FROM customer_support WHERE ticket_id = ?");
        $stmt->execute([$id]);
        echo json_encode(['message' => 'Ticket deleted']);
        break;
}
