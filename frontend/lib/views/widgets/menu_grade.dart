import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/opcao_menu.dart';

/// Menu em grade dos perfis (admin, controlador de acesso, síndico e morador).
/// Cada perfil só passa as próprias seções.
/// Tem 2 colunas no celular e ganha mais em telas largas.
/// Com fonte grande ou tela estreita, cai para 1 coluna em vez de
/// cortar palavra no meio.
class MenuGrade extends StatelessWidget {
  const MenuGrade({
    super.key,
    required this.perfil,
    required this.iconePerfil,
    required this.secoes,
    required this.onSelecionar,
    required this.onSair,
  });

  final String perfil;
  final IconData iconePerfil;
  final List<SecaoMenu> secoes;
  final ValueChanged<OpcaoMenu> onSelecionar;
  final VoidCallback onSair;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final medidas = _MedidasCard(context, secoes);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          sliver: SliverToBoxAdapter(
            child: _Cabecalho(perfil: perfil, iconePerfil: iconePerfil),
          ),
        ),
        for (final secao in secoes) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Text(secao.titulo, style: textTheme.titleMedium),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final largura = constraints.crossAxisExtent;
                final colunas = medidas.colunas(largura);
                final larguraCard =
                    (largura - _espaco * (colunas - 1)) / colunas;

                return SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: colunas,
                    mainAxisExtent: medidas.altura(larguraCard),
                    mainAxisSpacing: _espaco,
                    crossAxisSpacing: _espaco,
                  ),
                  itemCount: secao.opcoes.length,
                  itemBuilder: (context, i) {
                    final opcao = secao.opcoes[i];
                    return _CardOpcao(
                      opcao: opcao,
                      onTap: () => onSelecionar(opcao),
                    );
                  },
                );
              },
            ),
          ),
        ],
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
          sliver: SliverToBoxAdapter(
            child: OutlinedButton.icon(
              onPressed: onSair,
              icon: const Icon(Icons.logout),
              label: const Text('Sair da conta'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

const _espaco = 12.0;
const _paddingCard = 12.0;
const _tamanhoIcone = 44.0;

/// Mede os cards com os estilos de texto reais, para a grade acompanhar
/// a fonte escolhida no celular.
class _MedidasCard {
  _MedidasCard(BuildContext context, List<SecaoMenu> secoes)
    : _opcoes = [for (final secao in secoes) ...secao.opcoes],
      _textTheme = Theme.of(context).textTheme,
      _estiloBase = DefaultTextStyle.of(context).style,
      _scaler = MediaQuery.textScalerOf(context);

  final List<OpcaoMenu> _opcoes;
  final TextTheme _textTheme;
  final TextStyle _estiloBase;
  final TextScaler _scaler;

  /// Card mais largo que isso vira mais uma coluna.
  static const _larguraMaxima = 240.0;

  /// Quantas colunas cabem sem cortar palavra de título no meio.
  int colunas(double largura) {
    final palavras = {for (final opcao in _opcoes) ...opcao.titulo.split(' ')};
    final maiorPalavra = palavras
        .map((palavra) => _medir(palavra, _textTheme.titleMedium).width)
        .fold(0.0, math.max);
    final larguraMinima = 2 * _paddingCard + maiorPalavra.ceilToDouble();

    final pelaTela = ((largura + _espaco) / (_larguraMaxima + _espaco)).ceil();
    final peloTexto = ((largura + _espaco) / (larguraMinima + _espaco)).floor();
    return math.max(1, math.min(pelaTela, peloTexto));
  }

  /// Altura do card mais alto, para todos ficarem do mesmo tamanho.
  double altura(double larguraCard) {
    final larguraTexto = larguraCard - 2 * _paddingCard;
    double maior(TextStyle? estilo, String Function(OpcaoMenu) texto) => _opcoes
        .map((opcao) => _medir(texto(opcao), estilo, larguraTexto).height)
        .fold(0.0, math.max);

    final altura =
        2 * _paddingCard +
        _tamanhoIcone +
        12 +
        maior(_textTheme.titleMedium, (opcao) => opcao.titulo) +
        4 +
        maior(_textTheme.bodySmall, (opcao) => opcao.descricao);
    return altura.ceilToDouble();
  }

  /// Mede como o card desenha: no máximo 2 linhas, com reticências.
  Size _medir(
    String texto,
    TextStyle? estilo, [
    double larguraMaxima = double.infinity,
  ]) {
    final painter = TextPainter(
      text: TextSpan(text: texto, style: _estiloBase.merge(estilo)),
      textDirection: TextDirection.ltr,
      textScaler: _scaler,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: larguraMaxima);
    final tamanho = painter.size;
    painter.dispose();
    return tamanho;
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.perfil, required this.iconePerfil});

  final String perfil;
  final IconData iconePerfil;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Menu', style: textTheme.headlineMedium),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconePerfil, size: 18, color: AppColors.onPrimaryContainer),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  perfil,
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardOpcao extends StatelessWidget {
  const _CardOpcao({required this.opcao, required this.onTap});

  final OpcaoMenu opcao;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (cor, fundo) = switch (opcao.tom) {
      TomOpcao.padrao => (AppColors.primary, AppColors.primaryContainer),
      TomOpcao.sucesso => (AppColors.success, AppColors.successContainer),
      TomOpcao.atencao => (AppColors.warning, AppColors.warningContainer),
      TomOpcao.perigo => (AppColors.error, AppColors.errorContainer),
    };

    return Semantics(
      button: true,
      container: true,
      child: Card(
        // O espaço entre os cards vem da grade.
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(_paddingCard),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: _tamanhoIcone,
                  height: _tamanhoIcone,
                  decoration: BoxDecoration(
                    color: fundo,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(opcao.icone, color: cor),
                ),
                const SizedBox(height: 12),
                Text(
                  opcao.titulo,
                  style: textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  opcao.descricao,
                  style: textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
