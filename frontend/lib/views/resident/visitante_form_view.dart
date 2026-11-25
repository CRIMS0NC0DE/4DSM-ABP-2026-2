import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/meus_visitantes_controller.dart';
import '../../core/constants/formato.dart';
import '../../core/theme/app_colors.dart';
import '../../models/meu_visitante.dart';
import '../../services/api_client.dart';
import '../widgets/botao_acao.dart';
import '../widgets/campo_selecao.dart';
import '../widgets/campo_texto.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/estado_vazio.dart';
import '../widgets/tela_base.dart';

/// Novo visitante (condômino): dados da pessoa, a catraca (só as de
/// GET /me/visitors/catracas), os dias e o horário. Depois de criar, mostra
/// a senha provisória, que só aparece uma vez. Volta com true quando conclui.
class VisitanteFormView extends StatefulWidget {
  VisitanteFormView({super.key, MeusVisitantesController? controller})
    : controller = controller ?? MeusVisitantesController();

  final MeusVisitantesController controller;

  @override
  State<VisitanteFormView> createState() => _VisitanteFormViewState();
}

class _VisitanteFormViewState extends State<VisitanteFormView>
    with CarregaDados<List<CatracaDoConvite>, VisitanteFormView> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _cpf = TextEditingController();
  String? _catracaId;
  late var _inicio = controller.hoje();
  late var _fim = _inicio;
  var _horaInicio = const TimeOfDay(hour: 8, minute: 0);
  var _horaFim = const TimeOfDay(hour: 18, minute: 0);
  var _salvando = false;

  /// Erros de cada campo que a API devolveu no 400.
  Map<String, List<String>> _errosDaApi = const {};

  /// Campos com lugar para o erro embaixo; os outros viram aviso.
  static const _camposNaTela = {'nome', 'email', 'cpf', 'accessPointId'};

  /// Preenchido depois que a API criou o visitante.
  VisitanteCriado? _criado;

  MeusVisitantesController get controller => widget.controller;

  CatracaDoConvite? get _catraca =>
      dados?.where((c) => c.catraca.id == _catracaId).firstOrNull;

  @override
  Future<List<CatracaDoConvite>> buscar() async {
    final catracas = await controller.catracas();
    // Com uma catraca só, já vem escolhida. Se a escolhida sumiu da lista,
    // limpa: o seletor quebra com um valor que não está entre as opções.
    final ids = {for (final c in catracas) c.catraca.id};
    if (!ids.contains(_catracaId)) _catracaId = null;
    if (_catracaId == null && catracas.length == 1) {
      _aplicarCatraca(catracas.first);
    }
    return catracas;
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _cpf.dispose();
    super.dispose();
  }

  /// Escolhe a catraca e traz as datas para dentro da autorização do
  /// morador nela.
  void _aplicarCatraca(CatracaDoConvite? catraca) {
    _catracaId = catraca?.catraca.id;
    final ate = catraca?.ate;
    if (ate == null || ate.isBefore(controller.hoje())) return;
    if (_fim.isAfter(ate)) _fim = ate;
    if (_inicio.isAfter(ate)) _inicio = ate;
  }

  Future<void> _escolherData(bool inicio) async {
    final hoje = controller.hoje();
    final primeira = inicio || _inicio.isBefore(hoje) ? hoje : _inicio;
    var ultima = _catraca?.ate ?? DateTime(hoje.year + 1, hoje.month, hoje.day);
    if (ultima.isBefore(primeira)) ultima = primeira;
    // O seletor exige a data inicial entre a primeira e a última.
    var atual = inicio ? _inicio : _fim;
    if (atual.isBefore(primeira)) atual = primeira;
    if (atual.isAfter(ultima)) atual = ultima;
    final data = await showDatePicker(
      context: context,
      initialDate: atual,
      firstDate: primeira,
      lastDate: ultima,
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

  /// As regras do backend que dá para conferir antes de enviar.
  String? _problemaNoPeriodo() {
    final ate = _catraca?.ate;
    if (_inicio.isBefore(controller.hoje())) {
      return 'O primeiro dia não pode ser antes de hoje.';
    }
    if (_fim.isBefore(_inicio)) {
      return 'O último dia precisa ser igual ou depois do primeiro.';
    }
    if (ate != null && _fim.isAfter(ate)) {
      return 'Sua autorização nessa catraca vai até ${Formato.data(ate)}. '
          'Escolha um último dia até essa data.';
    }
    if (_horaInicio == _horaFim) {
      return 'O horário inicial e o final não podem ser iguais.';
    }
    return null;
  }

  String? _erroDaApi(String campo) => _errosDaApi[campo]?.first;

  Future<void> _salvar() async {
    if (_salvando) return;
    _errosDaApi = const {};
    if (!_form.currentState!.validate()) return;
    if (_problemaNoPeriodo() case final problema?) {
      avisar(context, problema);
      return;
    }
    setState(() => _salvando = true);
    try {
      final criado = await controller.criar(
        nome: _nome.text.trim(),
        email: _email.text.trim(),
        cpf: _cpf.text.trim(),
        catracaId: _catracaId!,
        dataInicio: _inicio,
        dataFim: _fim,
        horaInicio: Formato.horaApi(_horaInicio),
        horaFim: Formato.horaApi(_horaFim),
      );
      if (mounted) setState(() => _criado = criado);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.campos.isNotEmpty) {
        _errosDaApi = e.campos;
        _form.currentState!.validate();
        // Datas e horário não têm onde mostrar o erro embaixo.
        final outro = [
          for (final MapEntry(:key, :value) in e.campos.entries)
            if (!_camposNaTela.contains(key)) ...value,
        ].firstOrNull;
        avisar(context, outro ?? e.mensagem);
      } else {
        // Ex.: 403 "Você só pode convidar para as catracas que você usa…",
        // 409 e-mail ou CPF de outra pessoa, sem conexão.
        await tratarErro(context, e);
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  List<Widget> _formulario(List<CatracaDoConvite> catracas) {
    if (catracas.isEmpty) {
      return [
        EstadoVazio(
          icone: Icons.no_meeting_room_outlined,
          titulo: 'Nenhuma catraca para convidar',
          texto:
              'Você só pode convidar para as catracas que você usa, enquanto '
              'a sua autorização valer. Fale com a portaria.',
          rotuloAcao: 'Atualizar',
          onAcao: recarregar,
        ),
      ];
    }
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final escolhida = _catraca;

    return [
      Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CampoTexto(
              rotulo: 'Nome completo',
              controller: _nome,
              icone: Icons.person_outline,
              teclado: TextInputType.name,
              validator: (v) => (v ?? '').trim().length < 3
                  ? 'Informe o nome completo do visitante.'
                  : _erroDaApi('nome'),
            ),
            const SizedBox(height: 20),
            CampoTexto(
              rotulo: 'E-mail',
              controller: _email,
              icone: Icons.mail_outline,
              dica: 'visitante@email.com',
              ajuda: 'O visitante entra no app com este e-mail.',
              teclado: TextInputType.emailAddress,
              validator: (v) {
                final email = (v ?? '').trim();
                if (email.isEmpty) return 'Informe o e-mail do visitante.';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                  return 'E-mail inválido.';
                }
                return _erroDaApi('email');
              },
            ),
            const SizedBox(height: 20),
            CampoTexto(
              rotulo: 'CPF',
              controller: _cpf,
              icone: Icons.badge_outlined,
              dica: '000.000.000-00',
              ajuda: 'Pode digitar só os números.',
              teclado: TextInputType.number,
              acao: TextInputAction.done,
              validator: (v) =>
                  (v ?? '').replaceAll(RegExp(r'\D'), '').length != 11
                  ? 'O CPF precisa ter 11 números.'
                  : _erroDaApi('cpf'),
            ),
            const SizedBox(height: 20),
            CampoEscolha<String>(
              rotulo: 'Catraca',
              valor: _catracaId,
              icone: Icons.location_on_outlined,
              opcoes: [
                for (final c in catracas)
                  (c.catraca.id, '${c.catraca.nome} · ${c.catraca.edificio}'),
              ],
              onMudar: (id) => setState(
                () => _aplicarCatraca(
                  catracas.where((c) => c.catraca.id == id).firstOrNull,
                ),
              ),
              validator: (v) => v == null
                  ? 'Escolha a catraca.'
                  : _erroDaApi('accessPointId'),
            ),
            if (escolhida != null) ...[
              const SizedBox(height: 8),
              Text(
                '${escolhida.catraca.onde}\n'
                'Você pode convidar até ${Formato.data(escolhida.ate)}.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 20),
            CampoSelecao(
              rotulo: 'Primeiro dia',
              valor: Formato.data(_inicio),
              icone: Icons.event_outlined,
              onTocar: () => _escolherData(true),
            ),
            const SizedBox(height: 20),
            CampoSelecao(
              rotulo: 'Último dia',
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
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_criado case final criado?) {
      return TelaBase(
        titulo: 'Visitante cadastrado',
        subtitulo: 'Passe os dados de acesso para o visitante',
        rodape: BotaoAcao(
          rotulo: 'Concluir',
          icone: Icons.check,
          onTocar: () => Navigator.of(context).maybePop(true),
        ),
        filhos: [
          _Resultado(
            criado: criado,
            catraca: _catraca?.catraca.nome ?? 'catraca escolhida',
            periodo: Formato.dataApi(_inicio) == Formato.dataApi(_fim)
                ? 'em ${Formato.data(_inicio)}'
                : 'de ${Formato.data(_inicio)} a ${Formato.data(_fim)}',
            horario:
                'das ${Formato.horaApi(_horaInicio)} '
                'às ${Formato.horaApi(_horaFim)}',
          ),
        ],
      );
    }
    final catracas = dados;
    return TelaBase(
      titulo: 'Novo visitante',
      subtitulo: 'Libere a entrada de alguém por tempo limitado',
      rodape: catracas == null || catracas.isEmpty
          ? null
          : BotaoAcao(
              rotulo: 'Cadastrar visitante',
              icone: Icons.person_add_alt,
              carregando: _salvando,
              onTocar: _salvar,
            ),
      filhos: conteudo(_formulario),
    );
  }
}

/// Depois de criar: onde e quando o visitante entra e a senha provisória.
class _Resultado extends StatelessWidget {
  const _Resultado({
    required this.criado,
    required this.catraca,
    required this.periodo,
    required this.horario,
  });

  final VisitanteCriado criado;
  final String catraca;
  final String periodo;
  final String horario;

  Future<void> _copiar(BuildContext context, String senha) async {
    try {
      await Clipboard.setData(ClipboardData(text: senha));
      if (context.mounted) avisar(context, 'Senha copiada.');
    } catch (_) {
      if (context.mounted) {
        avisar(context, 'Não foi possível copiar. Anote a senha.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final status = StatusColors.of(context);
    final senha = criado.senhaProvisoria;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, color: status.success, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${criado.nome} pode entrar pela $catraca $periodo, '
                    '$horario.',
                    style: textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (senha != null)
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Senha provisória',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    senha,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ela aparece só agora. Copie ou anote e passe para '
                    '${criado.nome}, junto com o e-mail ${criado.email}: é '
                    'com eles que o visitante entra no app.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _copiar(context, senha),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copiar senha'),
                  ),
                ],
              ),
            ),
          )
        else
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${criado.nome} já tinha cadastro no Passe, então não '
                      'há senha nova. O visitante entra no app com o e-mail '
                      '${criado.email} e a senha que já usa. Se não lembrar, '
                      'a portaria troca a senha.',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          'Na hora de entrar, o visitante abre o app e escaneia o QR Code da '
          'catraca.',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
