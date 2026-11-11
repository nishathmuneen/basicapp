import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class PasswordHasher {
  static const int _iterations = 5000;

  static String hashPassword(String password) {
    final random = Random.secure();
    final saltBytes = List<int>.generate(16, (_) => random.nextInt(256));
    final saltHex = _toHex(saltBytes);
    final digestHex = _derive(password, saltBytes, _iterations);
    return 'hmac_sha256\$$_iterations\$$saltHex\$$digestHex';
  }

  static bool verifyPassword(String password, String storedHash) {
    final parts = storedHash.split('\$');
    if (parts.length != 4 || parts[0] != 'hmac_sha256') return false;
    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations <= 0) return false;
    final saltBytes = _fromHex(parts[2]);
    if (saltBytes == null) return false;
    final candidateHex = _derive(password, saltBytes, iterations);
    return _constantTimeEquals(candidateHex, parts[3]);
  }

  static String _derive(String password, List<int> saltBytes, int iterations) {
    final key = utf8.encode(password);
    final hmac = Hmac(sha256, key);
    var state = hmac.convert(saltBytes).bytes;
    for (var i = 1; i < iterations; i++) {
      state = hmac.convert(state).bytes;
    }
    return _toHex(state);
  }

  static String _toHex(List<int> bytes) {
    final sb = StringBuffer();
    for (final b in bytes) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }

  static List<int>? _fromHex(String hex) {
    if (hex.length.isOdd) return null;
    final out = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      final byte = int.tryParse(hex.substring(i, i + 2), radix: 16);
      if (byte == null) return null;
      out.add(byte);
    }
    return out;
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}

