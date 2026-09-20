import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/date_time_utils.dart';

/// Non-secret metadata for a user-configured OpenAI-compatible provider.
///
/// The raw API key is deliberately absent from this model: it lives only in
/// the device's secure storage, referenced by [apiKeyRef]. Never add an
/// `apiKey` field — the Firestore security rules reject any provider document
/// that contains one.
class AIProviderConfig {
  const AIProviderConfig({
    required this.id,
    required this.userId,
    required this.name,
    required this.baseUrl,
    this.apiKeyRef,
    this.selectedModel,
    this.organizationId,
    this.temperature = AppConstants.defaultTemperature,
    this.maxTokens = AppConstants.defaultMaxTokens,
    this.isActive = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String baseUrl;

  /// Key under which the raw API key is stored in secure storage.
  final String? apiKeyRef;
  final String? selectedModel;
  final String? organizationId;
  final double temperature;
  final int maxTokens;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'name': name,
    'baseUrl': baseUrl,
    'apiKeyRef': apiKeyRef,
    'selectedModel': selectedModel,
    'organizationId': organizationId,
    'temperature': temperature,
    'maxTokens': maxTokens,
    'isActive': isActive,
    'createdAt': createdAt?.millisecondsSinceEpoch,
    'updatedAt': updatedAt?.millisecondsSinceEpoch,
  };

  /// Firestore payload with server-timestamp sentinels for time fields.
  Map<String, dynamic> toFirestoreMap() => {
    'id': id,
    'userId': userId,
    'name': name,
    'baseUrl': baseUrl,
    'apiKeyRef': apiKeyRef,
    'selectedModel': selectedModel,
    'organizationId': organizationId,
    'temperature': temperature,
    'maxTokens': maxTokens,
    'isActive': isActive,
    if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  factory AIProviderConfig.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return AIProviderConfig(
      id: id,
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      baseUrl: map['baseUrl'] as String? ?? '',
      apiKeyRef: map['apiKeyRef'] as String?,
      selectedModel: map['selectedModel'] as String?,
      organizationId: map['organizationId'] as String?,
      temperature: _toDouble(map['temperature']),
      maxTokens: _toInt(map['maxTokens']),
      isActive: map['isActive'] as bool? ?? false,
      createdAt: DateTimeUtils.coerce(map['createdAt']),
      updatedAt: DateTimeUtils.coerce(map['updatedAt']),
    );
  }

  /// Firestore may return ints where doubles are expected (and vice versa);
  /// coerce defensively so streams never throw on a slightly different type.
  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return AppConstants.defaultTemperature;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return AppConstants.defaultMaxTokens;
  }

  AIProviderConfig copyWith({
    String? id,
    String? userId,
    String? name,
    String? baseUrl,
    String? apiKeyRef,
    String? selectedModel,
    String? organizationId,
    double? temperature,
    int? maxTokens,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AIProviderConfig(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    baseUrl: baseUrl ?? this.baseUrl,
    apiKeyRef: apiKeyRef ?? this.apiKeyRef,
    selectedModel: selectedModel ?? this.selectedModel,
    organizationId: organizationId ?? this.organizationId,
    temperature: temperature ?? this.temperature,
    maxTokens: maxTokens ?? this.maxTokens,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIProviderConfig &&
          other.id == id &&
          other.userId == userId &&
          other.name == name &&
          other.baseUrl == baseUrl &&
          other.apiKeyRef == apiKeyRef &&
          other.selectedModel == selectedModel &&
          other.organizationId == organizationId &&
          other.temperature == temperature &&
          other.maxTokens == maxTokens &&
          other.isActive == isActive;

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    name,
    baseUrl,
    apiKeyRef,
    selectedModel,
    organizationId,
    temperature,
    maxTokens,
    isActive,
  );
}
