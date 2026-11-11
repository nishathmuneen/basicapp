import 'package:flutter/material.dart';

class AppColors {
  static const Color pageBg = Color(0xFFFFFFFF);
  static const Color subtleBg = Color(0xFFF4FAFE);
  static const Color skyLight = Color(0xFFE0F2FE);
  static const Color skyBorder = Color(0xFFBAE6FD);
  static const Color tealSoft = Color(0xFFF0FDFA);

  static const Color tealPrimary = Color(0xFF0F766E);
  static const Color tealAccent = Color(0xFF0D9488);
  static const Color skyPrimary = Color(0xFF0284C7);
  static const Color skyDark = Color(0xFF0369A1);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF334155);
  static const Color textMuted = Color(0xFF475569);

  static const Color greenBg = Color(0xFFECFDF5);
  static const Color greenText = Color(0xFF065F46);
  static const Color greenBorder = Color(0xFF10B981);

  static const Color yellowBg = Color(0xFFFEFCE8);
  static const Color yellowText = Color(0xFF854D0E);
  static const Color yellowBorder = Color(0xFFCA8A04);

  static const Color redBg = Color(0xFFFEF2F2);
  static const Color redText = Color(0xFF991B1B);
  static const Color redBorder = Color(0xFFDC2626);
}

class StatusPalette {
  const StatusPalette({
    required this.bg,
    required this.fg,
    required this.border,
    required this.icon,
  });

  final Color bg;
  final Color fg;
  final Color border;
  final IconData icon;

  static StatusPalette fromColorName(String color) {
    switch (color) {
      case 'green':
        return const StatusPalette(
          bg: AppColors.greenBg,
          fg: AppColors.greenText,
          border: AppColors.greenBorder,
          icon: Icons.check_circle_outline_rounded,
        );
      case 'yellow':
        return const StatusPalette(
          bg: AppColors.yellowBg,
          fg: AppColors.yellowText,
          border: AppColors.yellowBorder,
          icon: Icons.warning_amber_rounded,
        );
      case 'red':
        return const StatusPalette(
          bg: AppColors.redBg,
          fg: AppColors.redText,
          border: AppColors.redBorder,
          icon: Icons.error_outline_rounded,
        );
      default:
        return const StatusPalette(
          bg: AppColors.subtleBg,
          fg: AppColors.skyDark,
          border: AppColors.skyBorder,
          icon: Icons.info_outline_rounded,
        );
    }
  }
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.tealPrimary,
    primary: AppColors.tealPrimary,
    secondary: AppColors.skyPrimary,
    surface: AppColors.pageBg,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.pageBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.pageBg,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.pageBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.skyBorder, width: 1.5),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.pageBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF94A3B8), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF94A3B8), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.skyDark, width: 2.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.redBorder, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.tealPrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.skyDark,
        side: const BorderSide(color: AppColors.skyPrimary, width: 1.5),
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.pageBg,
      indicatorColor: AppColors.skyLight,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: selected ? AppColors.skyDark : AppColors.textSecondary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppColors.skyDark : AppColors.textSecondary,
        );
      }),
    ),
  );
}

