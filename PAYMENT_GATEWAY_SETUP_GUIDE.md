# ElectroZoneBD - Payment Gateway Integration Guide

## 📋 Current Payment Status

### ✅ What's Already Configured

1. **Payment Method Management (Backend Ready)**
   - PaymentMethodController for CRUD operations
   - PaymentMethod model with database integration
   - API endpoints for payment methods
   - Admin panel to manage payment methods

2. **Order Payment Integration**
   - Orders store `payment_method` field
   - Orders store `transaction_id` for tracking
   - Orders store `payment_status` field
   - Payment event logging

3. **Database Schema**
   - `payment_methods` table (created)
   - `orders.payment_method` field
   - `orders.transaction_id` field
   - `orders.payment_status` field

### ❌ What Needs Implementation

1. **Payment Gateway APIs** (Not Yet Integrated)
   - bKash API integration incomplete
   - Nagad API integration incomplete
   - SSLCommerz integration incomplete

2. **Payment Processing**
   - Transaction processing logic
   - Payment verification webhook handlers
   - Refund logic

3. **Frontend Integration**
   - Flutter payment screen UI (prepared but not wired)
   - Payment redirect logic

---

## 🔧 Task 12: Payment Gateway Status Check

### Current Setup Status

**Payment Methods in Database:**
```
1. bKash (Mobile Banking)
2. Nagad (Mobile Banking)
3. Credit Card (via SSLCommerz)
4. Debit Card (via SSLCommerz)
5. Bank Transfer
```

**Configuration Location:** `backend/.env`

```env
# Payment Gateway Configs (Prepared but not active)
BKASH_APP_KEY=your_app_key
BKASH_APP_SECRET=your_app_secret
BKASH_USERNAME=your_username
BKASH_PASSWORD=your_password
BKASH_SANDBOX_URL=https://checkout.sandbox.bkash.com
BKASH_PRODUCTION_URL=https://checkout.bkash.com

NAGAD_MERCHANT_ID=your_merchant_id
NAGAD_MERCHANT_KEY=your_merchant_key
NAGAD_SANDBOX_URL=https://api.sandbox.nagad.com.bd
NAGAD_PRODUCTION_URL=https://api.nagad.com.bd

SSLCOMMERZ_STORE_ID=your_store_id
SSLCOMMERZ_STORE_PASSWORD=your_store_password
SSLCOMMERZ_SANDBOX_URL=https://sandbox.sslcommerz.com
SSLCOMMERZ_PRODUCTION_URL=https://api.sslcommerz.com
```

---

## 🚀 Payment Gateway Integration Steps

### Option 1: bKash Integration

#### Step 1: Get bKash Credentials

1. Go to: https://developer.bkash.com
2. Sign up or login
3. Create app
4. Get credentials:
   - App Key
   - App Secret
   - Username
   - Password

#### Step 2: Update .env

On cPanel, edit `.env`:
```env
BKASH_APP_KEY=your_key_here
BKASH_APP_SECRET=your_secret_here
BKASH_USERNAME=your_username
BKASH_PASSWORD=your_password
```

#### Step 3: Create Payment Controller

Create file: `backend/controllers/bkashPaymentController.php`

