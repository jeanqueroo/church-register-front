// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<bool> launchExternalMapUrl(String url) async {
  html.window.open(url, '_blank');
  return true;
}
