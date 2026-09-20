import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../models/ai_model_info.dart';
import '../models/chat_message.dart';
import 'chat_service.dart';

/// OpenAI-compatible chat adapter.
///
/// Targets the de-facto standard `/chat/completions` + `/models` endpoints
/// implemented by many vendors. Provider-specific request or response
/// variations may require a dedicated adapter — see README.md ("Known
/// limitations") — but the common format covers most OpenAI-compatible
/// services.
class OpenAICompatibleChatService implements ChatService {
  OpenAICompatibleChatService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// Normalizes a user-provided base URL: trims, strips trailing slashes,
  /// and validates the HTTP/HTTPS scheme.
  @visibleForTesting
  String normalizeBaseUrl(String raw) {
    var url = raw.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.isAbsolute) {
      throw const AIRequestException(
        'The provider base URL is invalid.',
        type: AIRequestFailureType.invalidBaseUrl,
      );
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw const AIRequestException(
        'Only HTTP or HTTPS base URLs are supported.',
        type: AIRequestFailureType.invalidBaseUrl,
      );
    }
    return url;
  }

  Map<String, String> _headers(String apiKey, String? organizationId) => {
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
    if (organizationId != null && organizationId.trim().isNotEmpty)
      'OpenAI-Organization': organizationId.trim(),
  };

  @override
  Future<String> sendChat({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<ChatMessage> messages,
    double? temperature,
    int? maxTokens,
    String? organizationId,
  }) async {
    final normalizedBase = normalizeBaseUrl(baseUrl);
    final history = messages.length > AppConstants.aiHistoryMessageLimit
        ? messages.sublist(messages.length - AppConstants.aiHistoryMessageLimit)
        : messages;

    final response = await _request(
      () => _client.post(
        Uri.parse('$normalizedBase/chat/completions'),
        headers: _headers(apiKey, organizationId),
        body: jsonEncode({
          'model': model,
          'messages': [
            for (final m in history)
              {'role': m.role.name, 'content': m.content},
          ],
          'temperature': temperature,
          'max_tokens': maxTokens,
        }),
      ),
    );

    return parseChatCompletion(response);
  }

  @visibleForTesting
  String parseChatCompletion(String responseBody) {
    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        throw const AIRequestException(
          'The provider returned an unsupported response format.',
          type: AIRequestFailureType.unsupportedResponseFormat,
        );
      }
      json = decoded;
    } on FormatException {
      throw const AIRequestException(
        'The provider returned a malformed response.',
        type: AIRequestFailureType.malformedResponse,
      );
    }

    final choices = json['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const AIRequestException(
        'The provider returned an empty response.',
        type: AIRequestFailureType.emptyResponse,
      );
    }
    final first = choices.first;
    if (first is! Map<String, dynamic>) {
      throw const AIRequestException(
        'The provider returned an unsupported response format.',
        type: AIRequestFailureType.unsupportedResponseFormat,
      );
    }
    final message = first['message'];
    if (message is! Map<String, dynamic>) {
      throw const AIRequestException(
        'The provider returned an unsupported response format.',
        type: AIRequestFailureType.unsupportedResponseFormat,
      );
    }
    final content = message['content'];
    if (content is! String || content.trim().isEmpty) {
      throw const AIRequestException(
        'The model returned an empty response.',
        type: AIRequestFailureType.emptyResponse,
      );
    }
    return content;
  }

  @override
  Future<List<AIModelInfo>> fetchModels({
    required String baseUrl,
    required String apiKey,
    String? organizationId,
  }) async {
    final normalizedBase = normalizeBaseUrl(baseUrl);
    final response = await _request(
      () => _client.get(
        Uri.parse('$normalizedBase/models'),
        headers: _headers(apiKey, organizationId),
      ),
    );
    return parseModels(response);
  }

  /// Parser kept public for unit tests; supports the common `{"data": [...]}`
  /// wrapper and tolerates extra fields.
  @visibleForTesting
  List<AIModelInfo> parseModels(String responseBody) {
    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        throw const AIRequestException(
          'The provider returned an unsupported model-list format.',
          type: AIRequestFailureType.unsupportedResponseFormat,
        );
      }
      json = decoded;
    } on FormatException {
      throw const AIRequestException(
        'The provider returned a malformed model list.',
        type: AIRequestFailureType.malformedResponse,
      );
    }

    final data = json['data'];
    if (data is! List) {
      throw const AIRequestException(
        'The provider returned an unsupported model-list format.',
        type: AIRequestFailureType.unsupportedResponseFormat,
      );
    }

    final models = <AIModelInfo>[];
    for (final entry in data) {
      if (entry is! Map) continue;
      final map = entry.map((k, v) => MapEntry(k.toString(), v));
      final id = map['id'];
      if (id is! String || id.trim().isEmpty) continue;
      final model = AIModelInfo.fromMap(map);
      if (models.any((m) => m.id == model.id)) continue; // de-duplicate
      models.add(model);
    }
    models.sort((a, b) => a.id.toLowerCase().compareTo(b.id.toLowerCase()));
    return models;
  }

  @visibleForTesting
  List<AIModelInfo> parseModelsFromRawList(String responseBody) {
    final decoded = jsonDecode(responseBody);
    if (decoded is! List) {
      throw const AIRequestException(
        'The provider returned an unsupported model-list format.',
        type: AIRequestFailureType.unsupportedResponseFormat,
      );
    }
    return _dedupeAndSort(
      decoded.whereType<Map>().map(
        (m) => AIModelInfo.fromMap(m.map((k, v) => MapEntry(k.toString(), v))),
      ),
    );
  }

  List<AIModelInfo> _dedupeAndSort(Iterable<AIModelInfo> source) {
    final models = <String, AIModelInfo>{};
    for (final m in source) {
      models.putIfAbsent(m.id, () => m);
    }
    final list = models.values.toList()
      ..sort((a, b) => a.id.toLowerCase().compareTo(b.id.toLowerCase()));
    return list;
  }

  @override
  Future<bool> testConnection({
    required String baseUrl,
    required String apiKey,
    String? organizationId,
  }) async {
    try {
      await fetchModels(
        baseUrl: baseUrl,
        apiKey: apiKey,
        organizationId: organizationId,
      );
      return true;
    } on AIRequestException catch (error) {
      if (error.type == AIRequestFailureType.unauthorized ||
          error.type == AIRequestFailureType.forbidden) {
        rethrow;
      }
      // Unreachable host / bad URL surfaces as a failed test, not a crash.
      if (error.type == AIRequestFailureType.invalidBaseUrl) rethrow;
      rethrow;
    }
  }
}

