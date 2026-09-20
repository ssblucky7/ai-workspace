import 'package:flutter/material.dart';

/// Original AI Workspace brand palette.
///
/// Indigo-violet primary with a teal secondary accent — an AI-inspired but
/// neutral identity that does not reference any vendor's branding.
abstract final class AppColors {
  AppColors._();

  // Brand seed.
  static const Color primary = Color(0xFF5B5FE9);
  static const Color primaryContainerLight = Color(0xFFE4E3FF);
  static const Color primaryContainerDark = Color(0xFF3F43B8);
  static const Color secondary = Color(0xFF14B8A6);
  static const Color secondaryContainerLight = Color(0xFFCCF0EA);
  static const Color secondaryContainerDark = Color(0xFF0F5F57);

  // Light scheme.
  static const Color lightBackground = Color(0xFFFAF9F7); // warm off-white
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainer = Color(0xFFF2F1EC);
  static const Color lightSurfaceContainerHigh = Color(0xFFECEBE6);
  static const Color lightOutline = Color(0xFFDFDDD5);
  static const Color lightOnSurface = Color(0xFF1B1B1F);
  static const Color lightOnSurfaceVariant = Color(0xFF47464F);

  // Dark scheme.
  static const Color darkBackground = Color(0xFF121317); // charcoal
  static const Color darkSurface = Color(0xFF1B1C21);
  static const Color darkSurfaceContainer = Color(0xFF24252C);
  static const Color darkSurfaceContainerHigh = Color(0xFF2F3038);
  static const Color darkOutline = Color(0xFF3D3E47);
  static const Color darkOnSurface = Color(0xFFE5E1E9);
  static const Color darkOnSurfaceVariant = Color(0xFFC8C5D0);

  // Semantic.
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorDark = Color(0xFFFFB4AB);
  static const Color success = Color(0xFF2E7D32);
  static const Color successDark = Color(0xFF9CD67C);
}
