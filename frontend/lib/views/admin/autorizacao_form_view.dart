import 'package:flutter/material.dart';

import '../../core/formatos.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../../services/api_client.dart';
import '../widgets/admin_widgets.dart';
import '../widgets/botao_acao.dart';

/// Criar, editar e cancelar uma autorização (A9, A10 · RF03, RF05).
/// Na edição a pessoa não muda (a API não permite): para outra pessoa, crie
/// uma nova. Cancelar é o "excluir": a autorização continua no histórico.
/// Fecha devolvendo true quando algo mudou, para a lista recarregar.
class AutorizacaoFormView extends StatefulWidget {
  const AutorizacaoFormView({super.key, this.autorizacao, this._servico});

  /// Null cria uma nova.
  final Autorizacao? autorizacao;
  final AdminService? _servico;

  @override
  State<AutorizacaoFormView> createState() => _AutorizacaoFormViewState();
}

class _AutorizacaoFormViewState extends State<AutorizacaoFormView> {
  late final AdminService _servico = widget._servico ?? AdminService.instancia;

  late final Future<(List<UsuarioAdmin>, List<CatracaComCaminho>)> _opcoes =
      _carregarOpcoes();

  String? _userId;
  String? _catracaId;
  DateTime? _inicio;
  DateTime? _fim;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFim;
  late final _usos = TextEditingController(
    text: '${widget.autorizacao?.maxUsos ?? 1}',
  );
  var _salvando = false;

  Autorizacao? get _a => widget.autorizacao;
  bool get _nova => _a == null;
  bool get _somenteLeitura => _a != null && !_a!.editavel;

  @override
  void initState() {
    super.initState();
    final a = _a;
    if (a != null) {
      _userId = a.userId;
      _catracaId = a.accessPointId;
      _inicio = Formatos.daDataIso(a.dataInicio);
      _fim = Formatos.daDataIso(a.dataFim);
      final i = Formatos.daHora(a.horaInicio), f = Formatos.daHora(a.horaFim);
      _horaInicio = TimeOfDay(hour: i.hora, minute: i.minuto);
      _horaFim = TimeOfDay(hour: f.hora, minute: f.minuto);
    }
  }

  @override
  void dispose() {
    _usos.dispose();
    super.dispose();
  }

  Future<(List<UsuarioAdmin>, List<CatracaComCaminho>)> _carregarOpcoes() async {
    final usuarios = await _servico.usuarios();
    final locais = await _servico.locais();
    return (usuarios, locais.catracas);
  }

  String _hhmm(TimeOfDay t) => Formatos.horaHm(t.hour, t.minute);

  Future<void> _escolherData(bool inicio) async {
    final atual = inicio ? _inicio : _fim;
    final data = await showDatePicker(
      context: context,
      initialDate: atual ?? _inicio ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );
    if (data == null) return;
    setState(() {
      if (inicio) {
        _inicio = data;
        // Fim antes do início não existe: acompanha o início.
        if (_fim != null && _fim!.isBefore(data)) _fim = data;
      } else {
        _fim = data;
      }
    });
  }

