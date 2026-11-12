import 'package:flutter/material.dart';

class AppColors {
  static const Color pageBg = Color(0xFFFFFFFF);
  static const Color subtleBg = Color(0xFFF2FFFD);
  static const Color tealSoft = Color(0xFFF0FDFA);
  static const Color turquoiseSoft = Color(0xFFE6FFFA);
  static const Color turquoiseLight = Color(0xFFCCFBF1);
  static const Color turquoiseBorder = Color(0xFF5EEAD4);
  static const Color turquoiseAccent = Color(0xFF2DD4BF);

  static const Color tealPrimary = Color(0xFF0F766E);
  static const Color tealDark = Color(0xFF115E59);
  static const Color tealAccent = Color(0xFF0D9488);
  static const Color turquoisePrimary = Color(0xFF0891B2);
  static const Color turquoiseDark = Color(0xFF0E7490);

  static const Color bgTealTop = Color(0xFFB2F5EA);
  static const Color bgTurquoiseBottom = Color(0xFFB5F0F5);

  static const LinearGradient appBackgroundGradient = LinearGradient(
    colors: [
      bgTealTop,
      pageBg,
      subtleBg,
      bgTurquoiseBottom,
    ],
    stops: [0.0, 0.35, 0.70, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [
      tealPrimary,
      tealAccent,
      Color(0xFF14B8A6),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient welcomeCardGradient = LinearGradient(
    colors: [
      pageBg,
      turquoiseSoft,
      turquoiseLight,
    ],
    stops: [0.0, 0.55, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sheetGradient = LinearGradient(
    colors: [
      pageBg,
      subtleBg,
      Color(0xFFD8FAF5),
    ],
    stops: [0.0, 0.55, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

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
          bg: AppColors.turquoiseSoft,
          fg: AppColors.tealDark,
          border: AppColors.turquoiseBorder,
          icon: Icons.info_outline_rounded,
        );
    }
  }
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.tealAccent,
    primary: AppColors.tealPrimary,
    secondary: AppColors.turquoisePrimary,
    surface: AppColors.pageBg,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.subtleBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.tealPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 2,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: Colors.white),
      actionsIconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.pageBg,
      elevation: 1,
      shadowColor: AppColors.tealPrimary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.turquoiseBorder, width: 1.4),
      ),
      margin: EdgeInsets.zero,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.subtleBg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.turquoiseBorder, width: 1.5),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.turquoiseLight,
      thickness: 1.2,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.pageBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF99F6E4), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF64B5B0), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.tealPrimary, width: 2.2),
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
        backgroundColor: AppColors.pageBg,
        foregroundColor: AppColors.tealDark,
        side: const BorderSide(color: AppColors.tealAccent, width: 1.5),
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.tealPrimary,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.turquoiseLight;
          }
          return AppColors.pageBg;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.tealDark;
          }
          return AppColors.textSecondary;
        }),
        side: const WidgetStatePropertyAll(
          BorderSide(color: AppColors.turquoiseBorder, width: 1.4),
        ),
        iconColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.tealDark;
          }
          return AppColors.textSecondary;
        }),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.pageBg,
      selectedColor: AppColors.turquoiseLight,
      checkmarkColor: AppColors.tealDark,
      side: const BorderSide(color: AppColors.turquoiseBorder, width: 1.2),
      labelStyle: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return AppColors.tealDark;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.tealAccent;
        }
        return AppColors.turquoiseSoft;
      }),
      trackOutlineColor: const WidgetStatePropertyAll(AppColors.turquoiseBorder),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.pageBg,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.turquoiseLight,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: selected ? AppColors.tealDark : AppColors.textSecondary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppColors.tealDark : AppColors.textSecondary,
        );
      }),
    ),
  );
}
