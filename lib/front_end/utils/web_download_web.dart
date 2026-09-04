// Web implementation using dart:html
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

void downloadTextOnWeb(
  String text,
  String filename, {
  String mimeType = 'text/plain;charset=utf-8',
}) {
  final bytes = utf8.encode(text);
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

void downloadCsvOnWeb(String csv, String filename) {
  downloadTextOnWeb(csv, filename, mimeType: 'text/csv;charset=utf-8');
}









