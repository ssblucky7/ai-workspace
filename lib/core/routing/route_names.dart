/// Centralized route names and paths (single source of truth).
abstract final class RouteNames {
  // Names.
  static const String splash = 'splash';
  static const String signIn = 'sign-in';
  static const String signUp = 'sign-up';
  static const String forgotPassword = 'forgot-password';
  static const String home = 'home';
  static const String chat = 'chat';
  static const String conversationHistory = 'conversation-history';
  static const String aiProviders = 'ai-providers';
  static const String addEditProvider = 'add-edit-provider';
  static const String modelSelection = 'model-selection';
  static const String settings = 'settings';
  static const String profile = 'profile';
  static const String about = 'about';

  // Paths.
  static const String splashPath = '/splash';
  static const String signInPath = '/sign-in';
  static const String signUpPath = '/sign-up';
  static const String forgotPasswordPath = '/forgot-password';
  static const String homePath = '/home';
  static const String conversationHistoryPath = '/conversations';
  static const String aiProvidersPath = '/providers';
  static const String addEditProviderPath = '/providers/edit';
  static const String modelSelectionPath = '/providers/model-selection';
  static const String settingsPath = '/settings';
  static const String profilePath = '/profile';
  static const String aboutPath = '/about';

  /// Router route pattern for a conversation chat view.
  static const String chatPath = '/chat/:conversationId';

  /// Chat route path builder. `new` starts a brand-new conversation.
  static String chatRoutePath(String conversationId) => '/chat/$conversationId';
  static const String newChatPath = '/chat/new';
}
