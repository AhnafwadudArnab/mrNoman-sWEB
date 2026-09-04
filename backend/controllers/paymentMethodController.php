<?php
require_once __DIR__ . '/../models/payment_methods.php';

class PaymentMethodController {
    private $db;
    private $paymentMethod;
    
    public function __construct($db) {
        $this->db = $db;
        $this->paymentMethod = new PaymentMethod($db);
    }
    
    public function getAll() {
        try {
            $methods = $this->paymentMethod->getAll();
            return [
                'success' => true,
                'data' => $methods
            ];
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Failed to fetch payment methods: ' . $e->getMessage()
            ];
        }
    }
    
    public function getEnabled() {
        try {
            $methods = $this->paymentMethod->getEnabled();
            return [
                'success' => true,
                'data' => $methods
            ];
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Failed to fetch enabled payment methods: ' . $e->getMessage()
            ];
        }
    }
    
    public function getById($id) {
        try {
            $method = $this->paymentMethod->getById($id);
            if ($method) {
                return [
                    'success' => true,
                    'data' => $method
                ];
            }
            return [
                'success' => false,
                'message' => 'Payment method not found'
            ];
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Failed to fetch payment method: ' . $e->getMessage()
            ];
        }
    }
    
    public function create($data) {
        try {
            $this->paymentMethod->method_name = $data['method_name'] ?? '';
            $this->paymentMethod->method_type = $data['method_type'] ?? 'mobile_banking';
            $this->paymentMethod->is_enabled = isset($data['is_enabled']) ? (int)$data['is_enabled'] : 1;
            $this->paymentMethod->account_number = $data['account_number'] ?? '';
            $this->paymentMethod->display_order = $data['display_order'] ?? 0;
            $this->paymentMethod->icon_url = $data['icon_url'] ?? '';
            
            if ($this->paymentMethod->create()) {
                return [
                    'success' => true,
                    'message' => 'Payment method created successfully',
                    'method_id' => $this->paymentMethod->method_id
                ];
            }
            return [
                'success' => false,
                'message' => 'Failed to create payment method'
            ];
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Failed to create payment method: ' . $e->getMessage()
            ];
        }
    }
    
    public function update($id, $data) {
        try {
            $this->paymentMethod->method_id = $id;
            $this->paymentMethod->method_name = $data['method_name'] ?? '';
            $this->paymentMethod->method_type = $data['method_type'] ?? 'mobile_banking';
            $this->paymentMethod->is_enabled = isset($data['is_enabled']) ? (int)$data['is_enabled'] : 1;
            $this->paymentMethod->account_number = $data['account_number'] ?? '';
            $this->paymentMethod->display_order = $data['display_order'] ?? 0;
            $this->paymentMethod->icon_url = $data['icon_url'] ?? '';
            
            if ($this->paymentMethod->update()) {
                return [
                    'success' => true,
                    'message' => 'Payment method updated successfully'
                ];
            }
            return [
                'success' => false,
                'message' => 'Failed to update payment method'
            ];
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Failed to update payment method: ' . $e->getMessage()
            ];
        }
    }
    
    public function delete($id) {
        try {
            $this->paymentMethod->method_id = $id;
            if ($this->paymentMethod->delete()) {
                return [
                    'success' => true,
                    'message' => 'Payment method deleted successfully'
                ];
            }
            return [
                'success' => false,
                'message' => 'Failed to delete payment method'
            ];
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Failed to delete payment method: ' . $e->getMessage()
            ];
        }
    }
    
    public function toggleStatus($id, $status) {
        try {
            if ($this->paymentMethod->toggleStatus($id, $status)) {
                return [
                    'success' => true,
                    'message' => 'Payment method status updated successfully'
                ];
            }
            return [
                'success' => false,
                'message' => 'Failed to update payment method status'
            ];
        } catch (Exception $e) {
            return [
                'success' => false,
                'message' => 'Failed to update status: ' . $e->getMessage()
            ];
        }
    }
}
?>
