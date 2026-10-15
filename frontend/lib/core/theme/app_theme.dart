import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema Material 3 do app, seguindo o docs/Design.pdf:
/// fonte Inter, texto base 18sp, botões com 56dp de altura, contraste WCAG AA.
abstract final class AppTheme {
  static const _radius = 12.0;
  static const _buttonSize = Size(64, 56);

  static final ThemeData light = _build();

  static ThemeData _build() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      error: AppColors.error,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.divider,
    );

    final base = ThemeData(
      colorScheme: colorScheme,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: AppColors.background,
    );

    final text = base.textTheme;
    final textTheme = text.copyWith(
      headlineMedium: text.headlineMedium?.copyWith(fontSize: 28, fontWeight: FontWeight.w700),
      headlineSmall: text.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w700),
      titleLarge: text.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
      titleMedium: text.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      bodyLarge: text.bodyLarge?.copyWith(fontSize: 18, height: 1.4),
      bodyMedium: text.bodyMedium?.copyWith(fontSize: 16, height: 1.4),
      bodySmall: text.bodySmall?.copyWith(fontSize: 14, color: AppColors.textSecondary),
      labelLarge: text.labelLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      labelMedium: text.labelMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
    );

    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius));

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: _buttonSize,
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: _buttonSize,
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        prefixIconColor: AppColors.textSecondary,
        hintStyle: textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
        border: _inputBorder(AppColors.border),
        enabledBorder: _inputBorder(AppColors.border),
        focusedBorder: _inputBorder(AppColors.primary, width: 2),
        errorBorder: _inputBorder(AppColors.error, width: 2),
        focusedErrorBorder: _inputBorder(AppColors.error, width: 2),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.divider),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 1),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(_radius),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
