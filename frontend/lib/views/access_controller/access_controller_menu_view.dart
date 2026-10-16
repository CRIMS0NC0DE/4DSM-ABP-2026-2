import 'package:flutter/material.dart';

import '../../controllers/access_controller_menu_controller.dart';
import '../../models/opcao_menu.dart';
import '../user/login_view.dart';
import '../widgets/menu_grade.dart';

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

  void _sair(BuildContext context) {
    controller.sair();
    // Volta para o login e limpa o histórico, para o Voltar não reabrir o menu.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginView()),
      (_) => false,
    );
  }

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
