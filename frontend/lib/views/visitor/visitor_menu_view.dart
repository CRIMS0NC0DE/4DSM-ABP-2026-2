import 'package:flutter/material.dart';

import '../../controllers/visitor_menu_controller.dart';
import '../../models/opcao_menu.dart';
import '../user/login_view.dart';
import '../widgets/menu_grade.dart';

class VisitorMenuView extends StatelessWidget {
  final VisitorMenuController controller;

  VisitorMenuView({super.key, VisitorMenuController? controller})
    : controller = controller ?? VisitorMenuController();

  void _abrir(BuildContext context, OpcaoMenu opcao) {
    controller.abrir(opcao);
    // Protótipo: as telas ainda não existem, então só avisa.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${opcao.titulo}: tela em construção.')),
      );
  }

  Future<void> _sair(BuildContext context) async {
    await controller.sair();
    if (!context.mounted) return;
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
          perfil: 'Visitante',
          // Mesmo ícone do perfil Visitante na lista de usuários (A3).
          iconePerfil: Icons.schedule,
          secoes: controller.secoes,
          onSelecionar: (opcao) => _abrir(context, opcao),
          onSair: () => _sair(context),
        ),
      ),
    );
  }
}
