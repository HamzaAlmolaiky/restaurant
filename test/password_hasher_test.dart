import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant/app/helpers/password_hasher.dart';

void main() {
  group('PasswordHasher', () {
    test('hashes passwords without storing the plain value', () {
      final hashed = PasswordHasher.hash('secret123');

      expect(hashed, isNot('secret123'));
      expect(PasswordHasher.isHashed(hashed), isTrue);
    });

    test('verifies hashed passwords', () {
      final hashed = PasswordHasher.hash('secret123');

      expect(PasswordHasher.verify('secret123', hashed), isTrue);
      expect(PasswordHasher.verify('wrong', hashed), isFalse);
    });

    test('keeps legacy plain-text verification for migration', () {
      expect(PasswordHasher.verify('legacy', 'legacy'), isTrue);
      expect(PasswordHasher.verify('wrong', 'legacy'), isFalse);
    });
  });
}
