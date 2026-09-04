import 'package:electrocitybd1/front_end/pages/home_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:electrocitybd1/front_end/All_Pages/CART/Cart_provider.dart';
import 'package:electrocitybd1/front_end/Provider/Admin_product_provider.dart';
import 'package:electrocitybd1/front_end/Provider/admin_theme_provider.dart';
import 'package:electrocitybd1/front_end/Provider/notification_provider.dart';
import 'package:electrocitybd1/front_end/Provider/api_ready_notifier.dart';
import 'package:electrocitybd1/front_end/Provider/product_refresh_notifier.dart';
import 'package:electrocitybd1/front_end/Provider/Banner_provider.dart';
import 'package:electrocitybd1/front_end/Provider/Orders_provider.dart';
import 'package:electrocitybd1/front_end/pages/Profiles/Wishlist_provider.dart';
import 'package:electrocitybd1/front_end/utils/auth_session.dart';
import 'package:electrocitybd1/front_end/utils/api_service.dart';
import 'package:electrocitybd1/front_end/utils/scroll_to_top_observer.dart';
import 'package:electrocitybd1/front_end/Provider/language_provider.dart';
import 'package:electrocitybd1/front_end/pages/Services/app_localizations.dart';
import 'package:electrocitybd1/config/app_config.dart';

// ignore: depend_on_referenced_packages
import 'dart:async' show unawaited;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Flutter framework error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('🔴 Flutter Error: ${details.exceptionAsString()}');
      debugPrint('Stack: ${details.stack}');
      debugPrint('═══════════════════════════════════════');
    }
  };

  // Catch async errors not caught by Flutter framework (e.g. in Futures/Isolates)
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('🔴 Unhandled async error: $error');
      debugPrint('Stack: $stack');
      debugPrint('═══════════════════════════════════════');
    }
    return true; // Prevent crash — error is handled
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ApiReadyNotifier()),
        ChangeNotifierProvider(create: (_) => ProductRefreshNotifier()),
        ChangeNotifierProvider(create: (_) => BannerProvider()),
        ChangeNotifierProvider(create: (_) => AdminProductProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => AdminThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _scrollObserver = ScrollToTopObserver();

  Future<void> _initApiBase() async {
    if (kIsWeb) {
      // Allow runtime override via ?api=http://... query param
      final apiOverride = Uri.base.queryParameters['api'];
      if (apiOverride != null && apiOverride.startsWith('http')) {
        ApiService.setBaseUrl(apiOverride);
        if (kDebugMode) debugPrint('✓ Web API URL (override): $apiOverride');
        return;
      }

      // Web browsers should not probe localhost unless explicitly overridden.
      // It creates noisy failed requests before falling back to production.
      ApiService.setBaseUrl(AppConfig.apiBaseUrl);
      if (kDebugMode) debugPrint('✓ Web API URL: ${AppConfig.apiBaseUrl}');
      return;
    }

    // Non-web: try configured URL first, then local fallbacks
    final candidates = <String>[
      AppConfig.apiBaseUrl,
      'http://10.0.2.2:8080/api',
      'http://localhost:8080/api',
    ];
    for (final base in candidates) {
      try {
        ApiService.setBaseUrl(base);
        await ApiService.get(
          '/health',
          withAuth: false,
        ).timeout(const Duration(seconds: 2));
        if (kDebugMode) debugPrint('✓ Connected to backend at $base');
        break;
      } catch (_) {
        continue;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await _initApiBase();
    } catch (_) {
      // API base probe failed — fall back to production URL (already set)
    }
    if (!mounted) return;

    // Signal widgets immediately so sections start loading in parallel
    context.read<ApiReadyNotifier>().markReady();
    unawaited(ApiService.prefetchHomeProducts());

    // Init cart, wishlist, banners, orders all in parallel (non-blocking)
    unawaited(context.read<CartProvider>().init());
    unawaited(context.read<WishlistProvider>().init());
    unawaited(context.read<BannerProvider>().load());

    try {
      final userData = await AuthSession.getUserData();
      if (!mounted) return;
      unawaited(
        context.read<OrdersProvider>().init(userId: userData?.email ?? ''),
      );
    } catch (_) {
      if (mounted) {
        unawaited(context.read<OrdersProvider>().init(userId: ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bp = context.watch<BannerProvider>();
    final languageProvider = context.watch<LanguageProvider>();

    return MaterialApp(
      title: 'ElectroZoneBD',
      debugShowCheckedModeBanner: false,
      locale: languageProvider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        textTheme: ThemeData.light().textTheme,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.dark,
        ),
        textTheme: ThemeData.dark().textTheme,
        useMaterial3: true,
        dialogBackgroundColor: const Color(0xFF2A2A2A),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF2A2A2A),
          surfaceTintColor: Colors.transparent,
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: const Color(0xFF2A2A2A),
          surfaceTintColor: Colors.transparent,
          headerBackgroundColor: const Color(0xFF7C3AED),
          headerForegroundColor: Colors.white,
          dayForegroundColor: WidgetStateProperty.all(Colors.white),
          yearForegroundColor: WidgetStateProperty.all(Colors.white70),
          weekdayStyle: const TextStyle(color: Colors.white70),
        ),
        timePickerTheme: TimePickerThemeData(
          backgroundColor: const Color(0xFF2A2A2A),
          hourMinuteTextColor: Colors.white,
          dayPeriodTextColor: Colors.white,
        ),
      ),
      navigatorObservers: [_scrollObserver],
      home: HomePage(),
    );
  }
}
