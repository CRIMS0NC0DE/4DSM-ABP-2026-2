import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:public/controllers/resident_menu_controller.dart';
import 'package:public/controllers/visitor_menu_controller.dart';
import 'package:public/models/opcao_menu.dart';
import 'package:public/services/sessao_service.dart';
import 'package:public/views/user/login_view.dart';
import 'package:public/views/user/scanner_qr_view.dart';
import 'package:public/views/visitor/visitor_menu_view.dart';

import '../../support/api_falsa.dart';

/// Guarda o que a tela pediu ao controller, para conferir no teste.
class _ControllerEspiao extends VisitorMenuController {
  final abertas = <String>[];
  var saiu = false;

  @override
  void abrir(OpcaoMenu opcao) => abertas.add(opcao.titulo);

  @override
  Future<void> sair() async => saiu = true;
}

List<String> _titulos(List<SecaoMenu> secoes) => [
  for (final secao in secoes)
    for (final opcao in secao.opcoes) opcao.titulo,
];

void main() {
  group('Permissões do visitante', () {
    final titulos = _titulos(VisitorMenuController().secoes);

    test('Cada opção aparece uma vez só', () {
      expect(titulos.toSet().length, titulos.length);
    });

    test('O morador tem todas as opções do visitante', () {
      final doMorador = _titulos(ResidentMenuController().secoes);
      expect(doMorador, containsAll(titulos));
    });

    test('Não vê gestão do prédio nem cadastra visitantes', () {
      const deFora = [
        'Meus visitantes',
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
      for (final titulo in deFora) {
        expect(titulos, isNot(contains(titulo)));
      }
    });
  });

  testWidgets('Mostra todas as opções do menu do visitante', (
    WidgetTester tester,
  ) async {
    final controller = VisitorMenuController();
    await tester.pumpWidget(
      MaterialApp(home: VisitorMenuView(controller: controller)),
    );

    expect(find.text('Visitante'), findsOneWidget);

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

    await tester.pumpWidget(MaterialApp(home: VisitorMenuView()));
    await tester.scrollUntilVisible(find.text('Sair da conta'), 200);

    // Se algum card estourasse, o Flutter lançaria um erro de overflow.
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tocar numa opção chama o controller e avisa', (
    WidgetTester tester,
  ) async {
    final controller = _ControllerEspiao();
    await tester.pumpWidget(
      MaterialApp(home: VisitorMenuView(controller: controller)),
    );

    await tester.tap(find.text('Minhas autorizações'));
    await tester.pump();

    expect(controller.abertas, ['Minhas autorizações']);
    expect(
      find.text('Minhas autorizações: tela em construção.'),
      findsOneWidget,
    );
  });

  testWidgets('Escanear QR Code abre o scanner', (WidgetTester tester) async {
    final controller = _ControllerEspiao();
    await tester.pumpWidget(
      MaterialApp(home: VisitorMenuView(controller: controller)),
    );

    await tester.tap(find.text('Escanear QR Code'));
    await tester.pumpAndSettle();

    expect(controller.abertas, ['Escanear QR Code']);
    expect(find.byType(ScannerQrView), findsOneWidget);
  });

  testWidgets('Sair da conta chama o controller e volta para o login', (
    WidgetTester tester,
  ) async {
    final controller = _ControllerEspiao();
    await tester.pumpWidget(
      MaterialApp(home: VisitorMenuView(controller: controller)),
    );

    await tester.scrollUntilVisible(find.text('Sair da conta'), 200);
    await tester.ensureVisible(find.text('Sair da conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();

    expect(controller.saiu, isTrue);
    expect(find.byType(LoginView), findsOneWidget);
  });

  testWidgets('Sair da conta apaga a sessão aberta no login pela API', (
    WidgetTester tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    final auth = authFalso();
    await tester.runAsync(() => auth.entrar('visitante@passe.com', senhaDemo));
    expect(SessaoService.instancia.token, isNotNull);

    await tester.pumpWidget(
      MaterialApp(
        home: VisitorMenuView(controller: VisitorMenuController(auth: auth)),
      ),
    );
    await tester.scrollUntilVisible(find.text('Sair da conta'), 200);
    await tester.ensureVisible(find.text('Sair da conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();

    expect(SessaoService.instancia.token, isNull);
    expect(find.byType(LoginView), findsOneWidget);
  });
}
