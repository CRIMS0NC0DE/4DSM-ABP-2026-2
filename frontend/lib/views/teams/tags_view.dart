import 'package:flutter/material.dart';

import '../../controllers/usuarios_controller.dart';
import '../../core/constants/formato.dart';
import '../../models/usuario_cadastro.dart';
import '../../services/api_client.dart';
import '../widgets/botao_acao.dart';
import '../widgets/campo_selecao.dart';
import '../widgets/campo_texto.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/estado_vazio.dart';
import '../widgets/tela_base.dart';

/// Tags NFC (sem tela no design): vincular, bloquear e remover. A API não tem
/// lista só de tags nem busca por UID, então lê GET /users e filtra aqui.
class TagsView extends StatefulWidget {
  TagsView({super.key, UsuariosController? controller})
    : controller = controller ?? UsuariosController();

  final UsuariosController controller;

  @override
  State<TagsView> createState() => _TagsViewState();
}

class _TagsViewState extends State<TagsView>
    with CarregaDados<List<UsuarioCadastro>, TagsView> {
  final _busca = TextEditingController();

  UsuariosController get controller => widget.controller;

  @override
  Future<List<UsuarioCadastro>> buscar() => controller.listar();

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  Future<void> _executar(Future<void> Function() acao) async {
    try {
      await acao();
      if (mounted) await carregar();
    } on ApiException catch (e) {
      if (mounted) await tratarErro(context, e);
    }
  }

  Future<void> _vincular(List<UsuarioCadastro> pessoas) async {
    final permitidas = [
      for (final p in pessoas)
        if (p.ativo && controller.podeGerenciar(p.perfil)) p,
    ];
    final dados = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FormularioTag(pessoas: permitidas),
    );
    if (dados == null) return;
    await _executar(() => controller.vincularTag(dados.$1, dados.$2));
  }

  Future<void> _remover(UsuarioCadastro pessoa, TagNfc tag) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Remover esta tag?'),
        content: Text(
          'A tag final ${Formato.finalTag(tag.uid)} deixa de ser de '
          '${pessoa.nome}. Se ela só perdeu a tag, prefira bloquear.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Manter'),
          ),
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmou == true) {
      await _executar(() => controller.removerTag(pessoa.id, tag.id));
    }
  }

  List<Widget> _lista(List<UsuarioCadastro> pessoas) {
    final busca = _busca.text.trim().toLowerCase();
    final comTag = [
      for (final p in pessoas)
        if (p.tags.isNotEmpty &&
            (p.nome.toLowerCase().contains(busca) ||
                p.tags.any((t) => t.uid.toLowerCase().contains(busca))))
          p,
    ];
    if (comTag.isEmpty) {
      return const [
        EstadoVazio(
          icone: Icons.contactless_outlined,
          titulo: 'Nenhuma tag encontrada',
          texto: 'Vincule uma tag ou busque por outro nome.',
        ),
      ];
    }
    return [
      for (final pessoa in comTag)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    pessoa.nome,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    Formato.perfil(pessoa.perfil),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  for (final tag in pessoa.tags)
                    _LinhaTag(
                      tag: tag,
                      // O controlador não mexe nas tags da equipe (403).
                      podeMudar: controller.podeGerenciar(pessoa.perfil),
                      onAtiva: (ativa) => _executar(
                        () => controller.alterarTag(pessoa.id, tag.id, ativa),
                      ),
                      onRemover: () => _remover(pessoa, tag),
                    ),
                ],
              ),
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final atual = dados;
    return TelaBase(
      titulo: 'Tags NFC',
      subtitulo: 'Vincular e bloquear tags',
      onAtualizar: carregar,
      botaoFlutuante: atual == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _vincular(atual),
              icon: const Icon(Icons.add),
              label: const Text('Vincular tag'),
            ),
      filhos: [
        TextField(
          controller: _busca,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Nome ou UID da tag',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 16),
        ...conteudo(_lista),
      ],
    );
  }
}

class _LinhaTag extends StatelessWidget {
  const _LinhaTag({
    required this.tag,
    required this.podeMudar,
    required this.onAtiva,
    required this.onRemover,
  });

  final TagNfc tag;
  final bool podeMudar;
  final ValueChanged<bool> onAtiva;
  final VoidCallback onRemover;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Icon(Icons.contactless_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tag.uid),
                Text(
                  tag.ativa ? 'Ativa' : 'Bloqueada',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (podeMudar) ...[
            Semantics(
              label: tag.ativa ? 'Bloquear tag' : 'Desbloquear tag',
              child: Switch(value: tag.ativa, onChanged: onAtiva),
            ),
            IconButton(
              onPressed: onRemover,
              tooltip: 'Remover tag',
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ],
      ),
    );
  }
}

class _FormularioTag extends StatefulWidget {
  const _FormularioTag({required this.pessoas});

  final List<UsuarioCadastro> pessoas;

  @override
  State<_FormularioTag> createState() => _FormularioTagState();
}

class _FormularioTagState extends State<_FormularioTag> {
  final _form = GlobalKey<FormState>();
  final _uid = TextEditingController();
  String? _pessoaId;

  /// Mesma regra da API (tagSchema em users.controller.ts).
  static final _formatoUid = RegExp(r'^[0-9a-fA-F:\s-]{4,40}$');

  @override
  void dispose() {
    _uid.dispose();
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
                'Vincular tag',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              CampoEscolha<String>(
                rotulo: 'Pessoa',
                valor: _pessoaId,
                icone: Icons.person_outline,
                opcoes: [for (final p in widget.pessoas) (p.id, p.nome)],
                onMudar: (v) => setState(() => _pessoaId = v),
                validator: (v) => v == null ? 'Escolha a pessoa.' : null,
              ),
              const SizedBox(height: 20),
              CampoTexto(
                rotulo: 'UID da tag',
                controller: _uid,
                icone: Icons.contactless_outlined,
                dica: '04:A1:B2:C3',
                ajuda: 'Aparece no histórico quando a tag é lida na catraca.',
                acao: TextInputAction.done,
                validator: (v) => _formatoUid.hasMatch((v ?? '').trim())
                    ? null
                    : 'Use de 4 a 40 caracteres em hexadecimal.',
              ),
              const SizedBox(height: 24),
              BotaoAcao(
                rotulo: 'Vincular',
                icone: Icons.check,
                onTocar: () {
                  if (_form.currentState!.validate()) {
                    Navigator.of(context).pop((_pessoaId!, _uid.text.trim()));
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
