import 'package:flutter/material.dart';

import '../../controllers/perfil_controller.dart';
import '../../core/constants/formato.dart';
import '../../models/usuario_cadastro.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/tela_base.dart';
import '../widgets/tela_carregando.dart';
import 'ajuda_view.dart';
import 'login_view.dart';

/// U9 · Perfil / Sair.
class PerfilView extends StatefulWidget {
  PerfilView({super.key, PerfilController? controller})
    : controller = controller ?? PerfilController();

  final PerfilController controller;

  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView>
    with CarregaDados<UsuarioCadastro, PerfilView> {
  @override
  Future<UsuarioCadastro> buscar() => widget.controller.carregar();

  Future<void> _sair() => TelaCarregando.abrir(
    context,
    mensagem: 'Saindo…',
    tarefa: () async {
      await widget.controller.sair();
      return LoginView();
    },
  );

  List<Widget> _dados(UsuarioCadastro usuario) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final tag = usuario.tags.firstOrNull;

    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                child: Text(Formato.iniciais(usuario.nome)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(usuario.nome, style: textTheme.titleLarge),
                    Text(
                      Formato.perfil(usuario.perfil),
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('E-mail'),
              subtitle: Text(usuario.email),
            ),
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('CPF'),
              subtitle: Text(Formato.cpfMascarado(usuario.cpf)),
            ),
            ListTile(
              leading: const Icon(Icons.contactless_outlined),
              title: const Text('Tag NFC'),
              subtitle: Text(
                tag == null
                    ? 'Nenhuma tag vinculada'
                    : '${tag.ativa ? 'Vinculada' : 'Bloqueada'} · '
                          'final ${Formato.finalTag(tag.uid)}',
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text('Ajuda e contato da portaria'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AjudaView()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Sobre o Passe'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'Passe',
                applicationVersion: 'Versão 1.0',
                applicationLegalese: 'ABP 4º DSM · FATEC Jacareí, 2026',
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      OutlinedButton.icon(
        onPressed: _sair,
        icon: const Icon(Icons.logout),
        label: const Text('Sair da conta'),
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.error,
          side: BorderSide(color: colorScheme.error, width: 1.5),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      titulo: 'Perfil',
      onAtualizar: carregar,
      filhos: conteudo(_dados),
    );
  }
}
