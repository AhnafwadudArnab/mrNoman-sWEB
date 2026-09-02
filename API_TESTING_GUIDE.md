# ElectroZoneBD Backend - API Endpoint Testing Guide

## 📋 Overview

This guide provides step-by-step instructions to test all API endpoints after deployment to cPanel.

**Base URL:** `https://electrozonebd.com/api`

---

## 🛠️ Testing Tools

Choose one:

### Option 1: Postman (Recommended)
- Download: https://www.postman.com/downloads/
- Import API collection (create manually or use curl)
- Test all endpoints with UI

### Option 2: cURL (Command Line)
```bash
# Test endpoint:
curl -X GET "https://electrozonebd.com/api/health"
```

### Option 3: Browser
- Simple GET requests only
- Open URL directly: `https://electrozonebd.com/api/products`

### Option 4: VS Code REST Client Extension
- Install: "REST Client" by Huachao Mao
- Create `.http` file with requests
- Click "Send Request"

---

## ✅ Test 1: API Health Check

**Endpoint:** `GET /health`

**URL:** `https://electrozonebd.com/api/health`

**Expected Response (200 OK):**
```json
{
  "status": "ok",
  "message": "API is running"
}
```

**cURL Command:**
```bash
curl -X GET "https://electrozonebd.com/api/health"
```

**What this tests:**
- ✅ API server is running
- ✅ .htaccess routing works
- ✅ PHP is executing correctly

---

## ✅ Test 2: Get All Products

**Endpoint:** `GET /products`

**URL:** `https://electrozonebd.com/api/products`

**Query Parameters (Optional):**
```
?limit=10&offset=0    # Pagination
?category=1           # Filter by category
?search=phone         # Search products
?sort=price_asc       # Sort by price
```

**Expected Response (200 OK):**
```json
[
  {
    "product_id": 1,
    "product_name": "Samsung TV 43 inch",
    "description": "HD Smart TV",
    "price": 25999,
    "stock_quantity": 50,
    "image_url": "assets/prod/samsung-tv.jpg",
    "category_id": 1,
    "brand_id": 3,
    "created_at": "2024-01-01T10:00:00Z"
  },
  {
    "product_id": 2,
    "product_name": "Philips LED Bulb",
    ...
  }
]
```

**cURL Command:**
```bash
curl -X GET "https://electrozonebd.com/api/products?limit=5"
```

**What this tests:**
- ✅ Database connection
- ✅ Product query works
- ✅ JSON serialization
- ✅ Pagination

---

## ✅ Test 3: Get Single Product

**Endpoint:** `GET /products/{id}`

**URL:** `https://electrozonebd.com/api/products/1`

**Expected Response (200 OK):**
```json
{
  "product_id": 1,
  "product_name": "Samsung TV 43 inch",
  "description": "4K Ultra HD Smart TV with built-in WiFi",
  "price": 25999,
  "stock_quantity": 50,
  "image_url": "assets/prod/samsung-tv.jpg",
  "category_id": 1,
  "category_name": "Television",
  "brand_id": 3,
  "brand_name": "Samsung",
  "rating": 4.5,
  "reviews_count": 12,
  "created_at": "2024-01-01T10:00:00Z",
  "specifications": {
    "screen_size": "43 inch",
    "resolution": "4K",
    "refresh_rate": "60Hz"
  }
}
```

**cURL Command:**
```bash
curl -X GET "https://electrozonebd.com/api/products/1"
```

**What this tests:**
- ✅ Single product retrieval
- ✅ Related data (category, brand)
- ✅ Specifications JSON parsing

---

## ✅ Test 4: Get Categories

**Endpoint:** `GET /categories`

**URL:** `https://electrozonebd.com/api/categories`

**Expected Response (200 OK):**
```json
[
  {
    "category_id": 1,
    "category_name": "Television",
    "description": "TVs and displays"
  },
  {
    "category_id": 2,
    "category_name": "Mobile Phones",
    "description": "Smartphones and accessories"
  },
  ...
]
```

**cURL Command:**
```bash
curl -X GET "https://electrozonebd.com/api/categories"
```

---

## ✅ Test 5: User Registration

**Endpoint:** `POST /auth/register`

