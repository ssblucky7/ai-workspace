import 'package:flutter_test/flutter_test.dart';

import 'package:ai_workspace/core/utils/validators.dart';
import 'package:ai_workspace/services/secure_storage_service.dart';

void main() {
  group('Provider configuration validation', () {
    // Validates the same shared validators the service layer applies,
    // without touching Firestore (no Firebase app required in tests).
    test('valid configuration passes all validators', () {
      expect(Validators.validateProviderName('My Provider'), isNull);
      expect(Validators.validateBaseUrl('https://api.example.com/v1'), isNull);
      expect(Validators.validateApiKey('sk-test'), isNull);
      expect(Validators.validateModelId('gpt-test'), isNull);
      expect(Validators.validateOrganizationId('org-1'), isNull);
    });

    test('collects every field error', () {
      expect(Validators.validateProviderName(''), isNotNull);
      expect(Validators.validateBaseUrl('not-a-url'), isNotNull);
      expect(Validators.validateApiKey(''), isNotNull);
      expect(Validators.validateModelId(''), isNotNull);
      expect(Validators.validateOrganizationId('has space'), isNotNull);
    });

    test('accepts localhost http URLs for local development', () {
      expect(Validators.validateBaseUrl('http://localhost:11434/v1'), isNull);
    });
  });

  group('SecureStorageService.apiKeyRef', () {
    test('builds per-user, per-provider references', () {
      expect(SecureStorageService.apiKeyRef('uid-1', 'p1'), 'api_key/uid-1/p1');
      // Distinct users and providers never collide.
      expect(
        SecureStorageService.apiKeyRef('uid-1', 'p1') !=
            SecureStorageService.apiKeyRef('uid-2', 'p1'),
        isTrue,
      );
    });
  });
}
