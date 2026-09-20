import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_paths.dart';
import '../core/errors/error_mapper.dart';
import '../core/utils/validators.dart';
import '../models/ai_provider_config.dart';
import '../models/ai_model_info.dart';
import 'chat_service.dart';
import 'secure_storage_service.dart';

/// Persistence layer for AI provider configurations.
///
/// Metadata (name, base URL, model, temperature, etc.) is stored in
/// Firestore under the user's own path; the raw API key is kept ONLY in the
/// device's secure storage, referenced by `apiKeyRef`. Secrets never enter
/// Firestore — the security rules also reject any provider document that
/// includes an `apiKey` field.
class ProviderConfigService {
  ProviderConfigService({
    FirebaseFirestore? firestore,
    required this.secureStorage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final SecureStorageService secureStorage;

  /// Real-time stream of the user's provider configurations.
  Stream<List<AIProviderConfig>> watchProviders({required String uid}) {
    return _firestore
        .collection(FirestorePaths.providersCol(uid))
        .orderBy('updatedAt', descending: true)
        .snapshots(includeMetadataChanges: false)
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AIProviderConfig.fromMap(doc.data(), id: doc.id))
              .toList(),
        );
  }

  /// Writes provider metadata to Firestore (create or full update) and
  /// stores the raw API key in secure storage when a new key is supplied.
  Future<void> saveProvider({
    required AIProviderConfig provider,
    String? apiKey,
  }) async {
    final keyRef = SecureStorageService.apiKeyRef(provider.userId, provider.id);
    final hasNewKey = apiKey != null && apiKey.trim().isNotEmpty;
    debugPrint('ProviderConfigService.saveProvider: provider.id=${provider.id}, userId=${provider.userId}, hasNewKey=$hasNewKey, keyRef=$keyRef, provider.apiKeyRef=${provider.apiKeyRef}');
    // Point the Firestore metadata at the secure-storage reference.
    final providerWithRef =
        hasNewKey || provider.apiKeyRef == null || provider.apiKeyRef!.isEmpty
        ? provider.copyWith(apiKeyRef: keyRef)
        : provider;
    debugPrint('ProviderConfigService.saveProvider: providerWithRef.apiKeyRef=${providerWithRef.apiKeyRef}');

    try {
      if (hasNewKey) {
        debugPrint('ProviderConfigService.saveProvider: Saving API key to secure storage');
        await secureStorage.saveApiKey(keyRef, apiKey.trim());
        debugPrint('ProviderConfigService.saveProvider: API key saved to secure storage');
      }
      debugPrint('ProviderConfigService.saveProvider: Saving provider to Firestore');
      await _firestore
          .doc(FirestorePaths.providerDoc(provider.userId, provider.id))
          .set(providerWithRef.toFirestoreMap(), SetOptions(merge: true));
      debugPrint('ProviderConfigService.saveProvider: Provider saved to Firestore');
    } on FirebaseException catch (error) {
      // Roll back the secure-storage write if Firestore rejected the
      // metadata, so no orphaned secret remains.
      if (hasNewKey) {
        await _tryDeleteKey(keyRef);
      }
      throw ErrorMapper.mapFirestore(error);
    } catch (error) {
      if (hasNewKey) {
        await _tryDeleteKey(keyRef);
      }
      throw ErrorMapper.map(error);
    }
  }

  /// Loads the raw API key for [provider] from secure storage.
  Future<String?> getApiKey(AIProviderConfig provider) {
    final ref = provider.apiKeyRef != null && provider.apiKeyRef!.isNotEmpty
        ? provider.apiKeyRef!
        : SecureStorageService.apiKeyRef(provider.userId, provider.id);
    debugPrint('ProviderConfigService.getApiKey: provider.id=${provider.id}, userId=${provider.userId}, provider.apiKeyRef=${provider.apiKeyRef}, using ref=$ref');
    return secureStorage.getApiKey(ref);
  }

  /// Deletes the Firestore metadata and the secure-storage entry.
  Future<void> deleteProvider({required AIProviderConfig provider}) async {
    final keyRef = provider.apiKeyRef != null && provider.apiKeyRef!.isNotEmpty
        ? provider.apiKeyRef!
        : SecureStorageService.apiKeyRef(provider.userId, provider.id);
    try {
      await _firestore
          .doc(FirestorePaths.providerDoc(provider.userId, provider.id))
          .delete();
      await secureStorage.deleteApiKey(keyRef);
    } on FirebaseException catch (error) {
      throw ErrorMapper.mapFirestore(error);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Marks exactly one provider active by updating all of the user's
  /// provider documents in a single batch.
  Future<void> setActiveProvider({
    required String uid,
    required String providerId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.providersCol(uid))
          .get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isActive': doc.id == providerId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } on FirebaseException catch (error) {
      throw ErrorMapper.mapFirestore(error);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Validates a provider configuration and returns user-safe error
  /// messages keyed by field (empty map = valid).
  Map<String, String> validateConfiguration({
    required String name,
    required String baseUrl,
    required String apiKey,
    String? organizationId,
    String? selectedModel,
  }) {
    return {
      'name': ?Validators.validateProviderName(name),
      'baseUrl': ?Validators.validateBaseUrl(baseUrl),
      'apiKey': ?Validators.validateApiKey(apiKey),
      'organizationId': ?Validators.validateOrganizationId(organizationId),
      'selectedModel': ?Validators.validateModelId(selectedModel),
    };
  }

  /// Tests connectivity using [chatService].
  Future<bool> testProviderConnection({
    required AIProviderConfig provider,
    required String apiKey,
    required ChatService chatService,
  }) {
    return chatService.testConnection(
      baseUrl: provider.baseUrl,
      apiKey: apiKey,
      organizationId: provider.organizationId,
    );
  }

  /// Fetches the provider's available models via [chatService].
  Future<List<AIModelInfo>> fetchProviderModels({
    required AIProviderConfig provider,
    required String apiKey,
    required ChatService chatService,
  }) {
    return chatService.fetchModels(
      baseUrl: provider.baseUrl,
      apiKey: apiKey,
      organizationId: provider.organizationId,
    );
  }

  Future<void> _tryDeleteKey(String ref) async {
    try {
      await secureStorage.deleteApiKey(ref);
    } catch (_) {
      // Best-effort rollback of the secret only.
    }
  }
}
