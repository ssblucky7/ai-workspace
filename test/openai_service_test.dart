import 'package:flutter_test/flutter_test.dart';

import 'package:ai_workspace/services/openai_compatible_chat_service.dart';

void main() {
  group('OpenAICompatibleChatService', () {
    final service = OpenAICompatibleChatService();

    group('normalizeBaseUrl', () {
      test('strips trailing slashes', () {
        expect(
          service.normalizeBaseUrl('https://api.example.com/v1/'),
          'https://api.example.com/v1',
        );
        expect(
          service.normalizeBaseUrl('https://api.example.com/v1///'),
          'https://api.example.com/v1',
        );
      });

      test('rejects non-http schemes and malformed URLs', () {
        expect(
          () => service.normalizeBaseUrl('ftp://x.dev'),
          throwsA(isA<Exception>()),
        );
        expect(
          () => service.normalizeBaseUrl('not a url'),
          throwsA(isA<Exception>()),
        );
      });

      test('trims whitespace', () {
        expect(
          service.normalizeBaseUrl('  https://api.example.com  '),
          'https://api.example.com',
        );
      });
    });

    group('parseChatCompletion', () {
      test('extracts the assistant content', () {
        const body = '''
          {
            "id": "chatcmpl-1",
            "choices": [
              {"message": {"role": "assistant", "content": "Hello there!"}}
            ]
          }
        ''';
        expect(service.parseChatCompletion(body), 'Hello there!');
      });

      test('throws on malformed JSON', () {
        expect(
          () => service.parseChatCompletion('{not json'),
          throwsA(isA<Exception>()),
        );
      });

      test('throws on missing or empty choices', () {
        expect(
          () => service.parseChatCompletion('{"choices": []}'),
          throwsA(isA<Exception>()),
        );
      });

      test('throws on unsupported structures', () {
        expect(
          () => service.parseChatCompletion('[1, 2, 3]'),
          throwsA(isA<Exception>()),
        );
        expect(
          () => service.parseChatCompletion('{"choices": [{"nope": 1}]}'),
          throwsA(isA<Exception>()),
        );
      });

      test('throws on empty assistant content', () {
        const body = '{"choices": [{"message": {"content": "  "}}]}';
        expect(
          () => service.parseChatCompletion(body),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('parseModels', () {
      test('parses the common {"data": [...]} format, dedupes, sorts', () {
        const body = '''
          {
            "data": [
              {"id": "zeta-model", "owned_by": "org"},
              {"id": "alpha-model"},
              {"id": "alpha-model"},
              {"id": ""}
            ]
          }
        ''';
        final models = service.parseModels(body);
        expect(models.length, 2, reason: 'duplicates and blanks removed');
        expect(models.first.id, 'alpha-model');
        expect(models.last.id, 'zeta-model');
        expect(models.first.ownedBy, isNull);
      });

      test('throws on unsupported formats', () {
        expect(
          () => service.parseModels('{"items": []}'),
          throwsA(isA<Exception>()),
        );
        expect(() => service.parseModels('[]'), throwsA(isA<Exception>()));
        expect(() => service.parseModels('nope'), throwsA(isA<Exception>()));
      });
    });
  });
}
