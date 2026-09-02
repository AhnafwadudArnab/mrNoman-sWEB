import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [Locale('en', 'US')];

  // Common
  String get appName => _localizedValues[locale.languageCode]!['app_name']!;
  String get home => _localizedValues[locale.languageCode]!['home']!;
  String get categories =>
      _localizedValues[locale.languageCode]!['categories']!;
  String get cart => _localizedValues[locale.languageCode]!['cart']!;
  String get profile => _localizedValues[locale.languageCode]!['profile']!;
  String get search => _localizedValues[locale.languageCode]!['search']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;

  // Products
  String get products => _localizedValues[locale.languageCode]!['products']!;
  String get addToCart =>
      _localizedValues[locale.languageCode]!['add_to_cart']!;
  String get buyNow => _localizedValues[locale.languageCode]!['buy_now']!;
  String get price => _localizedValues[locale.languageCode]!['price']!;
  String get stock => _localizedValues[locale.languageCode]!['stock']!;
  String get outOfStock =>
      _localizedValues[locale.languageCode]!['out_of_stock']!;

  // Cart
  String get emptyCart => _localizedValues[locale.languageCode]!['empty_cart']!;
  String get checkout => _localizedValues[locale.languageCode]!['checkout']!;
  String get total => _localizedValues[locale.languageCode]!['total']!;
  String get subtotal => _localizedValues[locale.languageCode]!['subtotal']!;

  // Orders
  String get orders => _localizedValues[locale.languageCode]!['orders']!;
  String get orderHistory =>
      _localizedValues[locale.languageCode]!['order_history']!;
  String get orderDetails =>
      _localizedValues[locale.languageCode]!['order_details']!;

  // Auth
  String get login => _localizedValues[locale.languageCode]!['login']!;
  String get register => _localizedValues[locale.languageCode]!['register']!;
  String get logout => _localizedValues[locale.languageCode]!['logout']!;
  String get email => _localizedValues[locale.languageCode]!['email']!;
  String get password => _localizedValues[locale.languageCode]!['password']!;
  String get forgotPassword =>
      _localizedValues[locale.languageCode]!['forgot_password']!;

  // Admin
  String get dashboard => _localizedValues[locale.languageCode]!['dashboard']!;
  String get manageProducts =>
      _localizedValues[locale.languageCode]!['manage_products']!;
  String get manageOrders =>
      _localizedValues[locale.languageCode]!['manage_orders']!;
  String get promotions =>
      _localizedValues[locale.languageCode]!['promotions']!;
  String get flashSales =>
      _localizedValues[locale.languageCode]!['flash_sales']!;

  // Messages
  String get success => _localizedValues[locale.languageCode]!['success']!;
  String get error => _localizedValues[locale.languageCode]!['error']!;
  String get loading => _localizedValues[locale.languageCode]!['loading']!;
  String get noData => _localizedValues[locale.languageCode]!['no_data']!;

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'ElectroZoneBD',
      'home': 'Home',
      'categories': 'Categories',
      'cart': 'Cart',
      'profile': 'Profile',
      'search': 'Search',
      'settings': 'Settings',
      'products': 'Products',
      'add_to_cart': 'Add to Cart',
      'buy_now': 'Buy Now',
      'price': 'Price',
      'stock': 'Stock',
      'out_of_stock': 'Out of Stock',
      'empty_cart': 'Your cart is empty',
      'checkout': 'Checkout',
      'total': 'Total',
      'subtotal': 'Subtotal',
      'orders': 'Orders',
      'order_history': 'Order History',
      'order_details': 'Order Details',
      'login': 'Login',
      'register': 'Register',
      'logout': 'Logout',
      'email': 'Email',
      'password': 'Password',
      'forgot_password': 'Forgot Password?',
      'dashboard': 'Dashboard',
      'manage_products': 'Manage Products',
      'manage_orders': 'Manage Orders',
      'promotions': 'Promotions',
      'flash_sales': 'Flash Sales',
      'success': 'Success',
      'error': 'Error',
      'loading': 'Loading...',
      'no_data': 'No data available',
    },
    'bn': {
      'app_name': 'ইলেক্ট্রোসিটি বিডি',
      'home': 'হোম',
      'categories': 'ক্যাটাগরি',
      'cart': 'কার্ট',
      'profile': 'প্রোফাইল',
      'search': 'খুঁজুন',
      'settings': 'সেটিংস',
      'products': 'পণ্য',
      'add_to_cart': 'কার্টে যোগ করুন',
      'buy_now': 'এখনই কিনুন',
      'price': 'মূল্য',
      'stock': 'স্টক',
      'out_of_stock': 'স্টক শেষ',
      'empty_cart': 'আপনার কার্ট খালি',
      'checkout': 'চেকআউট',
      'total': 'মোট',
      'subtotal': 'সাবটোটাল',
      'orders': 'অর্ডার',
      'order_history': 'অর্ডার ইতিহাস',
      'order_details': 'অর্ডার বিস্তারিত',
      'login': 'লগইন',
      'register': 'রেজিস্টার',
      'logout': 'লগআউট',
      'email': 'ইমেইল',
      'password': 'পাসওয়ার্ড',
      'forgot_password': 'পাসওয়ার্ড ভুলে গেছেন?',
      'dashboard': 'ড্যাশবোর্ড',
      'manage_products': 'পণ্য পরিচালনা',
      'manage_orders': 'অর্ডার পরিচালনা',
      'promotions': 'প্রমোশন',
      'flash_sales': 'ফ্ল্যাশ সেল',
      'success': 'সফল',
      'error': 'ত্রুটি',
      'loading': 'লোড হচ্ছে...',
      'no_data': 'কোন তথ্য নেই',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