```php
<?php
class BkashPaymentController {
    private $appKey;
    private $appSecret;
    private $username;
    private $password;
    private $baseUrl;
    
    public function __construct() {
        $this->appKey = getenv('BKASH_APP_KEY');
        $this->appSecret = getenv('BKASH_APP_SECRET');
        $this->username = getenv('BKASH_USERNAME');
        $this->password = getenv('BKASH_PASSWORD');
        $this->baseUrl = getenv('APP_ENV') == 'production' 
            ? getenv('BKASH_PRODUCTION_URL')
            : getenv('BKASH_SANDBOX_URL');
    }
    
    public function createPayment($orderId, $amount, $returnUrl) {
        // 1. Get token
        $token = $this->getToken();
        
        // 2. Create payment
        $payload = [
            'mode' => '0011',
            'payerReference' => 'order_' . $orderId,
            'callbackURL' => $returnUrl,
            'amount' => $amount,
            'currency' => 'BDT',
            'intent' => 'sale',
            'merchantInvoiceNumber' => 'INV_' . $orderId
        ];
        
        $response = $this->makeRequest(
            '/payment/request',
            'POST',
            $payload,
            $token
        );
        
        return $response;
    }
    
    public function executePayment($paymentID, $payerID) {
        $token = $this->getToken();
        
        $payload = [
            'paymentID' => $paymentID,
            'payerID' => $payerID
        ];
        
        $response = $this->makeRequest(
            '/payment/execute',
            'POST',
            $payload,
            $token
        );
        
        return $response;
    }
    
    private function getToken() {
        $auth = base64_encode(
            $this->username . ':' . $this->password
        );
        
        $headers = [
            'Content-Type: application/json',
            'Authorization: Basic ' . $auth
        ];
        
        $curl = curl_init();
        curl_setopt_array($curl, [
            CURLOPT_URL => $this->baseUrl . '/oauth/token',
            CURLOPT_HTTPHEADER => $headers,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => json_encode([
                'app_key' => $this->appKey,
                'app_secret' => $this->appSecret
            ])
        ]);
        
        $response = curl_exec($curl);
        curl_close($curl);
        
        $data = json_decode($response, true);
        return $data['id_token'] ?? null;
    }
    
    private function makeRequest($endpoint, $method, $payload, $token) {
        $headers = [
            'Content-Type: application/json',
            'Authorization: Bearer ' . $token,
            'X-APP-Key: ' . $this->appKey
        ];
        
        $curl = curl_init();
        curl_setopt_array($curl, [
            CURLOPT_URL => $this->baseUrl . $endpoint,
            CURLOPT_HTTPHEADER => $headers,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_CUSTOMREQUEST => $method,
            CURLOPT_POSTFIELDS => json_encode($payload)
        ]);
        
        $response = curl_exec($curl);
        $httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
        curl_close($curl);
        
        return [
            'status_code' => $httpCode,
            'data' => json_decode($response, true)
        ];
    }
}
```

#### Step 4: Create API Endpoint

In `backend/public/index.php`, add route:

```php
// Payment routes
$_GET['action'] === 'create' => BkashPaymentController->createPayment()
$_GET['action'] === 'execute' => BkashPaymentController->executePayment()
```

#### Step 5: Update Order Controller

When creating order, call bKash:

```php
if ($paymentMethod == 'bkash') {
    $bkash = new BkashPaymentController();
    $paymentResponse = $bkash->createPayment(
        $orderId,
        $total,
        'https://electrozonebd.com/api/payment/callback'
    );
    
    return [
        'success' => true,
        'payment_url' => $paymentResponse['data']['bkashURL'],
        'order_id' => $orderId
    ];
}
```

---

### Option 2: SSLCommerz Integration (Recommended for Credit Cards)

#### Step 1: Get SSLCommerz Credentials

1. Go to: https://www.sslcommerz.com
2. Create merchant account
3. Get credentials:
   - Store ID
   - Store Password

#### Step 2: Add to .env

```env
SSLCOMMERZ_STORE_ID=your_store_id
SSLCOMMERZ_STORE_PASSWORD=your_password
```

#### Step 3: Create SSLCommerz Controller

```php
<?php
class SslcommerzPaymentController {
    private $storeId;
    private $storePassword;
    private $apiUrl;
    
    public function __construct() {
        $this->storeId = getenv('SSLCOMMERZ_STORE_ID');
        $this->storePassword = getenv('SSLCOMMERZ_STORE_PASSWORD');
        $this->apiUrl = getenv('APP_ENV') == 'production'
            ? 'https://api.sslcommerz.com/gwprocess/v4/api.php'
            : 'https://sandbox.sslcommerz.com/gwprocess/v4/api.php';
    }
    
    public function initializePayment($order) {
        $postData = [
            'store_id' => $this->storeId,
            'store_passwd' => $this->storePassword,
            'total_amount' => $order['total_amount'],
            'currency' => 'BDT',
            'tran_id' => 'order_' . $order['order_id'],
            'success_url' => 'https://electrozonebd.com/api/payment/success',
            'fail_url' => 'https://electrozonebd.com/api/payment/fail',
            'cancel_url' => 'https://electrozonebd.com/api/payment/cancel',
            'ipn_url' => 'https://electrozonebd.com/api/payment/ipn',
            'cus_name' => $order['customer_name'],
            'cus_email' => $order['customer_email'],
            'cus_phone' => $order['customer_phone'],
            'cus_add1' => $order['delivery_address']
        ];
        
        $response = $this->makeRequest($postData);
        return $response;
    }
    
    public function validatePayment($tranId) {
        $postData = [
            'store_id' => $this->storeId,
            'store_passwd' => $this->storePassword,
            'tran_id' => $tranId
        ];
        
        $response = $this->makeRequest($postData, 'api/queryTransaction');
        return $response;
    }
    
    private function makeRequest($postData, $endpoint = 'gwprocess/v4/api.php') {
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $this->apiUrl);
        curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($postData));
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        
        $response = curl_exec($ch);
        curl_close($ch);
        
        return json_decode($response, true);
    }
}
```