/// Central request wrapper: timeout, HTTP-status mapping, and network error
/// translation — all producing user-safe messages without the API key.
Future<String> _request(Future<http.Response> Function() send) async {
  try {
    final response = await send().timeout(AppConstants.aiRequestTimeout);
    return _mapStatusToBody(response);
  } on TimeoutException {
    throw const AIRequestException(
      'The AI request timed out. Please try again.',
      type: AIRequestFailureType.timeout,
    );
  } on AIRequestException {
    rethrow;
  } on http.ClientException catch (error) {
    throw AIRequestException(
      'Could not reach the AI provider. Check the base URL and your network.',
      type: AIRequestFailureType.network,
      cause: error,
    );
  } catch (error) {
    throw AIRequestException(
      'The AI request failed. Please try again.',
      type: AIRequestFailureType.unknown,
      cause: error,
    );
  }
}

Future<String> _mapStatusToBody(http.Response response) async {
  switch (response.statusCode ~/ 100) {
    case 2:
      return response.body;
    case 4:
      switch (response.statusCode) {
        case 401:
          throw const AIRequestException(
            'The provider rejected the API key (unauthorized).',
            type: AIRequestFailureType.unauthorized,
          );
        case 403:
          throw const AIRequestException(
            'The provider denied access to this model.',
            type: AIRequestFailureType.forbidden,
          );
        case 429:
          throw const AIRequestException(
            'The provider rate limit was hit. Please wait and try again.',
            type: AIRequestFailureType.rateLimited,
          );
        default:
          throw const AIRequestException(
            'The provider rejected the request. Verify the configuration.',
            type: AIRequestFailureType.unknown,
          );
      }
    default:
      throw const AIRequestException(
        'The AI provider had a server error. Please try again later.',
        type: AIRequestFailureType.serverError,
      );
  }
}
