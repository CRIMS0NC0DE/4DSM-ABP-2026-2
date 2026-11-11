import 'package:flutter/material.dart';

import '../../../controllers/admin_menu_controller.dart';
import '../../../models/opcao_menu.dart';
import '../../user/login_view.dart';
import '../../widgets/tela_carregando.dart';
import '../../shared/historico_view.dart';
import '../autorizacoes_view.dart';
import '../painel_view.dart';
import '../tags_view.dart';
import '../terminais_view.dart';
import '../usuarios_view.dart';
import '../visitantes_view.dart';
import '../locais_view.dart';
import '../relatorios_view.dart';
import '../../widgets/menu_grade.dart';


class AdminMenuView extends StatelessWidget {
  final AdminMenuController controller;

  AdminMenuView({super.key, AdminMenuController? controller})
    : controller = controller ?? AdminMenuController();
  void _abrir(BuildContext context, OpcaoMenu opcao) {
    controller.abrir(opcao);
    final tela = switch (opcao.titulo) {
      'Painel' => PainelView(),
      'Autorizações' => AutorizacoesView(),
      'Histórico de acessos' => HistoricoView(daEquipe: true),
      'Acessos negados' => HistoricoView(daEquipe: true, soNegados: true),
      'Usuários' => UsuariosView(),
      'Visitantes' => VisitantesView(),
      'Tags NFC' => TagsView(),
      'Terminais' => TerminaisView(),
      'Locais' => LocaisView(),
      'Relatórios' => RelatoriosView(),
      _ => null,
    };
    if (tela != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));
      return;
    }
    // As opções que ainda não têm tela só avisam.
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