---

## 🧪 Testing Payment Flow

### Without Payment Gateway (Current State)

Orders are created with payment_method stored, but no actual payment processing:

```
1. User selects payment method
2. Order created with payment_method field
3. Payment status = "pending"
4. No actual transaction occurs
5. Manual admin verification needed
```

### With Payment Gateway (After Integration)

```
1. User selects payment method
2. API redirects to payment gateway
3. User completes payment on gateway
4. Webhook callback received
5. Order payment_status updated to "paid"
6. Order processing begins
```

---

## 📋 Current Payment Methods Available

You can configure these methods in cPanel admin panel:

1. **bKash**
   - Mobile banking
   - Needs API integration

2. **Nagad**
   - Mobile banking
   - Needs API integration

3. **Credit Card** (via SSLCommerz)
   - Visa, Mastercard
   - Recommended - easier to integrate

4. **Debit Card**
   - Via SSLCommerz
   - Same as credit card flow

5. **Bank Transfer**
   - Manual method
   - No integration needed
   - Requires admin approval

---

## 🎯 Next Steps for Payment Integration

### Priority 1: Set Up SSLCommerz (Easiest)
1. Create SSLCommerz merchant account
2. Get Store ID and Password
3. Update .env on cPanel
4. Create SslcommerzPaymentController
5. Add payment endpoint in API
6. Test with sandbox

### Priority 2: Set Up bKash (Popular in BD)
1. Create bKash developer account
2. Get API credentials
3. Update .env on cPanel
4. Create BkashPaymentController
5. Add payment endpoint
6. Test with sandbox

### Priority 3: Manual Payment (Quick Solution)
- Keep orders in "pending" status
- Admin manually verifies payment
- Admin updates order status in dashboard
- No integration needed
- Good for initial launch

---

## 🔐 Security Considerations

When implementing payment gateways:

1. **Never commit credentials to Git**
   - Keep API keys in .env only
   - Add .env to .gitignore

2. **Use HTTPS for all payment URLs**
   - Already configured on cPanel

3. **Validate all webhook callbacks**
   - Verify signature from payment gateway
   - Check transaction status before updating order

4. **Store transaction IDs**
   - For refund purposes
   - For audit trail
   - Already prepared in orders table

5. **Log all payment events**
   - Use Logger::logPayment()
   - Track failed transactions
   - Monitor for fraud

---

## 📊 Recommended Strategy for Launch

### Phase 1: Manual Payment (Week 1-2)
- Orders created in "pending" status
- Admin dashboard shows pending orders
- Admin manually verifies payment
- Admin updates status to "confirmed"
- Works for small volume

### Phase 2: Easy Payment (Week 3-4)
- Add SSLCommerz integration
- Support Credit/Debit cards
- Automated payment verification
- Better UX for customers

### Phase 3: Full Integration (Month 2)
- Add bKash integration
- Add Nagad integration
- Multiple payment options
- Better conversion rate

---

## ✅ Current Status

**Payment System Status:** ⚠️ Partial (Ready for Manual Processing)

- [x] Database schema ready
- [x] Order payment fields ready
- [x] Payment method management ready
- [x] Admin UI prepared
- [x] Email notifications prepared
- [ ] bKash gateway integration
- [ ] Nagad gateway integration
- [ ] SSLCommerz gateway integration
- [ ] Webhook handlers
- [ ] Refund logic

---

## 🎯 Task 12 Complete

✅ Payment gateway infrastructure is ready
✅ Backend prepared for integration
❌ Live payment processing not yet implemented

**Recommendation:** For initial launch, use manual payment verification. Integrate payment gateways after basic functionality is tested.

Next: Task 13 - Complete end-to-end flow testing

