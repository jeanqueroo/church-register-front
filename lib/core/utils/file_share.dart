import 'file_share_platform.dart'
    if (dart.library.html) 'file_share_web.dart'
    if (dart.library.io) 'file_share_io.dart';

/// Comparte un archivo CSV mediante el diálogo nativo del sistema.
Future<bool> shareCsvFile({
  required List<int> bytes,
  required String fileName,
  String? subject,
}) {
  return shareFile(
    bytes: bytes,
    fileName: fileName,
    mimeType: 'text/csv',
    subject: subject,
  );
}
