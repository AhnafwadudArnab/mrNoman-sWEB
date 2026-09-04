import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart'
    show
        group,
        expect,
        isA,
        setUpAll,
        isTrue,
        test,
        isNotNull,
        contains,
        Timeout;

/// Returns true if the backend server is reachable.
Future<bool> _isServerAvailable(String base) async {
  try {
    await http
        .get(Uri.parse('$base/health'))
        .timeout(const Duration(seconds: 3));
    return true;
  } catch (_) {
    return false;
  }
}

void main() {
  const base = 'http://127.0.0.1:8000/api';
  String? adminToken;
  bool _serverAvailable = false;

  group('Bug Condition Exploration - Product Upload with Image', () {
    setUpAll(() async {
      _serverAvailable = await _isServerAvailable(base);
      if (!_serverAvailable) {
        print(
          '⚠ Backend not available at $base — all bug exploration tests will be skipped',
        );
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
          print('Successfully logged in as admin');
        } else {
          print('Login failed with status: ${loginRes.statusCode}');
          print('Response: ${loginRes.body}');
        }
      } catch (e) {
        print('Warning: Could not login as admin: $e');
        print('Test will attempt to run without authentication');
      }
    });

    test(
      'Product upload with image returns valid, parseable JSON',
      () async {
        if (!_serverAvailable) {
          print('Skipping: backend not available');
          return;
        }
        // CRITICAL: This test MUST FAIL on unfixed code
        // Failure confirms the bug exists (invalid JSON response)

        // Create a minimal test image (1x1 PNG)
        final imageBytes = _createTestPngImage();

        // Prepare multipart request
        final uri = Uri.parse('$base/products');
        final request = http.MultipartRequest('POST', uri);

        // Add authentication if available
        if (adminToken != null) {
          request.headers['Authorization'] = 'Bearer $adminToken';
          print(
            'Added Authorization header with token: ${adminToken?.substring(0, 20)}...',
          );
        } else {
          print('Warning: No admin token available');
        }

        // Add product fields
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        request.fields['product_name'] = 'Test Product $timestamp';
        request.fields['description'] = 'Test product for bug exploration';
        request.fields['price'] = '99.99';
        request.fields['stock_quantity'] = '10';
        request.fields['category_id'] = '1'; // Add category_id
        request.fields['brand_id'] = '1'; // Add brand_id

        // Add image file
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: 'test_image_$timestamp.png',
          ),
        );

        // Send request and capture raw response
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        // Capture raw response body for analysis
        final rawBody = response.body;
        print('Response status code: ${response.statusCode}');
        print('Response headers: ${response.headers}');
        print(
          'Raw response body (first 500 chars): ${rawBody.substring(0, rawBody.length > 500 ? 500 : rawBody.length)}',
        );

        // ASSERTION 1: Response body should be valid JSON
        // This will FAIL on unfixed code if PHP warnings/notices are prepended
        dynamic parsedJson;
        try {
          parsedJson = jsonDecode(rawBody);
          print('✓ Response body is valid JSON');
        } catch (e) {
          print('✗ COUNTEREXAMPLE FOUND: Response body is NOT valid JSON');
          print('Parse error: $e');
          print('Full raw response: $rawBody');

          // Analyze the corruption pattern
          _analyzeJsonCorruption(rawBody);

          // Re-throw to fail the test
          rethrow;
        }

        // ASSERTION 2: Response should be parseable without FormatException
        expect(
          parsedJson,
          isNotNull,
          reason: 'Response should be parseable JSON',
        );

        // ASSERTION 3: For successful creation, response should contain product_id
        if (response.statusCode >= 200 && response.statusCode < 300) {
          expect(
            parsedJson,
            isA<Map>(),
            reason: 'Successful response should be a JSON object',
          );

          final responseMap = parsedJson as Map<String, dynamic>;
          final hasProductId =
              responseMap.containsKey('product_id') ||
              responseMap.containsKey('productId');

          expect(
            hasProductId,
            isTrue,
            reason: 'Response should contain product_id or productId field',
          );

          print('✓ Response contains product_id field');
        }

        // ASSERTION 4: Content-Type header should be application/json
        final contentType = response.headers['content-type'] ?? '';
        expect(
          contentType,
          contains('application/json'),
          reason: 'Content-Type header should be application/json',
        );

        print('✓ All assertions passed - bug is NOT present');
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'Product upload with larger image returns valid JSON',
      () async {
        if (!_serverAvailable) {
          print('Skipping: backend not available');
          return;
        }
        // Test with a slightly larger image to potentially trigger more output
        final imageBytes = _createTestPngImage(width: 10, height: 10);

        final uri = Uri.parse('$base/products');
        final request = http.MultipartRequest('POST', uri);

        if (adminToken != null) {
          request.headers['Authorization'] = 'Bearer $adminToken';
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        request.fields['product_name'] = 'Test Product Large $timestamp';
        request.fields['description'] = 'Test product with larger image';
        request.fields['price'] = '149.99';
        request.fields['stock_quantity'] = '5';
        request.fields['category_id'] = '1';
        request.fields['brand_id'] = '1';

        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: 'test_large_$timestamp.png',
          ),
        );

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        final rawBody = response.body;

        print('Large image test - Status: ${response.statusCode}');
        print(
          'Raw response (first 300 chars): ${rawBody.substring(0, rawBody.length > 300 ? 300 : rawBody.length)}',
        );

        // Attempt to parse JSON
        dynamic parsedJson;
        try {
          parsedJson = jsonDecode(rawBody);
          print('✓ Large image response is valid JSON');
        } catch (e) {
          print('✗ COUNTEREXAMPLE: Large image response is NOT valid JSON');
          print('Parse error: $e');
          _analyzeJsonCorruption(rawBody);
          rethrow;
        }

        expect(parsedJson, isNotNull);
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'Product upload with special characters in name returns valid JSON',
      () async {
        if (!_serverAvailable) {
          print('Skipping: backend not available');
          return;
        }
        // Test with Unicode characters to check encoding issues
        final imageBytes = _createTestPngImage();

        final uri = Uri.parse('$base/products');
        final request = http.MultipartRequest('POST', uri);

        if (adminToken != null) {
          request.headers['Authorization'] = 'Bearer $adminToken';
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        request.fields['product_name'] =
            'পণ্য Test 产品 $timestamp'; // Bengali + Chinese
        request.fields['description'] = 'Test with émojis 🔥 and spëcial çhars';
        request.fields['price'] = '199.99';
        request.fields['stock_quantity'] = '3';
        request.fields['category_id'] = '1';
        request.fields['brand_id'] = '1';

        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: 'test_unicode_$timestamp.png',
          ),
        );

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        final rawBody = response.body;

        print('Unicode test - Status: ${response.statusCode}');

        // Attempt to parse JSON
        dynamic parsedJson;
        try {
          parsedJson = jsonDecode(rawBody);
          print('✓ Unicode response is valid JSON');
        } catch (e) {
          print('✗ COUNTEREXAMPLE: Unicode response is NOT valid JSON');
          print('Parse error: $e');
          _analyzeJsonCorruption(rawBody);
          rethrow;
        }

        expect(parsedJson, isNotNull);
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}

/// Creates a minimal valid PNG image for testing
/// Returns a Uint8List containing PNG bytes
Uint8List _createTestPngImage({int width = 1, int height = 1}) {
  // Minimal 1x1 PNG image (red pixel)
  // PNG signature + IHDR + IDAT + IEND chunks
  if (width == 1 && height == 1) {
    return Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 dimensions
      0x08,
      0x02,
      0x00,
      0x00,
      0x00,
      0x90,
      0x77,
      0x53, // bit depth, color type, CRC
      0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, // IDAT chunk
      0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00, // compressed image data
      0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xDD, 0x8D, // CRC
      0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, // IEND chunk
      0x44, 0xAE, 0x42, 0x60, 0x82, // CRC
    ]);
  }

  // For larger images, create a simple pattern
  // This is a simplified approach - real PNG encoding is more complex
  // But for testing purposes, we can use a basic structure
  final List<int> bytes = [];

  // PNG signature
  bytes.addAll([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

  // IHDR chunk (simplified)
  bytes.addAll([0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52]);
  bytes.addAll(_intToBytes(width, 4));
  bytes.addAll(_intToBytes(height, 4));
  bytes.addAll([0x08, 0x02, 0x00, 0x00, 0x00]);
  bytes.addAll([0x00, 0x00, 0x00, 0x00]); // Placeholder CRC

  // IDAT chunk (simplified - just some data)
  final dataSize = width * height * 3 + height; // RGB + filter bytes
  bytes.addAll(_intToBytes(dataSize + 2, 4));
  bytes.addAll([0x49, 0x44, 0x41, 0x54]);
  bytes.addAll([0x08, 0xD7]); // zlib header
  for (int i = 0; i < dataSize; i++) {
    bytes.add(0x00); // Black pixels
  }
  bytes.addAll([0x00, 0x00, 0x00, 0x00]); // Placeholder CRC

  // IEND chunk
  bytes.addAll([0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44]);
  bytes.addAll([0xAE, 0x42, 0x60, 0x82]);

  return Uint8List.fromList(bytes);
}

/// Helper to convert int to bytes
List<int> _intToBytes(int value, int length) {
  final bytes = <int>[];
  for (int i = length - 1; i >= 0; i--) {
    bytes.add((value >> (i * 8)) & 0xFF);
  }
  return bytes;
}

/// Analyzes the raw response to identify JSON corruption patterns
void _analyzeJsonCorruption(String rawBody) {
  print('\n=== JSON CORRUPTION ANALYSIS ===');

  // Check for PHP warnings/notices
  if (rawBody.contains('Warning:') || rawBody.contains('Notice:')) {
    print('✗ PATTERN DETECTED: PHP warnings/notices prepended to JSON');
    final warningMatch = RegExp(
      r'(Warning|Notice):.*?(?=\{|\[|$)',
    ).firstMatch(rawBody);
    if (warningMatch != null) {
      print('  Found: ${warningMatch.group(0)}');
    }
  }

  // Check for HTML error pages
  if (rawBody.contains('<!DOCTYPE') || rawBody.contains('<html')) {
    print('✗ PATTERN DETECTED: HTML error page instead of JSON');
    print('  Response appears to be HTML, not JSON');
  }

  // Check for trailing PHP closing tags or whitespace
  final jsonStart = rawBody.indexOf('{');
  final jsonArrayStart = rawBody.indexOf('[');
  final firstJsonChar =
      jsonStart >= 0 && (jsonArrayStart < 0 || jsonStart < jsonArrayStart)
      ? jsonStart
      : jsonArrayStart;

  if (firstJsonChar > 0) {
    print('✗ PATTERN DETECTED: Content before JSON starts');
    print('  $firstJsonChar characters before first JSON character');
    print('  Prefix: "${rawBody.substring(0, firstJsonChar)}"');
  }

  final jsonEnd = rawBody.lastIndexOf('}');
  final jsonArrayEnd = rawBody.lastIndexOf(']');
  final lastJsonChar = jsonEnd > jsonArrayEnd ? jsonEnd : jsonArrayEnd;

  if (lastJsonChar >= 0 && lastJsonChar < rawBody.length - 1) {
    print('✗ PATTERN DETECTED: Content after JSON ends');
    final suffix = rawBody.substring(lastJsonChar + 1);
    print('  ${suffix.length} characters after last JSON character');
    print('  Suffix: "$suffix"');

    if (suffix.contains('?>')) {
      print('  Contains PHP closing tag: ?>');
    }
  }

  // Check for encoding issues
  if (rawBody.contains('\uFEFF')) {
    print('✗ PATTERN DETECTED: UTF-8 BOM (Byte Order Mark) present');
  }

  // Check Content-Type mismatch
  print('\n=== EXPECTED COUNTEREXAMPLES ===');
  print('This test is designed to surface one or more of these issues:');
  print('1. PHP warnings/notices prepended to JSON response');
  print('2. HTML error pages returned instead of JSON');
  print('3. Trailing whitespace or PHP closing tags (?>)');
  print('4. UTF-8 encoding issues (BOM)');
  print('5. Output buffer not cleaned before JSON response');
  print('================================\n');
}
