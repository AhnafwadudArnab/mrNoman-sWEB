<?php
require_once __DIR__ . '/config/env.php';

$base_url = 'http://localhost:8000/api';

echo "=== Testing API Endpoints ===\n\n";

// Test banners endpoint
echo "1. Testing /banners endpoint\n";
echo "   URL: $base_url/banners\n";
$response = @file_get_contents("$base_url/banners.php");
if ($response === false) {
    echo "   ❌ Connection failed\n";
} else {
    $data = json_decode($response, true);
    if (is_array($data)) {
        echo "   ✅ Response valid JSON\n";
        echo "   Hero banners: " . count($data['hero'] ?? []) . "\n";
        echo "   Mid banners: " . count($data['mid'] ?? []) . "\n";
        echo "   Sidebar: " . (isset($data['sidebar']) ? '✅' : '❌') . "\n";
    } else {
        echo "   ❌ Response is not valid JSON\n";
        echo "   Response: " . substr($response, 0, 200) . "...\n";
    }
}

echo "\n2. Testing /products endpoint\n";
echo "   URL: $base_url/products\n";
$response = @file_get_contents("$base_url/products.php");
if ($response === false) {
    echo "   ❌ Connection failed\n";
} else {
    $data = json_decode($response, true);
    if (is_array($data)) {
        echo "   ✅ Response valid JSON\n";
        echo "   Total products: " . count($data) . "\n";
        if (count($data) > 0) {
            $first = $data[0];
            echo "   First product keys: " . implode(', ', array_keys($first)) . "\n";
        }
    } else {
        echo "   ❌ Response is not valid JSON\n";
        echo "   Response: " . substr($response, 0, 200) . "...\n";
    }
}

echo "\n3. Testing /flutter_home_data endpoint\n";
echo "   URL: $base_url/flutter_home_data\n";
$response = @file_get_contents("$base_url/flutter_home_data.php");
if ($response === false) {
    echo "   ❌ Connection failed\n";
} else {
    $data = json_decode($response, true);
    if (is_array($data) && isset($data['data'])) {
        echo "   ✅ Response valid JSON\n";
        $sections = $data['data'];
        foreach (['banners', 'best_sellers', 'deals_of_the_day', 'trending_products', 'categories'] as $section) {
            $count = is_array($sections[$section]) ? count($sections[$section]) : 0;
            echo "   $section: $count\n";
        }
    } else {
        echo "   ❌ Response is not valid JSON or missing 'data'\n";
        echo "   Response: " . substr($response, 0, 200) . "...\n";
    }
}

echo "\n4. Testing /deals endpoint\n";
echo "   URL: $base_url/deals\n";
$response = @file_get_contents("$base_url/deals.php");
if ($response === false) {
    echo "   ❌ Connection failed\n";
} else {
    $data = json_decode($response, true);
    if (is_array($data)) {
        echo "   ✅ Response valid JSON\n";
        echo "   Total deals: " . count($data) . "\n";
    } else {
        echo "   ❌ Response is not valid JSON\n";
        echo "   Response: " . substr($response, 0, 200) . "...\n";
    }
}

?>
