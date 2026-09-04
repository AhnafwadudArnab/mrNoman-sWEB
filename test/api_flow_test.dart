import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

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

Future<String> _registerAndLogin({
  required String base,
  required String email,
  required String password,
}) async {
  await http.post(
    Uri.parse('$base/auth/register'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'firstName': 'Test',
      'lastName': 'User',
      'email': email,
      'password': password,
      'phone': '01234567890',
      'gender': 'Male',
    }),
  );

  final loginRes = await http.post(
    Uri.parse('$base/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );

  final login = jsonDecode(loginRes.body) as Map;
  final token = login['token'] as String?;
  if (token == null || token.isEmpty) {
    throw StateError('Unable to login and get token for $email');
  }

  return token;
}

void main() {
  const base = 'http://127.0.0.1:8000/api';
  String? token;
  bool serverAvailable = false;

  group('Backend API end-to-end', () {
    late String email;
    const String password = 'TestPass123!';

    setUpAll(() async {
      serverAvailable = await _isServerAvailable(base);
      if (!serverAvailable) {
        print(
          '⚠ Backend not available at $base — all API tests will be skipped',
        );
      }
    });

    setUp(() {
      final ts = DateTime.now().millisecondsSinceEpoch;
      email = 'test_$ts@electrocity.local';
    });

    test('health check', () async {
      if (!serverAvailable) {
        print('Skipping: backend not available');
        return;
      }
      final res = await http.get(Uri.parse('$base/health'));
      final body = jsonDecode(res.body) as Map;
      expect(body['status'], 'ok');
    });

    test('register + login + me + change-password', () async {
      if (!serverAvailable) {
        print('Skipping: backend not available');
        return;
      }
      final regRes = await http.post(
        Uri.parse('$base/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': 'Test',
          'lastName': 'User',
          'email': email,
          'password': password,
          'phone': '01234567890',
          'gender': 'Male',
        }),
      );
      final reg = jsonDecode(regRes.body) as Map;
      expect(reg['token'], isNotNull);
      token = reg['token'] as String;

      final loginRes = await http.post(
        Uri.parse('$base/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final login = jsonDecode(loginRes.body) as Map;
      expect(login['token'], isNotNull);
      token = login['token'] as String;

      final meRes = await http.get(
        Uri.parse('$base/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final me = jsonDecode(meRes.body) as Map;
      expect(me['email'], email);

      final chRes = await http.put(
        Uri.parse('$base/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': password,
          'newPassword': 'New$password',
        }),
      );
      final ch = jsonDecode(chRes.body) as Map;
      expect(ch['message'], 'Password changed');

      final reloginRes = await http.post(
        Uri.parse('$base/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': 'New$password'}),
      );
      final relogin = jsonDecode(reloginRes.body) as Map;
      expect(relogin['token'], isNotNull);
      token = relogin['token'] as String;
    });

    test('products + cart + order flow', () async {
      if (!serverAvailable) {
        print('Skipping: backend not available');
        return;
      }
      token ??= await _registerAndLogin(
        base: base,
        email: email,
        password: password,
      );

      final prodsRes = await http.get(Uri.parse('$base/products'));
      final prodsBody = jsonDecode(prodsRes.body);
      // API returns {"products":[...]} or a plain list
      final list = (prodsBody is Map ? prodsBody['products'] : prodsBody) as List<dynamic>;
      expect(list.isNotEmpty, true, reason: 'Need at least one product in DB');
      final first = list.first as Map<String, dynamic>;
      final pid = first['product_id'] ?? first['productId'];
      expect(pid, isNotNull);

      expect(
        token,
        isNotNull,
        reason: 'token must be available from previous test',
      );

      final addRes = await http.post(
        Uri.parse('$base/cart'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'product_id': pid, 'quantity': 2}),
      );
      final cart = jsonDecode(addRes.body) as Map;
      final items = (cart['items'] as List).cast<Map>();
      expect(items.isNotEmpty, true);

      final cartId = items.first['cart_id'] as int;
      final updRes = await http.put(
        Uri.parse('$base/cart'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'cart_id': cartId, 'quantity': 3}),
      );
      final cart2 = jsonDecode(updRes.body) as Map;
      final items2 = (cart2['items'] as List).cast<Map>();
      expect(items2.first['quantity'], 3);

      final orderRes = await http.post(
        Uri.parse('$base/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'payment_method': 'Cash on Delivery',
          'delivery_address': 'Test Address',
        }),
      );
      final order = jsonDecode(orderRes.body) as Map;
      expect(order['order_id'], isNotNull);
    });
  });
}
