import 'package:flutter/services.dart';

Future<bool> shareFile({
  required List<int> bytes,
  required String fileName,
  required String mimeType,
  String? subject,
}) async {
  const channel = MethodChannel('com.church.register/file_share');
  try {
    return await channel.invokeMethod<bool>('shareFile', {
      'bytes': bytes,
      'fileName': fileName,
      'mimeType': mimeType,
      'subject': subject ?? '',
    }) ??
        false;
  } on PlatformException {
    return false;
  } on MissingPluginException {
    return false;
  }
}
