# Admin Login - Complete Debugging Guide

## Flow Analysis

### Frontend sends:
```
POST /auth/admin-login
{
  "username": "adminNoman@electrozonebd.com",
  "password": "ElectroAdmin@2026"
}
```

### API Service converts endpoint:
- Input: `/auth/admin-login`
- Using `_toPHP()`: `/auth/admin-login.php`
- Actual URL: `http://localhost:8000/api/auth/admin-login.php`

### Backend receives:
- File: `/backend/api/auth/admin-login.php`
- Method: POST
- Content-Type: application/json

## ✅ Verified Working Components

### 1. Backend Login Endpoint
- ✅ `/backend/api/auth/admin-login.php` exists
- ✅ Accepts POST requests
- ✅ Parses JSON body correctly
- ✅ Queries database correctly
- ✅ Verifies passwords correctly
- ✅ Generates JWT tokens correctly
- ✅ Returns correct response format

### 2. Password Hashes
- ✅ All 3 admin accounts have correct bcrypt hashes
- ✅ password_verify() working for all accounts
- ✅ Test results: All passwords verified successfully

### 3. JWT Token Generation
- ✅ JWT class working correctly
- ✅ Tokens generated with correct payload
- ✅ Token verification working
- ✅ 7-day expiration set correctly

### 4. Database Connection
- ✅ PDO connection working
- ✅ Query execution working
- ✅ Prepared statements working
- ✅ User table accessible

## Test Results

### Backend Direct Test
```
Email: adminNoman@electrozonebd.com
Password: ElectroAdmin@2026
Result: ✅ LOGIN SUCCESS
Token Generated: eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
User Data: Returned correctly
```

### Token Test
```
Token Valid: ✅ Yes
Payload: user_id: 26, email: adminNoman@electrozonebd.com, role: admin
Expiration: 7 days from login
```

## Possible Issues

### If Frontend Still Showing "Invalid Credentials":

1. **URL Mismatch**
   - Check: Base URL in AppConfig
   - Expected: `http://localhost:8000/api` (dev) or `https://electrozonebd.com/api` (prod)
   - Verify: In Flutter app, admin login should call correct API endpoint

2. **Network Error**
   - Check: Is backend running on the configured port?
   - Check: Is CORS properly configured?
   - Check: Check browser console for actual error message

3. **Request Body Issue**
   - Check: Flutter is sending JSON body correctly
   - Check: "username" field name (not "email")
   - Check: No extra spaces in credentials

4. **Response Parsing**
   - Check: Flutter is parsing response correctly
   - Check: Token is being saved properly
   - Check: User data structure matches expected format

5. **Endpoint Routing**
   - The `_toPHP()` conversion changes `/auth/admin-login` to `/auth/admin-login.php`
   - File exists at: `/backend/api/auth/admin-login.php`
   - This should work correctly

## How to Debug

### Step 1: Check Backend is Running
```bash
curl -X POST http://localhost:8000/api/auth/admin-login.php \
  -H "Content-Type: application/json" \
  -d '{"username":"adminNoman@electrozonebd.com","password":"ElectroAdmin@2026"}'
```
Expected: Should return JSON with token and user data

### Step 2: Check Flutter Network Request
- Open Flutter DevTools
- Go to Network tab
- Try admin login
- Look for request to `/api/auth/admin-login.php`
- Check status code (should be 200)
- Check response body

### Step 3: Check JWT Token
- If token is received, verify it at jwt.io
- Paste token in debugger
- Verify payload contains: user_id, email, role, exp

### Step 4: Check Token Storage
- In Flutter app, token should be saved to SharedPreferences
- Key: `electrocity_jwt_token`
- Check if it's being retrieved correctly

## Files to Check

1. **Backend**:
   - ✅ `/backend/api/auth/admin-login.php` - Working correctly
   - ✅ `/backend/util/JWT.php` - Working correctly
   - ✅ `/backend/api/bootstrap.php` - Connection working

2. **Frontend**:
   - `/lib/Front-end/utils/api_service.dart` - AdminLogin method
   - `/lib/Front-end/All Pages/Registrations/admin_login.dart` - Login UI
   - `/lib/Front-end/utils/auth_session.dart` - Token storage

## Next Steps If Still Not Working

1. Add logging to Flutter app to see exact error
2. Check browser DevTools Network tab for exact response
3. Verify base URL is set correctly in AppConfig
4. Check if CORS headers are being received
5. Ensure backend is responding with correct HTTP status codes

## Status

✅ **Backend: 100% Working**
- Database connection: ✅
- Password verification: ✅
- Token generation: ✅
- Response format: ✅

⚠️ **Frontend: Unknown**
- Need to check actual network request/response
- Check browser console for errors
- Verify base URL configuration
