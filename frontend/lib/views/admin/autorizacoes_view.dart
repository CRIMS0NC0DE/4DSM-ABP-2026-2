import 'package:flutter/material.dart';

import '../../core/formatos.dart';
import '../../core/theme/app_colors.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../widgets/admin_widgets.dart';
import 'autorizacao_form_view.dart';

/// Filtros da lista de autorizações (A8).
class FiltroAutorizacoes {
  const FiltroAutorizacoes({
    this.situacao,
    this.usuario,
    this.catraca,
    this.de,
    this.ate,
  });

  /// ATIVA, EXPIRADA ou CANCELADA (o que a API filtra).
  final String? situacao;
  final UsuarioAdmin? usuario;
  final CatracaComCaminho? catraca;
  final DateTime? de;
  final DateTime? ate;

  bool get vazio =>
      situacao == null &&
      usuario == null &&
      catraca == null &&
      de == null &&
      ate == null;

  /// Quantos filtros além da situação estão ligados.
  int get avancados => [usuario, catraca, de, ate].nonNulls.length;
}

/// Autorizações (A7, A8 · RF04): quem pode entrar, onde, quando e quantas
/// vezes. Daqui o admin abre uma para editar ou cancelar e cria novas.
class AutorizacoesView extends StatefulWidget {
  const AutorizacoesView({super.key, this._servico});

  final AdminService? _servico;

  @override
  State<AutorizacoesView> createState() => _AutorizacoesViewState();
}

class _AutorizacoesViewState extends State<AutorizacoesView> {
  late final AdminService _servico = widget._servico ?? AdminService.instancia;

  var _filtro = const FiltroAutorizacoes(situacao: 'ATIVA');
  var _versao = 0;

  Future<List<Autorizacao>> _carregar() => _servico.autorizacoes(
    situacao: _filtro.situacao,
    userId: _filtro.usuario?.id,
    accessPointId: _filtro.catraca?.catraca.id,
    de: _filtro.de == null ? null : Formatos.dataIso(_filtro.de!),
    ate: _filtro.ate == null ? null : Formatos.dataIso(_filtro.ate!),
  );

