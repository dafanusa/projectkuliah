import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

Future<bool> saveFileBytesImpl({
  required String fileName,
  required String mimeType,
  required Uint8List bytes,
}) async {
  final location = await getSaveLocation(suggestedName: fileName);
  if (location == null) {
    return false;
  }
  final file = XFile.fromData(
    bytes,
    name: fileName,
    mimeType: mimeType,
  );
  await file.saveTo(location.path);
  return true;
}
