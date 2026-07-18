import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// DisplayVision brand palette — premium black / white / orange.
class DVColors {
  DVColors._();

  static const Color background = Color(0xFF0A0A0C);
  static const Color surface = Color(0xFF121216);
  static const Color surfaceRaised = Color(0xFF1A1A20);
  static const Color stroke = Color(0x1FFFFFFF);

  static const Color orange = Color(0xFFFF6A00);
  static const Color orangeBright = Color(0xFFFF8A3C);
  static const Color orangeDeep = Color(0xFFE05500);

  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFF9A9AA3);

  static const Color success = Color(0xFF3DDC84);
  static const Color warning = Color(0xFFFFC24B);
  static const Color danger = Color(0xFFFF5252);

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [orangeDeep, orange, orangeBright],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );
}

class DVTheme {
  DVTheme._();

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: DVColors.background,
      colorScheme: const ColorScheme.dark(
        primary: DVColors.orange,
        secondary: DVColors.orangeBright,
        surface: DVColors.surface,
        onPrimary: Colors.white,
        onSurface: DVColors.textPrimary,
        error: DVColors.danger,
      ),
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displaySmall: GoogleFonts.sora(
        fontSize: 32, fontWeight: FontWeight.w700, color: DVColors.textPrimary),
      headlineSmall: GoogleFonts.sora(
        fontSize: 22, fontWeight: FontWeight.w600, color: DVColors.textPrimary),
      titleLarge: GoogleFonts.sora(
        fontSize: 18, fontWeight: FontWeight.w600, color: DVColors.textPrimary),
      titleMedium: GoogleFonts.inter(
        fontSize: 15, fontWeight: FontWeight.w600, color: DVColors.textPrimary),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14, color: DVColors.textPrimary),
      bodySmall: GoogleFonts.inter(
        fontSize: 12, color: DVColors.textSecondary),
      labelLarge: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: DVColors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DVColors.surfaceRaised,
        hintStyle: const TextStyle(color: DVColors.textSecondary),
        labelStyle: const TextStyle(color: DVColors.textSecondary),
        prefixIconColor: DVColors.textSecondary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DVColors.stroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DVColors.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DVColors.orange, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: DVColors.orange,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DVColors.textPrimary,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: DVColors.stroke),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: DVColors.orange,
        foregroundColor: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: DVColors.surface.withOpacity(0.92),
        indicatorColor: DVColors.orange.withOpacity(0.18),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? DVColors.orange
                : DVColors.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.bodySmall!.copyWith(
            color: states.contains(WidgetState.selected)
                ? DVColors.orange
                : DVColors.textSecondary,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: DVColors.surfaceRaised,
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: const DividerThemeData(color: DVColors.stroke),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: DVColors.surfaceRaised,
        side: const BorderSide(color: DVColors.stroke),
        labelStyle: textTheme.bodySmall,
      ),
    );
  }
}