  Future<void> _escolherHora(bool inicio) async {
    final hora = await showTimePicker(
      context: context,
      initialTime:
          (inicio ? _horaInicio : _horaFim) ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (hora == null) return;
    setState(() => inicio ? _horaInicio = hora : _horaFim = hora);
  }

  /// Texto do primeiro problema do formulário, ou null se está tudo certo.
  String? _problema() {
    if (_userId == null) return 'Escolha a pessoa.';
    if (_catracaId == null) return 'Escolha o local.';
    if (_inicio == null || _fim == null) return 'Informe o início e o fim do período.';
    if (_fim!.isBefore(_inicio!)) return 'O fim precisa ser depois do início.';
    if (_horaInicio == null || _horaFim == null) return 'Informe o horário.';
    if (_hhmm(_horaInicio!) == _hhmm(_horaFim!)) {
      return 'O horário inicial e o final não podem ser iguais.';
    }
    final usos = int.tryParse(_usos.text.trim());
    if (usos == null || usos < 1 || usos > 10000) {
      return 'A quantidade de usos vai de 1 a 10000.';
    }
    final feitos = _a?.usosRealizados ?? 0;
    if (usos < feitos) return 'Esta autorização já foi usada $feitos vez(es).';
    return null;
  }

  Future<void> _salvar() async {
    final problema = _problema();
    if (problema != null) {
      avisar(context, problema, erro: true);
      return;
    }
    setState(() => _salvando = true);
    try {
      final usos = int.parse(_usos.text.trim());
      if (_nova) {
        await _servico.criarAutorizacao(
          userId: _userId!,
          accessPointId: _catracaId!,
          dataInicio: Formatos.dataIso(_inicio!),
          dataFim: Formatos.dataIso(_fim!),
          horaInicio: _hhmm(_horaInicio!),
          horaFim: _hhmm(_horaFim!),
          maxUsos: usos,
        );
      } else {
        await _servico.atualizarAutorizacao(
          _a!.id,
          accessPointId: _catracaId!,
          dataInicio: Formatos.dataIso(_inicio!),
          dataFim: Formatos.dataIso(_fim!),
          horaInicio: _hhmm(_horaInicio!),
          horaFim: _hhmm(_horaFim!),
          maxUsos: usos,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (erro) {
      if (!mounted) return;
      setState(() => _salvando = false);
      avisar(context, erro.mensagem, erro: true);
    }
  }

  /// A10: confirmação antes de cancelar.
  Future<void> _cancelar() async {
    final a = _a!;
    final sim = await confirmar(
      context,
      titulo: 'Cancelar esta autorização?',
      texto: '${a.nomeUsuario} não vai mais conseguir passar pela '
          '${a.nomeCatraca}. Para liberar de novo, será preciso criar outra autorização.',
      rotuloSim: 'Sim, cancelar',
      rotuloNao: 'Não, manter',
    );
    if (!sim || !mounted) return;
    setState(() => _salvando = true);
    try {
      await _servico.cancelarAutorizacao(a.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (erro) {
      if (!mounted) return;
      setState(() => _salvando = false);
      avisar(context, erro.mensagem, erro: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final bloqueado = _somenteLeitura || _salvando;
    return TelaAdmin(
      titulo: _nova
          ? 'Nova autorização'
          : (_somenteLeitura ? 'Autorização' : 'Editar autorização'),
      corpo: FutureBuilder<(List<UsuarioAdmin>, List<CatracaComCaminho>)>(
        future: _opcoes,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErroDeCarga(
              erro: snapshot.error!,
              onTentarDeNovo: () => Navigator.of(context).pop(),
            );
          }
          final (usuarios, catracas) = snapshot.data!;
          // Na criação só quem está ativo recebe autorização.
          final pessoas = [
            for (final u in usuarios)
              if (u.ativo || u.id == _userId) u,
          ];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              if (_somenteLeitura)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: colorScheme.onErrorContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Esta autorização foi cancelada e não pode ser editada. '
                          'Crie outra se precisar liberar o acesso.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Text('Pessoa', style: textTheme.labelLarge),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _userId,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline),
                  hintText: 'Escolha a pessoa',
                ),
                items: [
                  for (final u in pessoas)
                    DropdownMenuItem(
                      value: u.id,
                      child: Text(
                        '${u.nome} · ${u.perfil.rotulo}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                // A pessoa de uma autorização existente não muda.
                onChanged: _nova && !bloqueado
                    ? (id) => setState(() => _userId = id)
                    : null,
              ),
              const SizedBox(height: 16),
              Text('Local', style: textTheme.labelLarge),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _catracaId,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.location_on_outlined),
                  hintText: 'Escolha a catraca',
                ),
                items: [
                  for (final c in catracas)
                    DropdownMenuItem(
                      value: c.catraca.id,
                      child: Text(c.rotulo, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: bloqueado
                    ? null
                    : (id) => setState(() => _catracaId = id),
              ),
              const SizedBox(height: 16),
              Text('Período', style: textTheme.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _BotaoCampo(
                      icone: Icons.calendar_month,
                      texto: _inicio == null ? 'Início' : Formatos.data(_inicio!),
                      onTap: bloqueado ? null : () => _escolherData(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BotaoCampo(
                      icone: Icons.calendar_month,
                      texto: _fim == null ? 'Fim' : Formatos.data(_fim!),
                      onTap: bloqueado ? null : () => _escolherData(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Horário', style: textTheme.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _BotaoCampo(
                      icone: Icons.schedule,
                      texto: _horaInicio == null ? 'Das' : 'Das ${_hhmm(_horaInicio!)}',
                      onTap: bloqueado ? null : () => _escolherHora(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BotaoCampo(
                      icone: Icons.schedule,
                      texto: _horaFim == null ? 'Até' : 'Até ${_hhmm(_horaFim!)}',
                      onTap: bloqueado ? null : () => _escolherHora(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Quantidade de usos', style: textTheme.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _usos,
                enabled: !bloqueado,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.confirmation_number_outlined),
                  helperText: _nova
                      ? 'Quantas vezes a pessoa pode passar.'
                      : 'Já usada ${_a!.usosRealizados} vez(es).',
                ),
              ),
              if (!_somenteLeitura) ...[
                const SizedBox(height: 24),
                BotaoAcao(
                  rotulo: _nova ? 'Criar autorização' : 'Salvar alterações',
                  icone: Icons.check,
                  carregando: _salvando,
                  onTocar: _salvar,
                ),
              ],
              if (!_nova && !_somenteLeitura) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _salvando ? null : _cancelar,
                  icon: const Icon(Icons.block),
                  label: const Text('Cancelar esta autorização'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    side: BorderSide(color: colorScheme.error, width: 1.5),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Botão que parece um campo: abre o seletor de data ou hora.
class _BotaoCampo extends StatelessWidget {
  const _BotaoCampo({required this.icone, required this.texto, required this.onTap});

  final IconData icone;
  final String texto;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icone),
      label: Text(texto, overflow: TextOverflow.ellipsis),
    );
  }
}
