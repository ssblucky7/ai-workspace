import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_workspace/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeProvider', () {
    test('defaults to system mode and persists selection', () async {
      // Fresh, isolated mock prefs for this test.
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final provider = ThemeProvider(prefs: prefs);
      await provider.initialize();

      expect(provider.themeMode, ThemeMode.system);

      await provider.setThemeMode(ThemeMode.dark);
      expect(provider.themeMode, ThemeMode.dark);
      expect(prefs.getString('ai_workspace.themeMode'), 'dark');

      // A new instance restores the saved preference.
      final restored = ThemeProvider(prefs: prefs);
      await restored.initialize();
      expect(restored.themeMode, ThemeMode.dark);
    });

    test('toggleLightDark switches between light and dark', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final provider = ThemeProvider(prefs: prefs);
      await provider.initialize();

      // System counts as "not dark" -> first toggle lands on dark.
      await provider.toggleLightDark();
      expect(provider.themeMode, ThemeMode.dark);
      await provider.toggleLightDark();
      expect(provider.themeMode, ThemeMode.light);
    });

    test('notifies listeners on change', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final provider = ThemeProvider(prefs: prefs);
      await provider.initialize();

      var notified = false;
      provider.addListener(() => notified = true);
      await provider.setThemeMode(ThemeMode.light);
      expect(notified, isTrue);
    });

    test('setting the same mode is a no-op', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final provider = ThemeProvider(prefs: prefs);
      await provider.initialize();
      await provider.setThemeMode(ThemeMode.light);

      var notified = false;
      provider.addListener(() => notified = true);
      await provider.setThemeMode(ThemeMode.light);
      expect(notified, isFalse);
    });
  });
}
