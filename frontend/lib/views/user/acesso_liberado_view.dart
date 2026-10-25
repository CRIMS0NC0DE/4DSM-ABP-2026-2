import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/decisao_acesso.dart';

/// U5 · Acesso liberado. Tela cheia em verde, igual nos dois modos do
/// celular, para dar para ver de longe (docs/Design.pdf).
class AcessoLiberadoView extends StatelessWidget {
  const AcessoLiberadoView({
    super.key,
    required this.decisao,
    required this.onConcluir,
  });

  final DecisaoAcesso decisao;
  final VoidCallback onConcluir;

  static const _fundo = AppColors.lightSuccess;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final catraca = decisao.catraca;
    final usos = decisao.usosRestantes;

    return Scaffold(
      backgroundColor: _fundo,
      body: SafeArea(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        children: [
                          const SizedBox(height: 32),
                          const CircleAvatar(
                            radius: 56,
                            backgroundColor: Colors.white,
                            foregroundColor: _fundo,
                            child: Icon(Icons.check, size: 64),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            decisao.titulo,
                            textAlign: TextAlign.center,
                            style: textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pode passar pela catraca.',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 32),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  if (catraca != null)
                                    _Linha(
                                      icone: Icons.location_on_outlined,
                                      texto: catraca.nome,
                                      detalhe: catraca.caminho,
                                    ),
                                  _Linha(
                                    icone: Icons.schedule,
                                    texto: 'Hoje, às ${_hora(decisao.em)}',
                                  ),
                                  if (usos != null)
                                    _Linha(
                                      icone: Icons.confirmation_number_outlined,
                                      texto: _usos(usos),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: onConcluir,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: _fundo,
                            ),
                            icon: const Icon(Icons.home_outlined),
                            label: const Text('Voltar ao início'),
                          ),
                        ],
                      ),
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

  static String _hora(DateTime em) {
    final local = em.toLocal();
    String doisDigitos(int n) => n.toString().padLeft(2, '0');
    return '${doisDigitos(local.hour)}:${doisDigitos(local.minute)}';
  }

  static String _usos(int restantes) => switch (restantes) {
    0 => 'Este foi seu último uso',
    1 => 'Resta 1 uso',
    _ => 'Restam $restantes usos',
  };
}

class _Linha extends StatelessWidget {
  const _Linha({required this.icone, required this.texto, this.detalhe});

  final IconData icone;
  final String texto;
  final String? detalhe;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  texto,
                  style: textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                if (detalhe != null)
                  Text(
                    detalhe!,
                    style: textTheme.bodyMedium?.copyWith(color: Colors.white),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
