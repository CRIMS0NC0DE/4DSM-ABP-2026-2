import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/formatos.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../../services/api_client.dart';
import '../widgets/admin_widgets.dart';

/// Terminais das catracas (RF12): quem está online e, para o admin,
/// cadastrar terminal e trocar a chave. A chave aparece uma única vez: é
/// preciso gravá-la no firmware do ESP32.
class TerminaisView extends StatefulWidget {
  const TerminaisView({super.key, AdminService? servico}) : _servico = servico;

  final AdminService? _servico;

  @override
  State<TerminaisView> createState() => _TerminaisViewState();
}

class _TerminaisViewState extends State<TerminaisView> {
  late final AdminService _servico = widget._servico ?? AdminService.instancia;
  var _versao = 0;

  /// Terminais e catracas juntos: o terminal só traz o id da catraca.
  Future<(List<TerminalAdmin>, List<CatracaComCaminho>)> _carregar() async {
    final terminais = await _servico.terminais();
    final locais = await _servico.locais();
    return (terminais, locais.catracas);
  }

  Future<void> _mostrarChave(TerminalAdmin terminal) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.vpn_key_outlined, size: 36),
        title: Text('Chave de ${terminal.nome}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Grave esta chave no firmware agora. Ela não aparece de novo.',
            ),
            const SizedBox(height: 12),
            SelectableText(
              terminal.chave ?? '',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: terminal.chave ?? ''));
              if (context.mounted) avisar(context, 'Chave copiada.');
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copiar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Já gravei'),
          ),
        ],
      ),
    );
  }

  Future<void> _trocarChave(TerminalAdmin terminal) async {
    final sim = await confirmar(
      context,
      titulo: 'Trocar a chave de ${terminal.nome}?',
      texto: 'A chave atual para de valer na hora. O terminal só volta a '
          'funcionar depois de receber a chave nova.',
      rotuloSim: 'Sim, trocar',
      rotuloNao: 'Não, manter',
    );
    if (!sim) return;
    try {
      final novo = await _servico.trocarChave(terminal.id);
      if (!mounted) return;
      await _mostrarChave(novo);
      if (mounted) setState(() => _versao++);
    } on ApiException catch (erro) {
      if (mounted) avisar(context, erro.mensagem, erro: true);
    }
  }

  Future<void> _cadastrar(List<CatracaComCaminho> catracas, Set<String> comTerminal) async {
    final livres = [
      for (final c in catracas)
        if (!comTerminal.contains(c.catraca.id)) c,
    ];
    if (livres.isEmpty) {
      avisar(context, 'Todas as catracas já têm terminal.');
      return;
    }
    final dados = await showDialog<(String, CatracaComCaminho)>(
      context: context,
      builder: (_) => _DialogoNovoTerminal(catracas: livres),
    );
    if (dados == null) return;
    try {
      final novo = await _servico.cadastrarTerminal(dados.$1, dados.$2.catraca.id);
      if (!mounted) return;
      await _mostrarChave(novo);
      if (mounted) setState(() => _versao++);
    } on ApiException catch (erro) {
      if (mounted) avisar(context, erro.mensagem, erro: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = _servico.souAdmin;
    return TelaAdmin(
      titulo: 'Terminais',
      subtitulo: 'Sem sinal há mais de 90 s, o terminal aparece offline.',
      corpo: CarregaDados<(List<TerminalAdmin>, List<CatracaComCaminho>)>(
        key: ValueKey(_versao),
        carregar: _carregar,
        mensagem: 'Carregando terminais…',
        construir: (context, dados) {
          final (terminais, catracas) = dados;
          final nomes = {for (final c in catracas) c.catraca.id: c.rotulo};
          return RefreshIndicator(
            onRefresh: () async => setState(() => _versao++),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                if (terminais.isEmpty)
                  const EstadoVazio(
                    icone: Icons.qr_code_2,
                    titulo: 'Nenhum terminal cadastrado',
                    texto: 'Cadastre o terminal de uma catraca para ele mostrar o QR Code.',
                  ),
                for (final t in terminais)
                  _CartaoTerminal(
                    terminal: t,
                    catraca: nomes[t.accessPointId] ?? 'Catraca removida',
                    onTrocarChave: admin ? () => _trocarChave(t) : null,
                  ),
                if (admin) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _cadastrar(
                      catracas,
                      {for (final t in terminais) t.accessPointId},
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Novo terminal'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CartaoTerminal extends StatelessWidget {
  const _CartaoTerminal({
    required this.terminal,
    required this.catraca,
    required this.onTrocarChave,
  });

  final TerminalAdmin terminal;
  final String catraca;
  final VoidCallback? onTrocarChave;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final sinal = terminal.ultimoSinal;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(terminal.nome, style: textTheme.titleMedium)),
                Selo(
                  texto: terminal.online ? 'Online' : 'Offline',
                  tom: terminal.online ? TomSelo.sucesso : TomSelo.perigo,
                  icone: terminal.online ? Icons.wifi : Icons.wifi_off,
                ),
              ],
            ),
            LinhaInfo(icone: Icons.location_on_outlined, texto: catraca),
            LinhaInfo(
              icone: Icons.schedule,
              texto: sinal == null
                  ? 'Nunca enviou sinal'
                  : 'Último sinal ${Formatos.hojeOuData(sinal, DateTime.now())}',
            ),
            if (onTrocarChave != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onTrocarChave,
                  icon: const Icon(Icons.vpn_key_outlined),
                  label: const Text('Trocar chave'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DialogoNovoTerminal extends StatefulWidget {
  const _DialogoNovoTerminal({required this.catracas});

  final List<CatracaComCaminho> catracas;

  @override
  State<_DialogoNovoTerminal> createState() => _DialogoNovoTerminalState();
}

class _DialogoNovoTerminalState extends State<_DialogoNovoTerminal> {
  final _nome = TextEditingController();
  late CatracaComCaminho _catraca = widget.catracas.first;
  String? _erro;

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (_nome.text.trim().isEmpty) {
      setState(() => _erro = 'Informe o nome');
      return;
    }
    Navigator.of(context).pop((_nome.text.trim(), _catraca));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo terminal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nome,
            autofocus: true,
            decoration: InputDecoration(labelText: 'Nome', errorText: _erro),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<CatracaComCaminho>(
            initialValue: _catraca,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Catraca'),
            items: [
              for (final c in widget.catracas)
                DropdownMenuItem(
                  value: c,
                  child: Text(c.rotulo, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (c) => setState(() => _catraca = c ?? _catraca),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _confirmar, child: const Text('Cadastrar')),
      ],
    );
  }
}
