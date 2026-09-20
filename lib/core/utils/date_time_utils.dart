import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Date/time helpers, including safe conversion of Firestore values.
abstract final class DateTimeUtils {
  /// Converts a Firestore [Timestamp], [DateTime], epoch int, or ISO string
  /// into a [DateTime]. Returns `null` for missing or malformed values
  /// instead of throwing, so a single bad field can never crash a list view.
  static DateTime? coerce(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      return parsed;
    }
    return null;
  }

  /// Compact, user-friendly timestamp.
  ///
  /// - Same day  -> `14:32`
  /// - Same year -> `Mar 3`
  /// - Older     -> `Mar 3, 2024`
  static String formatTimestamp(DateTime? time, {DateTime? now}) {
    if (time == null) return 'Unknown';
    final local = time.toLocal();
    final reference = (now ?? DateTime.now());
    final isSameDay =
        local.year == reference.year &&
        local.month == reference.month &&
        local.day == reference.day;
    if (isSameDay) return DateFormat('HH:mm').format(local);
    if (local.year == reference.year) return DateFormat('MMM d').format(local);
    return DateFormat('MMM d, yyyy').format(local);
  }

  /// Full timestamp used for profile and detail views.
  static String formatFullTimestamp(DateTime? time) {
    if (time == null) return 'Unknown';
    return DateFormat('MMM d, yyyy · HH:mm').format(time.toLocal());
  }
}
