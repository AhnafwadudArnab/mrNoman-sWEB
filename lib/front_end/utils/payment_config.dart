import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PaymentConfig {
  final bool bkashEnabled;
  final bool nagadEnabled;
  final bool rocketEnabled;
  final bool upayEnabled;
  final String bkashNumber;
  final String nagadNumber;
  final String rocketNumber;
  final String upayNumber;

  const PaymentConfig({
    this.bkashEnabled = true,
    this.nagadEnabled = true,
    this.rocketEnabled = true,
    this.upayEnabled = true,
    this.bkashNumber = '',
    this.nagadNumber = '',
    this.rocketNumber = '',
    this.upayNumber = '',
  });

  PaymentConfig copyWith({
    bool? bkashEnabled,
    bool? nagadEnabled,
    bool? rocketEnabled,
    bool? upayEnabled,
    String? bkashNumber,
    String? nagadNumber,
    String? rocketNumber,
    String? upayNumber,
  }) {
    return PaymentConfig(
      bkashEnabled: bkashEnabled ?? this.bkashEnabled,
      nagadEnabled: nagadEnabled ?? this.nagadEnabled,
      rocketEnabled: rocketEnabled ?? this.rocketEnabled,
      upayEnabled: upayEnabled ?? this.upayEnabled,
      bkashNumber: bkashNumber ?? this.bkashNumber,
      nagadNumber: nagadNumber ?? this.nagadNumber,
      rocketNumber: rocketNumber ?? this.rocketNumber,
      upayNumber: upayNumber ?? this.upayNumber,
    );
  }

  Map<String, dynamic> toJson() => {
    'bkashEnabled': bkashEnabled,
    'nagadEnabled': nagadEnabled,
    'rocketEnabled': rocketEnabled,
    'upayEnabled': upayEnabled,
    'bkashNumber': bkashNumber,
    'nagadNumber': nagadNumber,
    'rocketNumber': rocketNumber,
    'upayNumber': upayNumber,
  };

  static PaymentConfig fromJson(Map<String, dynamic> json) => PaymentConfig(
    bkashEnabled: (json['bkashEnabled'] as bool?) ?? true,
    nagadEnabled: (json['nagadEnabled'] as bool?) ?? true,
    rocketEnabled: (json['rocketEnabled'] as bool?) ?? true,
    upayEnabled: (json['upayEnabled'] as bool?) ?? true,
    bkashNumber: (json['bkashNumber'] as String?) ?? '',
    nagadNumber: (json['nagadNumber'] as String?) ?? '',
    rocketNumber: (json['rocketNumber'] as String?) ?? '',
    upayNumber: (json['upayNumber'] as String?) ?? '',
  );
}

class PaymentConfigStore {
  static const _key = 'electrocity_payment_config';

  static Future<PaymentConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const PaymentConfig();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return PaymentConfig.fromJson(map);
    } catch (_) {
      return const PaymentConfig();
    }
  }

  static Future<void> save(PaymentConfig cfg) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(cfg.toJson()));
  }
}









