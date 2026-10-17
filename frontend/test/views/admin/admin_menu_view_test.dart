import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:public/controllers/admin_menu_controller.dart';
import 'package:public/models/opcao_menu.dart';
import 'package:public/views/admin/admin_menu_view.dart';

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

  testWidgets('Tocar numa opção chama o controller e avisa', (
    WidgetTester tester,
  ) async {
    final controller = _ControllerEspiao();
    await tester.pumpWidget(
      MaterialApp(home: AdminMenuView(controller: controller)),
    );

    await tester.scrollUntilVisible(find.text('Usuários'), 200);
    await tester.pump();
    await tester.tap(find.text('Usuários'));
    await tester.pump();

    expect(controller.abertas, ['Usuários']);
    expect(find.text('Usuários: tela em construção.'), findsOneWidget);
  });

  testWidgets('Tocar em Sair da conta chama o controller', (
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
  });
}
