import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/autorizacao.dart';

/// Selo com a situação da autorização, ex.: "✓ Ativa" em verde (U7, U8).
class SeloSituacao extends StatelessWidget {
  const SeloSituacao({super.key, required this.situacao});

  final SituacaoAutorizacao situacao;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = StatusColors.of(context);
    final (icone, fundo, cor) = switch (situacao) {
      SituacaoAutorizacao.ativa => (
        Icons.check_circle,
        status.successContainer,
        status.onSuccessContainer,
      ),
      SituacaoAutorizacao.agendada => (
        Icons.schedule,
        colorScheme.primaryContainer,
        colorScheme.onPrimaryContainer,
      ),
      SituacaoAutorizacao.esgotada => (
        Icons.block,
        status.warningContainer,
        status.onWarningContainer,
      ),
      SituacaoAutorizacao.expirada => (
        Icons.event_busy,
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurfaceVariant,
      ),
      SituacaoAutorizacao.cancelada => (
        Icons.cancel,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 18, color: cor),
            const SizedBox(width: 6),
            Text(
              situacao.rotulo,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: cor),
            ),
          ],
        ),
      ),
    );
  }
}
