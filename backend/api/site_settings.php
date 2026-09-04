<?php
header('Content-Type: application/json');
ob_start(); // buffer PHP warnings/notices so they don't corrupt JSON
require_once __DIR__ . '/bootstrap.php';
require_once __DIR__ . '/../config/cors.php';

$db = db();
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

if ($method === 'OPTIONS') {
    http_response_code(200);
    echo json_encode(['ok' => true]);
    exit;
}

try {
    switch ($method) {
        case 'GET':
            if (isset($_GET['key'])) {
                $key = $_GET['key'];
                $stmt = $db->prepare("SELECT * FROM site_settings WHERE setting_key = ?");
                $stmt->execute([$key]);
                $result = $stmt->fetch(PDO::FETCH_ASSOC);
                
                if ($result) {
                    // Ensure we return proper data structure
                    echo json_encode([
                        'id' => $result['id'] ?? null,
                        'setting_key' => $result['setting_key'] ?? $key,
                        'setting_value' => $result['setting_value'] ?? null,
                        'created_at' => $result['created_at'] ?? null,
                        'updated_at' => $result['updated_at'] ?? null,
                    ]);
                } else {
                    // Return structure with null value if not found
                    echo json_encode([
                        'setting_key' => $key,
                        'setting_value' => null
                    ]);
                }
            } else {
                $stmt = $db->query("SELECT * FROM site_settings");
                echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
            }
            break;
            
        case 'POST':
        case 'PUT':
            $data = json_decode(file_get_contents('php://input'), true);
            
            if (!isset($data['setting_key']) || !isset($data['setting_value'])) {
                http_response_code(400);
                echo json_encode(['error' => 'Missing setting_key or setting_value']);
                exit;
            }
            
            // Check if table exists, create if not
            $db->exec("CREATE TABLE IF NOT EXISTS site_settings (
                id INT AUTO_INCREMENT PRIMARY KEY,
                setting_key VARCHAR(100) UNIQUE NOT NULL,
                setting_value TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
            
            $stmt = $db->prepare("
                INSERT INTO site_settings (setting_key, setting_value)
                VALUES (?, ?)
                ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value), updated_at = CURRENT_TIMESTAMP
            ");
            $stmt->execute([
                $data['setting_key'],
                $data['setting_value']
            ]);
            
            echo json_encode([
                'success' => true,
                'message' => 'Setting saved',
                'setting_key' => $data['setting_key']
            ]);
            break;
            
        default:
            http_response_code(405);
            echo json_encode(['error' => 'Method not allowed']);
            break;
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Server error',
        'message' => $e->getMessage()
    ]);
}
