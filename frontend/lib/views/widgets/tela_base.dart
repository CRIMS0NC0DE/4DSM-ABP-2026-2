import 'package:flutter/material.dart';


class TelaBase extends StatelessWidget {
  const TelaBase({
    super.key,
    required this.titulo,
    required this.filhos,
    this.subtitulo,
    this.onAtualizar,
    this.botaoFlutuante,
    this.rodape,
  });

  final String titulo;
  final String? subtitulo;
  final List<Widget> filhos;
  final Future<void> Function()? onAtualizar;

  /// Ex.: "+ Novo usuário" (A3).
  final Widget? botaoFlutuante;

  /// Fixo embaixo, ex.: "Salvar alterações" (A4).
  final Widget? rodape;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final rolagem = SingleChildScrollView(
      // Puxar para atualizar funciona mesmo com a lista curta.
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            // Sobra embaixo para o botão flutuante não cobrir o último item.
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              botaoFlutuante == null ? 24 : 96,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (Navigator.of(context).canPop())
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Voltar'),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(titulo, style: textTheme.headlineMedium),
                if (subtitulo != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitulo!,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ...filhos,
              ],
            ),
          ),
        ),
      ),
    );

    final atualizar = onAtualizar;
    return Scaffold(
      floatingActionButton: botaoFlutuante,
      body: SafeArea(
        child: atualizar == null
            ? rolagem
            : RefreshIndicator(onRefresh: atualizar, child: rolagem),
      ),
      bottomNavigationBar: rodape == null
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                  child: Center(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 432),
                      child: SizedBox(width: double.infinity, child: rodape),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}