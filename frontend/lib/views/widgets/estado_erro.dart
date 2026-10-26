import 'package:flutter/material.dart';

import 'botao_acao.dart';

/// Tela de um problema que a própria pessoa resolve (docs/Design.pdf: sem
/// internet, câmera negada, localização negada): ícone num círculo, o que
/// aconteceu, a ação que resolve e o Voltar.
class EstadoErro extends StatelessWidget {
  const EstadoErro({
    super.key,
    required this.icone,
    required this.titulo,
    required this.texto,
    required this.rotuloAcao,
    required this.iconeAcao,
    required this.onAcao,
    required this.rotuloVoltar,
    required this.iconeVoltar,
    required this.onVoltar,
    this.dica,
    this.destaque = true,
  });

  final IconData icone;
  final String titulo;
  final String texto;

  final String rotuloAcao;
  final IconData iconeAcao;
  final VoidCallback onAcao;

  final String rotuloVoltar;
  final IconData iconeVoltar;
  final VoidCallback onVoltar;

  /// Quadro informativo embaixo, ex.: "Sem internet, sua tag NFC continua
  /// funcionando no terminal."
  final String? dica;

  /// Círculo na cor da marca (permissões) ou cinza (sem internet).
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        // Rola quando não cabe (fonte grande).
        child: LayoutBuilder(
          builder: (context, tela) => SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 480,
                  minHeight: tela.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: destaque
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest,
                          foregroundColor: destaque
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                          child: Icon(icone, size: 36),
                        ),
                      ),
                      const SizedBox(height: 24),
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
                      const SizedBox(height: 32),
                      BotaoAcao(
                        rotulo: rotuloAcao,
                        icone: iconeAcao,
                        onTocar: onAcao,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: onVoltar,
                        icon: Icon(iconeVoltar),
                        label: Text(rotuloVoltar),
                      ),
                      if (dica != null) ...[
                        const SizedBox(height: 24),
                        _Dica(texto: dica!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dica extends StatelessWidget {
  const _Dica({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.contactless_outlined, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(texto, style: textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}
