import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/opcao_menu.dart';

/// Selo pequeno com ícone e texto, ex.: "Liberado", "Condômino", "Online".
/// Usa os mesmos tons do menu, para a cor acompanhar o modo do celular.
class Selo extends StatelessWidget {
  const Selo({
    super.key,
    required this.texto,
    required this.icone,
    this.tom = TomOpcao.padrao,
  });

  final String texto;
  final IconData icone;
  final TomOpcao tom;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = StatusColors.of(context);
    final (fundo, cor) = switch (tom) {
      TomOpcao.padrao => (
        colorScheme.primaryContainer,
        colorScheme.onPrimaryContainer,
      ),
      TomOpcao.sucesso => (status.successContainer, status.onSuccessContainer),
      TomOpcao.atencao => (status.warningContainer, status.onWarningContainer),
      TomOpcao.perigo => (
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
      ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 16, color: cor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                texto,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: cor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
