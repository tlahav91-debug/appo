import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark();
    final nunitoTextTheme = GoogleFonts.nunitoTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: bgDeep,
      colorScheme: const ColorScheme.dark(
        primary: pink,
        surface: surface,
        onPrimary: textCol,
        onSurface: textCol,
      ),
      textTheme: nunitoTextTheme.copyWith(
        bodyLarge: GoogleFonts.sora(
          color: textCol,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.sora(
          color: textSec,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: GoogleFonts.sora(
          color: textDim,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        displayLarge: GoogleFonts.nunito(
          color: textCol,
          fontSize: 32,
          fontWeight: FontWeight.w900,
        ),
        displayMedium: GoogleFonts.nunito(
          color: textCol,
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
        displaySmall: GoogleFonts.nunito(
          color: textCol,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: GoogleFonts.nunito(
          color: textCol,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: GoogleFonts.nunito(
          color: textCol,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: GoogleFonts.nunito(
          color: textCol,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: GoogleFonts.nunito(
          color: textCol,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: GoogleFonts.sora(
          color: textCol,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: GoogleFonts.sora(
          color: textSec,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelLarge: GoogleFonts.nunito(
          color: textCol,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        labelMedium: GoogleFonts.nunito(
          color: textSec,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        labelSmall: GoogleFonts.nunito(
          color: textDim,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: pink, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lava),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lava, width: 2),
        ),
        hintStyle: GoogleFonts.sora(color: textDim),
        labelStyle: GoogleFonts.sora(color: textSec),
        errorStyle: GoogleFonts.sora(color: lava, fontSize: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: pink,
        contentTextStyle: GoogleFonts.sora(color: textCol),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
