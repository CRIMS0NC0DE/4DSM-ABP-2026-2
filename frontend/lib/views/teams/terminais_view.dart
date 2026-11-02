import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/terminais_controller.dart';
import '../../core/constants/formato.dart';
import '../../models/local.dart';
import '../../models/opcao_menu.dart';
import '../../models/terminal.dart';
import '../../services/api_client.dart';
import '../widgets/botao_acao.dart';
import '../widgets/campo_selecao.dart';
import '../widgets/campo_texto.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/estado_vazio.dart';
import '../widgets/selo.dart';
import '../widgets/tela_base.dart';

/// Terminais (sem tela no design): quem está no ar e, para o admin, cadastrar
/// e trocar a chave.
class TerminaisView extends StatefulWidget {
  TerminaisView({super.key, TerminaisController? controller})
    : controller = controller ?? TerminaisController();

  final TerminaisController controller;

  @override
  State<TerminaisView> createState() => _TerminaisViewState();
}

class _TerminaisViewState extends State<TerminaisView>
    with CarregaDados<DadosTerminais, TerminaisView> {
  TerminaisController get controller => widget.controller;

  @override
  Future<DadosTerminais> buscar() => controller.carregar();

  /// A chave só aparece uma vez: a tela insiste para copiar antes de fechar.
  Future<void> _mostrarChave(Terminal terminal) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DialogoChave(terminal: terminal),
  );

  Future<void> _cadastrar(DadosTerminais atual) async {
    final ocupadas = {for (final t in atual.terminais) t.accessPointId};
    final livres = [
      for (final c in atual.catracas)
        if (!ocupadas.contains(c.catraca.id)) c,
    ];
    if (livres.isEmpty) {
      avisar(context, 'Todas as catracas já têm terminal.');
      return;
    }
    final novo = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FormularioTerminal(catracas: livres),
    );
    if (novo == null) return;
    try {
      final terminal = await controller.cadastrar(novo.$1, novo.$2);
      if (!mounted) return;
      await _mostrarChave(terminal);
      if (mounted) await carregar();
    } on ApiException catch (e) {
      if (mounted) await tratarErro(context, e);
    }
  }

  Future<void> _trocarChave(Terminal terminal) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Trocar a chave?'),
        content: Text(
          '${terminal.nome} para de funcionar até a chave nova ser gravada no '
          'firmware e no broker.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Não trocar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            child: const Text('Trocar chave'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;
    try {
      final atualizado = await controller.trocarChave(terminal.id);
      if (!mounted) return;
      await _mostrarChave(atualizado);
    } on ApiException catch (e) {
      if (mounted) await tratarErro(context, e);
    }
  }

  List<Widget> _lista(DadosTerminais d) {
    if (d.terminais.isEmpty) {
      return const [
        EstadoVazio(
          icone: Icons.qr_code_2,
          titulo: 'Nenhum terminal cadastrado',
          texto: 'Cada catraca tem um terminal, que mostra o QR rotativo.',
        ),
      ];
    }
    return [
      for (final terminal in d.terminais)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _CartaoTerminal(
            terminal: terminal,
            caminho: d.catracas
                .where((c) => c.catraca.id == terminal.accessPointId)
                .firstOrNull
                ?.caminho,
            onTrocarChave: controller.podeGerenciar
                ? () => _trocarChave(terminal)
                : null,
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final atual = dados;
    return TelaBase(
      titulo: 'Terminais',
      subtitulo: 'Leitores de QR Code das catracas',
      onAtualizar: carregar,
      botaoFlutuante: controller.podeGerenciar && atual != null
          ? FloatingActionButton.extended(
              onPressed: () => _cadastrar(atual),
              icon: const Icon(Icons.add),
              label: const Text('Novo terminal'),
            )
          : null,
      filhos: conteudo(_lista),
    );
  }
}

class _CartaoTerminal extends StatelessWidget {
  const _CartaoTerminal({
    required this.terminal,
    required this.caminho,
    required this.onTrocarChave,
  });

  final Terminal terminal;
  final String? caminho;
  final VoidCallback? onTrocarChave;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final sinal = terminal.ultimoSinal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(terminal.nome, style: textTheme.titleMedium),
                ),
                const SizedBox(width: 8),
                terminal.online
                    ? const Selo(
                        texto: 'No ar',
                        icone: Icons.check_circle,
                        tom: TomOpcao.sucesso,
                      )
                    : const Selo(
                        texto: 'Fora do ar',
                        icone: Icons.cloud_off,
                        tom: TomOpcao.perigo,
                      ),
              ],
            ),
            if (caminho != null) Text(caminho!, style: textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(
              sinal == null
                  ? 'Ainda não deu sinal'
                  : 'Último sinal: ${Formato.data(sinal)} às ${Formato.hora(sinal)}',
              style: textTheme.bodyMedium,
            ),
            if (onTrocarChave != null)
              TextButton.icon(
                onPressed: onTrocarChave,
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                icon: const Icon(Icons.key_outlined),
                label: const Text('Trocar chave'),
              ),
          ],
        ),
      ),
    );
  }
}

class _FormularioTerminal extends StatefulWidget {
  const _FormularioTerminal({required this.catracas});

  final List<CatracaNoLocal> catracas;

  @override
  State<_FormularioTerminal> createState() => _FormularioTerminalState();
}

class _FormularioTerminalState extends State<_FormularioTerminal> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  String? _catracaId;

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
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
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Novo terminal',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              CampoTexto(
                rotulo: 'Nome',
                controller: _nome,
                icone: Icons.edit_outlined,
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Informe o nome.' : null,
              ),
              const SizedBox(height: 20),
              CampoEscolha<String>(
                rotulo: 'Catraca',
                valor: _catracaId,
                icone: Icons.location_on_outlined,
                opcoes: [
                  for (final c in widget.catracas) (c.catraca.id, c.caminho),
                ],
                onMudar: (v) => setState(() => _catracaId = v),
                validator: (v) => v == null ? 'Escolha a catraca.' : null,
              ),
              const SizedBox(height: 24),
              BotaoAcao(
                rotulo: 'Cadastrar',
                icone: Icons.check,
                onTocar: () {
                  if (_form.currentState!.validate()) {
                    Navigator.of(context).pop((_nome.text.trim(), _catracaId!));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogoChave extends StatelessWidget {
  const _DialogoChave({required this.terminal});

  final Terminal terminal;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final chave = terminal.chave ?? '';

    return AlertDialog(
      title: const Text('Copie a chave agora'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ela não aparece de novo. Grave no firmware e no broker.',
            ),
            const SizedBox(height: 16),
            Text('Id do terminal', style: textTheme.labelMedium),
            SelectableText(terminal.id),
            const SizedBox(height: 12),
            Text('Chave', style: textTheme.labelMedium),
            SelectableText(chave),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: chave));
            if (context.mounted) avisar(context, 'Chave copiada.');
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copiar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Já guardei'),
        ),
      ],
    );
  }
}
