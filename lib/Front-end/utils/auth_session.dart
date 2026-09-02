import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class UserData {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String gender;
  final String address;

  UserData({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.gender,
    this.address = '',
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phone': phone,
    'gender': gender,
    'address': address,
  };

  // Create from JSON (local storage)
  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
    firstName: json['firstName'] ?? '',
    lastName: json['lastName'] ?? '',
    email: json['email'] ?? '',
    phone: json['phone'] ?? '',
    gender: json['gender'] ?? 'Male',
    address: json['address'] ?? '',
  );

  // Create from API response (backend login/register/profile)
  factory UserData.fromApiResponse(Map<String, dynamic> data) {
    // Handle both wrapped {"user": {...}} and direct {...} responses
    final user =
        data.containsKey('user') && data['user'] is Map<String, dynamic>
        ? data['user'] as Map<String, dynamic>
        : data;

    return UserData(
      firstName: (user['firstName'] ?? user['full_name'] ?? '').toString(),
      lastName: (user['lastName'] ?? user['last_name'] ?? '').toString(),
      email: (user['email'] ?? '').toString(),
      phone: (user['phone'] ?? user['phone_number'] ?? '').toString(),
      gender: (user['gender'] ?? 'Male').toString(),
      address: (user['address'] ?? '').toString(),
    );
  }

  // Get full name
  String get fullName => '$firstName $lastName';
}

class AuthSession {
  static const String _loggedInKey = 'electrocity_is_logged_in';
  static const String _userDataKey = 'electrocity_user_data';
  static const String _isAdminKey = 'electrocity_is_admin';
  static const String _tokenKey = 'electrocity_jwt_token';

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  static Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, value);
  }

  static Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isAdminKey) ?? false;
  }

  static Future<void> setAdmin(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isAdminKey, value);
  }

  // Save user data
  static Future<void> saveUserData(UserData userData) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(userData.toJson());
    await prefs.setString(_userDataKey, userJson);
    await setLoggedIn(true);
  }

  // Get user data
  static Future<UserData?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userDataKey);

    if (userJson == null) return null;

    try {
      final jsonData = jsonDecode(userJson);
      return UserData.fromJson(jsonData);
    } catch (e) {
      return null;
    }
  }

  // Update user data
  static Future<void> updateUserData(UserData userData) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(userData.toJson());
    await prefs.setString(_userDataKey, userJson);
  }

  // Clear all data on logout
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_isAdminKey);
    await prefs.remove(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
