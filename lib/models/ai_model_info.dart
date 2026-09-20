import '../core/utils/date_time_utils.dart';

/// A model entry returned by an OpenAI-compatible `/models` endpoint.
class AIModelInfo {
  const AIModelInfo({
    required this.id,
    required this.name,
    this.ownedBy,
    this.createdAt,
    this.metadata,
  });

  final String id;
  final String name;
  final String? ownedBy;
  final DateTime? createdAt;

  /// Optional provider-specific metadata, parsed defensively. Only primitive
  /// values are passed through; unexpected shapes fall back to an empty map.
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'ownedBy': ownedBy,
    'createdAt': createdAt?.millisecondsSinceEpoch,
    'metadata': metadata,
  };

  factory AIModelInfo.fromMap(Map<String, dynamic> map) {
    return AIModelInfo(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? map['id'] as String? ?? '',
      ownedBy: map['ownedBy'] as String?,
      createdAt: DateTimeUtils.coerce(map['created']),
      metadata: _safeMetadata(map['metadata']),
    );
  }

  static Map<String, dynamic>? _safeMetadata(dynamic value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }

  AIModelInfo copyWith({
    String? id,
    String? name,
    String? ownedBy,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) => AIModelInfo(
    id: id ?? this.id,
    name: name ?? this.name,
    ownedBy: ownedBy ?? this.ownedBy,
    createdAt: createdAt ?? this.createdAt,
    metadata: metadata ?? this.metadata,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIModelInfo && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}
