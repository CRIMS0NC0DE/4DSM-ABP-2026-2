import 'package:flutter/material.dart';

import '../../controllers/historico_controller.dart';
import '../../core/constants/motivos.dart';
import '../../models/evento_acesso.dart';
import '../widgets/campo_selecao.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/tela_base.dart';

/// Relatórios (só admin, sem tela no design). A API não tem rota agregada: os
/// totais vêm prontos de /access-events e os detalhes são somados aqui sobre
/// os [_limite] acessos mais recentes do período.
class RelatoriosView extends StatefulWidget {
  RelatoriosView({super.key, HistoricoController? controller})
    : controller = controller ?? HistoricoController(daEquipe: true);

  final HistoricoController controller;

  @override
  State<RelatoriosView> createState() => _RelatoriosViewState();
}

/// O máximo que a API devolve por página.
const _limite = 200;

class _RelatoriosViewState extends State<RelatoriosView>
    with CarregaDados<PaginaEventos, RelatoriosView> {
  var _periodo = PeriodoHistorico.seteDias;

  @override
  Future<PaginaEventos> buscar() => widget.controller.carregar(
    FiltroEventos(periodo: _periodo),
    limite: _limite,
  );

  Map<String, int> _contar(Iterable<String> chaves) {
    final contagem = <String, int>{};
    for (final chave in chaves) {
      contagem[chave] = (contagem[chave] ?? 0) + 1;
    }
    return Map.fromEntries(
      contagem.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  List<Widget> _relatorio(PaginaEventos p) {
    final textTheme = Theme.of(context).textTheme;
    final porLocal = _contar(p.itens.map((e) => e.catraca ?? 'Sem catraca'));
    final porMotivo = _contar(
      p.itens.where((e) => !e.liberado).map((e) => Motivos.titulo(e.motivo)),
    );

    return [
      Row(
        children: [
          Expanded(child: _Total(rotulo: 'Liberados', valor: p.liberados)),
          const SizedBox(width: 12),
          Expanded(child: _Total(rotulo: 'Negados', valor: p.negados)),
        ],
      ),
      if (p.total > _limite) ...[
        const SizedBox(height: 12),
        Text(
          'Os detalhes abaixo somam os $_limite acessos mais recentes de '
          '${p.total}.',
          style: textTheme.bodySmall,
        ),
      ],
      const SizedBox(height: 24),
      Text('Acessos por local', style: textTheme.titleMedium),
      const SizedBox(height: 8),
      if (porLocal.isEmpty) const Text('Nenhum acesso no período.'),
      for (final MapEntry(:key, :value) in porLocal.entries)
        _Barra(rotulo: key, valor: value, maximo: porLocal.values.first),
      const SizedBox(height: 24),
      Text('Motivos de recusa', style: textTheme.titleMedium),
      const SizedBox(height: 8),
      if (porMotivo.isEmpty) const Text('Nenhuma recusa no período.'),
      for (final MapEntry(:key, :value) in porMotivo.entries)
        _Barra(rotulo: key, valor: value, maximo: porMotivo.values.first),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      titulo: 'Relatórios',
      subtitulo: 'Acessos por período e local',
      onAtualizar: carregar,
      filhos: [
        EscolhaEmChips<PeriodoHistorico>(
          rotulo: 'Período',
          valor: _periodo,
          opcoes: [for (final p in PeriodoHistorico.values) (p, p.rotulo)],
          onMudar: (p) {
            _periodo = p;
            recarregar();
          },
        ),
        const SizedBox(height: 20),
        ...conteudo(_relatorio),
      ],
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.rotulo, required this.valor});

  final String rotulo;
  final int valor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$valor', style: textTheme.headlineMedium),
            Text(rotulo, style: textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra({
    required this.rotulo,
    required this.valor,
    required this.maximo,
  });

  final String rotulo;
  final int valor;
  final int maximo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(rotulo)),
              const SizedBox(width: 8),
              Text('$valor'),
            ],
          ),
          const SizedBox(height: 4),
          ExcludeSemantics(
            child: LinearProgressIndicator(
              value: maximo == 0 ? 0 : valor / maximo,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}
