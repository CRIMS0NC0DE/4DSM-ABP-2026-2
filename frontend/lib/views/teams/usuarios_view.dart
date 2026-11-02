import 'dart:async';

import 'package:flutter/material.dart';

import '../../controllers/usuarios_controller.dart';
import '../../core/constants/formato.dart';
import '../../models/opcao_menu.dart';
import '../../models/usuario.dart';
import '../../models/usuario_cadastro.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/estado_vazio.dart';
import '../widgets/selo.dart';
import '../widgets/tela_base.dart';
import 'usuario_form_view.dart';

/// A3 · Usuários: busca por nome, e-mail ou CPF, e filtro por perfil.
class UsuariosView extends StatefulWidget {
  UsuariosView({super.key, UsuariosController? controller})
    : controller = controller ?? UsuariosController();

  final UsuariosController controller;

  @override
  State<UsuariosView> createState() => _UsuariosViewState();
}

class _UsuariosViewState extends State<UsuariosView>
    with CarregaDados<List<UsuarioCadastro>, UsuariosView> {
  final _busca = TextEditingController();
  Timer? _espera;
  Perfil? _perfil;

  UsuariosController get controller => widget.controller;

  @override
  Future<List<UsuarioCadastro>> buscar() =>
      controller.listar(busca: _busca.text, perfil: _perfil);

  @override
  void dispose() {
    _espera?.cancel();
    _busca.dispose();
    super.dispose();
  }

  /// Espera parar de digitar, para não chamar a API a cada letra.
  void _aoDigitar(String _) {
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 400), carregar);
  }

  Future<void> _abrir(UsuarioCadastro? usuario) async {
    final salvo = await Navigator.of(context).push<UsuarioCadastro>(
      MaterialPageRoute(
        builder: (_) =>
            UsuarioFormView(usuario: usuario, controller: controller),
      ),
    );
    if (salvo != null && mounted) await carregar();
  }

  List<Widget> _lista(List<UsuarioCadastro> lista) {
    if (lista.isEmpty) {
      return const [
        EstadoVazio(
          icone: Icons.person_search,
          titulo: 'Ninguém encontrado',
          texto: 'Tente outro nome, e-mail ou CPF.',
        ),
      ];
    }
    return [
      Text(
        '${lista.length} ${lista.length == 1 ? 'usuário' : 'usuários'}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 12),
      for (final usuario in lista)
        _CartaoUsuario(
          usuario: usuario,
          // Sem permissão a API responde 403: a tela nem oferece a edição.
          onTocar: controller.podeGerenciar(usuario.perfil)
              ? () => _abrir(usuario)
              : null,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      titulo: 'Usuários',
      subtitulo: 'Pessoas, perfis e documentos',
      onAtualizar: carregar,
      botaoFlutuante: FloatingActionButton.extended(
        onPressed: () => _abrir(null),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Novo usuário'),
      ),
      filhos: [
        TextField(
          controller: _busca,
          onChanged: _aoDigitar,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Nome, e-mail ou CPF',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Todos'),
              selected: _perfil == null,
              onSelected: (_) {
                _perfil = null;
                recarregar();
              },
            ),
            for (final perfil in Perfil.values)
              ChoiceChip(
                label: Text(Formato.perfil(perfil)),
                selected: _perfil == perfil,
                onSelected: (_) {
                  _perfil = perfil;
                  recarregar();
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        ...conteudo(_lista),
      ],
    );
  }
}

class _CartaoUsuario extends StatelessWidget {
  const _CartaoUsuario({required this.usuario, required this.onTocar});

  final UsuarioCadastro usuario;
  final VoidCallback? onTocar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final tagsAtivas = usuario.tags.where((t) => t.ativa).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTocar,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  child: Text(Formato.iniciais(usuario.nome)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(usuario.nome, style: textTheme.titleMedium),
                      Text(
                        'CPF ${Formato.cpfMascarado(usuario.cpf)}',
                        style: textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Selo(
                            texto: Formato.perfil(usuario.perfil),
                            icone: Icons.badge_outlined,
                          ),
                          if (!usuario.ativo)
                            const Selo(
                              texto: 'Desativado',
                              icone: Icons.block,
                              tom: TomOpcao.perigo,
                            ),
                          Selo(
                            texto: usuario.tags.isEmpty
                                ? 'Sem tag'
                                : tagsAtivas == 0
                                ? 'Tag bloqueada'
                                : 'Tag ${Formato.finalTag(usuario.tags.first.uid)}',
                            icone: Icons.contactless_outlined,
                            tom: usuario.tags.isNotEmpty && tagsAtivas == 0
                                ? TomOpcao.atencao
                                : TomOpcao.padrao,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onTocar != null) const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
