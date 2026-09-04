/// Application-wide constants for URLs, text, and configuration values
/// Centralized location for hardcoded strings and URLs used throughout the app
library;

class AppConstants {
  // --- Production URLs ---
  static const String productionDomain = 'electrozonebd.com';
  static const String productionUrl = 'https://electrozonebd.com';
  static const String baseUrl = 'https://electrozonebd.com';

  // --- Policy & Legal URLs ---
  static const String termsOfService = '$productionUrl/terms';
  static const String returnPolicy = '$productionUrl/return-policy';
  static const String privacyPolicy = '$productionUrl/privacy-policy';

  // --- Development/Debug URLs ---
  static const String debugLocalhost = 'http://localhost:8000';
  static const String debugAndroidEmulator = 'http://10.0.2.2:8000';
  
  // --- API URLs ---
  static const String debugLocalhostApi = 'http://localhost:8000/api';
  static const String debugAndroidEmulatorApi = 'http://10.0.2.2:8000/api';
  static const String debugFallbackApi1 = 'http://127.0.0.1:8080/api';
  static const String debugFallbackApi2 = 'http://localhost:8080/api';

  // --- Image Upload Paths ---
  static const String uploadsEndpoint = '/uploads/';
  static const String apiUploadsEndpoint = '/api/uploads/';
  static const String apiPublicUploadsEndpoint = '/api/public/uploads/';

  // --- Payment Methods ---
  static const String paymentMethodBkash = 'bKash';
  static const String paymentMethodNagad = 'Nagad';
  static const String paymentMethodRocket = 'Rocket';
  static const String paymentMethodUpay = 'Upay';
  static const String paymentMethodCod = 'Cash on Delivery';

  // --- Error Messages ---
  static const String errorConnectionFailed = 'Unable to load. Please check your connection.';
  static const String errorLoadingProducts = 'Unable to load products. Please check your connection.';
  static const String errorRegistrationFailed = 'Registration failed. Please try again.';
  static const String errorInvalidCredentials = 'Invalid email or password.';
  static const String errorSessionExpired = 'Session expired. Please log in again.';
  static const String errorAccessDenied = 'Access denied. Admin privileges required.';
  static const String errorUploadFailed = 'Upload failed. Please try again.';

  // --- Success Messages ---
  static const String successOrderPlaced = 'Order placed successfully!';
  static const String successProfileUpdated = 'Profile updated successfully!';
  static const String successProductAdded = 'Product added successfully!';

  // --- Default Values ---
  static const String defaultDeliveryDays = '5';
  static const String defaultPaymentMethod = 'Cash on Delivery';

  // --- Branding ---
  static const String appName = 'ElectroZoneBD';
  static const String appTitle = 'ElectrocityBD';
  static const String companyName = 'ElectrocityBD';
}









