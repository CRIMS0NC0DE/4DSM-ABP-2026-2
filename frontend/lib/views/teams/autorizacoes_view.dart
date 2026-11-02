import 'package:flutter/material.dart';

import '../../controllers/autorizacoes_controller.dart';
import '../../core/constants/formato.dart';
import '../../models/autorizacao.dart';
import '../../models/autorizacao_equipe.dart';
import '../../services/api_client.dart';
import '../user/autorizacao_textos.dart';
import '../widgets/botao_acao.dart';
import '../widgets/campo_selecao.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/estado_vazio.dart';
import '../widgets/selo_situacao.dart';
import '../widgets/tela_base.dart';
import 'autorizacao_form_view.dart';

/// A7 · Autorizações, com a A8 (filtros) num painel que sobe de baixo.
class AutorizacoesView extends StatefulWidget {
  AutorizacoesView({super.key, AutorizacoesController? controller})
    : controller = controller ?? AutorizacoesController();

  final AutorizacoesController controller;

  @override
  State<AutorizacoesView> createState() => _AutorizacoesViewState();
}

class _AutorizacoesViewState extends State<AutorizacoesView>
    with CarregaDados<List<AutorizacaoEquipe>, AutorizacoesView> {
  var _filtro = const FiltroAutorizacoes();

  AutorizacoesController get controller => widget.controller;

  @override
  Future<List<AutorizacaoEquipe>> buscar() => controller.listar(_filtro);

  void _aplicar(FiltroAutorizacoes filtro) {
    _filtro = filtro;
    recarregar();
  }

  Future<void> _abrirFiltros() async {
    final filtro = await showModalBottomSheet<FiltroAutorizacoes>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          _FiltrosAutorizacoes(inicial: _filtro, controller: controller),
    );
    if (filtro != null) _aplicar(filtro);
  }

  Future<void> _abrirFormulario([AutorizacaoEquipe? autorizacao]) async {
    final salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AutorizacaoFormView(
          autorizacao: autorizacao,
          controller: controller,
        ),
      ),
    );
    if (salvou == true && mounted) await carregar();
  }

  List<Widget> _lista(List<AutorizacaoEquipe> lista) {
    if (lista.isEmpty) {
      return [
        EstadoVazio(
          icone: Icons.event_busy,
          titulo: 'Nenhuma autorização encontrada',
          texto: 'Mude os filtros ou crie uma nova autorização.',
          rotuloAcao: 'Limpar filtros',
          iconeAcao: Icons.filter_alt_off,
          onAcao: () => _aplicar(const FiltroAutorizacoes()),
        ),
      ];
    }
    final hoje = DateTime.now();
    return [
      Text(
        '${lista.length} ${lista.length == 1 ? 'autorização' : 'autorizações'}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 12),
      for (final item in lista)
        _CartaoAutorizacaoEquipe(
          item: item,
          hoje: hoje,
          onEditar: () => _abrirFormulario(item),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final f = _filtro;
    return TelaBase(
      titulo: 'Autorizações',
      subtitulo: 'Quem pode entrar, onde e quando',
      onAtualizar: carregar,
      botaoFlutuante: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        icon: const Icon(Icons.add),
        label: const Text('Nova autorização'),
      ),
      filhos: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            BotaoFiltrar(onTocar: _abrirFiltros),
            if (f.situacao != null)
              Chip(label: Text('Status: ${f.situacao!.rotulo}')),
            if (f.pessoaNome != null) Chip(label: Text(f.pessoaNome!)),
            if (f.catracaNome != null) Chip(label: Text(f.catracaNome!)),
            if (f.de != null) Chip(label: Text('De ${Formato.data(f.de!)}')),
            if (f.ate != null) Chip(label: Text('Até ${Formato.data(f.ate!)}')),
          ],
        ),
        const SizedBox(height: 16),
        ...conteudo(_lista),
      ],
    );
  }
}

class _CartaoAutorizacaoEquipe extends StatelessWidget {
  const _CartaoAutorizacaoEquipe({
    required this.item,
    required this.hoje,
    required this.onEditar,
  });

  final AutorizacaoEquipe item;
  final DateTime hoje;
  final VoidCallback onEditar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final a = item.autorizacao;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onEditar,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.pessoaNome, style: textTheme.titleMedium),
                          Text(
                            '${a.catraca.nome} · ${a.catraca.edificio}',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SeloSituacao(situacao: a.situacao),
                  ],
                ),
                const Divider(height: 24),
                _Linha(Icons.event_outlined, a.periodoCurto(hoje)),
                _Linha(Icons.schedule, a.horario),
                _Linha(Icons.confirmation_number_outlined, a.usos),
                TextButton(
                  onPressed: onEditar,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: Text('Ver e editar')),
                      Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha(this.icone, this.texto);

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icone,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texto, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// A8 · Filtros.
class _FiltrosAutorizacoes extends StatefulWidget {
  const _FiltrosAutorizacoes({required this.inicial, required this.controller});

