import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:public/controllers/resident_menu_controller.dart';
import 'package:public/models/opcao_menu.dart';
import 'package:public/views/resident/resident_menu_view.dart';
import 'package:public/views/user/login_view.dart';

/// Guarda o que a tela pediu ao controller, para conferir no teste.
class _ControllerEspiao extends ResidentMenuController {
  final abertas = <String>[];
  var saiu = false;

  @override
  void abrir(OpcaoMenu opcao) => abertas.add(opcao.titulo);

  @override
  void sair() => saiu = true;
}

void main() {
  group('Permissões do morador', () {
    final titulos = [
      for (final secao in ResidentMenuController().secoes)
        for (final opcao in secao.opcoes) opcao.titulo,
    ];

    test('Cada opção aparece uma vez só', () {
      expect(titulos.toSet().length, titulos.length);
    });

    test('Não vê as opções de gestão do admin e da portaria', () {
      const deGestao = [
        'Painel',
        'Autorizações',
        'Usuários',
        'Visitantes',
        'Locais',
        'Tags NFC',
        'Terminais',
        'Relatórios',
        'Comunicados',
        'Configurações',
      ];
      for (final titulo in deGestao) {
        expect(titulos, isNot(contains(titulo)));
      }
    });
  });

  testWidgets('Mostra todas as opções do menu do morador', (
    WidgetTester tester,
  ) async {
    final controller = ResidentMenuController();
    await tester.pumpWidget(
      MaterialApp(home: ResidentMenuView(controller: controller)),
    );

    expect(find.text('Morador'), findsOneWidget);

    // A grade só monta o que está na tela, então rola até cada opção.
    for (final secao in controller.secoes) {
      await tester.scrollUntilVisible(find.text(secao.titulo), 200);
      for (final opcao in secao.opcoes) {
        await tester.scrollUntilVisible(find.text(opcao.titulo), 200);
        expect(find.text(opcao.titulo), findsOneWidget);
        expect(find.text(opcao.descricao), findsOneWidget);
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

    await tester.pumpWidget(MaterialApp(home: ResidentMenuView()));
    await tester.scrollUntilVisible(find.text('Sair da conta'), 200);

    // Se algum card estourasse, o Flutter lançaria um erro de overflow.
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tocar numa opção chama o controller e avisa', (
    WidgetTester tester,
  ) async {
    final controller = _ControllerEspiao();
    await tester.pumpWidget(
      MaterialApp(home: ResidentMenuView(controller: controller)),
    );

    await tester.tap(find.text('Escanear QR Code'));
    await tester.pump();

    expect(controller.abertas, ['Escanear QR Code']);
    expect(find.text('Escanear QR Code: tela em construção.'), findsOneWidget);
  });

  testWidgets('Sair da conta chama o controller e volta para o login', (
    WidgetTester tester,
  ) async {
    final controller = _ControllerEspiao();
    await tester.pumpWidget(
      MaterialApp(home: ResidentMenuView(controller: controller)),
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
