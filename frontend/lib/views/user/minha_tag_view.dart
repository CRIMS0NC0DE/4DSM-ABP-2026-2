import 'package:flutter/material.dart';

import '../../controllers/perfil_controller.dart';
import '../../core/constants/formato.dart';
import '../../models/opcao_menu.dart';
import '../../models/usuario_cadastro.dart';
import '../../services/api_client.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/estado_vazio.dart';
import '../widgets/selo.dart';
import '../widgets/tela_base.dart';

/// Minha tag NFC. Ver funciona hoje. Com [podeBloquear], o morador bloqueia a
/// própria tag: só ligue depois da B6 (PATCH /me/tags/:tagId).
class MinhaTagView extends StatefulWidget {
  MinhaTagView({
    super.key,
    this.podeBloquear = false,
    PerfilController? controller,
  }) : controller = controller ?? PerfilController();

  final bool podeBloquear;
  final PerfilController controller;

  @override
  State<MinhaTagView> createState() => _MinhaTagViewState();
}

class _MinhaTagViewState extends State<MinhaTagView>
    with CarregaDados<UsuarioCadastro, MinhaTagView> {
  @override
  Future<UsuarioCadastro> buscar() => widget.controller.carregar();

  Future<void> _bloquear(TagNfc tag) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Bloquear esta tag?'),
        content: const Text(
          'Ela para de abrir a catraca. Para usar de novo, só a portaria '
          'consegue liberar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Manter'),
          ),
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            child: const Text('Bloquear'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;
    try {
      await widget.controller.bloquearTag(tag.id);
      if (mounted) await carregar();
    } on ApiException catch (e) {
      if (mounted) await tratarErro(context, e);
    }
  }

  List<Widget> _tags(UsuarioCadastro usuario) {
    if (usuario.tags.isEmpty) {
      return const [
        EstadoVazio(
          icone: Icons.contactless_outlined,
          titulo: 'Você não tem tag vinculada',
          texto: 'Peça na portaria para vincular uma tag ao seu cadastro.',
        ),
      ];
    }
    final textTheme = Theme.of(context).textTheme;
    return [
      for (final tag in usuario.tags)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Final ${Formato.finalTag(tag.uid)}',
                          style: textTheme.titleLarge,
                        ),
                      ),
                      tag.ativa
                          ? const Selo(
                              texto: 'Ativa',
                              icone: Icons.check_circle,
                              tom: TomOpcao.sucesso,
                            )
                          : const Selo(
                              texto: 'Bloqueada',
                              icone: Icons.block,
                              tom: TomOpcao.perigo,
                            ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tag.ativa
                        ? 'Aproxime do terminal da catraca para passar.'
                        : 'Fale com a portaria para liberar.',
                    style: textTheme.bodyMedium,
                  ),
                  if (widget.podeBloquear && tag.ativa) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _bloquear(tag),
                      icon: const Icon(Icons.block),
                      label: const Text('Bloquear tag'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      Text(
        'Perdeu a tag? Avise a portaria o quanto antes.',
        style: textTheme.bodySmall,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      titulo: 'Minha tag NFC',
      subtitulo: 'Passe aproximando a tag do terminal',
      onAtualizar: carregar,
      filhos: conteudo(_tags),
    );
  }
}
