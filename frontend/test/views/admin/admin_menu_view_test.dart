import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:public/controllers/admin_menu_controller.dart';
import 'package:public/models/opcao_menu.dart';
import 'package:public/views/shared/comunicados_view.dart';
import 'package:public/views/teams/configuracoes_view.dart';
import 'package:public/views/teams/admin/admin_menu_view.dart';
import 'package:public/views/user/login_view.dart';

/// Guarda o que a tela pediu ao controller, para conferir no teste.
class _ControllerEspiao extends AdminMenuController {
  final abertas = <String>[];
  var saiu = false;

  @override
  void abrir(OpcaoMenu opcao) => abertas.add(opcao.titulo);

  @override
  Future<void> sair() async => saiu = true;
}

void main() {
  testWidgets('Mostra todas as opções do menu do admin', (
    WidgetTester tester,
  ) async {
    final controller = AdminMenuController();
    await tester.pumpWidget(
      MaterialApp(home: AdminMenuView(controller: controller)),
    );

    expect(find.text('Administrador'), findsOneWidget);

    // A grade só monta o que está na tela, então rola até cada opção.
    for (final secao in controller.secoes) {
      await tester.scrollUntilVisible(find.text(secao.titulo), 200);
      for (final opcao in secao.opcoes) {
        await tester.scrollUntilVisible(find.text(opcao.titulo), 200);
        expect(find.text(opcao.titulo), findsOneWidget);
      }
    }
  });

  testWidgets('Cabe no celular mesmo com a fonte do sistema no dobro', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(MaterialApp(home: AdminMenuView()));
    await tester.scrollUntilVisible(find.text('Sair da conta'), 200);

    // Se algum card estourasse, o Flutter lançaria um erro de overflow.
    expect(tester.takeException(), isNull);
  });

  testWidgets('Comunicados abre a tela de gestão dos avisos', (
    WidgetTester tester,
  ) async {
    final controller = _ControllerEspiao();
    await tester.pumpWidget(
      MaterialApp(home: AdminMenuView(controller: controller)),
    );

    await tester.scrollUntilVisible(find.text('Comunicados'), 200);
    await tester.pump();
    await tester.tap(find.text('Comunicados'));
    await tester.pumpAndSettle();

    expect(controller.abertas, ['Comunicados']);
    expect(find.byType(ComunicadosView), findsOneWidget);
    expect(
      tester
          .widget<ComunicadosView>(find.byType(ComunicadosView))
          .podeGerenciar,
      isTrue,
    );
    expect(find.textContaining('em construção'), findsNothing);
  });

  testWidgets('Configurações abre a tela das regras do condomínio', (
    WidgetTester tester,
  ) async {
    final controller = _ControllerEspiao();
    await tester.pumpWidget(
      MaterialApp(home: AdminMenuView(controller: controller)),
    );

    await tester.scrollUntilVisible(find.text('Configurações'), 200);
    await tester.pump();
    await tester.tap(find.text('Configurações'));
    await tester.pumpAndSettle();

    expect(controller.abertas, ['Configurações']);
    expect(find.byType(ConfiguracoesView), findsOneWidget);
  });

  testWidgets('Tocar em Sair da conta chama o controller e volta ao login', (
    WidgetTester tester,
  ) async {
    final controller = _ControllerEspiao();
    await tester.pumpWidget(
      MaterialApp(home: AdminMenuView(controller: controller)),
    );

    await tester.scrollUntilVisible(find.text('Sair da conta'), 200);
    await tester.pump();
    await tester.tap(find.text('Sair da conta'));
    await tester.pump();

    expect(controller.saiu, isTrue);
    // A rota nova só aparece no frame seguinte ao push.
    await tester.pump();
    expect(find.text('Saindo…'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(LoginView), findsOneWidget);
    expect(find.byType(AdminMenuView), findsNothing);
  });
}
