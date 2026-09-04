<?php
require_once __DIR__ . '/bootstrap.php';

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
if ($method === 'OPTIONS') { http_response_code(200); exit; }

$u = requireAuth();

switch ($method) {
    case 'GET':
        // notifications table may not exist yet
        try {
            $stmt = db()->prepare('SELECT * FROM notifications WHERE (user_id = ? OR user_id IS NULL) ORDER BY created_at DESC LIMIT 50');
            $stmt->execute([$u['user_id']]);
            jsonResponse(['notifications' => $stmt->fetchAll()]);
        } catch (Throwable $e) {
            jsonResponse(['notifications' => []]);
        }
        break;

    case 'POST':
        requireAdmin();
        $data = getJsonBody();
        if (empty($data['title']) || empty($data['message'])) errorResponse('Title and message required', 400);
        try {
            $stmt = db()->prepare('INSERT INTO notifications (user_id, type, title, message, related_id, created_at) VALUES (?, ?, ?, ?, ?, NOW())');
            $stmt->execute([$data['user_id'] ?? null, $data['type'] ?? 'general', $data['title'], $data['message'], $data['related_id'] ?? null]);
            jsonResponse(['message' => 'Notification created', 'notification_id' => db()->lastInsertId()]);
        } catch (Throwable $e) {
            errorResponse('Notifications not available', 503);
        }
        break;

    case 'PUT':
        $id = (int)($_GET['id'] ?? 0);
        if (!$id) errorResponse('Notification ID required', 400);
        try {
            db()->prepare('UPDATE notifications SET is_read=1, read_at=NOW() WHERE notification_id=? AND (user_id=? OR user_id IS NULL)')->execute([$id, $u['user_id']]);
            jsonResponse(['message' => 'Notification marked as read']);
        } catch (Throwable $e) {
            errorResponse('Notifications not available', 503);
        }
        break;

    case 'DELETE':
        $id = (int)($_GET['id'] ?? 0);
        if (!$id) errorResponse('Notification ID required', 400);
        try {
            if ($u['role'] === 'admin') {
                db()->prepare('DELETE FROM notifications WHERE notification_id=?')->execute([$id]);
            } else {
                db()->prepare('DELETE FROM notifications WHERE notification_id=? AND user_id=?')->execute([$id, $u['user_id']]);
            }
            jsonResponse(['message' => 'Notification deleted']);
        } catch (Throwable $e) {
            errorResponse('Notifications not available', 503);
        }
        break;

    default:
        errorResponse('Method not allowed', 405);
}
