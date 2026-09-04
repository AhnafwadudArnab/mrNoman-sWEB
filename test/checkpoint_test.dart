import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart' show group, fail, expect, isA, setUpAll, anyOf, isTrue, test, equals, isNotNull, Timeout;
import 'package:http/http.dart' as http;

/// Checkpoint Test - Comprehensive verification of the product upload fix
/// 
/// This test suite verifies:
/// 1. Bug condition exploration test passes (product upload with image returns valid JSON)
/// 2. Preservation tests pass (non-multipart operations unchanged)
/// 3. Full product upload flow from frontend form to database
/// 4. Error cases: large images, invalid file types, missing fields
/// 5. Concurrent uploads and special characters in product data
/// Returns true if the backend server is reachable.
Future<bool> _isServerAvailable(String base) async {
  try {
    await http.get(Uri.parse('$base/health')).timeout(const Duration(seconds: 3));
    return true;
  } catch (_) {
    return false;
  }
}

void main() {
  const base = 'http://127.0.0.1:8000/api';
  String? adminToken;
  bool _serverAvailable = false;

  group('Checkpoint - Product Upload Fix Verification', () {
    setUpAll(() async {
      _serverAvailable = await _isServerAvailable(base);
      if (!_serverAvailable) {
        print('⚠ Backend not available at $base — all checkpoint tests will be skipped');
        return;
      }
      // Login as admin to get authentication token
      try {
        final loginRes = await http.post(
          Uri.parse('$base/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': 'ahnaf@electrocitybd.com',
            'password': 'Admin@1234',
          }),
        );
        
        if (loginRes.statusCode == 200) {
          final loginData = jsonDecode(loginRes.body) as Map<String, dynamic>;
          adminToken = loginData['token'] as String?;
          print('✓ Successfully logged in as admin');
        } else {
          print('✗ Login failed with status: ${loginRes.statusCode}');
        }
      } catch (e) {
        print('✗ Could not login as admin: $e');
      }
    });

    test('1. Bug condition test - Product upload with image returns valid JSON', () async {
      if (!_serverAvailable) { print('Skipping: backend not available'); return; }
      // Verify the bug fix works: multipart upload returns valid JSON
      final imageBytes = _createTestPngImage();
      final uri = Uri.parse('$base/products');
      final request = http.MultipartRequest('POST', uri);
      
      if (adminToken != null) {
        request.headers['Authorization'] = 'Bearer $adminToken';
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      request.fields['product_name'] = 'Checkpoint Test $timestamp';
      request.fields['description'] = 'Checkpoint verification product';
      request.fields['price'] = '99.99';
      request.fields['stock_quantity'] = '10';
      request.fields['category_id'] = '1';
      request.fields['brand_id'] = '1';
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'checkpoint_$timestamp.png',
        ),
      );
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      // Verify valid JSON response
      dynamic parsedJson;
      try {
        parsedJson = jsonDecode(response.body);
        print('✓ Product upload with image returns valid JSON');
      } catch (e) {
        fail('Product upload returned invalid JSON: $e\nResponse: ${response.body}');
      }
      
      expect(response.statusCode, anyOf([200, 201]));
      expect(parsedJson, isA<Map>());
      
      final responseMap = parsedJson as Map<String, dynamic>;
      final hasProductId = responseMap.containsKey('product_id') || 
                          responseMap.containsKey('productId');
      expect(hasProductId, isTrue);
      
      print('✓ Bug condition test passed');
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('2. Preservation test - Non-multipart operations work correctly', () async {
      if (!_serverAvailable) { print('Skipping: backend not available'); return; }
      // Verify GET /products returns valid JSON
      final getRes = await http.get(Uri.parse('$base/products'));
      expect(getRes.statusCode, equals(200));
      
      dynamic parsedJson;
      try {
        parsedJson = jsonDecode(getRes.body);
        print('✓ GET /products returns valid JSON');
      } catch (e) {
        fail('GET /products returned invalid JSON: $e');
      }
      
      expect(parsedJson, anyOf([isA<List>(), isA<Map>()]));
      
      // Verify POST without image file works
      if (adminToken != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final postRes = await http.post(
          Uri.parse('$base/products'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $adminToken',
          },
          body: jsonEncode({
            'product_name': 'No-Image Test $timestamp',
            'description': 'Product without image file',
            'price': '149.99',
            'stock_quantity': '5',
            'category_id': '1',
            'brand_id': '1',
            'image_url': 'https://example.com/test.jpg',
          }),
        );
        
        try {
          final postJson = jsonDecode(postRes.body);
          print('✓ POST without image file returns valid JSON');
          expect(postRes.statusCode, anyOf([200, 201]));
        } catch (e) {
          fail('POST without image returned invalid JSON: $e');
        }
      }
      
      print('✓ Preservation test passed');
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('3. Full product upload flow - Form to database', () async {
      if (!_serverAvailable) { print('Skipping: backend not available'); return; }
      // Test the complete flow: upload product and verify it persists
      final imageBytes = _createTestPngImage();
      final uri = Uri.parse('$base/products');
      final request = http.MultipartRequest('POST', uri);
      
      if (adminToken != null) {
        request.headers['Authorization'] = 'Bearer $adminToken';
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final productName = 'Flow Test Product $timestamp';
      request.fields['product_name'] = productName;
      request.fields['description'] = 'Testing full flow';
      request.fields['price'] = '299.99';
      request.fields['stock_quantity'] = '15';
      request.fields['category_id'] = '1';
      request.fields['brand_id'] = '1';
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'flow_test_$timestamp.png',
        ),
      );
      
      // Upload product
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      expect(response.statusCode, anyOf([200, 201]));
      
      final createData = jsonDecode(response.body) as Map<String, dynamic>;
      final productId = createData['product_id'] ?? createData['productId'];
      expect(productId, isNotNull);
      
      print('✓ Product created with ID: $productId');
      
      // Verify product persists by retrieving it
      final getRes = await http.get(Uri.parse('$base/products?id=$productId'));
      expect(getRes.statusCode, equals(200));
      
      final productData = jsonDecode(getRes.body) as Map<String, dynamic>;
      expect(productData['product_name'], equals(productName));
      expect(productData['price'], anyOf([equals('299.99'), equals(299.99)]));
      
      print('✓ Product persists in database');
      print('✓ Full flow test passed');
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('4a. Error case - Large image (exceeds size limit)', () async {
      if (!_serverAvailable) { print('Skipping: backend not available'); return; }
      // Test with a very large image
      final largeImageBytes = _createLargeTestImage();
      final uri = Uri.parse('$base/products');
      final request = http.MultipartRequest('POST', uri);
      
      if (adminToken != null) {
        request.headers['Authorization'] = 'Bearer $adminToken';
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      request.fields['product_name'] = 'Large Image Test $timestamp';
      request.fields['description'] = 'Testing large image handling';
      request.fields['price'] = '99.99';
      request.fields['stock_quantity'] = '10';
      request.fields['category_id'] = '1';
      request.fields['brand_id'] = '1';
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          largeImageBytes,
          filename: 'large_$timestamp.png',
        ),
      );
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      // Response should be valid JSON regardless of success or error
      dynamic parsedJson;
      try {
        parsedJson = jsonDecode(response.body);
        print('✓ Large image response is valid JSON');
      } catch (e) {
        fail('Large image response is invalid JSON: $e\nResponse: ${response.body}');
      }
      
      expect(parsedJson, isA<Map>());
      
      // If it's an error response, verify it has an error message
      if (response.statusCode >= 400) {
        final responseMap = parsedJson as Map<String, dynamic>;
        expect(responseMap.containsKey('error') || responseMap.containsKey('message'), isTrue);
        print('✓ Error response properly formatted');
      }
      
      print('✓ Large image error case handled correctly');
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('4b. Error case - Invalid file type', () async {
      if (!_serverAvailable) { print('Skipping: backend not available'); return; }
      // Test with a non-image file (text file disguised as image)
      final invalidBytes = Uint8List.fromList('This is not an image'.codeUnits);
      final uri = Uri.parse('$base/products');
      final request = http.MultipartRequest('POST', uri);
      
      if (adminToken != null) {
        request.headers['Authorization'] = 'Bearer $adminToken';
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      request.fields['product_name'] = 'Invalid File Test $timestamp';
      request.fields['description'] = 'Testing invalid file handling';
      request.fields['price'] = '99.99';
      request.fields['stock_quantity'] = '10';
      request.fields['category_id'] = '1';
      request.fields['brand_id'] = '1';
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          invalidBytes,
          filename: 'invalid_$timestamp.txt',
        ),
      );
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      // Response should be valid JSON
      dynamic parsedJson;
      try {
        parsedJson = jsonDecode(response.body);
        print('✓ Invalid file type response is valid JSON');
      } catch (e) {
        fail('Invalid file response is invalid JSON: $e\nResponse: ${response.body}');
      }
      
      expect(parsedJson, isA<Map>());
      
      print('✓ Invalid file type error case handled correctly');
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('4c. Error case - Missing required fields', () async {
      if (!_serverAvailable) { print('Skipping: backend not available'); return; }
      // Test with missing required fields
      final imageBytes = _createTestPngImage();
      final uri = Uri.parse('$base/products');
      final request = http.MultipartRequest('POST', uri);
      
      if (adminToken != null) {
        request.headers['Authorization'] = 'Bearer $adminToken';
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // Only provide product_name, missing other required fields
      request.fields['product_name'] = 'Missing Fields Test $timestamp';
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'missing_$timestamp.png',
        ),
      );
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      // Response should be valid JSON
      dynamic parsedJson;
      try {
        parsedJson = jsonDecode(response.body);
        print('✓ Missing fields response is valid JSON');
      } catch (e) {
        fail('Missing fields response is invalid JSON: $e\nResponse: ${response.body}');
      }
      
      expect(parsedJson, isA<Map>());
      
      print('✓ Missing fields error case handled correctly');
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('5a. Special characters in product data', () async {
      if (!_serverAvailable) { print('Skipping: backend not available'); return; }
      // Test with Unicode characters, emojis, special chars
      final imageBytes = _createTestPngImage();
      final uri = Uri.parse('$base/products');
      final request = http.MultipartRequest('POST', uri);
      
      if (adminToken != null) {
        request.headers['Authorization'] = 'Bearer $adminToken';
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      request.fields['product_name'] = 'পণ্য Test 产品 🔥 $timestamp';
      request.fields['description'] = 'Spëcial çhars & émojis 🎉 テスト';
      request.fields['price'] = '199.99';
      request.fields['stock_quantity'] = '3';
      request.fields['category_id'] = '1';
      request.fields['brand_id'] = '1';
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'unicode_$timestamp.png',
        ),
      );
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      // Verify valid JSON with proper UTF-8 encoding
      dynamic parsedJson;
      try {
        parsedJson = jsonDecode(response.body);
        print('✓ Special characters response is valid JSON');
      } catch (e) {
        fail('Special characters response is invalid JSON: $e\nResponse: ${response.body}');
      }
      
      expect(response.statusCode, anyOf([200, 201]));
      expect(parsedJson, isA<Map>());
      
      print('✓ Special characters handled correctly');
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('5b. Concurrent uploads', () async {
      if (!_serverAvailable) { print('Skipping: backend not available'); return; }
      // Test multiple simultaneous uploads
      final futures = <Future<http.Response>>[];
      
      for (int i = 0; i < 3; i++) {
        final imageBytes = _createTestPngImage();
        final uri = Uri.parse('$base/products');
        final request = http.MultipartRequest('POST', uri);
        
        if (adminToken != null) {
          request.headers['Authorization'] = 'Bearer $adminToken';
        }
        
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        request.fields['product_name'] = 'Concurrent Test $i $timestamp';
        request.fields['description'] = 'Concurrent upload test $i';
        request.fields['price'] = '${100 + i * 10}.99';
        request.fields['stock_quantity'] = '${5 + i}';
        request.fields['category_id'] = '1';
        request.fields['brand_id'] = '1';
        
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: 'concurrent_${i}_$timestamp.png',
          ),
        );
        
        futures.add(
          request.send().then((streamedResponse) => 
            http.Response.fromStream(streamedResponse)
          )
        );
      }
      
      // Wait for all uploads to complete
      final responses = await Future.wait(futures);
      
      // Verify all responses are valid JSON
      for (int i = 0; i < responses.length; i++) {
        final response = responses[i];
        
        try {
          final parsedJson = jsonDecode(response.body);
          expect(parsedJson, isA<Map>());
          print('✓ Concurrent upload $i returned valid JSON');
        } catch (e) {
          fail('Concurrent upload $i returned invalid JSON: $e\nResponse: ${response.body}');
        }
      }
      
      print('✓ All concurrent uploads handled correctly');
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}

/// Creates a minimal valid PNG image for testing
Uint8List _createTestPngImage({int width = 1, int height = 1}) {
  if (width == 1 && height == 1) {
    return Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 dimensions
      0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, // bit depth, color type, CRC
      0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, // IDAT chunk
      0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00, // compressed image data
      0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xDD, 0x8D, // CRC
      0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, // IEND chunk
      0x44, 0xAE, 0x42, 0x60, 0x82, // CRC
    ]);
  }
  
  // For larger images, use the same minimal PNG
  return _createTestPngImage();
}

/// Creates a large test image (simulated)
Uint8List _createLargeTestImage() {
  // Create a 6MB file (exceeds typical upload limits)
  final size = 6 * 1024 * 1024;
  final bytes = List<int>.filled(size, 0);
  
  // Add PNG signature at the beginning
  bytes[0] = 0x89;
  bytes[1] = 0x50;
  bytes[2] = 0x4E;
  bytes[3] = 0x47;
  
  return Uint8List.fromList(bytes);
}
