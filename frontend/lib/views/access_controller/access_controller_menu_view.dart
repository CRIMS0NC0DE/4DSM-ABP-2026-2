import 'package:flutter/material.dart';

import '../../controllers/access_controller_menu_controller.dart';
import '../../models/opcao_menu.dart';
import '../user/login_view.dart';
import '../widgets/menu_grade.dart';
import '../widgets/tela_carregando.dart';

class AccessControllerMenuView extends StatelessWidget {
  final AccessControllerMenuController controller;

  AccessControllerMenuView({
    super.key,
    AccessControllerMenuController? controller,
  }) : controller = controller ?? AccessControllerMenuController();

  void _abrir(BuildContext context, OpcaoMenu opcao) {
    controller.abrir(opcao);
    // Protótipo: as telas ainda não existem, então só avisa.
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
          perfil: 'Controlador de acesso',
          iconePerfil: Icons.shield_outlined,
          secoes: controller.secoes,
          onSelecionar: (opcao) => _abrir(context, opcao),
          onSair: () => _sair(context),
        ),
      ),
    );
  }
}
