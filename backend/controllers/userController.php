<?php
require_once __DIR__ . '/../models/user.php';
require_once __DIR__ . '/../models/wishlist.php';

class UserController {
    private $db;
    private $user;
    
    public function __construct($db) {
        $this->db = $db;
        $this->user = new User($db);
    }
    
    public function getProfile($user_id) {
        $profile = $this->user->getById($user_id);
        
        if (!$profile) {
            http_response_code(404);
            return ['message' => 'User not found'];
        }
        
        unset($profile['password']);
        return $profile;
    }
    
    public function updateProfile($user_id, $data) {
        $this->user->user_id = $user_id;
        $this->user->full_name = $data['full_name'] ?? '';
        $this->user->last_name = $data['last_name'] ?? '';
        $this->user->phone_number = $data['phone_number'] ?? '';
        $this->user->address = $data['address'] ?? '';
        $this->user->gender = $data['gender'] ?? 'Male';
        
        if ($this->user->update()) {
            return $this->getProfile($user_id);
        }
        
        http_response_code(500);
        return ['message' => 'Failed to update profile'];
    }
    
    public function getWishlist($user_id) {
        $wishlist = new Wishlist($this->db);
        return $wishlist->getUserWishlist($user_id);
    }
    
    public function addToWishlist($user_id, $data) {
        if (!isset($data['product_id'])) {
            http_response_code(400);
            return ['message' => 'Product ID required'];
        }
        
        $wishlist = new Wishlist($this->db);
        $wishlist->user_id = $user_id;
        $wishlist->product_id = $data['product_id'];
        
        if ($wishlist->addItem()) {
            return $this->getWishlist($user_id);
        }
        
        http_response_code(500);
        return ['message' => 'Failed to add to wishlist'];
    }
    
    public function removeFromWishlist($user_id, $data) {
        if (!isset($data['product_id'])) {
            http_response_code(400);
            return ['message' => 'Product ID required'];
        }
        
        $wishlist = new Wishlist($this->db);
        $wishlist->user_id = $user_id;
        $wishlist->product_id = $data['product_id'];
        
        if ($wishlist->removeItem()) {
            return $this->getWishlist($user_id);
        }
        
        http_response_code(500);
        return ['message' => 'Failed to remove from wishlist'];
    }
    
    public function checkWishlist($user_id, $product_id) {
        $wishlist = new Wishlist($this->db);
        return ['in_wishlist' => $wishlist->isInWishlist($user_id, $product_id)];
    }
}
?>
