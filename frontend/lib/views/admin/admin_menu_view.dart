import 'package:flutter/material.dart';

import '../../controllers/admin_menu_controller.dart';
import '../../models/opcao_menu.dart';
import '../widgets/menu_grade.dart';

class AdminMenuView extends StatelessWidget {
  final AdminMenuController controller;

  AdminMenuView({super.key, AdminMenuController? controller})
    : controller = controller ?? AdminMenuController();

  void _abrir(BuildContext context, OpcaoMenu opcao) {
    controller.abrir(opcao);
    // Protótipo: as telas ainda não existem, então só avisa.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${opcao.titulo}: tela em construção.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: MenuGrade(
          perfil: 'Administrador',
          iconePerfil: Icons.admin_panel_settings_outlined,
          secoes: controller.secoes,
          onSelecionar: (opcao) => _abrir(context, opcao),
          onSair: controller.sair,
        ),
      ),
    );
  }
}
