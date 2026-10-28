import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/formatos.dart';
import '../../models/admin_models.dart';
import '../../models/usuario.dart';
import '../../services/admin_service.dart';
import '../widgets/admin_widgets.dart';
import 'usuario_form_view.dart';

/// Lista de usuários (A3 · RF01): busca por nome, e-mail ou CPF, filtro por
/// perfil e acesso ao cadastro de cada pessoa. Também serve de porta de
/// entrada para visitantes e tags NFC.
class UsuariosView extends StatefulWidget {
  const UsuariosView({
    super.key,
    this.titulo = 'Usuários',
    this.perfilInicial,
    this._servico,
  });

  final String titulo;
  final Perfil? perfilInicial;
  final AdminService? _servico;

  @override
  State<UsuariosView> createState() => _UsuariosViewState();
}

class _UsuariosViewState extends State<UsuariosView> {
  late final AdminService _servico = widget._servico ?? AdminService.instancia;
  final _busca = TextEditingController();
  Timer? _espera;

  late Perfil? _perfil = widget.perfilInicial;
  var _termo = '';
  var _versao = 0;

  @override
  void dispose() {
    _espera?.cancel();
    _busca.dispose();
    super.dispose();
  }

  /// Espera a pessoa parar de digitar antes de consultar a API.
  void _digitou(String texto) {
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _termo = texto);
    });
  }

  Future<void> _abrirForm([UsuarioAdmin? usuario]) async {
    final mudou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => UsuarioFormView(
          usuario: usuario,
          perfilInicial: _perfil,
          servico: _servico,
        ),
      ),
    );
    if (mudou == true && mounted) setState(() => _versao++);
  }

  @override
  Widget build(BuildContext context) {
    return TelaAdmin(
      titulo: widget.titulo,
      botaoFlutuante: FloatingActionButton.extended(
        onPressed: () => _abrirForm(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Novo usuário'),
      ),
      corpo: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _busca,
              onChanged: _digitou,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Buscar usuário',
                hintText: 'Nome, e-mail ou CPF',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _busca.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpar busca',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _busca.clear();
                          setState(() => _termo = '');
                        },
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: _perfil == null,
                  onSelected: (_) => setState(() => _perfil = null),
                ),
                for (final p in Perfil.values) ...[
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(p.rotulo),
                    selected: _perfil == p,
                    onSelected: (_) => setState(() => _perfil = p),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: CarregaDados<List<UsuarioAdmin>>(
              key: ValueKey('$_termo|${_perfil?.api}|$_versao'),
              carregar: () => _servico.usuarios(busca: _termo, perfil: _perfil),
              mensagem: 'Carregando usuários…',
              construir: (context, usuarios) => _Lista(
                usuarios: usuarios,
                servico: _servico,
                onAbrir: _abrirForm,
                onAtualizar: () async => setState(() => _versao++),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({
    required this.usuarios,
    required this.servico,
    required this.onAbrir,
    required this.onAtualizar,
  });

  final List<UsuarioAdmin> usuarios;
  final AdminService servico;
  final ValueChanged<UsuarioAdmin> onAbrir;
  final Future<void> Function() onAtualizar;

  @override
  Widget build(BuildContext context) {
    if (usuarios.isEmpty) {
      return const EstadoVazio(
        icone: Icons.person_search,
        titulo: 'Nenhum usuário encontrado',
        texto: 'Mude a busca ou o filtro de perfil.',
      );
    }
    return RefreshIndicator(
      onRefresh: onAtualizar,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        itemCount: usuarios.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          if (i == 0) {
            return Text(
              '${usuarios.length} ${usuarios.length == 1 ? 'usuário encontrado' : 'usuários encontrados'}',
              style: Theme.of(context).textTheme.bodySmall,
            );
          }
          final u = usuarios[i - 1];
          return _CartaoUsuario(
            usuario: u,
            editavel: servico.podeGerenciar(u.perfil),
            onTap: () => onAbrir(u),
          );
        },
      ),
    );
  }
}

class _CartaoUsuario extends StatelessWidget {
  const _CartaoUsuario({
    required this.usuario,
    required this.editavel,
    required this.onTap,
  });

  final UsuarioAdmin usuario;
  final bool editavel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final iniciais = usuario.nome
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    final tag = usuario.tagAtiva;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: editavel ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                child: Text(iniciais),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(usuario.nome, style: textTheme.titleMedium),
                    Text(
                      'CPF ${Formatos.cpfMascarado(usuario.cpf)}',
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Selo(
                          texto: usuario.perfil.rotulo,
                          tom: TomSelo.marca,
                          icone: switch (usuario.perfil) {
                            Perfil.admin => Icons.admin_panel_settings_outlined,
                            Perfil.controladorAcesso => Icons.security,
                            Perfil.morador => Icons.home_outlined,
                            Perfil.visitante => Icons.schedule,
                          },
                        ),
                        Selo(
                          texto: tag == null
                              ? 'Sem tag'
                              : 'Tag ${Formatos.finalDaTag(tag.uid)}',
                          tom: TomSelo.neutro,
                          icone: tag == null
                              ? Icons.do_not_disturb_on_outlined
                              : Icons.contactless_outlined,
                        ),
                        if (!usuario.ativo)
                          const Selo(
                            texto: 'Desativado',
                            tom: TomSelo.perigo,
                            icone: Icons.block,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (editavel) const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
