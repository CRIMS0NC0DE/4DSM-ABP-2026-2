import 'package:flutter/material.dart';

import '../../controllers/historico_controller.dart';
import '../../models/evento_acesso.dart';
import '../../models/local.dart';
import '../../services/api_client.dart';
import '../widgets/botao_acao.dart';
import '../widgets/campo_selecao.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/estado_vazio.dart';
import '../widgets/item_evento.dart';
import '../widgets/tela_base.dart';

/// A11 · Histórico de acessos, com A12 (sem resultados) e os filtros. É a
/// mesma tela para os quatro perfis e para "Acessos negados" ([soNegados]).
class HistoricoView extends StatefulWidget {
  HistoricoView({
    super.key,
    required this.daEquipe,
    this.soNegados = false,
    HistoricoController? controller,
  }) : controller = controller ?? HistoricoController(daEquipe: daEquipe);

  /// true: todos os acessos (/access-events). false: só os de quem está logado.
  final bool daEquipe;
  final bool soNegados;
  final HistoricoController controller;

  @override
  State<HistoricoView> createState() => _HistoricoViewState();
}

class _HistoricoViewState extends State<HistoricoView>
    with CarregaDados<PaginaEventos, HistoricoView> {
  var _filtro = const FiltroEventos();
  var _carregandoMais = false;

  HistoricoController get controller => widget.controller;

  FiltroEventos get _filtroDaTela => FiltroEventos(
    periodo: _filtro.periodo,
    negados: widget.soNegados ? true : _filtro.negados,
    metodo: _filtro.metodo,
    catracaId: _filtro.catracaId,
    catracaNome: _filtro.catracaNome,
  );

  @override
  Future<PaginaEventos> buscar() => controller.carregar(_filtroDaTela);

  Future<void> _carregarMais(PaginaEventos atual) async {
    setState(() => _carregandoMais = true);
    try {
      final proxima = await controller.carregar(
        _filtroDaTela,
        pular: atual.itens.length,
      );
      if (mounted) setState(() => dados = atual.comMais(proxima));
    } on ApiException catch (e) {
      if (mounted) await tratarErro(context, e);
    } finally {
      if (mounted) setState(() => _carregandoMais = false);
    }
  }

  void _aplicar(FiltroEventos filtro) {
    _filtro = filtro;
    recarregar();
  }

  Future<void> _abrirFiltros() async {
    final filtro = await showModalBottomSheet<FiltroEventos>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FiltrosHistorico(
        inicial: _filtro,
        soNegados: widget.soNegados,
        controller: controller,
      ),
    );
    if (filtro != null) _aplicar(filtro);
  }

  List<Widget> _chips() {
    return [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          BotaoFiltrar(onTocar: _abrirFiltros),
          if (_filtro.periodo != PeriodoHistorico.tudo)
            InputChip(
              label: Text(controller.rotuloPeriodo(_filtro.periodo)),
              onDeleted: () => _aplicar(
                FiltroEventos(
                  negados: _filtro.negados,
                  metodo: _filtro.metodo,
                  catracaId: _filtro.catracaId,
                  catracaNome: _filtro.catracaNome,
                ),
              ),
            ),
          if (_filtro.negados != null)
            InputChip(
              label: Text(_filtro.negados! ? 'Negados' : 'Liberados'),
              onDeleted: () => _aplicar(
                FiltroEventos(
                  periodo: _filtro.periodo,
                  metodo: _filtro.metodo,
                  catracaId: _filtro.catracaId,
                  catracaNome: _filtro.catracaNome,
                ),
              ),
            ),
          if (_filtro.metodo != null)
            InputChip(
              label: Text(_filtro.metodo == 'NFC' ? 'Tag NFC' : 'QR Code'),
              onDeleted: () => _aplicar(
                FiltroEventos(
                  periodo: _filtro.periodo,
                  negados: _filtro.negados,
                  catracaId: _filtro.catracaId,
                  catracaNome: _filtro.catracaNome,
                ),
              ),
            ),
          if (_filtro.catracaId != null)
            InputChip(
              label: Text(_filtro.catracaNome ?? 'Catraca'),
              onDeleted: () => _aplicar(
                FiltroEventos(
                  periodo: _filtro.periodo,
                  negados: _filtro.negados,
                  metodo: _filtro.metodo,
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 16),
    ];
  }

  String _resumo(PaginaEventos p) => widget.soNegados
      ? '${p.total} ${p.total == 1 ? 'acesso negado' : 'acessos negados'}'
      : '${p.total} registros · ${p.liberados} liberados, ${p.negados} negados';

  List<Widget> _lista(PaginaEventos pagina) {
    if (pagina.itens.isEmpty) {
      return [
        EstadoVazio(
          icone: Icons.search_off,
          titulo: 'Nenhum acesso encontrado',
          texto: _filtro.vazio
              ? 'Quando alguém passar pela catraca, o acesso aparece aqui.'
              : 'Mude os filtros ou escolha outro período.',
          rotuloAcao: _filtro.vazio ? null : 'Limpar filtros',
          iconeAcao: Icons.filter_alt_off,
          onAcao: () => _aplicar(const FiltroEventos()),
        ),
      ];
    }
    return [
      Text(_resumo(pagina), style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 12),
      for (final evento in pagina.itens)
        ItemEvento(
          evento: evento,
          mostrarPessoa: widget.daEquipe,
          mostrarOQueFazer: !widget.daEquipe,
        ),
      if (pagina.itens.length < pagina.total)
        OutlinedButton.icon(
          onPressed: _carregandoMais ? null : () => _carregarMais(pagina),
          icon: const Icon(Icons.expand_more),
          label: Text(_carregandoMais ? 'Carregando…' : 'Carregar mais'),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      titulo: widget.soNegados ? 'Acessos negados' : 'Histórico de acessos',
      subtitulo: widget.soNegados
          ? (widget.daEquipe ? 'Motivo de cada recusa' : 'Motivo e o que fazer')
          : (widget.daEquipe
                ? 'Entradas liberadas e negadas'
                : 'Suas entradas liberadas e negadas'),
      onAtualizar: carregar,
      filhos: [..._chips(), ...conteudo(_lista)],
    );
  }
}

class _FiltrosHistorico extends StatefulWidget {
  const _FiltrosHistorico({
    required this.inicial,
    required this.soNegados,
    required this.controller,
  });

  final FiltroEventos inicial;
  final bool soNegados;
  final HistoricoController controller;

  @override
  State<_FiltrosHistorico> createState() => _FiltrosHistoricoState();
}

class _FiltrosHistoricoState extends State<_FiltrosHistorico> {
  late var _periodo = widget.inicial.periodo;
  late var _negados = widget.inicial.negados;
  late var _metodo = widget.inicial.metodo;
  late var _catracaId = widget.inicial.catracaId;
  List<CatracaNoLocal> _catracas = const [];

  @override
  void initState() {
    super.initState();
    _carregarCatracas();
  }

  Future<void> _carregarCatracas() async {
    try {
      final lista = await widget.controller.catracas();
      if (mounted) setState(() => _catracas = lista);
    } on ApiException {
      // Sem a lista, o filtro de local só não aparece.
    }
  }

  void _mostrar() {
    final catraca = _catracas
        .where((c) => c.catraca.id == _catracaId)
        .firstOrNull;
    Navigator.of(context).pop(
      FiltroEventos(
        periodo: _periodo,
        negados: _negados,
        metodo: _metodo,
        catracaId: _catracaId,
        catracaNome: catraca?.catraca.nome ?? widget.inicial.catracaNome,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Filtrar histórico',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            EscolhaEmChips<PeriodoHistorico>(
              rotulo: 'Período',
              valor: _periodo,
              opcoes: [for (final p in PeriodoHistorico.values) (p, p.rotulo)],
              onMudar: (p) => setState(() => _periodo = p),
            ),
            if (!widget.soNegados) ...[
              const SizedBox(height: 20),
              EscolhaEmChips<bool?>(
                rotulo: 'Resultado',
                valor: _negados,
                opcoes: const [
                  (null, 'Todos'),
                  (false, 'Liberados'),
                  (true, 'Negados'),
                ],
                onMudar: (v) => setState(() => _negados = v),
              ),
            ],
            const SizedBox(height: 20),
            EscolhaEmChips<String?>(
              rotulo: 'Como entrou',
              valor: _metodo,
              opcoes: const [
                (null, 'Todos'),
                ('QR', 'QR Code'),
                ('NFC', 'Tag NFC'),
              ],
              onMudar: (v) => setState(() => _metodo = v),
            ),
            if (_catracas.isNotEmpty) ...[
              const SizedBox(height: 20),
              CampoEscolha<String?>(
                rotulo: 'Local',
                valor: _catracaId,
                icone: Icons.location_on_outlined,
                opcoes: [
                  (null, 'Todos os locais'),
                  for (final c in _catracas) (c.catraca.id, c.caminho),
                ],
                onMudar: (v) => setState(() => _catracaId = v),
              ),
            ],
            const SizedBox(height: 24),
            BotaoAcao(
              rotulo: 'Mostrar resultados',
              icone: Icons.check,
              onTocar: _mostrar,
            ),
          ],
        ),
      ),
    );
  }
}
