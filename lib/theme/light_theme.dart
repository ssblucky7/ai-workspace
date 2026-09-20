import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'chat_theme_extension.dart';

/// Light theme: warm off-white background, white surfaces, indigo accent,
/// dark readable text, subtle borders and shadows.
ThemeData buildLightTheme() {
  const scheme = ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primaryContainerLight,
    onPrimaryContainer: Color(0xFF160F4B),
    secondary: AppColors.secondary,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.secondaryContainerLight,
    onSecondaryContainer: Color(0xFF00504A),
    error: AppColors.error,
    onError: Colors.white,
    errorContainer: Color(0xFFFFEDEA),
    onErrorContainer: Color(0xFF410002),
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightOnSurface,
    onSurfaceVariant: AppColors.lightOnSurfaceVariant,
    surfaceContainer: AppColors.lightSurfaceContainer,
    surfaceContainerHigh: AppColors.lightSurfaceContainerHigh,
    outline: AppColors.lightOutline,
    outlineVariant: Color(0xFFC9C7BF),
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.lightBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightBackground,
      foregroundColor: AppColors.lightOnSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.lightOnSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightOutline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightOutline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(64, 48),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.lightSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.lightOutline),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.lightOutline),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.lightOnSurface,
      contentTextStyle: const TextStyle(color: Colors.white),
      actionTextColor: AppColors.primaryContainerLight,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.lightSurface,
      indicatorColor: AppColors.primaryContainerLight,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.lightOnSurfaceVariant,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppColors.lightSurface,
      indicatorColor: AppColors.primaryContainerLight,
      selectedIconTheme: const IconThemeData(color: Color(0xFF160F4B)),
      selectedLabelTextStyle: const TextStyle(
        color: Color(0xFF160F4B),
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: const TextStyle(
        color: AppColors.lightOnSurfaceVariant,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.lightSurfaceContainer,
      selectedColor: AppColors.primaryContainerLight,
      labelStyle: const TextStyle(color: AppColors.lightOnSurface),
      side: const BorderSide(color: AppColors.lightOutline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(AppColors.lightSurface),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.lightOutline),
          ),
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.lightOutline,
      thickness: 1,
      space: 1,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.lightSurface,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
  );

  return base.copyWith(
    extensions: base.extensions.values.cast<ThemeExtension<dynamic>>().toList()
      ..add(
        const ChatThemeExtension(
          userBubble: AppColors.primaryContainerLight,
          userBubbleText: Color(0xFF160F4B),
          assistantBubble: AppColors.lightSurfaceContainer,
          assistantBubbleText: AppColors.lightOnSurface,
          failedBubble: Color(0xFFFFEDEA),
          failedBubbleText: Color(0xFF93000A),
        ),
      ),
  );
}