**URL:** `https://electrozonebd.com/api/auth/register`

**Request Body (JSON):**
```json
{
  "first_name": "Test",
  "last_name": "User",
  "email": "testuser@example.com",
  "password": "SecurePass123!",
  "phone": "01700000001",
  "gender": "Male"
}
```

**Expected Response (201 Created):**
```json
{
  "success": true,
  "message": "User registered successfully",
  "user_id": 5,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**cURL Command:**
```bash
curl -X POST "https://electrozonebd.com/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "Test",
    "last_name": "User",
    "email": "testuser@example.com",
    "password": "SecurePass123!",
    "phone": "01700000001",
    "gender": "Male"
  }'
```

**What this tests:**
- ✅ User registration works
- ✅ Password hashing
- ✅ JWT token generation

---

## ✅ Test 6: User Login

**Endpoint:** `POST /auth/login`

**URL:** `https://electrozonebd.com/api/auth/login`

**Request Body (JSON):**
```json
{
  "email": "adminNoman@electrozonebd.com",
  "password": "ElectroAdmin@2026"
}
```

**Expected Response (200 OK):**
```json
{
  "success": true,
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "user_id": 1,
    "first_name": "Admin",
    "last_name": "ElectroZone",
    "email": "adminNoman@electrozonebd.com",
    "role": "admin",
    "phone": "01700000001"
  }
}
```

**cURL Command:**
```bash
curl -X POST "https://electrozonebd.com/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "adminNoman@electrozonebd.com",
    "password": "ElectroAdmin@2026"
  }'
```

**What this tests:**
- ✅ User authentication works
- ✅ JWT token generation
- ✅ Password verification
- ✅ Admin role recognition

---

## ✅ Test 7: Add to Cart

**Endpoint:** `POST /cart`

**URL:** `https://electrozonebd.com/api/cart`

**Headers Required:**
```
Authorization: Bearer {JWT_TOKEN}
Content-Type: application/json
```

**Request Body:**
```json
{
  "product_id": 1,
  "quantity": 2
}
```

**Expected Response (201 Created):**
```json
{
  "success": true,
  "message": "Product added to cart",
  "cart_id": 10,
  "product_id": 1,
  "quantity": 2,
  "total_price": 51998
}
```

**cURL Command:**
```bash
curl -X POST "https://electrozonebd.com/api/cart" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "product_id": 1,
    "quantity": 2
  }'
```

**What this tests:**
- ✅ JWT authentication
- ✅ Authorization header handling
- ✅ Cart creation
- ✅ Database write operations

---

## ✅ Test 8: Get User Cart

**Endpoint:** `GET /cart`

**URL:** `https://electrozonebd.com/api/cart`

**Headers Required:**
```
Authorization: Bearer {JWT_TOKEN}
```

**Expected Response (200 OK):**
```json
{
  "success": true,
  "cart_items": [
    {
      "cart_id": 10,
      "product_id": 1,
      "product_name": "Samsung TV",
      "price": 25999,
      "quantity": 2,
      "subtotal": 51998,
      "image_url": "assets/prod/samsung-tv.jpg"
    }
  ],
  "total_items": 1,
  "total_amount": 51998
}
```

**cURL Command:**
```bash
curl -X GET "https://electrozonebd.com/api/cart" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## ✅ Test 9: Create Order

**Endpoint:** `POST /orders`

**URL:** `https://electrozonebd.com/api/orders`

**Headers Required:**
```
Authorization: Bearer {JWT_TOKEN}
Content-Type: application/json
```

**Request Body:**
```json
{
  "delivery_address": "123 Main St, Dhaka",
  "phone": "01700000001",
  "payment_method": "bkash",
  "coupon_code": "SAVE10"
}
```

**Expected Response (201 Created):**
```json
{
  "success": true,
  "message": "Order created successfully",
  "order_id": 5,
  "order_total": 46798.2,
  "items_count": 1,
  "status": "pending",
  "created_at": "2024-12-01T10:30:00Z"
}
```

**cURL Command:**
```bash
curl -X POST "https://electrozonebd.com/api/orders" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "delivery_address": "123 Main St, Dhaka",
    "phone": "01700000001",
    "payment_method": "bkash"
  }'
```

