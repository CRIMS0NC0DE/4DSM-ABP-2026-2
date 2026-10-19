import 'package:flutter/material.dart';

/// Paleta do app, em versão clara e escura.
/// Nas telas, prefira `Theme.of(context).colorScheme` e [StatusColors.of]
/// em vez destas constantes: assim a cor acompanha o modo do celular.
abstract final class AppColors {
  // Escuro — grafite
  static const darkBackground = Color(0xFF121316);
  static const darkSurface = Color(0xFF1E2026);
  static const darkSurfaceHigh = Color(0xFF272A31);
  static const darkPrimary = Color(0xFF00C2FF);
  static const darkOnPrimary = Color(0xFF001A1C);
  static const darkPrimaryContainer = Color(0xFF00363A);
  static const darkTextPrimary = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFF94A3B8);
  static const darkOutline = Color(0xFF2E323B);

  // Claro — limpo e vivo
  static const lightBackground = Color(0xFFF8FAFC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceHigh = Color(0xFFF1F5F9);
  static const lightPrimary = Color(0xFF0055FF);
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightPrimaryContainer = Color(0xFFE0EAFF);
  static const lightOnPrimaryContainer = Color(0xFF002A80);
  static const lightTextPrimary = Color(0xFF0F172A);
  static const lightTextSecondary = Color(0xFF64748B);
  static const lightOutline = Color(0xFFE2E8F0);

  // Acesso negado / erro.
  // O vermelho claro é um tom abaixo do #E11D48 para passar no contraste
  // WCAG AA sobre o fundo (4,57:1).
  static const lightError = Color(0xFFDF1C47);
  static const lightErrorContainer = Color(0xFFFFE4E8);
  static const lightOnErrorContainer = Color(0xFF9F1239);
  static const darkError = Color(0xFFFF5470);
  static const darkErrorContainer = Color(0xFF4A1521);
  static const darkOnErrorContainer = Color(0xFFFFB3C0);

  // Acesso liberado / autorização ativa
  static const lightSuccess = Color(0xFF12753A);
  static const lightSuccessContainer = Color(0xFFDCF4E4);
  static const lightOnSuccessContainer = Color(0xFF0A5228);
  static const darkSuccess = Color(0xFF34D399);
  static const darkSuccessContainer = Color(0xFF0B3B2A);
  static const darkOnSuccessContainer = Color(0xFFA7F3D0);

  // Atenção (ex.: "Último uso disponível")
  static const lightWarning = Color(0xFFA15C00);
  static const lightWarningContainer = Color(0xFFFFF1CC);
  static const lightOnWarningContainer = Color(0xFF7A4100);
  static const darkWarning = Color(0xFFFBBF24);
  static const darkWarningContainer = Color(0xFF3A2A06);
  static const darkOnWarningContainer = Color(0xFFFDE68A);
}

/// Cores de status que o [ColorScheme] do Material não tem.
/// Uso: `StatusColors.of(context).success`.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
  });

  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;

  static const light = StatusColors(
    success: AppColors.lightSuccess,
    successContainer: AppColors.lightSuccessContainer,
    onSuccessContainer: AppColors.lightOnSuccessContainer,
    warning: AppColors.lightWarning,
    warningContainer: AppColors.lightWarningContainer,
    onWarningContainer: AppColors.lightOnWarningContainer,
  );

  static const dark = StatusColors(
    success: AppColors.darkSuccess,
    successContainer: AppColors.darkSuccessContainer,
    onSuccessContainer: AppColors.darkOnSuccessContainer,
    warning: AppColors.darkWarning,
    warningContainer: AppColors.darkWarningContainer,
    onWarningContainer: AppColors.darkOnWarningContainer,
  );

  /// Sem o tema do app (ex.: nos testes), usa a versão do modo atual.
  static StatusColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<StatusColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  StatusColors copyWith({
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
  }) {
    return StatusColors(
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
    );
  }

  /// Faz a transição suave quando o celular troca de modo claro/escuro.
  @override
  StatusColors lerp(StatusColors? other, double t) {
    if (other == null) return this;
    return StatusColors(
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer:
          Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
    );
  }
}
