import 'package:flutter/material.dart';

import '../../controllers/autorizacoes_controller.dart';
import '../../core/constants/formato.dart';
import '../../models/autorizacao.dart';
import '../../models/autorizacao_equipe.dart';
import '../../models/usuario_cadastro.dart';
import '../../services/api_client.dart';
import '../widgets/botao_acao.dart';
import '../widgets/campo_selecao.dart';
import '../widgets/campo_texto.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/tela_base.dart';

/// A9 · Autorização · formulário, com a A10 (confirmar cancelamento). Ao salvar
/// ou cancelar, volta com true para a lista recarregar.
class AutorizacaoFormView extends StatefulWidget {
  AutorizacaoFormView({
    super.key,
    this.autorizacao,
    this.pessoaFixa,
    AutorizacoesController? controller,
  }) : controller = controller ?? AutorizacoesController();

  /// null cria uma nova.
  final AutorizacaoEquipe? autorizacao;

  /// Já escolhe a pessoa, ex.: passo 2 do cadastro de visitante.
  final UsuarioCadastro? pessoaFixa;
  final AutorizacoesController controller;

  @override
  State<AutorizacaoFormView> createState() => _AutorizacaoFormViewState();
}

class _AutorizacaoFormViewState extends State<AutorizacaoFormView>
    with CarregaDados<OpcoesAutorizacao, AutorizacaoFormView> {
  final _form = GlobalKey<FormState>();
  late final _a = widget.autorizacao?.autorizacao;
  late var _pessoaId = widget.autorizacao?.pessoaId ?? widget.pessoaFixa?.id;
  late var _catracaId = _a?.catraca.id;
  late var _inicio = _a?.dataInicio ?? DateTime.now();
  late var _fim = _a?.dataFim ?? DateTime.now();
  late var _horaInicio = _a == null
      ? const TimeOfDay(hour: 8, minute: 0)
      : Formato.horaDaApi(_a.horaInicio);
  late var _horaFim = _a == null
      ? const TimeOfDay(hour: 18, minute: 0)
      : Formato.horaDaApi(_a.horaFim);
  late final _usos = TextEditingController(text: '${_a?.maxUsos ?? 1}');
  var _salvando = false;

  bool get _nova => _a == null;
  bool get _cancelada => _a?.situacao == SituacaoAutorizacao.cancelada;

  @override
  Future<OpcoesAutorizacao> buscar() => widget.controller.opcoes();

  @override
  void dispose() {
    _usos.dispose();
    super.dispose();
  }

  Future<void> _escolherData(bool inicio) async {
    final hoje = DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: inicio ? _inicio : _fim,
      firstDate: DateTime(hoje.year - 5),
      lastDate: DateTime(hoje.year + 5),
    );
    if (data == null) return;
    setState(() {
      if (inicio) {
        _inicio = data;
        // Mantém o período válido sem obrigar a abrir o outro campo.
        if (_fim.isBefore(data)) _fim = data;
      } else {
        _fim = data;
      }
    });
  }

  Future<void> _escolherHora(bool inicio) async {
    final hora = await showTimePicker(
      context: context,
      initialTime: inicio ? _horaInicio : _horaFim,
    );
    if (hora != null) {
      setState(() => inicio ? _horaInicio = hora : _horaFim = hora);
    }
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    if (_fim.isBefore(_inicio)) {
      avisar(context, 'A data de término precisa ser depois da de início.');
      return;
    }
    if (_horaInicio == _horaFim) {
      avisar(context, 'O horário inicial e o final não podem ser iguais.');
      return;
    }
    setState(() => _salvando = true);
    try {
      final horaInicio = Formato.horaApi(_horaInicio);
      final horaFim = Formato.horaApi(_horaFim);
      final maxUsos = int.parse(_usos.text.trim());
      if (_nova) {
        await widget.controller.criar(
          pessoaId: _pessoaId!,
          catracaId: _catracaId!,
          dataInicio: _inicio,
          dataFim: _fim,
          horaInicio: horaInicio,
          horaFim: horaFim,
          maxUsos: maxUsos,
        );
      } else {
        await widget.controller.atualizar(
          _a!.id,
          catracaId: _catracaId!,
          dataInicio: _inicio,
          dataFim: _fim,
          horaInicio: horaInicio,
          horaFim: horaFim,
          maxUsos: maxUsos,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) await tratarErro(context, e);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  /// A10 · Cancelar · confirmação.
  Future<void> _cancelar() async {
    final nome = widget.autorizacao!.pessoaNome;
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        actionsOverflowButtonSpacing: 8,
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(contexto).colorScheme.error,
          size: 36,
        ),
        title: const Text('Cancelar esta autorização?'),
        content: Text(
          '$nome não vai mais conseguir passar pela ${_a!.catraca.nome}. Para '
          'liberar de novo, é preciso criar outra autorização.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Não, manter'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(contexto).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(contexto).colorScheme.error,
              foregroundColor: Theme.of(contexto).colorScheme.onError,
            ),
            icon: const Icon(Icons.block),
            label: const Text('Sim, cancelar'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    setState(() => _salvando = true);
    try {
      await widget.controller.cancelar(_a!.id);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) await tratarErro(context, e);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  List<Widget> _formulario(OpcoesAutorizacao opcoes) {
    // Só oferece quem está ativo. A pessoa já escolhida fica na lista mesmo
    // sem vir no GET /users, ou o seletor quebra sem o valor entre as opções.
    final pessoas = [
      for (final p in opcoes.pessoas)
        if (p.id != _pessoaId && p.ativo) (p.id, p.nome),
      if (_pessoaId case final id?)
        (
          id,
          widget.autorizacao?.pessoaNome ??
              widget.pessoaFixa?.nome ??
              opcoes.pessoas.where((p) => p.id == id).firstOrNull?.nome ??
              'Pessoa selecionada',
        ),
    ];
    return [
      Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CampoEscolha<String>(
              rotulo: 'Pessoa',
              valor: _pessoaId,
              icone: Icons.person_outline,
              opcoes: pessoas,
              // A API não deixa trocar a pessoa na edição.
              onMudar: _nova && widget.pessoaFixa == null
                  ? (v) => setState(() => _pessoaId = v)
                  : null,
              validator: (v) => v == null ? 'Escolha a pessoa.' : null,
            ),
            const SizedBox(height: 20),
            CampoEscolha<String>(
              rotulo: 'Local',
              valor: _catracaId,
              icone: Icons.location_on_outlined,
              opcoes: [
                for (final c in opcoes.catracas) (c.catraca.id, c.caminho),
              ],
              onMudar: (v) => setState(() => _catracaId = v),
              validator: (v) => v == null ? 'Escolha a catraca.' : null,
            ),
            const SizedBox(height: 20),
            CampoSelecao(
              rotulo: 'Início',
              valor: Formato.data(_inicio),
              icone: Icons.event_outlined,
              onTocar: () => _escolherData(true),
            ),
            const SizedBox(height: 20),
            CampoSelecao(
              rotulo: 'Fim',
              valor: Formato.data(_fim),
              icone: Icons.event_outlined,
              onTocar: () => _escolherData(false),
            ),
            const SizedBox(height: 20),
            CampoSelecao(
              rotulo: 'Das',
              valor: Formato.horaApi(_horaInicio),
              icone: Icons.schedule,
              onTocar: () => _escolherHora(true),
            ),
            const SizedBox(height: 20),
            CampoSelecao(
              rotulo: 'Até',
              valor: Formato.horaApi(_horaFim),
              icone: Icons.schedule,
              onTocar: () => _escolherHora(false),
            ),
            const SizedBox(height: 20),
            CampoTexto(
              rotulo: 'Quantidade de usos',
              controller: _usos,
              icone: Icons.confirmation_number_outlined,
              teclado: TextInputType.number,
              acao: TextInputAction.done,
              validator: (v) {
                final usos = int.tryParse((v ?? '').trim());
                return usos == null || usos < 1 || usos > 10000
                    ? 'Informe de 1 a 10000 usos.'
                    : null;
              },
            ),
            if (!_nova && !_cancelada) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _salvando ? null : _cancelar,
                icon: const Icon(Icons.block),
                label: const Text('Cancelar autorização'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.error,
                    width: 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      titulo: _nova ? 'Nova autorização' : 'Editar autorização',
      subtitulo: _cancelada
          ? 'Cancelada: não pode ser editada. Crie outra.'
          : widget.pessoaFixa != null
          ? 'Passo 2 de 2: onde e quando pode entrar'
          : null,
      rodape: _cancelada || dados == null
          ? null
          : BotaoAcao(
              rotulo: _nova ? 'Criar autorização' : 'Salvar alterações',
              icone: Icons.check,
              carregando: _salvando,
              onTocar: _salvar,
            ),
      filhos: conteudo(_formulario),
    );
  }
}