---

## ✅ Test 10: Get User Orders

**Endpoint:** `GET /orders`

**URL:** `https://electrozonebd.com/api/orders`

**Headers Required:**
```
Authorization: Bearer {JWT_TOKEN}
```

**Expected Response (200 OK):**
```json
{
  "success": true,
  "orders": [
    {
      "order_id": 5,
      "order_total": 46798.2,
      "items_count": 1,
      "status": "pending",
      "payment_method": "bkash",
      "created_at": "2024-12-01T10:30:00Z",
      "items": [
        {
          "order_item_id": 10,
          "product_id": 1,
          "product_name": "Samsung TV",
          "price": 25999,
          "quantity": 2
        }
      ]
    }
  ]
}
```

**cURL Command:**
```bash
curl -X GET "https://electrozonebd.com/api/orders" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## 🧪 Complete Testing Workflow

### Step 1: Health Check
```bash
curl https://electrozonebd.com/api/health
# Expected: {"status":"ok","message":"API is running"}
```

### Step 2: Browse Products
```bash
curl https://electrozonebd.com/api/products?limit=5
# Expected: Array of 5 products
```

### Step 3: Register New User
```bash
curl -X POST https://electrozonebd.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"first_name":"Test","last_name":"User","email":"test@example.com","password":"Test123!","phone":"01700000001"}'
# Save JWT_TOKEN from response
```

### Step 4: Login with Existing User
```bash
curl -X POST https://electrozonebd.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"adminNoman@electrozonebd.com","password":"ElectroAdmin@2026"}'
# Save JWT_TOKEN from response
```

### Step 5: Add to Cart (Use JWT_TOKEN)
```bash
curl -X POST https://electrozonebd.com/api/cart \
  -H "Authorization: Bearer JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"product_id":1,"quantity":2}'
```

### Step 6: View Cart
```bash
curl https://electrozonebd.com/api/cart \
  -H "Authorization: Bearer JWT_TOKEN"
```

### Step 7: Create Order
```bash
curl -X POST https://electrozonebd.com/api/orders \
  -H "Authorization: Bearer JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"delivery_address":"123 Main St","phone":"01700000001","payment_method":"bkash"}'
```

### Step 8: View Orders
```bash
curl https://electrozonebd.com/api/orders \
  -H "Authorization: Bearer JWT_TOKEN"
```

---

## ✅ Testing Checklist

- [ ] Health endpoint responds (200 OK)
- [ ] Products list returns data
- [ ] Single product endpoint works
- [ ] Categories endpoint works
- [ ] User registration succeeds
- [ ] User login succeeds
- [ ] JWT token is returned and valid
- [ ] Cart operations work with JWT
- [ ] Order creation works
- [ ] Order listing works
- [ ] Wishlist operations work
- [ ] Admin endpoints accessible with admin JWT
- [ ] Images load correctly
- [ ] No CORS errors in browser
- [ ] No 500 errors in API

---

## 🆘 Common Issues & Solutions

### Issue 1: "404 Not Found"
- Solution: Check .htaccess, verify mod_rewrite enabled
- Test: `https://electrozonebd.com/api/health`

### Issue 2: "401 Unauthorized"
- Solution: Include valid JWT token in Authorization header
- Test: Use JWT from login response

### Issue 3: "500 Internal Server Error"
- Solution: Check PHP error logs in cPanel
- Path: `/home/asiment3/public_html/api/storage/logs/error.log`

### Issue 4: "CORS Error"
- Solution: Verify CORS headers in .htaccess
- Test: Check response headers include `Access-Control-Allow-Origin`

### Issue 5: "Connection Refused"
- Solution: Backend not running or wrong domain
- Test: Ping cPanel server, verify DNS

---

## 📊 API Response Codes

```
200 OK             - Request successful
201 Created        - Resource created
400 Bad Request    - Invalid input
401 Unauthorized   - JWT token invalid/missing
403 Forbidden      - Access denied
404 Not Found      - Endpoint not found
500 Server Error   - Backend error
```

---

## 🎯 Task 11 Status

✅ **READY FOR TESTING**

Use this guide to verify all API endpoints work correctly after cPanel deployment.

Next: Task 12 - Payment gateway verification

