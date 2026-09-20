import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/errors/app_exception.dart';

/// Thin wrapper around platform secure storage for raw API keys.
///
/// Keys are stored with per-user, per-provider references
/// (`api_key/{uid}/{providerId}`) so entries can be deleted precisely when a
/// provider is removed and never collide between accounts on a shared
/// device.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static String apiKeyRef(String uid, String providerId) =>
      'api_key/$uid/$providerId';

  Future<String?> getApiKey(String ref) async {
    try {
      return await _storage.read(key: ref);
    } catch (error) {
      throw StorageException(
        'Could not read the saved API key from secure storage.',
        cause: error,
      );
    }
  }

  Future<void> saveApiKey(String ref, String apiKey) async {
    try {
      await _storage.write(key: ref, value: apiKey);
    } catch (error) {
      throw StorageException(
        'Could not save the API key to secure storage.',
        cause: error,
      );
    }
  }

  Future<void> deleteApiKey(String ref) async {
    try {
      await _storage.delete(key: ref);
    } catch (error) {
      if (await _storage.containsKey(key: ref)) {
        throw StorageException(
          'Could not remove the API key from secure storage.',
          cause: error,
        );
      }
      // Deleting a key that is already absent is a success.
    }
  }
}
