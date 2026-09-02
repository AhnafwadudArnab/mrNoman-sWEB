<?php
require_once __DIR__ . '/api/bootstrap.php';

echo "Testing flutter_home_data endpoint...\n\n";

try {
    $db = db();
    echo "✅ Database connected\n\n";
    
    // Test individual functions
    echo "Testing getBanners...\n";
    require_once __DIR__ . '/api/flutter_home_data.php';
    $banners = getBanners($db);
    echo "  Result: " . count($banners) . " banners\n";
    
} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n";
    echo "File: " . $e->getFile() . "\n";
    echo "Line: " . $e->getLine() . "\n";
    echo "Trace: " . $e->getTraceAsString() . "\n";
}
?>
