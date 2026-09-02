<?php
// ============================================
// CORS HEADERS FOR FLUTTER WEB
// ============================================
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Access-Control-Max-Age: 3600');
header('Content-Type: application/json');

// Handle OPTIONS preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}
header('Content-Type: application/json');
require_once __DIR__ . '/bootstrap.php';
require_once __DIR__ . '/../config/cors.php';

$db = db();
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

if ($method === 'OPTIONS') {
    http_response_code(200);
    echo json_encode(['ok' => true]);
    exit;
}

if ($method === 'GET') {
    try {
        // Get banners from database
        $stmt = $db->prepare('
            SELECT banner_type, image_url, link_url, title, description, button_text, display_order
            FROM banners
            WHERE active = TRUE
            AND (start_date IS NULL OR start_date <= CURDATE())
            AND (end_date IS NULL OR end_date >= CURDATE())
            ORDER BY banner_type, display_order
        ');
        $stmt->execute();
        $banners = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Group by banner type
        $hero = [];
        $mid = [];
        $sidebar = [];
        
        foreach ($banners as $banner) {
            $link = $banner['link_url'] ?? '';
            $sidebarConfig = [];
            if (($banner['banner_type'] ?? '') === 'sidebar' && is_string($link) && strpos($link, '{') === 0) {
                $decoded = json_decode($link, true);
                if (is_array($decoded)) {
                    $sidebarConfig = $decoded;
                    $link = $decoded['link'] ?? '';
                }
            }
            $item = [
                'image' => $banner['image_url'],
                'img' => $banner['image_url'],
                'link' => $link,
                'label' => $banner['title'],
                'title' => $banner['title'],
                'description' => $banner['description'],
                'subtitle' => $banner['description'],
                'buttonText' => $banner['button_text'],
                'source' => $sidebarConfig['source'] ?? '',
                'page' => $sidebarConfig['page'] ?? '',
                'productIds' => $sidebarConfig['productIds'] ?? []
            ];
            
            switch ($banner['banner_type']) {
                case 'hero':
                    $hero[] = $item;
                    break;
                case 'mid':
                    $mid[] = $item;
                    break;
                case 'sidebar':
                    $sidebar[] = $item;
                    break;
            }
        }
        
        // Sidebar promo is consumed as a single object in the storefront.
        $sidebarPromo = !empty($sidebar) ? $sidebar[0] : [
            'title' => 'FLASH SALE',
            'subtitle' => 'Up to 40% Off on Earbuds',
            'buttonText' => 'VIEW ALL',
            'image' => '',
            'img' => '',
            'link' => ''
        ];

        echo json_encode([
            'hero' => $hero,
            'mid' => $mid,
            'sidebar' => $sidebarPromo,
        ]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to fetch banners']);
    }
    exit;
}

if ($method === 'PUT' || $method === 'POST') {
    require_once __DIR__ . '/../middleware/authmiddleware.php';
    $admin = AuthMiddleware::authenticateAdmin();
    
    $data = json_decode(file_get_contents('php://input'), true);
    if (!is_array($data)) $data = [];
    
    try {
        // Clear existing banners if updating all
        if (isset($data['clearAll']) && $data['clearAll']) {
            $db->exec('DELETE FROM banners');
        }
        
        // Update hero banners
        if (isset($data['hero']) && is_array($data['hero'])) {
            // Delete existing hero banners
            $db->exec("DELETE FROM banners WHERE banner_type = 'hero'");
            
            // Insert new hero banners
            $stmt = $db->prepare('
                INSERT INTO banners (banner_type, image_url, link_url, title, description, button_text, display_order, active)
                VALUES (?, ?, ?, ?, ?, ?, ?, TRUE)
            ');
            
            foreach ($data['hero'] as $index => $banner) {
                $stmt->execute([
                    'hero',
                    $banner['image'] ?? $banner['img'] ?? '',
                    $banner['link'] ?? '',
                    $banner['label'] ?? $banner['title'] ?? '',
                    $banner['description'] ?? '',
                    $banner['buttonText'] ?? '',
                    $index
                ]);
            }
        }
        
        // Update mid banners
        if (isset($data['mid']) && is_array($data['mid'])) {
            // Delete existing mid banners first
            $db->exec("DELETE FROM banners WHERE banner_type = 'mid'");
            
            $stmt = $db->prepare('
                INSERT INTO banners (banner_type, image_url, link_url, title, description, button_text, display_order, active, start_date, end_date)
                VALUES (?, ?, ?, ?, ?, ?, ?, TRUE, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 YEAR))
            ');
            
            foreach ($data['mid'] as $index => $banner) {
                $imageUrl = $banner['img'] ?? $banner['image'] ?? '';
                
                // Log for debugging
                error_log("Saving mid banner $index: " . $imageUrl);
                
                $stmt->execute([
                    'mid',
                    $imageUrl,
                    $banner['link'] ?? '/deals',
                    $banner['title'] ?? 'Banner ' . ($index + 1),
                    $banner['description'] ?? '',
                    $banner['buttonText'] ?? 'Shop Now',
                    $index + 1
                ]);
            }
            
            // Log success
            error_log("Mid banners saved successfully: " . count($data['mid']) . " banners");
        }
        
        // Update sidebar promo
        if (isset($data['sidebar']) && is_array($data['sidebar'])) {
            $db->exec("DELETE FROM banners WHERE banner_type = 'sidebar'");
            
            $stmt = $db->prepare('
                INSERT INTO banners (banner_type, image_url, link_url, title, description, button_text, display_order, active)
                VALUES (?, ?, ?, ?, ?, ?, ?, TRUE)
            ');
            
            $sidebarLink = $data['sidebar']['link'] ?? '';
            $source = $data['sidebar']['source'] ?? $data['sidebar']['page'] ?? '';
            $productIds = $data['sidebar']['productIds'] ?? [];
            if (!is_array($productIds)) $productIds = [];
            if ($source !== '' || !empty($productIds)) {
                $sidebarLink = json_encode([
                    'link' => $sidebarLink,
                    'source' => $source,
                    'page' => $source,
                    'productIds' => array_values($productIds),
                ]);
            }

            $stmt->execute([
                'sidebar',
                $data['sidebar']['image'] ?? $data['sidebar']['img'] ?? '',
                $sidebarLink,
                $data['sidebar']['title'] ?? 'FLASH SALE',
                $data['sidebar']['subtitle'] ?? $data['sidebar']['description'] ?? '',
                $data['sidebar']['buttonText'] ?? 'VIEW ALL',
                0
            ]);
        }
        
        echo json_encode([
            'success' => true, 
            'message' => 'Banners updated successfully',
            'updated' => [
                'hero' => isset($data['hero']) ? count($data['hero']) : 0,
                'mid' => isset($data['mid']) ? count($data['mid']) : 0,
                'sidebar' => isset($data['sidebar']) ? 1 : 0
            ]
        ]);
    } catch (Throwable $e) {
        error_log("Banner save error: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['message' => 'Save failed: ' . $e->getMessage()]);
    }
    exit;
}

http_response_code(405);
echo json_encode(['message' => 'Method not allowed']);

