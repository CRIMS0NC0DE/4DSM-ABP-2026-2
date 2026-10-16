import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:public/controllers/login_controller.dart';
import 'package:public/views/admin/admin_menu_view.dart';
import 'package:public/views/user/login_view.dart';
import 'package:public/views/user/register_view.dart';

/// Guarda o que a tela pediu ao controller, para conferir no teste.
class _ControllerEspiao extends LoginController {
  String? usuario;
  String? senha;

  @override
  void entrar(String usuario, String senha) {
    this.usuario = usuario;
    this.senha = senha;
  }
}

/// O texto "Entrar" aparece no título e no botão; aqui só o botão.
final _botaoEntrar = find.ancestor(
  of: find.text('Entrar'),
  matching: find.bySubtype<FilledButton>(),
);

Finder _campo(String rotulo) => find.descendant(
  of: find.ancestor(of: find.text(rotulo), matching: find.byType(Column)).first,
  matching: find.byType(TextField),
);

void main() {
  testWidgets('Mostra os campos e os botões do login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: LoginView()));

    expect(find.text('E-mail ou CPF'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(_botaoEntrar, findsOneWidget);
    expect(find.text('Entrar com NFC'), findsOneWidget);
    expect(find.text('Esqueci minha senha'), findsOneWidget);
    expect(find.text('Registrar'), findsOneWidget);
  });

  testWidgets('Entrar sem preencher mostra os erros e não chama o controller', (
    WidgetTester tester,
  ) async {
    final controller = _ControllerEspiao();
    await tester.pumpWidget(
      MaterialApp(home: LoginView(controller: controller)),
    );

    await tester.tap(_botaoEntrar);
    await tester.pump();

    expect(find.text('Informe seu e-mail ou CPF.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
    expect(controller.usuario, isNull);
  });

  testWidgets('Entrar com os campos preenchidos abre o menu', (
    WidgetTester tester,
  ) async {
    final controller = _ControllerEspiao();
    await tester.pumpWidget(
      MaterialApp(home: LoginView(controller: controller)),
    );

    await tester.enterText(_campo('E-mail ou CPF'), ' maria@email.com ');
    await tester.enterText(_campo('Senha'), 'segredo123');
    await tester.tap(_botaoEntrar);
    await tester.pumpAndSettle();

    expect(controller.usuario, 'maria@email.com');
    expect(controller.senha, 'segredo123');
    expect(find.byType(AdminMenuView), findsOneWidget);
    expect(find.byType(LoginView), findsNothing);
  });

  testWidgets('Mostrar e Ocultar trocam a visibilidade da senha', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: LoginView()));

    bool senhaOculta() => tester.widget<TextField>(_campo('Senha')).obscureText;

    expect(senhaOculta(), isTrue);
    await tester.tap(find.text('Mostrar'));
    await tester.pump();
    expect(senhaOculta(), isFalse);
    await tester.tap(find.text('Ocultar'));
    await tester.pump();
    expect(senhaOculta(), isTrue);
  });

  testWidgets('Registrar abre a tela de criar conta', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: LoginView()));

    await tester.ensureVisible(find.text('Registrar'));
    await tester.tap(find.text('Registrar'));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterView), findsOneWidget);
  });

  testWidgets('Sair da conta no menu volta para o login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: LoginView()));

    await tester.enterText(_campo('E-mail ou CPF'), 'maria@email.com');
    await tester.enterText(_campo('Senha'), 'segredo123');
    await tester.tap(_botaoEntrar);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Sair da conta'), 200);
    await tester.ensureVisible(find.text('Sair da conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginView), findsOneWidget);
    expect(find.byType(AdminMenuView), findsNothing);
  });

  testWidgets('Cabe no celular mesmo com a fonte do sistema no dobro', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(MaterialApp(home: LoginView()));
    // Toca em Entrar vazio para as mensagens de erro também aparecerem.
    await tester.ensureVisible(_botaoEntrar);
    await tester.pump();
    await tester.tap(_botaoEntrar);
    await tester.pump();
    await tester.ensureVisible(find.text('Registrar'));
    await tester.pump();

    // Se algo estourasse, o Flutter lançaria um erro de overflow.
    expect(tester.takeException(), isNull);
  });
}
