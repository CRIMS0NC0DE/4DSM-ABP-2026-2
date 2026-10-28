import 'package:flutter/material.dart';

import '../../core/formatos.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../widgets/admin_widgets.dart';

enum _Periodo {
  hoje('Hoje'),
  seteDias('7 dias'),
  trintaDias('30 dias'),
  tudo('Tudo');

  const _Periodo(this.rotulo);
  final String rotulo;

  DateTime? get desde {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    return switch (this) {
      _Periodo.hoje => hoje,
      _Periodo.seteDias => hoje.subtract(const Duration(days: 6)),
      _Periodo.trintaDias => hoje.subtract(const Duration(days: 29)),
      _Periodo.tudo => null,
    };
  }
}

/// Histórico de acessos (A11, A12 · RF06): tudo que passou pelas catracas,
/// liberado ou negado, com o motivo. Filtra por período, resultado, forma de
/// entrada (QR ou tag) e catraca.
class HistoricoView extends StatefulWidget {
  const HistoricoView({
    super.key,
    this.somenteNegados = false,
    this.titulo = 'Histórico de acessos',
    this._servico,
  });

  /// Abre já filtrado nos negados ("Ver motivos" do painel).
  final bool somenteNegados;
  final String titulo;
  final AdminService? _servico;

  @override
  State<HistoricoView> createState() => _HistoricoViewState();
}

class _HistoricoViewState extends State<HistoricoView> {
  late final AdminService _servico = widget._servico ?? AdminService.instancia;

  var _periodo = _Periodo.hoje;
  late bool? _liberado = widget.somenteNegados ? false : null;
  String? _metodo;
  CatracaComCaminho? _catraca;

  var _versao = 0;
  final _itens = <EventoAcesso>[];
  PaginaEventos? _primeira;
  Object? _erro;
  var _carregando = true;
  var _carregandoMais = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<PaginaEventos> _buscar(int pular) => _servico.eventos(
    de: _periodo.desde,
    liberado: _liberado,
    metodo: _metodo,
    accessPointId: _catraca?.catraca.id,
    pular: pular,
  );

  Future<void> _carregar() async {
    final versao = ++_versao;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final pagina = await _buscar(0);
      if (!mounted || versao != _versao) return;
      setState(() {
        _primeira = pagina;
        _itens
          ..clear()
          ..addAll(pagina.itens);
        _carregando = false;
      });
    } catch (erro) {
      if (!mounted || versao != _versao) return;
      setState(() {
        _erro = erro;
        _carregando = false;
      });
    }
  }

  Future<void> _carregarMais() async {
    final versao = _versao;
    setState(() => _carregandoMais = true);
    try {
      final pagina = await _buscar(_itens.length);
      if (!mounted || versao != _versao) return;
      setState(() {
        _itens.addAll(pagina.itens);
        _carregandoMais = false;
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() => _carregandoMais = false);
      avisar(context, mensagemDoErro(erro), erro: true);
    }
  }

  void _mudar(VoidCallback alteracao) {
    alteracao();
    _carregar();
  }

  void _limpar() => _mudar(() {
    _periodo = _Periodo.tudo;
    _liberado = null;
    _metodo = null;
    _catraca = null;
  });

  Future<void> _escolherCatraca() async {
    final escolhida = await showModalBottomSheet<Object>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _SeletorDeCatraca(servico: _servico, atual: _catraca),
    );
    if (escolhida == null) return;
    _mudar(() => _catraca = escolhida is CatracaComCaminho ? escolhida : null);
  }

  bool get _comFiltro =>
      _periodo != _Periodo.hoje ||
      _liberado != null ||
      _metodo != null ||
      _catraca != null;

  @override
  Widget build(BuildContext context) {
    final pagina = _primeira;
    return TelaAdmin(
      titulo: widget.titulo,
      subtitulo: pagina == null
          ? null
          : '${pagina.total} registros · ${pagina.liberados} liberados, '
                '${pagina.negados} negados',
      corpo: Column(
        children: [
          _Filtros(
            periodo: _periodo,
            liberado: _liberado,
            metodo: _metodo,
            catraca: _catraca,
            onPeriodo: (p) => _mudar(() => _periodo = p),
            onLiberado: (v) => _mudar(() => _liberado = v),
            onMetodo: (m) => _mudar(() => _metodo = m),
            onCatraca: _escolherCatraca,
          ),
          Expanded(child: _corpo()),
        ],
      ),
    );
  }

  Widget _corpo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null) {
      return ErroDeCarga(erro: _erro!, onTentarDeNovo: _carregar);
    }
    if (_itens.isEmpty) {
      return EstadoVazio(
        icone: Icons.search_off,
        titulo: 'Nenhum acesso encontrado',
        texto: 'Mude os filtros ou escolha outro período.',
        rotuloAcao: _comFiltro ? 'Limpar filtros' : 'Atualizar',
        iconeAcao: _comFiltro ? Icons.filter_alt_off : Icons.refresh,
        onAcao: _comFiltro ? _limpar : _carregar,
      );
    }
    final total = _primeira?.total ?? _itens.length;
    final temMais = _itens.length < total;
    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _itens.length + (temMais ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          if (i == _itens.length) {
            return Center(
              child: OutlinedButton.icon(
                onPressed: _carregandoMais ? null : _carregarMais,
                icon: _carregandoMais
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more),
                label: Text('Ver mais (${total - _itens.length} restantes)'),
              ),
            );
          }
          return CartaoEvento(evento: _itens[i]);
        },
      ),
    );
  }
}

