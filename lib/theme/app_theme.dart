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
  static const Color background = Color(0xFFF7F5F0); // off-white/cream
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0EDE6);

  // Text
  static const Color textDark = Color(0xFF1E2022);
  static const Color textMedium = Color(0xFF4A5568);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Progress/chart
  static const Color progressBg = Color(0xFFE8F5E9);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryGreen,
        onPrimary: AppColors.textOnPrimary,
        secondary: AppColors.accentBrown,
        onSecondary: AppColors.textOnPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textDark,
        surfaceContainerHighest: AppColors.surfaceVariant,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: AppColors.primaryGreen.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textOnPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          side: const BorderSide(color: AppColors.primaryGreen),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E0D8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textMuted),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primaryGreen,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primaryGreen,
        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 13,
        ),
        tabAlignment: TabAlignment.start,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.progressBg,
        labelStyle: const TextStyle(
          color: AppColors.primaryGreen,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E0D8),
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
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
          fontSize: 17,
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
          fontSize: 15,
          fontWeight: FontWeight.normal,
          color: AppColors.textDark,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: AppColors.textMedium,
        ),
        labelLarge: TextStyle(
          fontSize: 13,
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
