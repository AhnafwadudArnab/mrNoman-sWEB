// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

void resetBrowserScroll() {
  html.window.scrollTo(0, 0);
  html.document.documentElement?.scrollTop = 0;
  html.document.body?.scrollTop = 0;
}
