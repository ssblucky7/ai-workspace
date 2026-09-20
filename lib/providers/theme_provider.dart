import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owns the app's [ThemeMode] and persists the choice via
/// SharedPreferences, so the preference survives restarts while switching
/// stays instant (no app restart, no state reset).
class ThemeProvider extends ChangeNotifier {
  ThemeProvider({required this._prefs});

  static const _prefKey = 'ai_workspace.themeMode';

  final SharedPreferences _prefs;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  bool get isDarkPreferred =>
      _themeMode == ThemeMode.dark || _themeMode == ThemeMode.system;

  /// Loads the persisted mode. Called once before runApp so no theme flash
  /// occurs on first frame.
  Future<void> initialize() async {
    final saved = _prefs.getString(_prefKey);
    switch (saved) {
      case 'light':
        _themeMode = ThemeMode.light;
      case 'dark':
        _themeMode = ThemeMode.dark;
      default:
        _themeMode = ThemeMode.system;
    }
    // No notifyListeners during init: main() reads the value before runApp.
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      await _prefs.setString(_prefKey, mode.name);
    } catch (_) {
      // Persistence is best-effort: the in-memory switch still applies.
    }
  }

  /// Cycles system -> light -> dark -> system.
  Future<void> cycleTheme() async {
    final next = switch (_themeMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    await setThemeMode(next);
  }

  Future<void> toggleLightDark() async {
    await setThemeMode(
      _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }
}
