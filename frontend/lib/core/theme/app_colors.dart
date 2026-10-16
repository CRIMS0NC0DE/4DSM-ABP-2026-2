import 'package:flutter/material.dart';

/// Cores tiradas do docs/Design.pdf.
/// Use estas constantes nas telas em vez de escrever Color(0xFF...) solto.
abstract final class AppColors {
  // Marca
  static const primary = Color(0xFF1D4ED8);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFDBE5FF);
  static const onPrimaryContainer = Color(0xFF0B2E83);

  // Fundo e superfícies
  static const background = Color(0xFFF3F5F9);
  static const surface = Color(0xFFFFFFFF);

  // Texto
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF4B5565);
  static const textMuted = Color(0xFF737B88);

  // Bordas e divisórias
  static const border = Color(0xFFD5DAE2);
  static const divider = Color(0xFFE5E9F0);

  // Acesso liberado / autorização ativa
  static const success = Color(0xFF12753A);
  static const successContainer = Color(0xFFDCF4E4);
  static const onSuccessContainer = Color(0xFF0A5228);

  // Acesso negado / erro
  static const error = Color(0xFFB42318);
  static const errorContainer = Color(0xFFFFE4E1);
  static const onErrorContainer = Color(0xFF8E1B12);

  // Atenção (ex.: "Último uso disponível")
  static const warning = Color(0xFFA15C00);
  static const warningContainer = Color(0xFFFFF1CC);
  static const onWarningContainer = Color(0xFF7A4100);

  // Telas escuras: scanner de QR e terminal
  static const dark = Color(0xFF0B1220);
}
