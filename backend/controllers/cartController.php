<?php
require_once __DIR__ . '/../models/carts.php';
require_once __DIR__ . '/../models/product.php';

class CartController {
    private $db;
    private $cart;
    
    public function __construct($db) {
        $this->db = $db;
        $this->cart = new Cart($db);
    }
    
    public function getCart($user_id) {
        $items = $this->cart->getUserCart($user_id);
        $total = $this->cart->getCartTotal($user_id);
        
        return [
            'items' => $items,
            'total' => floatval($total),
            'item_count' => count($items)
        ];
    }
    
    public function addItem($user_id, $data) {
        if (!isset($data['product_id']) || !isset($data['quantity'])) {
            http_response_code(400);
            return ['message' => 'Product ID and quantity required'];
        }
        
        // Check product stock
        $product = new Product($this->db);
        $product_data = $product->getById($data['product_id']);
        
        if (!$product_data) {
            http_response_code(404);
            return ['message' => 'Product not found'];
        }
        
        if ($product_data['stock_quantity'] < $data['quantity']) {
            http_response_code(400);
            return ['message' => 'Insufficient stock'];
        }
        
        $this->cart->user_id = $user_id;
        $this->cart->product_id = $data['product_id'];
        $this->cart->quantity = $data['quantity'];
        
        if ($this->cart->addItem()) {
            return $this->getCart($user_id);
        }
        
        http_response_code(500);
        return ['message' => 'Failed to add item to cart'];
    }
    
    public function updateQuantity($user_id, $data) {
        if (!isset($data['cart_id']) || !isset($data['quantity'])) {
            http_response_code(400);
            return ['message' => 'Cart ID and quantity required'];
        }
        
        $this->cart->cart_id = $data['cart_id'];
        $this->cart->user_id = $user_id;
        $this->cart->quantity = $data['quantity'];
        
        if ($this->cart->updateQuantity()) {
            return $this->getCart($user_id);
        }
        
        http_response_code(500);
        return ['message' => 'Failed to update cart'];
    }
    
    public function removeItem($user_id, $data) {
        if (!isset($data['cart_id'])) {
            http_response_code(400);
            return ['message' => 'Cart ID required'];
        }
        
        $this->cart->cart_id = $data['cart_id'];
        $this->cart->user_id = $user_id;
        
        if ($this->cart->removeItem()) {
            return $this->getCart($user_id);
        }
        
        http_response_code(500);
        return ['message' => 'Failed to remove item'];
    }
    
    public function clearCart($user_id) {
        if ($this->cart->clearCart($user_id)) {
            return ['message' => 'Cart cleared', 'items' => [], 'total' => 0];
        }
        
        http_response_code(500);
        return ['message' => 'Failed to clear cart'];
    }
}
?>
