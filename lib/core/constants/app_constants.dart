/// Application-wide constants for AI Workspace.
class AppConstants {
  AppConstants._();

  static const String appName = 'AI Workspace';
  static const String appVersion = '1.0.0+1';
  static const String appTagline = 'Your space for AI-assisted conversations.';

  // Validation bounds.
  static const int passwordMinLength = 6;
  static const int passwordMaxLength = 128;
  static const int fullNameMinLength = 2;
  static const int fullNameMaxLength = 64;
  static const int titleMaxLength = 120;
  static const int messageMaxLength = 32000;
  static const int lastMessagePreviewLength = 4000;
  static const int providerNameMaxLength = 60;
  static const int baseUrlMaxLength = 300;
  static const int modelIdMaxLength = 120;
  static const int organizationIdMaxLength = 64;

  static const double minTemperature = 0;
  static const double maxTemperature = 2;
  static const int minMaxTokens = 16;
  static const int maxMaxTokens = 200000;
  static const double defaultTemperature = 0.7;
  static const int defaultMaxTokens = 1024;

  // Networking.
  static const Duration aiRequestTimeout = Duration(seconds: 60);
  static const int aiModelFetchMaxAttempts = 2;

  // Firestore writes are limited to 500 operations per batch; stay well below.
  static const int firestoreDeleteBatchSize = 400;

  static const String defaultConversationTitle = 'New Conversation';
  static const int derivedTitleMaxLength = 42;

  /// Number of trailing messages sent to the AI provider as conversation
  /// context. Keeps request payloads bounded for long conversations.
  static const int aiHistoryMessageLimit = 30;

  /// Suggestions shown in an empty chat to help the user get started.
  static const List<String> chatSuggestions = [
    'Explain a concept in simple terms',
    'Draft a professional email',
    'Brainstorm ideas for a project',
    'Summarize my notes into bullet points',
  ];

  /// Advanced capabilities intentionally out of scope for the assignment
  /// version. Shown as "Coming soon" in the About screen and documented in
  /// the README under Future Enhancements.
  static const List<String> futureEnhancements = [
    'Image generation',
    'Audio and video generation',
    'Real-time AI voice or video calls',
    'Internet searching',
    'Web scraping',
    'MCP server integration and custom tools',
    'Custom skills',
    'Tool calling',
    'Document analysis (PDF / Word)',
    'Multi-agent workflows',
    'Local AI models',
    'Retrieval-augmented generation (RAG)',
    'File attachments',
  ];
}
