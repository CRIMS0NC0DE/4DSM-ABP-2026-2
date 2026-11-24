import 'package:flutter/material.dart';

import '../../controllers/celular_chave_controller.dart';
import '../../core/constants/formato.dart';
import '../../models/celular_nfc.dart';
import '../../models/opcao_menu.dart';
import '../../services/api_client.dart';
import '../widgets/botao_acao.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/estado_vazio.dart';
import '../widgets/selo.dart';
import '../widgets/tela_base.dart';

/// Celular como chave: o Android responde como uma tag quando encosta no
/// leitor da catraca (HCE). Só ativa e desativa; quem decide é a API.
class CelularChaveView extends StatefulWidget {
  CelularChaveView({super.key, CelularChaveController? controller})
    : controller = controller ?? CelularChaveController();

  final CelularChaveController controller;

  @override
  State<CelularChaveView> createState() => _CelularChaveViewState();
}

class _CelularChaveViewState extends State<CelularChaveView>
    with CarregaDados<SituacaoCelular, CelularChaveView> {
  var _trabalhando = false;

  @override
  Future<SituacaoCelular> buscar() => widget.controller.carregar();

  Future<void> _executar(
    Future<void> Function() acao, {
    required String sucesso,
  }) async {
    setState(() => _trabalhando = true);
    try {
      await acao();
      if (!mounted) return;
      avisar(context, sucesso);
      await carregar();
    } on ApiException catch (e) {
      if (mounted) await tratarErro(context, e);
    } finally {
      if (mounted) setState(() => _trabalhando = false);
    }
  }

  Future<bool> _confirmar(String titulo, String texto, String acao) async =>
      await showDialog<bool>(
        context: context,
        builder: (contexto) => AlertDialog(
          title: Text(titulo),
          content: Text(texto),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(contexto).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(contexto).pop(true),
              child: Text(acao),
            ),
          ],
        ),
      ) ==
      true;

  Future<void> _desativar(CelularNfc celular) async {
    final ok = await _confirmar(
      'Desativar este celular?',
      'Ele para de abrir a catraca. Dá para ativar de novo quando quiser.',
      'Desativar',
    );
    if (!ok) return;
    await _executar(
      () => widget.controller.desativar(celular.id),
      sucesso: 'Celular desativado.',
    );
  }

  Future<void> _remover(CelularNfc celular) async {
    final ok = await _confirmar(
      'Remover ${celular.nome}?',
      'Aquele aparelho para de abrir a catraca.',
      'Remover',
    );
    if (!ok) return;
    await _executar(
      () => widget.controller.remover(celular.id),
      sucesso: 'Celular removido.',
    );
  }

  Widget _avisoNfcDesligado() => Card(
    child: ListTile(
      leading: const Icon(Icons.nfc),
      title: const Text('O NFC está desligado'),
      subtitle: const Text('Ligue o NFC para o celular abrir a catraca.'),
      trailing: TextButton(
        onPressed: widget.controller.abrirAjustesNfc,
        child: const Text('Ligar'),
      ),
    ),
  );

  Widget _deste(CelularNfc celular) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(celular.nome, style: textTheme.titleLarge),
                ),
                celular.ativo
                    ? const Selo(
                        texto: 'Ativo',
                        icone: Icons.check_circle,
                        tom: TomOpcao.sucesso,
                      )
                    : const Selo(
                        texto: 'Bloqueado',
                        icone: Icons.block,
                        tom: TomOpcao.perigo,
                      ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              celular.ativo
                  ? 'Desbloqueie a tela e encoste a parte de trás do celular '
                        'no leitor da catraca. Funciona com o app fechado e '
                        'sem internet.'
                  : 'A portaria bloqueou este celular. Fale com ela para liberar.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Ativado em ${Formato.data(celular.criadoEm)}',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _trabalhando ? null : () => _desativar(celular),
              icon: const Icon(Icons.phonelink_erase),
              label: const Text('Desativar este celular'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ativar(SituacaoCelular s) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const EstadoVazio(
        icone: Icons.phone_android,
        titulo: 'Use o celular como chave',
        texto:
            'O celular passa a abrir a catraca como uma tag: é só encostar no '
            'leitor, com a tela desbloqueada. A chave fica guardada só neste '
            'aparelho.',
      ),
      const SizedBox(height: 16),
      BotaoAcao(
        rotulo: _trabalhando ? 'Ativando…' : 'Ativar este celular',
        icone: Icons.key,
        carregando: _trabalhando,
        onTocar: _trabalhando
            ? null
            : () => _executar(
                () => widget.controller.ativar(s.aparelho),
                sucesso: 'Pronto! Encoste o celular no leitor da catraca.',
              ),
      ),
    ],
  );

  List<Widget> _outros(SituacaoCelular s) => [
    if (s.outros.isNotEmpty) ...[
      const SizedBox(height: 24),
      Text('Outros celulares', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      for (final c in s.outros)
        Card(
          child: ListTile(
            leading: const Icon(Icons.smartphone),
            title: Text(c.nome),
            subtitle: Text(
              '${c.ativo ? 'Ativo' : 'Bloqueado'} · desde ${Formato.data(c.criadoEm)}',
            ),
            trailing: IconButton(
              tooltip: 'Remover',
              onPressed: _trabalhando ? null : () => _remover(c),
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        ),
    ],
  ];

  List<Widget> _pronto(SituacaoCelular s) {
    if (!s.aparelho.suportado) {
      return [
        const EstadoVazio(
          icone: Icons.phonelink_off,
          titulo: 'Este aparelho não serve como chave',
          texto:
              'Precisa de um celular Android com NFC. No iPhone e no '
              'navegador, entre pelo QR Code ou pela tag.',
        ),
        ..._outros(s),
      ];
    }
    final deste = s.deste;
    return [
      if (!s.aparelho.nfcLigado) ...[
        _avisoNfcDesligado(),
        const SizedBox(height: 12),
      ],
      if (deste != null) _deste(deste) else _ativar(s),
      ..._outros(s),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      titulo: 'Celular como chave',
      subtitulo: 'Encoste o celular no leitor da catraca',
      onAtualizar: carregar,
      filhos: conteudo(_pronto),
    );
  }
}
