import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'evora_colors.dart';
import 'evora_typography.dart';

/// Complete Material 3 ThemeData for Evora-Workers — Himalayan Modernism.
/// Designed for high outdoor contrast and minimum 48x48dp field touch targets.
class EvoraTheme {
  EvoraTheme._();

  static ThemeData lightTheme({bool isHindi = false}) {
    final textTheme = EvoraTypography.createTextTheme(isHindi: isHindi);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: EvoraColors.primary,
      scaffoldBackgroundColor: EvoraColors.background,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: EvoraColors.primary,
        onPrimary: EvoraColors.onPrimary,
        primaryContainer: EvoraColors.primaryContainer,
        onPrimaryContainer: EvoraColors.onPrimaryContainer,
        secondary: EvoraColors.secondary,
        onSecondary: EvoraColors.onSecondary,
        secondaryContainer: EvoraColors.secondaryContainer,
        onSecondaryContainer: EvoraColors.onSecondaryContainer,
        tertiary: EvoraColors.tertiary,
        onTertiary: EvoraColors.onTertiary,
        tertiaryContainer: EvoraColors.tertiaryContainer,
        onTertiaryContainer: EvoraColors.onTertiaryContainer,
        error: EvoraColors.error,
        onError: EvoraColors.onError,
        errorContainer: EvoraColors.errorContainer,
        onErrorContainer: EvoraColors.onErrorContainer,
        surface: EvoraColors.surface,
        onSurface: EvoraColors.onSurface,
        onSurfaceVariant: EvoraColors.onSurfaceVariant,
        outline: EvoraColors.outline,
        outlineVariant: EvoraColors.outlineVariant,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: EvoraColors.surfaceContainerLowest,
        foregroundColor: EvoraColors.onSurface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: EvoraColors.onSurface),
        titleTextStyle: TextStyle(
          color: EvoraColors.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: EvoraColors.surfaceContainerLowest,
        indicatorColor: EvoraColors.secondaryContainer.withValues(alpha: 0.45),
        elevation: 2,
        height: 70,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? EvoraColors.primary : EvoraColors.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? EvoraColors.primary : EvoraColors.onSurfaceVariant,
            size: 24,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: EvoraColors.primary,
          foregroundColor: EvoraColors.onPrimary,
          minimumSize: const Size(48, 48),
          elevation: 0,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: EvoraColors.onSurface,
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: EvoraColors.outlineVariant, width: 1.5),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: EvoraColors.primary,
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: EvoraColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: EvoraColors.outlineVariant, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: EvoraColors.outlineVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: EvoraColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: EvoraColors.error, width: 1.5),
        ),
        hintStyle: const TextStyle(
          color: EvoraColors.outline,
          fontSize: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: EvoraColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x140F172A), width: 1),
        ),
      ),
    );
  }
}
