import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:public/controllers/access_controller_menu_controller.dart';
import 'package:public/controllers/admin_menu_controller.dart';
import 'package:public/models/opcao_menu.dart';
import 'package:public/views/access_controller/access_controller_menu_view.dart';
import 'package:public/views/user/login_view.dart';

/// Guarda o que a tela pediu ao controller, para conferir no teste.
class _ControllerEspiao extends AccessControllerMenuController {
  final abertas = <String>[];
  var saiu = false;

  @override
  void abrir(OpcaoMenu opcao) => abertas.add(opcao.titulo);

  @override
  void sair() => saiu = true;
}

List<String> _titulos(List<SecaoMenu> secoes) => [
  for (final secao in secoes)
    for (final opcao in secao.opcoes) opcao.titulo,
];

void main() {
  group('Permissões do controlador de acesso', () {
    final titulos = _titulos(AccessControllerMenuController().secoes);

    test('Cada opção aparece uma vez só', () {
      expect(titulos.toSet().length, titulos.length);
    });

    test('O admin é o cargo superior: tem todas as opções do controlador', () {
      final doAdmin = _titulos(AdminMenuController().secoes);
      expect(doAdmin, containsAll(titulos));
    });

    test('Não tem as opções que são só do admin', () {
      const soDoAdmin = [
        'Locais',
        'Relatórios',
        'Comunicados',
        'Configurações',
      ];
      for (final titulo in soDoAdmin) {
        expect(titulos, isNot(contains(titulo)));
      }
    });
  });

  testWidgets('Mostra todas as opções do menu do controlador de acesso', (
    WidgetTester tester,
  ) async {
    final controller = AccessControllerMenuController();
    await tester.pumpWidget(
      MaterialApp(home: AccessControllerMenuView(controller: controller)),
    );

    expect(find.text('Controlador de acesso'), findsOneWidget);

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

    await tester.pumpWidget(MaterialApp(home: AccessControllerMenuView()));
    await tester.scrollUntilVisible(find.text('Sair da conta'), 200);

    // Se algum card estourasse, o Flutter lançaria um erro de overflow.
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tocar numa opção chama o controller e avisa', (
    WidgetTester tester,
  ) async {
    final controller = _ControllerEspiao();
    await tester.pumpWidget(
      MaterialApp(home: AccessControllerMenuView(controller: controller)),
    );

    await tester.scrollUntilVisible(find.text('Visitantes'), 200);
    await tester.pump();
    await tester.tap(find.text('Visitantes'));
    await tester.pump();

    expect(controller.abertas, ['Visitantes']);
    expect(find.text('Visitantes: tela em construção.'), findsOneWidget);
  });

  testWidgets('Sair da conta chama o controller e volta para o login', (
    WidgetTester tester,
  ) async {
    final controller = _ControllerEspiao();
    await tester.pumpWidget(
      MaterialApp(home: AccessControllerMenuView(controller: controller)),
    );

    await tester.scrollUntilVisible(find.text('Sair da conta'), 200);
    await tester.ensureVisible(find.text('Sair da conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();

    expect(controller.saiu, isTrue);
    expect(find.byType(LoginView), findsOneWidget);
  });
}
