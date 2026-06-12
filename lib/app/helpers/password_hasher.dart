import 'dart:convert';

import 'package:crypto/crypto.dart';

class PasswordHasher {
  PasswordHasher._();

  static const _prefix = r'sha256$';

  static bool isHashed(String value) => value.startsWith(_prefix);

  static String hash(String password) {
    final digest = sha256.convert(utf8.encode(password));
    return '$_prefix$digest';
  }

  static bool verify(String password, String storedValue) {
    if (!isHashed(storedValue)) {
      return password == storedValue;
    }
    return hash(password) == storedValue;
  }
}
