import 'package:flutter/material.dart';

class NavigationHelper {
  /// Navigate to a new page
  static Future<void> navigateTo(BuildContext context, Widget page) {
    return Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  /// Replace current page
  static Future<void> replaceTo(BuildContext context, Widget page) {
    return Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  /// Go back
  static void goBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  /// Go to home (clear stack)
  static Future<void> goHome(BuildContext context, Widget homePage) {
    return Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => homePage),
      (route) => false,
    );
  }
}
