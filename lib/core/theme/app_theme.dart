import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_palette.dart';

class AppTheme {
  static ThemeData getTheme({
    required AppPalette palette,
    required bool isDark,
  }) {
    final primary = palette.primary;
    final secondary = palette.secondary;

    // Derived colors
    final primaryVariant = isDark
        ? HSLColor.fromColor(primary).withLightness(0.6).toColor()
        : HSLColor.fromColor(primary).withLightness(0.4).toColor();

    final background = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC);
    final surface = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final error = isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);

    // Base Text Theme
    final baseTextTheme = isDark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    // Apply Google Fonts
    final textTheme = GoogleFonts.latoTextTheme(baseTextTheme).copyWith(
      displayLarge: GoogleFonts.playfairDisplayTextTheme(
        baseTextTheme,
      ).displayLarge,
      displayMedium: GoogleFonts.playfairDisplayTextTheme(
        baseTextTheme,
      ).displayMedium,
      displaySmall: GoogleFonts.playfairDisplayTextTheme(
        baseTextTheme,
      ).displaySmall,
      headlineLarge: GoogleFonts.playfairDisplayTextTheme(
        baseTextTheme,
      ).headlineLarge,
      headlineMedium: GoogleFonts.playfairDisplayTextTheme(
        baseTextTheme,
      ).headlineMedium,
      headlineSmall: GoogleFonts.playfairDisplayTextTheme(
        baseTextTheme,
      ).headlineSmall,
      titleLarge: GoogleFonts.playfairDisplayTextTheme(
        baseTextTheme,
      ).titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      textTheme: textTheme,
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: primary,
              primaryContainer: primaryVariant,
              secondary: secondary,
              surface: surface,
              error: error,
              onPrimary: Colors.white,
              onSecondary: const Color(0xFF0F172A),
              onSurface: const Color(0xFFE2E8F0),
              onError: Colors.white,
            )
          : ColorScheme.light(
              primary: primary,
              primaryContainer: primaryVariant,
              secondary: secondary,
              surface: surface,
              error: error,
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: const Color(0xFF1E293B),
              onError: Colors.white,
            ),
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: isDark ? surface : primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: isDark ? 4 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: surface,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF334155) : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF475569) : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF475569) : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: GoogleFonts.lato(),
        hintStyle: GoogleFonts.lato(),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: isDark
            ? const Color(0xFF94A3B8)
            : Colors.grey.shade600,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.lato(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.lato(),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? primary : const Color(0xFF1E293B),
        contentTextStyle: GoogleFonts.lato(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
