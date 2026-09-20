import '../models/ai_model_info.dart';
import '../models/chat_message.dart';

/// Abstraction over an AI chat backend, so the UI and providers depend on
/// an interface rather than a concrete HTTP client. Simplifies testing and
/// allows alternate backends later.
abstract class ChatService {
  /// Sends [messages] to the configured model and returns the assistant's
  /// reply text.
  ///
  /// Throws [AIRequestException] (via the implementation) for any failure —
  /// always with user-safe messages that never embed the API key.
  Future<String> sendChat({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<ChatMessage> messages,
    double? temperature,
    int? maxTokens,
    String? organizationId,
  });

  /// Fetches the list of models exposed by the provider.
  Future<List<AIModelInfo>> fetchModels({
    required String baseUrl,
    required String apiKey,
    String? organizationId,
  });

  /// Lightweight connectivity/credential check.
  Future<bool> testConnection({
    required String baseUrl,
    required String apiKey,
    String? organizationId,
  });
}
