import 'package:flutter_test/flutter_test.dart';

import 'package:ai_workspace/core/utils/api_key_masker.dart';

void main() {
  group('ApiKeyMasker.mask', () {
    test('shows only prefix and last 4 characters', () {
      final masked = ApiKeyMasker.mask('sk-abcdefghijklmnop1234');
      expect(masked, 'sk-••••••1234');
      expect(masked.contains('abcdefghijklmnop'), isFalse);
    });

    test('fully masks short keys', () {
      expect(ApiKeyMasker.mask('short'), '•••••');
    });

    test('handles null and empty', () {
      expect(ApiKeyMasker.mask(null), 'No key saved');
      expect(ApiKeyMasker.mask(''), 'No key saved');
    });

    test('never reveals the middle of a long key', () {
      const key = 'sk-prod-do-not-leak-this-secret-9988';
      final masked = ApiKeyMasker.mask(key);
      expect(masked, 'sk-••••••9988');
      expect(masked.contains('secret'), isFalse);
      expect(masked.contains('leak'), isFalse);
    });
  });
}
