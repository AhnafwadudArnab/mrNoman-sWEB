<?php
require 'api/bootstrap.php';

echo "=== Creating Missing Tables ===\n\n";

try {
    $pdo = db();
    
    // Create product_ratings table
    echo "Creating product_ratings table...\n";
    $pdo->exec("
    CREATE TABLE IF NOT EXISTS `product_ratings` (
      `rating_id` int(11) NOT NULL AUTO_INCREMENT,
      `product_id` int(11) NOT NULL,
      `rating_avg` decimal(3,2) DEFAULT 0.00,
      `review_count` int(11) DEFAULT 0,
      `rating_1_star` int(11) DEFAULT 0,
      `rating_2_star` int(11) DEFAULT 0,
      `rating_3_star` int(11) DEFAULT 0,
      `rating_4_star` int(11) DEFAULT 0,
      `rating_5_star` int(11) DEFAULT 0,
      `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
      `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
      PRIMARY KEY (`rating_id`),
      UNIQUE KEY `unique_product_rating` (`product_id`),
      CONSTRAINT `product_ratings_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ");
    echo "✓ product_ratings created\n\n";
    
    // Create product_reviews table if missing
    echo "Creating product_reviews table...\n";
    $pdo->exec("
    CREATE TABLE IF NOT EXISTS `product_reviews` (
      `review_id` int(11) NOT NULL AUTO_INCREMENT,
      `product_id` int(11) NOT NULL,
      `user_id` int(11) NOT NULL,
      `rating` int(11) NOT NULL CHECK (`rating` BETWEEN 1 AND 5),
      `review_text` text DEFAULT NULL,
      `review_title` varchar(255) DEFAULT NULL,
      `is_verified_purchase` tinyint(1) DEFAULT 0,
      `helpful_count` int(11) DEFAULT 0,
      `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
      `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
      PRIMARY KEY (`review_id`),
      KEY `idx_product_id` (`product_id`),
      KEY `idx_user_id` (`user_id`),
      KEY `idx_rating` (`rating`),
      KEY `idx_created_at` (`created_at`),
      CONSTRAINT `product_reviews_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE,
      CONSTRAINT `product_reviews_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ");
    echo "✓ product_reviews created\n\n";
    
    // Create product_specifications table if missing
    echo "Creating product_specifications table...\n";
    $pdo->exec("
    CREATE TABLE IF NOT EXISTS `product_specifications` (
      `spec_id` int(11) NOT NULL AUTO_INCREMENT,
      `product_id` int(11) NOT NULL,
      `spec_key` varchar(100) NOT NULL,
      `spec_value` text NOT NULL,
      `display_order` int(11) DEFAULT 0,
      PRIMARY KEY (`spec_id`),
      KEY `idx_product_specs` (`product_id`),
      CONSTRAINT `product_specifications_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ");
    echo "✓ product_specifications created\n\n";
    
    // Create reviews table if missing
    echo "Creating reviews table...\n";
    $pdo->exec("
    CREATE TABLE IF NOT EXISTS `reviews` (
      `review_id` int(11) NOT NULL AUTO_INCREMENT,
      `product_id` int(11) NOT NULL,
      `user_id` int(11) DEFAULT NULL,
      `rating` int(11) DEFAULT NULL CHECK (`rating` BETWEEN 1 AND 5),
      `review_text` text DEFAULT NULL,
      `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
      PRIMARY KEY (`review_id`),
      KEY `idx_reviews_product` (`product_id`),
      KEY `idx_reviews_user` (`user_id`),
      CONSTRAINT `reviews_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE,
      CONSTRAINT `reviews_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ");
    echo "✓ reviews created\n\n";
    
    // Create search_suggestions table if missing
    echo "Creating search_suggestions table...\n";
    $pdo->exec("
    CREATE TABLE IF NOT EXISTS `search_suggestions` (
      `suggestion_id` int(11) NOT NULL AUTO_INCREMENT,
      `suggestion_text` varchar(255) NOT NULL,
      `suggestion_type` enum('product','category','brand','keyword') DEFAULT 'keyword',
      `search_count` int(11) DEFAULT 0,
      `last_searched` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
      `is_active` tinyint(1) DEFAULT 1,
      `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
      PRIMARY KEY (`suggestion_id`),
      UNIQUE KEY `suggestion_text` (`suggestion_text`),
      KEY `idx_suggestion_text` (`suggestion_text`),
      KEY `idx_search_count` (`search_count`),
      KEY `idx_type` (`suggestion_type`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ");
    echo "✓ search_suggestions created\n\n";
    
    // Create search_history table if missing
    echo "Creating search_history table...\n";
    $pdo->exec("
    CREATE TABLE IF NOT EXISTS `search_history` (
      `search_id` int(11) NOT NULL AUTO_INCREMENT,
      `user_id` int(11) DEFAULT NULL,
      `search_query` varchar(255) NOT NULL,
      `results_count` int(11) DEFAULT 0,
      `searched_at` timestamp NOT NULL DEFAULT current_timestamp(),
      PRIMARY KEY (`search_id`),
      KEY `idx_search_query` (`search_query`),
      KEY `idx_searched_at` (`searched_at`),
      KEY `idx_user_query` (`user_id`,`search_query`),
      CONSTRAINT `search_history_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ");
    echo "✓ search_history created\n\n";
    
    // Create search_analytics table if missing
    echo "Creating search_analytics table...\n";
    $pdo->exec("
    CREATE TABLE IF NOT EXISTS `search_analytics` (
      `analytics_id` int(11) NOT NULL AUTO_INCREMENT,
      `date` date NOT NULL,
      `search_query` varchar(255) NOT NULL,
      `total_searches` int(11) DEFAULT 0,
      `unique_users` int(11) DEFAULT 0,
      `avg_results` int(11) DEFAULT 0,
      `zero_results_count` int(11) DEFAULT 0,
      `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
      `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
      PRIMARY KEY (`analytics_id`),
      UNIQUE KEY `unique_date_query` (`date`,`search_query`),
      KEY `idx_date` (`date`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ");
    echo "✓ search_analytics created\n\n";
    
    // Create rate_limits table if missing
    echo "Creating rate_limits table...\n";
    $pdo->exec("
    CREATE TABLE IF NOT EXISTS `rate_limits` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `ip_address` varchar(45) NOT NULL,
      `endpoint` varchar(255) NOT NULL,
      `request_count` int(11) DEFAULT 1,
      `window_start` timestamp NOT NULL DEFAULT current_timestamp(),
      `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
      PRIMARY KEY (`id`),
      KEY `idx_ip_endpoint` (`ip_address`,`endpoint`),
      KEY `idx_window` (`window_start`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ");
    echo "✓ rate_limits created\n\n";
    
    echo "✓✓✓ All missing tables created! ✓✓✓\n";
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
    exit(1);
}
?>