  Future<void> _abrir([Autorizacao? autorizacao]) async {
    final mudou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            AutorizacaoFormView(autorizacao: autorizacao, servico: _servico),
      ),
    );
    if (mudou == true && mounted) setState(() => _versao++);
  }

  Future<void> _filtrar() async {
    final novo = await showModalBottomSheet<FiltroAutorizacoes>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FolhaDeFiltros(servico: _servico, atual: _filtro),
    );
    if (novo != null && mounted) {
      setState(() {
        _filtro = novo;
        _versao++;
      });
    }
  }

  void _situacao(String? situacao) => setState(() {
    _filtro = FiltroAutorizacoes(
      situacao: situacao,
      usuario: _filtro.usuario,
      catraca: _filtro.catraca,
      de: _filtro.de,
      ate: _filtro.ate,
    );
    _versao++;
  });

  @override
  Widget build(BuildContext context) {
    return TelaAdmin(
      titulo: 'Autorizações',
      botaoFlutuante: FloatingActionButton.extended(
        onPressed: () => _abrir(),
        icon: const Icon(Icons.add),
        label: const Text('Nova autorização'),
      ),
      corpo: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ActionChip(
                  avatar: const Icon(Icons.tune, size: 18),
                  label: Text(
                    _filtro.avancados == 0
                        ? 'Filtrar'
                        : 'Filtrar (${_filtro.avancados})',
                  ),
                  onPressed: _filtrar,
                ),
                for (final (rotulo, valor) in const [
                  ('Todas', null),
                  ('Ativas', 'ATIVA'),
                  ('Expiradas', 'EXPIRADA'),
                  ('Canceladas', 'CANCELADA'),
                ]) ...[
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(rotulo),
                    selected: _filtro.situacao == valor,
                    onSelected: (_) => _situacao(valor),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: CarregaDados<List<Autorizacao>>(
              key: ValueKey(_versao),
              carregar: _carregar,
              mensagem: 'Carregando autorizações…',
              construir: (context, lista) {
                if (lista.isEmpty) {
                  return EstadoVazio(
                    icone: Icons.event_busy,
                    titulo: 'Nenhuma autorização encontrada',
                    texto: 'Mude os filtros ou crie uma nova autorização.',
                    rotuloAcao: _filtro.vazio ? 'Atualizar' : 'Limpar filtros',
                    iconeAcao: _filtro.vazio
                        ? Icons.refresh
                        : Icons.filter_alt_off,
                    onAcao: () => setState(() {
                      _filtro = const FiltroAutorizacoes();
                      _versao++;
                    }),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => setState(() => _versao++),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: lista.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Text(
                          '${lista.length} ${lista.length == 1 ? 'autorização encontrada' : 'autorizações encontradas'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        );
                      }
                      return _CartaoAutorizacao(
                        autorizacao: lista[i - 1],
                        onTap: () => _abrir(lista[i - 1]),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoAutorizacao extends StatelessWidget {
  const _CartaoAutorizacao({required this.autorizacao, required this.onTap});

  final Autorizacao autorizacao;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final a = autorizacao;
    final mesmoDia = a.dataInicio == a.dataFim;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(a.nomeUsuario, style: textTheme.titleMedium),
                  ),
                  SeloSituacao(situacao: a.situacao),
                ],
              ),
              Text(a.nomeCatraca, style: textTheme.bodyMedium),
              LinhaInfo(
                icone: Icons.event,
                texto: mesmoDia
                    ? 'Somente ${Formatos.dataIsoParaBr(a.dataInicio)}'
                    : '${Formatos.dataIsoParaBr(a.dataInicio)} a ${Formatos.dataIsoParaBr(a.dataFim)}',
              ),
              LinhaInfo(
                icone: Icons.schedule,
                texto: 'Das ${a.horaInicio} às ${a.horaFim}',
              ),
              LinhaInfo(
                icone: Icons.confirmation_number_outlined,
                texto: '${a.usosRestantes} de ${a.maxUsos} usos restantes',
              ),
              if (a.ultimoUso)
                LinhaInfo(
                  icone: Icons.warning_amber,
                  texto: 'Último uso disponível',
                  cor: StatusColors.of(context).warning,
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    a.editavel ? 'Ver e editar' : 'Ver detalhes',
                    style: textTheme.labelMedium?.copyWith(color: colorScheme.primary),
                  ),
                  Icon(Icons.chevron_right, size: 20, color: colorScheme.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Folha de filtros (A8): pessoa, local e período.
class _FolhaDeFiltros extends StatefulWidget {
  const _FolhaDeFiltros({required this.servico, required this.atual});

  final AdminService servico;
  final FiltroAutorizacoes atual;

  @override
  State<_FolhaDeFiltros> createState() => _FolhaDeFiltrosState();
}

class _FolhaDeFiltrosState extends State<_FolhaDeFiltros> {
  late UsuarioAdmin? _usuario = widget.atual.usuario;
  late CatracaComCaminho? _catraca = widget.atual.catraca;
  late DateTime? _de = widget.atual.de;
  late DateTime? _ate = widget.atual.ate;

  late final Future<(List<UsuarioAdmin>, List<CatracaComCaminho>)> _opcoes =
      _carregarOpcoes();

  Future<(List<UsuarioAdmin>, List<CatracaComCaminho>)> _carregarOpcoes() async {
    final usuarios = await widget.servico.usuarios();
    final locais = await widget.servico.locais();
    return (usuarios, locais.catracas);
  }

  Future<void> _escolherData(bool inicio) async {
    final base = (inicio ? _de : _ate) ?? DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );
    if (data == null) return;
    setState(() => inicio ? _de = data : _ate = data);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: FutureBuilder<(List<UsuarioAdmin>, List<CatracaComCaminho>)>(
            future: _opcoes,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return SizedBox(
                  height: 220,
                  child: ErroDeCarga(
                    erro: snapshot.error!,
                    onTentarDeNovo: () => Navigator.of(context).pop(),
                  ),
                );
              }
              final (usuarios, catracas) = snapshot.data!;
              // Mantém a escolha mesmo que o objeto venha de outra carga.
              final usuario = usuarios
                  .where((u) => u.id == _usuario?.id)
                  .firstOrNull;
              final catraca = catracas
                  .where((c) => c.catraca.id == _catraca?.catraca.id)
                  .firstOrNull;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Filtrar autorizações', style: textTheme.titleLarge),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<UsuarioAdmin?>(
                    initialValue: usuario,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Pessoa',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todas')),
                      for (final u in usuarios)
                        DropdownMenuItem(
                          value: u,
                          child: Text('${u.nome} · ${u.perfil.rotulo}', overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (u) => setState(() => _usuario = u),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<CatracaComCaminho?>(
                    initialValue: catraca,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Local',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      for (final c in catracas)
                        DropdownMenuItem(
                          value: c,
                          child: Text(c.rotulo, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (c) => setState(() => _catraca = c),
                  ),
                  const SizedBox(height: 16),
                  Text('Período', style: textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _escolherData(true),
                          icon: const Icon(Icons.calendar_month),
                          label: Text(_de == null ? 'Início' : Formatos.data(_de!)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _escolherData(false),
                          icon: const Icon(Icons.calendar_month),
                          label: Text(_ate == null ? 'Fim' : Formatos.data(_ate!)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(
                      FiltroAutorizacoes(
                        situacao: widget.atual.situacao,
                        usuario: usuario,
                        catraca: catraca,
                        de: _de,
                        ate: _ate,
                      ),
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('Mostrar resultados'),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(
                      FiltroAutorizacoes(situacao: widget.atual.situacao),
                    ),
                    icon: const Icon(Icons.filter_alt_off),
                    label: const Text('Limpar filtros'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
