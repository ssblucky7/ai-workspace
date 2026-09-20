import 'package:flutter_test/flutter_test.dart';

import 'package:ai_workspace/core/utils/date_time_utils.dart';
import 'package:ai_workspace/models/ai_provider_config.dart';

void main() {
  group('DateTimeUtils.coerce', () {
    test('handles int millis', () {
      final result = DateTimeUtils.coerce(1700000000000);
      expect(result, DateTime.fromMillisecondsSinceEpoch(1700000000000));
    });

    test('handles ISO strings', () {
      final result = DateTimeUtils.coerce('2024-01-15T10:30:00Z');
      expect(result, isNotNull);
      expect(result!.year, 2024);
    });

    test('returns null for malformed values', () {
      expect(DateTimeUtils.coerce(null), isNull);
      expect(DateTimeUtils.coerce('not-a-date'), isNull);
      expect(DateTimeUtils.coerce(3.14), isNull);
    });
  });

  group('DateTimeUtils.formatTimestamp', () {
    final now = DateTime(2026, 9, 13, 14, 30);

    test('same-day shows time only', () {
      final sameDay = DateTime(2026, 9, 13, 9, 5);
      expect(DateTimeUtils.formatTimestamp(sameDay, now: now), '09:05');
    });

    test('same-year shows month and day', () {
      final sameYear = DateTime(2026, 3, 3, 8, 0);
      expect(DateTimeUtils.formatTimestamp(sameYear, now: now), 'Mar 3');
    });

    test('older shows full date', () {
      final older = DateTime(2024, 3, 3, 8, 0);
      expect(DateTimeUtils.formatTimestamp(older, now: now), 'Mar 3, 2024');
    });

    test('null renders Unknown', () {
      expect(DateTimeUtils.formatTimestamp(null), 'Unknown');
    });
  });

  group('AIProviderConfig serialization', () {
    final config = AIProviderConfig(
      id: 'p1',
      userId: 'uid-1',
      name: 'Test Provider',
      baseUrl: 'https://api.example.com/v1',
      apiKeyRef: 'api_key/uid-1/p1',
      selectedModel: 'gpt-test',
      temperature: 0.5,
      maxTokens: 512,
      isActive: true,
    );

    test('round-trips through toMap/fromMap', () {
      final restored = AIProviderConfig.fromMap(config.toMap(), id: 'p1');
      expect(restored.name, 'Test Provider');
      expect(restored.baseUrl, 'https://api.example.com/v1');
      expect(restored.apiKeyRef, 'api_key/uid-1/p1');
      expect(restored.temperature, 0.5);
      expect(restored.maxTokens, 512);
      expect(restored.isActive, isTrue);
    });

    test('int temperature coerces to double without throwing', () {
      final restored = AIProviderConfig.fromMap({
        'userId': 'uid-1',
        'name': 'n',
        'baseUrl': 'https://x.dev',
        'temperature': 1,
        'maxTokens': 256,
        'isActive': true,
      }, id: 'p2');
      expect(restored.temperature, 1.0);
      expect(restored.maxTokens, 256);
    });

    test('toFirestoreMap never contains a raw apiKey field', () {
      final map = config.toFirestoreMap();
      expect(
        map.containsKey('apiKey'),
        isFalse,
        reason: 'Raw API keys must never be written to Firestore',
      );
      expect(map['apiKeyRef'], 'api_key/uid-1/p1');
    });

    test('copyWith preserves untouched fields', () {
      final edited = config.copyWith(selectedModel: 'other-model');
      expect(edited.selectedModel, 'other-model');
      expect(edited.name, config.name);
      expect(edited.isActive, isTrue);
    });
  });
}
