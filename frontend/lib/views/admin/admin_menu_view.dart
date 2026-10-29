import 'package:flutter/material.dart';

import '../../controllers/admin_menu_controller.dart';
import '../../models/opcao_menu.dart';
import '../../models/usuario.dart';
import '../user/login_view.dart';
import '../widgets/menu_grade.dart';
import '../widgets/tela_carregando.dart';
import 'autorizacoes_view.dart';
import 'historico_view.dart';
import 'locais_view.dart';
import 'painel_view.dart';
import 'terminais_view.dart';
import 'usuarios_view.dart';

class AdminMenuView extends StatelessWidget {
  final AdminMenuController controller;

  AdminMenuView({super.key, AdminMenuController? controller})
    : controller = controller ?? AdminMenuController();

  /// Tela de cada opção. Null para as que o backend ainda não tem
  /// (relatórios, comunicados e configurações).
  Widget? _telaDe(OpcaoMenu opcao) => switch (opcao.titulo) {
    'Painel' => const PainelView(),
    'Autorizações' => const AutorizacoesView(),
    'Histórico de acessos' => const HistoricoView(),
    'Acessos negados' => const HistoricoView(
      somenteNegados: true,
      titulo: 'Acessos negados',
    ),
    'Usuários' => const UsuariosView(),
    'Visitantes' => const UsuariosView(
      titulo: 'Visitantes',
      perfilInicial: Perfil.visitante,
    ),
    'Locais' => const LocaisView(),
    'Tags NFC' => const UsuariosView(titulo: 'Tags NFC'),
    'Terminais' => const TerminaisView(),
    _ => null,
  };

  void _abrir(BuildContext context, OpcaoMenu opcao) {
    controller.abrir(opcao);
    final tela = _telaDe(opcao);
    if (tela != null) {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => tela));
      return;
    }
    // Sem tela ainda: só avisa.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${opcao.titulo}: tela em construção.')),
      );
  }

  /// Volta para o login; a tela de carregamento limpa o histórico, para o
  /// Voltar não reabrir o menu.
  Future<void> _sair(BuildContext context) => TelaCarregando.abrir(
    context,
    mensagem: 'Saindo…',
    tarefa: () async {
      await controller.sair();
      return LoginView();
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: MenuGrade(
          perfil: 'Administrador',
          iconePerfil: Icons.admin_panel_settings_outlined,
          secoes: controller.secoes,
          onSelecionar: (opcao) => _abrir(context, opcao),
          onSair: () => _sair(context),
        ),
      ),
    );
  }
}