  final FiltroAutorizacoes inicial;
  final AutorizacoesController controller;

  @override
  State<_FiltrosAutorizacoes> createState() => _FiltrosAutorizacoesState();
}

class _FiltrosAutorizacoesState extends State<_FiltrosAutorizacoes> {
  late var _pessoaId = widget.inicial.pessoaId;
  late var _catracaId = widget.inicial.catracaId;
  late var _situacao = widget.inicial.situacao;
  late var _de = widget.inicial.de;
  late var _ate = widget.inicial.ate;
  OpcoesAutorizacao? _opcoes;

  @override
  void initState() {
    super.initState();
    _carregarOpcoes();
  }

  Future<void> _carregarOpcoes() async {
    try {
      final opcoes = await widget.controller.opcoes();
      if (mounted) setState(() => _opcoes = opcoes);
    } on ApiException catch (e) {
      if (mounted) await tratarErro(context, e);
    }
  }

  Future<void> _escolherData(bool inicio) async {
    final atual = inicio ? _de : _ate;
    final hoje = DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: atual ?? hoje,
      firstDate: DateTime(hoje.year - 5),
      lastDate: DateTime(hoje.year + 5),
    );
    if (data != null) setState(() => inicio ? _de = data : _ate = data);
  }

  void _mostrar() {
    final opcoes = _opcoes;
    Navigator.of(context).pop(
      FiltroAutorizacoes(
        pessoaId: _pessoaId,
        pessoaNome: opcoes?.pessoas
            .where((p) => p.id == _pessoaId)
            .firstOrNull
            ?.nome,
        catracaId: _catracaId,
        catracaNome: opcoes?.catracas
            .where((c) => c.catraca.id == _catracaId)
            .firstOrNull
            ?.catraca
            .nome,
        situacao: _situacao,
        de: _de,
        ate: _ate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final opcoes = _opcoes;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Filtrar autorizações',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            if (opcoes == null)
              const Carregando(mensagem: 'Carregando pessoas e locais…')
            else ...[
              CampoEscolha<String?>(
                rotulo: 'Pessoa',
                valor: _pessoaId,
                icone: Icons.person_outline,
                opcoes: [
                  (null, 'Todas as pessoas'),
                  for (final p in opcoes.pessoas) (p.id, p.nome),
                ],
                onMudar: (v) => setState(() => _pessoaId = v),
              ),
              const SizedBox(height: 16),
              CampoEscolha<String?>(
                rotulo: 'Local',
                valor: _catracaId,
                icone: Icons.location_on_outlined,
                opcoes: [
                  (null, 'Todos os locais'),
                  for (final c in opcoes.catracas) (c.catraca.id, c.caminho),
                ],
                onMudar: (v) => setState(() => _catracaId = v),
              ),
            ],
            const SizedBox(height: 16),
            EscolhaEmChips<SituacaoAutorizacao?>(
              rotulo: 'Status',
              valor: _situacao,
              opcoes: const [
                (null, 'Todas'),
                (SituacaoAutorizacao.ativa, 'Ativa'),
                (SituacaoAutorizacao.expirada, 'Expirada'),
                (SituacaoAutorizacao.cancelada, 'Cancelada'),
              ],
              onMudar: (v) => setState(() => _situacao = v),
            ),
            const SizedBox(height: 16),
            CampoSelecao(
              rotulo: 'Início do período',
              valor: _de == null ? 'Qualquer data' : Formato.data(_de!),
              icone: Icons.event_outlined,
              onTocar: () => _escolherData(true),
            ),
            const SizedBox(height: 16),
            CampoSelecao(
              rotulo: 'Fim do período',
              valor: _ate == null ? 'Qualquer data' : Formato.data(_ate!),
              icone: Icons.event_outlined,
              onTocar: () => _escolherData(false),
            ),
            const SizedBox(height: 24),
            BotaoAcao(
              rotulo: 'Mostrar resultados',
              icone: Icons.check,
              onTocar: _mostrar,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(const FiltroAutorizacoes()),
              child: const Text('Limpar filtros'),
            ),
          ],
        ),
      ),
    );
  }
}
