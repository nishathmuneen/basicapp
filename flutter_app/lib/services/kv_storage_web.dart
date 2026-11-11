import 'package:web/web.dart' as web;

bool get supportsNativeSqflite => false;

Future<String?> readLocalStore(String key) async {
  return web.window.localStorage.getItem(key);
}

Future<void> writeLocalStore(String key, String value) async {
  web.window.localStorage.setItem(key, value);
}

