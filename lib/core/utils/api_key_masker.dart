/// Masks an API key for safe display.
///
/// Only a short prefix and the last few characters are ever revealed, e.g.
/// `sk-••••••1234`. Keys short enough to be fully exposed by a prefix/suffix
/// are masked completely.
abstract final class ApiKeyMasker {
  static const int _prefixLength = 3;
  static const int _suffixLength = 4;
  static const int _minimumLengthForPartialReveal = 12;

  static String mask(String? apiKey) {
    if (apiKey == null || apiKey.isEmpty) return 'No key saved';
    if (apiKey.length < _minimumLengthForPartialReveal) {
      return '•' * apiKey.length;
    }
    final prefix = apiKey.substring(0, _prefixLength);
    final suffix = apiKey.substring(apiKey.length - _suffixLength);
    return '$prefix${'•' * 6}$suffix';
  }
}
