import 'package:flutter/material.dart';

import 'browser_scroll_reset_stub.dart'
    if (dart.library.html) 'browser_scroll_reset_web.dart';

class ScrollToTopObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _resetSoon();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _resetSoon();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _resetSoon();
  }

  void _resetSoon() {
    resetBrowserScroll();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      resetBrowserScroll();
      _resetPrimaryScroll();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        resetBrowserScroll();
        _resetPrimaryScroll();
      });
    });
  }

  void _resetPrimaryScroll() {
    final context = navigator?.overlay?.context ?? navigator?.context;
    if (context == null) return;
    final controller = PrimaryScrollController.maybeOf(context);
    if (controller == null || !controller.hasClients) return;
    for (final position in List<ScrollPosition>.from(controller.positions)) {
      if (position.hasPixels && position.pixels != 0) {
        position.jumpTo(0);
      }
    }
  }
}









