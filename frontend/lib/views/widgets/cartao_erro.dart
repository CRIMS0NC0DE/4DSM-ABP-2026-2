import 'package:flutter/material.dart';

import 'botao_acao.dart';

/// Problema ao carregar uma lista, dentro da própria tela (docs/Design.pdf,
/// E2 "Início · sem internet"): o título da tela continua em cima e o cartão
/// explica o que houve, com o botão para tentar de novo.
class CartaoErro extends StatelessWidget {
  const CartaoErro({
    super.key,
    required this.icone,
    required this.titulo,
    required this.texto,
    required this.onTentarDeNovo,
    this.dica,
  });

  final IconData icone;
  final String titulo;
  final String texto;
  final VoidCallback onTentarDeNovo;

  /// Quadro embaixo do cartão, ex.: "Sem internet, sua tag NFC continua
  /// funcionando no terminal."
  final String? dica;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    foregroundColor: colorScheme.onSurfaceVariant,
                    child: Icon(icone, size: 36),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  texto,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                BotaoAcao(
                  rotulo: 'Tentar novamente',
                  icone: Icons.refresh,
                  onTocar: onTentarDeNovo,
                ),
              ],
            ),
          ),
        ),
        if (dica != null) ...[
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.contactless_outlined,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      dica!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
