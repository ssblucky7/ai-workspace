import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'chat_theme_extension.dart';

/// Dark theme: charcoal background, slightly lighter surfaces, indigo
/// accent, high-contrast text, soft borders.
ThemeData buildDarkTheme() {
  const scheme = ColorScheme.dark(
    primary: Color(0xFFBDC1FF),
    onPrimary: Color(0xFF262A78),
    primaryContainer: AppColors.primaryContainerDark,
    onPrimaryContainer: Color(0xFFE4E3FF),
    secondary: Color(0xFF4FDAC7),
    onSecondary: Color(0xFF00382F),
    secondaryContainer: AppColors.secondaryContainerDark,
    onSecondaryContainer: Color(0xFFCCF0EA),
    error: AppColors.errorDark,
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkOnSurface,
    onSurfaceVariant: AppColors.darkOnSurfaceVariant,
    surfaceContainer: AppColors.darkSurfaceContainer,
    surfaceContainerHigh: AppColors.darkSurfaceContainerHigh,
    outline: AppColors.darkOutline,
    outlineVariant: Color(0xFF2C2D35),
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.darkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      foregroundColor: AppColors.darkOnSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.darkOnSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurfaceContainer,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkOutline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkOutline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFBDC1FF), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.errorDark, width: 1.5),
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
        foregroundColor: Color(0xFFBDC1FF),
        side: const BorderSide(color: Color(0xFF7A7EE8)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Color(0xFFBDC1FF),
        minimumSize: const Size(64, 48),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.darkOutline),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.darkOutline),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkSurfaceContainerHigh,
      contentTextStyle: const TextStyle(color: AppColors.darkOnSurface),
      actionTextColor: Color(0xFFBDC1FF),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      indicatorColor: AppColors.primaryContainerDark,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.darkOnSurfaceVariant,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppColors.darkSurface,
      indicatorColor: AppColors.primaryContainerDark,
      selectedIconTheme: const IconThemeData(color: Color(0xFFE4E3FF)),
      selectedLabelTextStyle: const TextStyle(
        color: Color(0xFFE4E3FF),
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: const TextStyle(
        color: AppColors.darkOnSurfaceVariant,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.darkSurfaceContainer,
      selectedColor: AppColors.primaryContainerDark,
      labelStyle: const TextStyle(color: AppColors.darkOnSurface),
      side: const BorderSide(color: AppColors.darkOutline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(AppColors.darkSurface),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.darkOutline),
          ),
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.darkOutline,
      thickness: 1,
      space: 1,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Color(0xFFBDC1FF),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryContainerDark,
      foregroundColor: Color(0xFFE4E3FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.darkSurface,
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
          userBubble: AppColors.primaryContainerDark,
          userBubbleText: Color(0xFFE4E3FF),
          assistantBubble: AppColors.darkSurfaceContainer,
          assistantBubbleText: AppColors.darkOnSurface,
          failedBubble: Color(0xFF3A1A17),
          failedBubbleText: Color(0xFFFFB4AB),
        ),
      ),
  );
}
