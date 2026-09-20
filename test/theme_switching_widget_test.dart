import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_workspace/providers/theme_provider.dart';

void main() {
  testWidgets('ThemeMode changes flow to MaterialApp without a rebuild '
      'exception and survive across modes', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final themeProvider = ThemeProvider(prefs: prefs);
    await themeProvider.initialize();

    late ThemeProvider exposed;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: themeProvider,
        child: Builder(
          builder: (context) {
            exposed = context.read<ThemeProvider>();
            return MaterialApp(
              theme: ThemeData(brightness: Brightness.light),
              darkTheme: ThemeData(brightness: Brightness.dark),
              themeMode: context.watch<ThemeProvider>().themeMode,
              home: const Scaffold(body: Center(child: Text('theme-host'))),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The host content survives every mode switch — proving state is not
    // reset by theme changes.
    for (final mode in [
      ThemeMode.light,
      ThemeMode.dark,
      ThemeMode.light,
      ThemeMode.system,
    ]) {
      await exposed.setThemeMode(mode);
      await tester.pumpAndSettle();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, mode);
      expect(find.text('theme-host'), findsOneWidget);
    }

    // Preference was persisted with the last selected value.
    expect(prefs.getString('ai_workspace.themeMode'), ThemeMode.system.name);
  });
}
