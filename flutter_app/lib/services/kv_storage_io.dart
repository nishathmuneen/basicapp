import 'dart:io';

import 'package:path/path.dart' as p;

bool get supportsNativeSqflite =>
    Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

File _storeFile(String key) {
  final baseDir = Platform.environment['APPDATA'] ??
      Platform.environment['XDG_DATA_HOME'] ??
      Platform.environment['HOME'] ??
      Directory.systemTemp.path;
  return File(p.join(baseDir, 'MyHealthTracker', '$key.json'));
}

Future<String?> readLocalStore(String key) async {
  final file = _storeFile(key);
  if (!await file.exists()) return null;
  return file.readAsString();
}

Future<void> writeLocalStore(String key, String value) async {
  final file = _storeFile(key);
  await file.parent.create(recursive: true);
  await file.writeAsString(value);
}