class _Filtros extends StatelessWidget {
  const _Filtros({
    required this.periodo,
    required this.liberado,
    required this.metodo,
    required this.catraca,
    required this.onPeriodo,
    required this.onLiberado,
    required this.onMetodo,
    required this.onCatraca,
  });

  final _Periodo periodo;
  final bool? liberado;
  final String? metodo;
  final CatracaComCaminho? catraca;
  final ValueChanged<_Periodo> onPeriodo;
  final ValueChanged<bool?> onLiberado;
  final ValueChanged<String?> onMetodo;
  final VoidCallback onCatraca;

  @override
  Widget build(BuildContext context) {
    Widget chip(String rotulo, bool marcado, VoidCallback onTap) =>
        ChoiceChip(label: Text(rotulo), selected: marcado, onSelected: (_) => onTap());

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final p in _Periodo.values) ...[
            chip(p.rotulo, periodo == p, () => onPeriodo(p)),
            const SizedBox(width: 8),
          ],
          const VerticalDivider(width: 16),
          chip('Liberados', liberado == true, () => onLiberado(liberado == true ? null : true)),
          const SizedBox(width: 8),
          chip('Negados', liberado == false, () => onLiberado(liberado == false ? null : false)),
          const VerticalDivider(width: 16),
          chip('QR Code', metodo == 'QR', () => onMetodo(metodo == 'QR' ? null : 'QR')),
          const SizedBox(width: 8),
          chip('Tag NFC', metodo == 'NFC', () => onMetodo(metodo == 'NFC' ? null : 'NFC')),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.location_on_outlined, size: 18),
            label: Text(catraca?.catraca.nome ?? 'Todas as catracas'),
            onPressed: onCatraca,
          ),
        ],
      ),
    );
  }
}

/// Uma tentativa de acesso: hora, pessoa, catraca, resultado e motivo.
class CartaoEvento extends StatelessWidget {
  const CartaoEvento({super.key, required this.evento, this.comData = true});

  final EventoAcesso evento;

  /// Mostra o dia junto da hora (no painel, é sempre hoje).
  final bool comData;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final quando = comData
        ? '${Formatos.diaMes(evento.quando)} ${Formatos.hora(evento.quando)}'
        : Formatos.hora(evento.quando);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$quando  ${evento.nomeUsuario ?? 'Pessoa não identificada'}',
                    style: textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (evento.nomeCatraca != null)
              LinhaInfo(icone: Icons.location_on_outlined, texto: evento.nomeCatraca!),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Selo(
                  texto: evento.liberado ? 'Liberado' : 'Negado',
                  tom: evento.liberado ? TomSelo.sucesso : TomSelo.perigo,
                  icone: evento.liberado ? Icons.check_circle : Icons.cancel,
                ),
                Selo(
                  texto: evento.porNfc ? 'Tag NFC' : 'QR Code',
                  tom: TomSelo.neutro,
                  icone: evento.porNfc ? Icons.contactless_outlined : Icons.qr_code_2,
                ),
              ],
            ),
            if (!evento.liberado && evento.motivo != null)
              LinhaInfo(
                icone: Icons.info_outline,
                texto: 'Motivo: ${rotuloMotivo(evento.motivo)}',
              ),
          ],
        ),
      ),
    );
  }
}

class _SeletorDeCatraca extends StatelessWidget {
  const _SeletorDeCatraca({required this.servico, required this.atual});

  final AdminService servico;
  final CatracaComCaminho? atual;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: CarregaDados<List<Edificio>>(
          carregar: servico.locais,
          mensagem: 'Carregando catracas…',
          construir: (context, locais) {
            final catracas = locais.catracas;
            return ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: const Icon(Icons.select_all),
                  title: const Text('Todas as catracas'),
                  selected: atual == null,
                  onTap: () => Navigator.of(context).pop(false),
                ),
                for (final c in catracas)
                  ListTile(
                    leading: const Icon(Icons.qr_code_2),
                    title: Text(c.catraca.nome),
                    subtitle: Text(c.caminho),
                    selected: atual?.catraca.id == c.catraca.id,
                    onTap: () => Navigator.of(context).pop(c),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
