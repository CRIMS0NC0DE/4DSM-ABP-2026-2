import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../controllers/relatorios_controller.dart';
import '../../core/constants/formato.dart';
import '../../core/theme/app_colors.dart';
import '../../models/local.dart';
import '../../models/relatorio_acessos.dart';
import '../../services/api_client.dart';
import '../widgets/campo_selecao.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/estado_vazio.dart';
import '../widgets/tela_base.dart';

/// Relatórios (sem tela no design): GET /reports/access soma na API todos os
/// acessos do período, por dia, método, catraca e motivo de recusa.
class RelatoriosView extends StatefulWidget {
  RelatoriosView({super.key, RelatoriosController? controller})
    : controller = controller ?? RelatoriosController();

  final RelatoriosController controller;

  @override
  State<RelatoriosView> createState() => _RelatoriosViewState();
}

/// Quantos motivos de recusa a tela lista; o resto vira uma linha só.
const _motivosNaTela = 5;

String _vezes(int n, String singular, String plural) =>
    n == 1 ? '1 $singular' : '$n $plural';

class _RelatoriosViewState extends State<RelatoriosView>
    with CarregaDados<RelatorioAcessos, RelatoriosView> {
  var _periodo = PeriodoRelatorio.seteDias;

  /// null = todas as catracas.
  String? _catracaId;
  List<CatracaNoLocal> _catracas = const [];

  @override
  void initState() {
    super.initState();
    _carregarCatracas();
  }

  @override
  Future<RelatorioAcessos> buscar() =>
      widget.controller.carregar(periodo: _periodo, catracaId: _catracaId);

  Future<void> _carregarCatracas() async {
    try {
      final lista = await widget.controller.catracas();
      if (mounted) setState(() => _catracas = lista);
    } on ApiException {
      // Sem a lista, o filtro de catraca só não aparece.
    }
  }

  /// Puxar para atualizar e "Tentar novamente" também buscam as catracas,
  /// se elas não vieram da primeira vez.
  Future<void> _atualizar() async {
    if (_catracas.isEmpty) _carregarCatracas();
    await carregar();
  }

  @override
  void recarregar() {
    if (_catracas.isEmpty) _carregarCatracas();
    super.recarregar();
  }

  String? _intervalo(RelatorioAcessos r) {
    final (de, ate) = (r.de, r.ate);
    if (de == null || ate == null) return null;
    return de == ate
        ? 'Período: ${Formato.data(de)}'
        : 'Período: ${Formato.diaMes(de)} a ${Formato.data(ate)}';
  }

  List<Widget> _relatorio(RelatorioAcessos r) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final status = StatusColors.of(context);
    final intervalo = _intervalo(r);
    final cabecalho = [
      if (intervalo != null)
        Text(
          intervalo,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
    ];

    if (r.vazio) {
      return [
        ...cabecalho,
        const EstadoVazio(
          icone: Icons.insert_chart_outlined,
          titulo: 'Nenhum acesso no período',
          texto:
              'Quando alguém passar pela catraca, os números aparecem aqui. '
              'Tente um período maior.',
        ),
      ];
    }

    final maiorMetodo = r.porMetodo.map((m) => m.total).fold(0, math.max);
    final maiorCatraca = r.porCatraca.map((c) => c.total).fold(0, math.max);
    final motivos = r.porMotivo.take(_motivosNaTela).toList();
    final outrosMotivos = r.porMotivo.skip(_motivosNaTela).toList();

    return [
      ...cabecalho,
      const SizedBox(height: 12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _Total(
              icone: Icons.sync_alt,
              cor: colorScheme.primary,
              fundo: colorScheme.primaryContainer,
              valor: '${r.total}',
              rotulo: 'Acessos no total',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Total(
              icone: Icons.percent,
              cor: status.success,
              fundo: status.successContainer,
              valor: '${r.taxaLiberacao}%',
              rotulo: 'Taxa de liberação',
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _Total(
              icone: Icons.check_circle_outline,
              cor: status.success,
              fundo: status.successContainer,
              valor: '${r.liberados}',
              rotulo: 'Liberados',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Total(
              icone: Icons.block,
              cor: colorScheme.error,
              fundo: colorScheme.errorContainer,
              valor: '${r.negados}',
              rotulo: 'Negados',
            ),
          ),
        ],
      ),
      if (r.porDia.isNotEmpty) ...[
        const SizedBox(height: 24),
        Text('Acessos por dia', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        _GraficoDias(dias: r.porDia),
      ],
      const SizedBox(height: 24),
      Text('Por método', style: textTheme.titleMedium),
      const SizedBox(height: 4),
      for (final metodo in r.porMetodo)
        _BarraDividida(
          icone: switch (metodo.metodo) {
            'NFC' => Icons.contactless_outlined,
            'CELULAR' => Icons.smartphone,
            _ => Icons.qr_code_2,
          },
          rotulo: metodo.texto,
          contagem: metodo,
          maximo: maiorMetodo,
        ),
      // Filtrado por uma catraca, a divisão por catraca não diz nada.
      if (_catracaId == null && r.porCatraca.isNotEmpty) ...[
        const SizedBox(height: 24),
        Text('Por catraca', style: textTheme.titleMedium),
        const SizedBox(height: 4),
        for (final catraca in r.porCatraca)
          _BarraDividida(
            icone: Icons.location_on_outlined,
            rotulo: catraca.nome,
            contagem: catraca,
            maximo: maiorCatraca,
          ),
      ],
      const SizedBox(height: 24),
      Text('Principais motivos de negação', style: textTheme.titleMedium),
      const SizedBox(height: 4),
      if (motivos.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Nenhum acesso negado no período.',
            style: textTheme.bodyMedium,
          ),
        ),
      for (final motivo in motivos)
        _BarraMotivo(
          rotulo: motivo.titulo,
          valor: motivo.total,
          maximo: motivos.first.total,
        ),
      if (outrosMotivos.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${_vezes(outrosMotivos.length, 'outro motivo', 'outros motivos')}'
            ': ${_vezes(outrosMotivos.fold(0, (s, m) => s + m.total), 'recusa', 'recusas')}.',
            style: textTheme.bodySmall,
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      titulo: 'Relatórios',
      subtitulo: 'Acessos por período e catraca',
      onAtualizar: _atualizar,
      filhos: [
        EscolhaEmChips<PeriodoRelatorio>(
          rotulo: 'Período',
          valor: _periodo,
          opcoes: [for (final p in PeriodoRelatorio.values) (p, p.rotulo)],
          onMudar: (p) {
            _periodo = p;
            recarregar();
          },
        ),
        if (_catracas.isNotEmpty) ...[
          const SizedBox(height: 16),
          CampoEscolha<String?>(
            rotulo: 'Catraca',
            valor: _catracaId,
            icone: Icons.location_on_outlined,
            opcoes: [
              (null, 'Todas as catracas'),
              for (final c in _catracas) (c.catraca.id, c.caminho),
            ],
            onMudar: (id) {
              _catracaId = id;
              recarregar();
            },
          ),
        ],
        const SizedBox(height: 20),
        ...conteudo(_relatorio),
      ],
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({
    required this.icone,
    required this.cor,
    required this.fundo,
    required this.valor,
    required this.rotulo,
  });

  final IconData icone;
  final Color cor;
  final Color fundo;
  final String valor;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: fundo,
              child: Icon(icone, color: cor),
            ),
            const SizedBox(height: 12),
            // Número grande com a fonte no dobro: diminui em vez de quebrar.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(valor, style: textTheme.headlineMedium),
            ),
            Text(rotulo, style: textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Barras por dia, liberados embaixo e negados em cima, feitas só com
/// widgets. Tocar e segurar numa barra mostra os números do dia.
class _GraficoDias extends StatelessWidget {
  const _GraficoDias({required this.dias});

  final List<AcessosDoDia> dias;

  static const _altura = 140.0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final status = StatusColors.of(context);
    final maximo = dias.map((d) => d.total).fold(0, math.max);
    final maiorDia = dias.where((d) => d.total == maximo).firstOrNull;
    final espaco = dias.length > 14 ? 1.0 : 4.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _Legenda(cor: status.success, texto: 'Liberados'),
                _Legenda(cor: colorScheme.error, texto: 'Negados'),
              ],
            ),
            const SizedBox(height: 12),
            Semantics(
              label: maiorDia == null || maximo == 0
                  ? 'Gráfico por dia: nenhum acesso.'
                  : 'Gráfico por dia: o dia com mais acessos foi '
                        '${Formato.diaMes(maiorDia.dia)}, com $maximo.',
              child: ExcludeSemantics(
                child: SizedBox(
                  height: _altura,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final dia in dias)
                        Expanded(
                          child: Tooltip(
                            message:
                                '${Formato.diaMes(dia.dia)}: '
                                '${_vezes(dia.liberados, 'liberado', 'liberados')}, '
                                '${_vezes(dia.negados, 'negado', 'negados')}',
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 40),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: espaco,
                                  ),
                                  child: _Coluna(
                                    dia: dia,
                                    maximo: maximo,
                                    altura: _altura,
                                    liberados: status.success,
                                    negados: colorScheme.error,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Divider(height: 1, color: colorScheme.outlineVariant),
            const SizedBox(height: 4),
            ExcludeSemantics(
              child: Row(
                children: [
                  Text(
                    Formato.diaMes(dias.first.dia),
                    style: textTheme.bodySmall,
                  ),
                  const Spacer(),
                  if (dias.length > 1)
                    Text(
                      Formato.diaMes(dias.last.dia),
                      style: textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Coluna extends StatelessWidget {
  const _Coluna({
    required this.dia,
    required this.maximo,
    required this.altura,
    required this.liberados,
    required this.negados,
  });

  final AcessosDoDia dia;
  final int maximo;
  final double altura;
  final Color liberados;
  final Color negados;

  @override
  Widget build(BuildContext context) {
    if (maximo == 0 || dia.total == 0) return const SizedBox.expand();
    // Um dia com poucos acessos ainda aparece; nunca passa da altura.
    final barra = math.min(altura, math.max(3.0, altura * dia.total / maximo));
    final alturaNegados = barra * dia.negados / dia.total;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (dia.negados > 0)
                SizedBox(
                  height: alturaNegados,
                  child: ColoredBox(color: negados),
                ),
              if (dia.liberados > 0)
                SizedBox(
                  height: barra - alturaNegados,
                  child: ColoredBox(color: liberados),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda({required this.cor, required this.texto});

  final Color cor;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(2),
          ),
          child: const SizedBox(width: 12, height: 12),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(texto, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

/// Uma linha do relatório: o total, a barra dividida entre liberados e
/// negados (do tamanho do total, perto do [maximo]) e os dois números.
class _BarraDividida extends StatelessWidget {
  const _BarraDividida({
    required this.icone,
    required this.rotulo,
    required this.contagem,
    required this.maximo,
  });

  final IconData icone;
  final String rotulo;
  final ContagemAcessos contagem;
  final int maximo;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final status = StatusColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icone, size: 20, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(child: Text(rotulo)),
              const SizedBox(width: 8),
              Text('${contagem.total}', style: textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 6),
          ExcludeSemantics(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: ColoredBox(
                  color: colorScheme.surfaceContainerHighest,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: maximo == 0 ? 0 : contagem.total / maximo,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (contagem.liberados > 0)
                            Expanded(
                              flex: contagem.liberados,
                              child: ColoredBox(color: status.success),
                            ),
                          if (contagem.negados > 0)
                            Expanded(
                              flex: contagem.negados,
                              child: ColoredBox(color: colorScheme.error),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_vezes(contagem.liberados, 'liberado', 'liberados')} · '
            '${_vezes(contagem.negados, 'negado', 'negados')}',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _BarraMotivo extends StatelessWidget {
  const _BarraMotivo({
    required this.rotulo,
    required this.valor,
    required this.maximo,
  });

  final String rotulo;
  final int valor;
  final int maximo;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(rotulo)),
              const SizedBox(width: 8),
              Text('$valor', style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 6),
          ExcludeSemantics(
            child: LinearProgressIndicator(
              value: maximo == 0 ? 0 : valor / maximo,
              minHeight: 8,
              color: colorScheme.error,
              backgroundColor: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
