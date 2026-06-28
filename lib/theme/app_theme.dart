import 'package:flutter/material.dart';

class AppColors {
  // Primary – deep forest green from Kebun Sei logo
  static const Color primaryGreen = Color(0xFF2D6A27);
  static const Color primaryGreenLight = Color(0xFF3D8A35);
  static const Color primaryGreenDark = Color(0xFF1A4A17);

  // Accent / secondary
  static const Color accentBrown = Color(0xFF8B6F47);
  static const Color accentLightGreen = Color(0xFF6DBF67);

  // Background & surface
  static const Color background = Color(0xFFF4F1EB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEFEAE1);

  // Text
  static const Color textDark = Color(0xFF1E2022);
  static const Color textMedium = Color(0xFF596273);
  static const Color textMuted = Color(0xFF747B8A);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Progress/chart
  static const Color progressBg = Color(0xFFE4EDE1);
  static const Color border = Color(0xFFE2DCD2);
  static const Color softGreen = Color(0xFFE7F1E4);
  static const Color field = Color(0xFFEDE9E1);
}

class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryGreen,
      brightness: Brightness.light,
      primary: AppColors.primaryGreen,
      secondary: AppColors.accentBrown,
      surface: AppColors.surface,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textOnPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.primaryGreen.withValues(
            alpha: 0.35,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.field,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primaryGreen,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(color: AppColors.textMuted),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primaryGreen,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primaryGreen,
        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 12,
        ),
        tabAlignment: TabAlignment.start,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryGreen,
        checkmarkColor: Colors.white,
        labelStyle: const TextStyle(
          color: AppColors.primaryGreen,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primaryGreen.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppColors.primaryGreen : AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primaryGreen : AppColors.textMuted,
            size: selected ? 24 : 22,
          );
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          color: AppColors.textDark,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textDark,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textMuted,
        textColor: AppColors.textDark,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textDark,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: AppColors.textMedium,
          height: 1.45,
        ),
        labelLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryGreen,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.normal,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
