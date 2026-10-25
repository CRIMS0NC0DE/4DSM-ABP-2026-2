import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/decisao_acesso.dart';
import '../widgets/estado_erro.dart';

/// U6 · Acesso negado. A mesma tela serve para N1 a N4: o texto já vem
/// pronto da API em titulo e oQueFazer. Tela cheia em vermelho, igual nos
/// dois modos do celular (docs/Design.pdf).
/// Sem a posição do celular (LOCALIZACAO_AUSENTE), mostra a E8.
class AcessoNegadoView extends StatelessWidget {
  const AcessoNegadoView({
    super.key,
    required this.decisao,
    required this.onTentarDeNovo,
    required this.onVoltar,
    required this.onPermitirLocalizacao,
  });

  final DecisaoAcesso decisao;

  /// Reabre o scanner: o QR da catraca troca a cada 10 s.
  final VoidCallback onTentarDeNovo;
  final VoidCallback onVoltar;
  final VoidCallback onPermitirLocalizacao;

  static const _fundo = AppColors.lightError;

  @override
  Widget build(BuildContext context) {
    if (decisao.semLocalizacao) {
      return EstadoErro(
        icone: Icons.location_off_outlined,
        titulo: decisao.titulo,
        texto: decisao.oQueFazer ?? '',
        dica:
            'A localização é usada só na hora de passar, para confirmar '
            'que você está perto da catraca.',
        rotuloAcao: 'Permitir localização',
        iconeAcao: Icons.my_location,
        onAcao: onPermitirLocalizacao,
        rotuloVoltar: 'Voltar ao início',
        iconeVoltar: Icons.home_outlined,
        onVoltar: onVoltar,
      );
    }

    final textTheme = Theme.of(context).textTheme;

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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 32),
                          const Center(
                            child: CircleAvatar(
                              radius: 56,
                              backgroundColor: Colors.white,
                              foregroundColor: _fundo,
                              child: Icon(Icons.close, size: 64),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Acesso negado',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _Motivo(decisao: decisao),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 32),
                          FilledButton.icon(
                            onPressed: onTentarDeNovo,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: _fundo,
                            ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tentar novamente'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: onVoltar,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
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
}

/// Cartão com o motivo e o que fazer, os dois vindos da API.
class _Motivo extends StatelessWidget {
  const _Motivo({required this.decisao});

  final DecisaoAcesso decisao;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final branco = textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    );
    final distancia = decisao.distanciaMetros;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Motivo', style: branco.labelMedium),
            const SizedBox(height: 4),
            Text(decisao.titulo, style: branco.titleMedium),
            if (decisao.motivo == 'LONGE_DO_TERMINAL' && distancia != null)
              Text(
                'Você está a $distancia m da catraca.',
                style: branco.bodyMedium,
              ),
            if (decisao.oQueFazer case final oQueFazer?) ...[
              const Divider(height: 24, color: Colors.white38),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('O que fazer', style: branco.labelMedium),
                        Text(oQueFazer, style: branco.bodyLarge),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
