import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:public/controllers/login_controller.dart';
import 'package:public/models/usuario.dart';
import 'package:public/services/sessao_service.dart';
import 'package:public/views/access_controller/access_controller_menu_view.dart';
import 'package:public/views/admin/admin_menu_view.dart';
import 'package:public/views/resident/resident_menu_view.dart';
import 'package:public/views/user/login_view.dart';
import 'package:public/views/user/register_view.dart';
import 'package:public/views/visitor/visitor_menu_view.dart';

import '../../support/api_falsa.dart';

/// Guarda o que a tela pediu ao controller, para conferir no teste.
class _ControllerEspiao extends LoginController {
  _ControllerEspiao() : super(auth: authFalso());

  String? usuario;
  String? senha;

  @override
  Future<Usuario> entrar(String usuario, String senha) {
    this.usuario = usuario;
    this.senha = senha;
    return super.entrar(usuario, senha);
  }
}

/// Login ligado à API falsa (mesmas contas do seed do backend).
LoginView _login({http.Client? cliente}) => LoginView(
  controller: LoginController(auth: authFalso(cliente: cliente)),
);

/// Menu que cada perfil deve abrir depois do login.
const _menuDoPerfil = {
  Perfil.admin: AdminMenuView,
  Perfil.controladorAcesso: AccessControllerMenuView,
  Perfil.morador: ResidentMenuView,
  Perfil.visitante: VisitorMenuView,
};

/// O texto "Entrar" aparece no título e no botão; aqui só o botão.
final _botaoEntrar = find.ancestor(
  of: find.text('Entrar'),
  matching: find.bySubtype<FilledButton>(),
);

Finder _campo(String rotulo) => find.descendant(
  of: find.ancestor(of: find.text(rotulo), matching: find.byType(Column)).first,
  matching: find.byType(TextField),
);

Future<void> _entrarCom(
  WidgetTester tester,
  String usuario, [
  String senha = senhaDemo,
]) async {
  await tester.enterText(_campo('E-mail ou CPF'), usuario);
  await tester.enterText(_campo('Senha'), senha);
  await tester.tap(_botaoEntrar);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await SessaoService.instancia.encerrar();
  });

  testWidgets('Mostra os campos e os botões do login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: _login()));

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

  testWidgets('Manda o e-mail sem espaços e a senha para o controller', (
    WidgetTester tester,
  ) async {
    final controller = _ControllerEspiao();
    await tester.pumpWidget(
      MaterialApp(home: LoginView(controller: controller)),
    );

    await _entrarCom(tester, ' admin@passe.com ');

    expect(controller.usuario, 'admin@passe.com');
    expect(controller.senha, senhaDemo);
  });

  for (final conta in contasDemo) {
    testWidgets('A conta ${conta.email} abre o menu do perfil dela', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: _login()));

      await _entrarCom(tester, conta.email);

      expect(find.byType(_menuDoPerfil[conta.perfil]!), findsOneWidget);
      expect(find.byType(LoginView), findsNothing);
      expect(SessaoService.instancia.usuario?.email, conta.email);
    });
  }

  testWidgets('Também entra pelo CPF, com ou sem pontuação', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: _login()));

    await _entrarCom(tester, '222.222.222-22');

    expect(find.byType(AccessControllerMenuView), findsOneWidget);
  });

  testWidgets('Senha errada mostra a mensagem da API e continua no login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: _login()));

    await _entrarCom(tester, 'admin@passe.com', 'senha-errada');

    expect(find.text('E-mail, CPF ou senha não conferem.'), findsOneWidget);
    expect(find.byType(LoginView), findsOneWidget);
    expect(find.byType(AdminMenuView), findsNothing);
    expect(SessaoService.instancia.token, isNull);
  });

  testWidgets('Conta que não existe avisa e continua no login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: _login()));

    await _entrarCom(tester, 'ninguem@passe.com');

    expect(find.text('E-mail, CPF ou senha não conferem.'), findsOneWidget);
    expect(find.byType(LoginView), findsOneWidget);
  });

  testWidgets('Sem internet avisa e continua no login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: _login(cliente: semInternet())));

    await _entrarCom(tester, 'admin@passe.com');

    expect(
      find.text(
        'Não foi possível falar com o servidor. '
        'Confira a internet e tente de novo.',
      ),
      findsOneWidget,
    );
    expect(find.byType(LoginView), findsOneWidget);
  });

  testWidgets('Enquanto a API responde, trava o botão e mostra Entrando…', (
    WidgetTester tester,
  ) async {
    final resposta = Completer<http.Response>();
    var chamadas = 0;
    final cliente = MockClient((request) {
      chamadas++;
      return resposta.future;
    });
    await tester.pumpWidget(MaterialApp(home: _login(cliente: cliente)));

    await tester.enterText(_campo('E-mail ou CPF'), 'admin@passe.com');
    await tester.enterText(_campo('Senha'), senhaDemo);
    await tester.tap(_botaoEntrar);
    await tester.pump();

    expect(find.text('Entrando…'), findsOneWidget);
    final botao = find.ancestor(
      of: find.text('Entrando…'),
      matching: find.bySubtype<FilledButton>(),
    );
    expect(tester.widget<FilledButton>(botao).onPressed, isNull);
    await tester.tap(botao);
    expect(chamadas, 1);

    resposta.complete(
      respostaJson({
        'token': tokenFalso(),
        'usuario': contasDemo.first.toJson(),
      }, 200),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AdminMenuView), findsOneWidget);
  });

  testWidgets('Mostrar e Ocultar trocam a visibilidade da senha', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: _login()));

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
    await tester.pumpWidget(MaterialApp(home: _login()));

    await tester.ensureVisible(find.text('Registrar'));
    await tester.tap(find.text('Registrar'));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterView), findsOneWidget);
  });

  testWidgets('Sair da conta no menu apaga a sessão e volta para o login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: _login()));

    await _entrarCom(tester, 'admin@passe.com');
    expect(SessaoService.instancia.token, isNotNull);

    await tester.scrollUntilVisible(find.text('Sair da conta'), 200);
    await tester.ensureVisible(find.text('Sair da conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginView), findsOneWidget);
    expect(find.byType(AdminMenuView), findsNothing);
    expect(SessaoService.instancia.token, isNull);
  });

  testWidgets('Cabe no celular mesmo com a fonte do sistema no dobro', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(MaterialApp(home: _login()));
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
