import 'package:flutter/services.dart';

Future<bool> launchExternalMapUrl(String url) async {
  const channel = MethodChannel('com.church.register/external_map');
  try {
    return await channel.invokeMethod<bool>('launchUrl', url) ?? false;
  } on PlatformException {
    return false;
  } on MissingPluginException {
    return false;
  }
}
