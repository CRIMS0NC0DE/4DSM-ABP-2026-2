import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:public/controllers/register_controller.dart';
import 'package:public/services/auth_service.dart';
import 'package:public/views/resident/resident_menu_view.dart';
import 'package:public/views/user/login_view.dart';
import 'package:public/views/user/register_view.dart';

/// Guarda o que a tela pediu ao controller, para conferir no teste.
class _ControllerEspiao extends RegisterController {
  Map<String, String>? dados;

  @override
  String? registrar({
    required String nome,
    required String cpf,
    required String email,
    required String senha,
  }) {
    dados = {'nome': nome, 'cpf': cpf, 'email': email, 'senha': senha};
    return null;
  }
}

Finder _campo(String rotulo) => find.descendant(
  of: find.ancestor(of: find.text(rotulo), matching: find.byType(Column)).first,
  matching: find.byType(TextField),
);

Future<void> _preencher(
  WidgetTester tester, {
  String email = 'maria@email.com',
  String confirmacao = 'segredo123',
}) async {
  await tester.enterText(_campo('Nome completo'), 'Maria Souza');
  await tester.enterText(_campo('CPF'), '123.456.789-09');
  await tester.enterText(_campo('E-mail'), email);
  await tester.enterText(_campo('Senha'), 'segredo123');
  await tester.enterText(_campo('Confirmar senha'), confirmacao);
}

Future<void> _tocarRegistrar(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Registrar'));
  await tester.pump();
  await tester.tap(find.text('Registrar'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Mostra os campos e o botão de registrar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: RegisterView()));

    expect(find.text('Nome completo'), findsOneWidget);
    expect(find.text('CPF'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Confirmar senha'), findsOneWidget);
    expect(find.text('Registrar'), findsOneWidget);
  });

  testWidgets(
    'Registrar sem preencher mostra os erros e não chama o controller',
    (WidgetTester tester) async {
      final controller = _ControllerEspiao();
      await tester.pumpWidget(
        MaterialApp(home: RegisterView(controller: controller)),
      );

      await _tocarRegistrar(tester);

      expect(find.text('Informe seu nome completo.'), findsOneWidget);
      expect(find.text('Informe seu CPF.'), findsOneWidget);
      expect(find.text('Informe seu e-mail.'), findsOneWidget);
      expect(find.text('Repita a senha.'), findsOneWidget);
      expect(controller.dados, isNull);
    },
  );

  testWidgets('Senhas diferentes não deixam registrar', (
    WidgetTester tester,
  ) async {
    final controller = _ControllerEspiao();
    await tester.pumpWidget(
      MaterialApp(home: RegisterView(controller: controller)),
    );

    await _preencher(tester, confirmacao: 'outra-senha');
    await _tocarRegistrar(tester);

    expect(find.text('As senhas não são iguais.'), findsOneWidget);
    expect(controller.dados, isNull);
  });

  testWidgets('Registrar com os campos certos chama o controller', (
    WidgetTester tester,
  ) async {
    final controller = _ControllerEspiao();
    await tester.pumpWidget(
      MaterialApp(home: RegisterView(controller: controller)),
    );

    await _preencher(tester);
    await _tocarRegistrar(tester);

    expect(controller.dados, {
      'nome': 'Maria Souza',
      'cpf': '123.456.789-09',
      'email': 'maria@email.com',
      'senha': 'segredo123',
    });
    expect(find.text('Conta criada. Agora é só entrar.'), findsOneWidget);
  });

  testWidgets(
    'Depois de registrar volta para o login com o e-mail preenchido',
    (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginView()));

      // Abre o cadastro pelo login, como no app.
      await tester.ensureVisible(find.text('Registrar'));
      await tester.tap(find.text('Registrar'));
      await tester.pumpAndSettle();
      expect(find.text('Voltar'), findsOneWidget);

      await _preencher(tester);
      await _tocarRegistrar(tester);

      expect(find.byType(RegisterView), findsNothing);
      expect(find.byType(LoginView), findsOneWidget);
      expect(find.text('maria@email.com'), findsOneWidget);

      // A conta nova já entra, e quem se cadastra pelo app é morador.
      await tester.enterText(_campo('Senha'), 'segredo123');
      await tester.tap(
        find.ancestor(
          of: find.text('Entrar'),
          matching: find.bySubtype<FilledButton>(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ResidentMenuView), findsOneWidget);
    },
  );

  testWidgets('E-mail que já tem conta avisa e não cria outra', (
    WidgetTester tester,
  ) async {
    final auth = AuthService();
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterView(controller: RegisterController(auth: auth)),
      ),
    );

    await _preencher(tester, email: 'morador@passe.com');
    await _tocarRegistrar(tester);

    expect(
      find.text('Já existe uma conta com esse e-mail ou CPF.'),
      findsOneWidget,
    );
    expect(find.text('Conta criada. Agora é só entrar.'), findsNothing);
    // A senha da conta original continua valendo.
    expect(auth.entrar('morador@passe.com', 'segredo123'), isNull);
    expect(auth.entrar('morador@passe.com', AuthService.senhaDemo), isNotNull);
  });
}
