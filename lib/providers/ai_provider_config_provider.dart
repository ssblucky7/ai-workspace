import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../models/ai_provider_config.dart';
import '../models/ai_model_info.dart';
import '../services/chat_service.dart';
import '../services/provider_config_service.dart';

/// State for the user's AI provider configurations.
///
/// Firestore metadata stream + secure-storage secret lookup + active
/// provider selection, with loading/error tracking for connection tests
/// and model fetching.
class AIProviderConfigProvider extends ChangeNotifier {
  AIProviderConfigProvider({
    required this._service,
    required this._chatService,
  });

  final ProviderConfigService _service;
  final ChatService _chatService;

  StreamSubscription<List<AIProviderConfig>>? _providersSub;
  String? _subscribedUid;

  List<AIProviderConfig> _providers = [];
  List<AIProviderConfig> get providers => _providers;

  /// The provider flagged `isActive` in Firestore, if any.
  AIProviderConfig? get activeProvider =>
      _providers.where((p) => p.isActive).firstOrNull;

  bool _loading = true;
  bool get loading => _loading;

  bool _busy = false;
  bool get busy => _busy;

  String? _error;
  String? get error => _error;

  List<AIModelInfo> _fetchedModels = [];
  List<AIModelInfo> get fetchedModels => _fetchedModels;

  bool _fetchingModels = false;
  bool get fetchingModels => _fetchingModels;

  void startListening(String uid) {
    if (_subscribedUid == uid) return;
    _subscribedUid = uid;
    _providersSub?.cancel();
    _loading = true;
    _error = null;
    notifyListeners();
    _providersSub = _service
        .watchProviders(uid: uid)
        .listen(
          (providers) {
            _providers = providers;
            _loading = false;
            _error = null;
            notifyListeners();
          },
          onError: (Object error) {
            _loading = false;
            _error = _safeMessage(error);
            notifyListeners();
          },
        );
  }

  /// Clears all user-scoped state (sign-out).
  void clearState() {
    _providersSub?.cancel();
    _providersSub = null;
    _subscribedUid = null;
    _providers = [];
    _loading = true;
    _busy = false;
    _error = null;
    _fetchedModels = [];
    _fetchingModels = false;
    notifyListeners();
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  void clearFetchedModels() {
    if (_fetchedModels.isNotEmpty || _fetchingModels) {
      _fetchedModels = [];
      _fetchingModels = false;
      notifyListeners();
    }
  }

  /// Loads the raw API key for [provider] from secure storage.
  Future<String?> getApiKeyFor(AIProviderConfig provider) =>
      _service.getApiKey(provider);

  /// Saves a provider configuration. When [apiKey] is null/empty, the
  /// previously stored key is preserved (edit flow without re-entering it).
  Future<bool> saveProvider({
    required String uid,
    required AIProviderConfig provider,
    String? apiKey,
  }) async {
    if (_busy) return false;
    _busy = true;
    _error = null;
    notifyListeners();
    debugPrint('AIProviderConfigProvider.saveProvider: uid=$uid, provider.id=${provider.id}, apiKey=${apiKey != null ? "provided (len=${apiKey.length})" : "null"}');
    try {
      // Exactly one active provider: deactivate any other currently
      // flagged active before saving this one.
      if (provider.isActive) {
        for (final other in _providers) {
          if (other.isActive && other.id != provider.id) {
            await _service.saveProvider(
              provider: other.copyWith(isActive: false),
            );
          }
        }
      }
      await _service.saveProvider(provider: provider, apiKey: apiKey);
      return true;
    } on AppException catch (error) {
      _error = error.message;
      return false;
    } catch (error) {
      _error = _safeMessage(error);
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Deletes a provider together with its secure-storage key.
  Future<bool> deleteProvider({required AIProviderConfig provider}) async {
    if (_busy) return false;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteProvider(provider: provider);
      return true;
    } on AppException catch (error) {
      _error = error.message;
      return false;
    } catch (error) {
      _error = _safeMessage(error);
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Selects which provider is active.
  Future<bool> selectActiveProvider({
    required String uid,
    required String providerId,
  }) async {
    _error = null;
    try {
      await _service.setActiveProvider(uid: uid, providerId: providerId);
      return true;
    } on AppException catch (error) {
      _error = error.message;
      return false;
    } catch (error) {
      _error = _safeMessage(error);
      return false;
    }
  }

  /// Tests connectivity using the supplied credentials. Returns null on
  /// success or a user-safe error message.
  Future<String?> testConnection({
    required AIProviderConfig provider,
    required String apiKey,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final ok = await _service.testProviderConnection(
        provider: provider,
        apiKey: apiKey,
        chatService: _chatService,
      );
      return ok ? null : 'The connection test did not succeed.';
    } on AppException catch (error) {
      return error.message;
    } catch (error) {
      return _safeMessage(error);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Fetches the provider's model list. Returns null on success or a
  /// user-safe error message; results are exposed via [fetchedModels].
  Future<String?> fetchModels({
    required AIProviderConfig provider,
    required String apiKey,
  }) async {
    _busy = true;
    _fetchingModels = true;
    _error = null;
    notifyListeners();
    try {
      final models = await _service.fetchProviderModels(
        provider: provider,
        apiKey: apiKey,
        chatService: _chatService,
      );
      _fetchedModels = models;
      return null;
    } on AppException catch (error) {
      _error = error.message;
      return error.message;
    } catch (error) {
      _error = _safeMessage(error);
      return _error;
    } finally {
      _busy = false;
      _fetchingModels = false;
      notifyListeners();
    }
  }

  String _safeMessage(Object error) {
    if (error is AppException) return error.message;
    return 'Something went wrong. Please try again.';
  }

  @override
  void dispose() {
    _providersSub?.cancel();
    super.dispose();
  }
}
