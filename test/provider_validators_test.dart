import 'package:flutter_test/flutter_test.dart';

import 'package:ai_workspace/core/utils/validators.dart';

void main() {
  group('Validators.validateBaseUrl', () {
    test('accepts https URLs', () {
      expect(Validators.validateBaseUrl('https://api.example.com/v1'), isNull);
    });

    test('accepts localhost http for development', () {
      expect(Validators.validateBaseUrl('http://localhost:8080/v1'), isNull);
      expect(Validators.validateBaseUrl('http://127.0.0.1:3000'), isNull);
    });

    test('rejects plain http on remote hosts', () {
      final error = Validators.validateBaseUrl('http://api.example.com/v1');
      expect(error, contains('HTTPS'));
    });

    test('rejects empty or malformed input', () {
      expect(Validators.validateBaseUrl(''), isNotNull);
      expect(Validators.validateBaseUrl('not a url'), isNotNull);
      expect(Validators.validateBaseUrl('ftp://example.com'), isNotNull);
    });
  });

  group('Validators provider field validators', () {
    test('provider name', () {
      expect(Validators.validateProviderName('My Provider'), isNull);
      expect(Validators.validateProviderName(''), isNotNull);
    });

    test('api key presence', () {
      expect(Validators.validateApiKey('sk-abc123'), isNull);
      expect(Validators.validateApiKey(''), equals('API key is required.'));
      expect(Validators.validateApiKey('', allowEmpty: true), isNull);
    });

    test('model id', () {
      expect(Validators.validateModelId('gpt-4o-mini'), isNull);
      expect(Validators.validateModelId(''), isNotNull);
    });

    test('temperature range', () {
      expect(Validators.validateTemperature('0.7'), isNull);
      expect(Validators.validateTemperature('2'), isNull);
      expect(Validators.validateTemperature('abc'), isNotNull);
      expect(Validators.validateTemperature('2.5'), isNotNull);
      expect(Validators.validateTemperature('-0.1'), isNotNull);
    });

    test('max tokens range', () {
      expect(Validators.validateMaxTokens('1024'), isNull);
      expect(Validators.validateMaxTokens('16'), isNull);
      expect(Validators.validateMaxTokens('abc'), isNotNull);
      expect(Validators.validateMaxTokens('8'), isNotNull);
    });

    test('organization id optional', () {
      expect(Validators.validateOrganizationId(''), isNull);
      expect(Validators.validateOrganizationId('org-123'), isNull);
      expect(Validators.validateOrganizationId('has space'), isNotNull);
    });
  });
}
