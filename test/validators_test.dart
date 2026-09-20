import 'package:flutter_test/flutter_test.dart';

import 'package:ai_workspace/core/utils/validators.dart';

void main() {
  group('Validators.validateEmail', () {
    test('accepts valid addresses', () {
      expect(Validators.validateEmail('user@example.com'), isNull);
      expect(Validators.validateEmail('  first.last@sub.domain.io  '), isNull);
    });

    test('rejects empty input', () {
      expect(
        Validators.validateEmail(''),
        equals('Please enter your email address.'),
      );
      expect(Validators.validateEmail('   '), isNotNull);
      expect(Validators.validateEmail(null), isNotNull);
    });

    test('rejects malformed addresses', () {
      expect(Validators.validateEmail('plainaddress'), isNotNull);
      expect(Validators.validateEmail('a@b'), isNotNull);
      expect(Validators.validateEmail('missing@domain'), isNotNull);
      expect(Validators.validateEmail('@domain.com'), isNotNull);
    });
  });

  group('Validators.validatePassword', () {
    test('accepts passwords of at least 6 characters', () {
      expect(Validators.validatePassword('123456'), isNull);
      expect(Validators.validatePassword('a longer password 9!'), isNull);
    });

    test('rejects short or empty passwords', () {
      expect(Validators.validatePassword('12345'), isNotNull);
      expect(Validators.validatePassword(''), isNotNull);
    });
  });

  group('Validators.validatePasswordConfirmation', () {
    test('matches', () {
      expect(
        Validators.validatePasswordConfirmation('secret1', 'secret1'),
        isNull,
      );
    });

    test('mismatch and empty', () {
      expect(
        Validators.validatePasswordConfirmation('secret1', 'secret2'),
        equals('Passwords do not match.'),
      );
      expect(Validators.validatePasswordConfirmation('', 'secret2'), isNotNull);
    });
  });

  group('Validators.validateFullName', () {
    test('accepts real names', () {
      expect(Validators.validateFullName('Ada Lovelace'), isNull);
      expect(Validators.validateFullName('  Suresh  '), isNull);
    });

    test('rejects empty or letter-less input', () {
      expect(Validators.validateFullName(''), isNotNull);
      expect(Validators.validateFullName('12345'), isNotNull);
      expect(Validators.validateFullName('a'), isNotNull);
    });
  });
}
