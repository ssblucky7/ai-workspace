import 'package:flutter/material.dart';

import 'dark_theme.dart';
import 'light_theme.dart';

/// Entry point for the app's custom Material 3 themes.
abstract final class AppTheme {
  static ThemeData get light => buildLightTheme();

  static ThemeData get dark => buildDarkTheme();
}
