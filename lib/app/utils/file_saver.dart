import 'dart:typed_data';

import 'file_saver_io.dart' if (dart.library.html) 'file_saver_web.dart';

Future<bool> saveFileBytes({
  required String fileName,
  required String mimeType,
  required Uint8List bytes,
}) async {
  return saveFileBytesImpl(
    fileName: fileName,
    mimeType: mimeType,
    bytes: bytes,
  );
}
