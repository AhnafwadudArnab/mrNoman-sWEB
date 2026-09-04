<?php
/**
 * Flutter API Testing Script
 * cPanel এ database check করার জন্য
 */

header('Content-Type: text/html; charset=utf-8');

// Config
$db_host = 'localhost';
$db_user = 'root'; // আপনার cPanel ইউজারনেম দিয়ে বদল করুন
$db_pass = '';     // আপনার ডাটাবেস পাসওয়ার্ড দিয়ে বদল করুন
$db_name = 'electrobd'; // আপনার ডাটাবেস নাম দিয়ে বদল করুন

?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Flutter API Test</title>
    <style>
        body { font-family: Arial; margin: 20px; }
        .success { color: green; }
        .error { color: red; }
        .warning { color: orange; }
        .container { border: 1px solid #ddd; padding: 20px; margin-bottom: 20px; }
        table { width: 100%; border-collapse: collapse; }
        td { border: 1px solid #ddd; padding: 8px; }
        th { background-color: #f0f0f0; }
    </style>
</head>
<body>

<h1>🚀 Flutter API Test Dashboard</h1>

<div class="container">
    <h2>১. Database Connection Test</h2>
    <?php
    $conn = new mysqli($db_host, $db_user, $db_pass, $db_name);
    if ($conn->connect_error) {
        echo '<p class="error">❌ ডাটাবেস সংযোগ ব্যর্থ: ' . $conn->connect_error . '</p>';
    } else {
        echo '<p class="success">✅ ডাটাবেস সংযোগ সফল!</p>';
    }
    $conn->set_charset("utf8mb4");
    ?>
</div>

<div class="container">
    <h2>२. Table Structure Check</h2>
    <table>
        <tr>
            <th>টেবিল নাম</th>
            <th>রেকর্ড সংখ্যা</th>
            <th>স্ট্যাটাস</th>
        </tr>
        <?php
        $tables = [
            'products',
            'categories',
            'brands',
            'users',
            'cart',
            'orders',
            'order_items',
            'reviews',
            'wishlist',
            'banners',
            'flash_sales',
            'best_sellers',
            'trending_products',
            'deals_of_the_day',
            'collections',
            'payment_methods'
        ];

        foreach ($tables as $table) {
            $query = "SELECT COUNT(*) as cnt FROM $table";
            $result = $conn->query($query);
            
            if ($result) {
                $row = $result->fetch_assoc();
                $count = $row['cnt'];
                $status = $count > 0 ? '<span class="success">✅ ' . $count . ' records</span>' : '<span class="warning">⚠️ 0 records</span>';
            } else {
                $status = '<span class="error">❌ Table not found</span>';
            }
            
            echo "<tr><td>$table</td><td>$count</td><td>$status</td></tr>";
        }
        ?>
    </table>
</div>

<div class="container">
    <h2>३. Sample Data Check</h2>
    
    <h3>শীর্ষ 5 পণ্য:</h3>
    <table>
        <tr>
            <th>পণ্যের নাম</th>
            <th>মূল্য</th>
            <th>স্টক</th>
        </tr>
        <?php
        $query = "SELECT product_name, price, stock_quantity FROM products LIMIT 5";
        $result = $conn->query($query);
        
        if ($result && $result->num_rows > 0) {
            while ($row = $result->fetch_assoc()) {
                echo "<tr>";
                echo "<td>" . $row['product_name'] . "</td>";
                echo "<td>৳" . $row['price'] . "</td>";
                echo "<td>" . $row['stock_quantity'] . "</td>";
                echo "</tr>";
            }
        } else {
            echo "<tr><td colspan='3' class='error'>কোনো পণ্য নেই</td></tr>";
        }
        ?>
    </table>
    
    <h3>ক্যাটেগরিগুলি:</h3>
    <table>
        <tr>
            <th>ক্যাটেগরি নাম</th>
            <th>বর্ণনা</th>
        </tr>
        <?php
        $query = "SELECT category_name, description FROM categories LIMIT 5";
        $result = $conn->query($query);
        
        if ($result && $result->num_rows > 0) {
            while ($row = $result->fetch_assoc()) {
                echo "<tr>";
                echo "<td>" . $row['category_name'] . "</td>";
                echo "<td>" . $row['description'] . "</td>";
                echo "</tr>";
            }
        } else {
            echo "<tr><td colspan='2' class='error'>কোনো ক্যাটেগরি নেই</td></tr>";
        }
        ?>
    </table>
</div>

<div class="container">
    <h2>४. API Endpoints Test</h2>
    
    <?php
    $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https://' : 'http://';
    $base_url = $protocol . $_SERVER['HTTP_HOST'] . '/backend/api';
    ?>
    
    <h3>আপনার API বেস URL:</h3>
    <code><?php echo $base_url; ?></code>
    
    <h3>উপলব্ধ এন্ডপয়েন্ট:</h3>
    <table>
        <tr>
            <th>এন্ডপয়েন্ট</th>
            <th>Method</th>
            <th>বর্ণনা</th>
        </tr>
        <tr>
            <td><?php echo $base_url; ?>/flutter_home_data.php</td>
            <td>GET</td>
            <td>Home screen data (banners, flash sales, etc.)</td>
        </tr>
        <tr>
            <td><?php echo $base_url; ?>/flutter_products.php?action=list</td>
            <td>GET</td>
            <td>সব পণ্যের তালিকা</td>
        </tr>
        <tr>
            <td><?php echo $base_url; ?>/flutter_products.php?action=details&product_id=1</td>
            <td>GET</td>
            <td>পণ্যের বিবরণ</td>
        </tr>
        <tr>
            <td><?php echo $base_url; ?>/flutter_products.php?action=search&search=blender</td>
            <td>GET</td>
            <td>পণ্য খোঁজা</td>
        </tr>
        <tr>
            <td><?php echo $base_url; ?>/flutter_cart.php?user_id=1</td>
            <td>GET</td>
            <td>কার্ট দেখুন</td>
        </tr>
        <tr>
            <td><?php echo $base_url; ?>/flutter_cart.php?user_id=1</td>
            <td>POST</td>
            <td>কার্টে যোগ করুন</td>
        </tr>
        <tr>
            <td><?php echo $base_url; ?>/flutter_orders.php?user_id=1</td>
            <td>GET</td>
            <td>ব্যবহারকারীর অর্ডার</td>
        </tr>
        <tr>
            <td><?php echo $base_url; ?>/flutter_orders.php</td>
            <td>POST</td>
            <td>নতুন অর্ডার তৈরি করুন</td>
        </tr>
    </table>
</div>

<div class="container">
    <h2>५. Live API Test</h2>
    
    <h3>Home Data API Test:</h3>
    <?php
    $curl_url = $base_url . '/flutter_home_data.php';
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $curl_url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 5);
    $response = curl_exec($ch);
    $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($http_code == 200) {
        $data = json_decode($response, true);
        if ($data['success']) {
            echo '<p class="success">✅ API সফল! ডাটা পাওয়া গেছে।</p>';
            echo '<pre>' . json_encode($data['data'], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . '</pre>';
        } else {
            echo '<p class="error">❌ API Error: ' . $data['message'] . '</p>';
        }
    } else {
        echo '<p class="error">❌ HTTP Error: ' . $http_code . '</p>';
        echo '<pre>' . $response . '</pre>';
    }
    ?>
</div>

<div class="container">
    <h2>६. Configuration Info</h2>
    <p><strong>Database Host:</strong> <?php echo $db_host; ?></p>
    <p><strong>Database Name:</strong> <?php echo $db_name; ?></p>
    <p><strong>PHP Version:</strong> <?php echo phpversion(); ?></p>
    <p><strong>MySQL Version:</strong> <?php echo $conn->server_info; ?></p>
</div>

<div class="container">
    <h2>७. Flutter curl Test Example</h2>
    <pre>
# Products API টেস্ট করুন:
curl "<?php echo $base_url; ?>/flutter_products.php?action=list&limit=5"

# Home Data টেস্ট করুন:
curl "<?php echo $base_url; ?>/flutter_home_data.php"

# Cart টেস্ট করুন (user_id=1):
curl "<?php echo $base_url; ?>/flutter_cart.php?user_id=1"

# Cart এ পণ্য যোগ করুন:
curl -X POST "<?php echo $base_url; ?>/flutter_cart.php?user_id=1" \
  -H "Content-Type: application/json" \
  -d '{"user_id": 1, "product_id": 1, "quantity": 2}'
    </pre>
</div>

</body>
</html>

<?php
$conn->close();
?>
