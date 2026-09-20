import '../core/utils/date_time_utils.dart';

/// Firestore user profile stored at `users/{uid}`.
class AppUser {
  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String fullName;
  final String email;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Initials rendered inside the avatar (e.g. "Ada Lovelace" -> "AL").
  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final first = parts.first;
      return (first.length >= 2 ? first.substring(0, 2) : first).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'fullName': fullName,
    'email': email,
    'photoUrl': photoUrl,
    'createdAt': createdAt?.millisecondsSinceEpoch,
    'updatedAt': updatedAt?.millisecondsSinceEpoch,
  };

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      createdAt: DateTimeUtils.coerce(map['createdAt']),
      updatedAt: DateTimeUtils.coerce(map['updatedAt']),
    );
  }

  AppUser copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AppUser(
    uid: uid ?? this.uid,
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    photoUrl: photoUrl ?? this.photoUrl,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          other.uid == uid &&
          other.fullName == fullName &&
          other.email == email &&
          other.photoUrl == photoUrl &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      Object.hash(uid, fullName, email, photoUrl, createdAt, updatedAt);
}
