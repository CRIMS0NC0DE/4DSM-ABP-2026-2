import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:public/controllers/login_controller.dart';
import 'package:public/controllers/register_controller.dart';
import 'package:public/services/sessao_service.dart';
import 'package:public/views/user/login_view.dart';
import 'package:public/views/user/register_view.dart';

import '../../support/api_falsa.dart';

const _mensagemDaApi = 'Pedido enviado. A portaria vai liberar seu acesso.';

/// Guarda o que a tela pediu ao controller, para conferir no teste.
class _ControllerEspiao extends RegisterController {
  _ControllerEspiao() : super(auth: authFalso());

  Map<String, String>? dados;

  @override
  Future<String> registrar({
    required String nome,
    required String cpf,
    required String email,
    required String senha,
  }) async {
    dados = {'nome': nome, 'cpf': cpf, 'email': email, 'senha': senha};
    return _mensagemDaApi;
  }
}

/// Responde o POST /auth/register como o contrato da API; [responder] troca
/// a resposta (ex.: 409).
MockClient _api({
  List<http.Request>? chamadas,
  http.Response Function()? responder,
}) {
  return MockClient((request) async {
    chamadas?.add(request);
    if (request.method == 'POST' && request.url.path == '/auth/register') {
      if (responder != null) return responder();
      final corpo = jsonDecode(request.body) as Map<String, dynamic>;
      return respostaJson({
        'mensagem': _mensagemDaApi,
        'usuario': {
          'id': 'u-novo',
          'nome': corpo['nome'],
          'email': corpo['email'],
          'cpf': (corpo['cpf'] as String).replaceAll(RegExp(r'\D'), ''),
          'perfil': 'CONDOMINO',
          'ativo': false,
          'createdAt': '2026-11-25T12:00:00.000Z',
          'updatedAt': '2026-11-25T12:00:00.000Z',
        },
      }, 201);
    }
    return erroDaApi(
      404,
      'ROTA_NAO_ENCONTRADA',
      '${request.method} ${request.url.path} não existe.',
    );
  });
}

RegisterView _cadastro({http.Client? cliente}) => RegisterView(
  controller: RegisterController(auth: authFalso(cliente: cliente ?? _api())),
);

Finder _campo(String rotulo) => find.descendant(
  of: find.ancestor(of: find.text(rotulo), matching: find.byType(Column)).first,
  matching: find.byType(TextField),
);

Future<void> _preencher(
  WidgetTester tester, {
  String nome = 'Maria Souza',
  String cpf = '123.456.789-09',
  String email = 'maria@email.com',
  String senha = 'segredo123',
  String? confirmacao,
}) async {
  await tester.enterText(_campo('Nome completo'), nome);
  await tester.enterText(_campo('CPF'), cpf);
  await tester.enterText(_campo('E-mail'), email);
  await tester.enterText(_campo('Senha'), senha);
  await tester.enterText(_campo('Confirmar senha'), confirmacao ?? senha);
}

Future<void> _enviar(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Enviar pedido'));
  await tester.pump();
  await tester.tap(find.text('Enviar pedido'));
  await tester.pumpAndSettle();
}

/// Abre o cadastro por cima de outra tela e devolve o que ele retornou.
Future<String? Function()> _abrirPorCima(
  WidgetTester tester,
  RegisterView tela,
) async {
  String? devolvido;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            devolvido = await Navigator.of(context)
                .push<String>(MaterialPageRoute(builder: (_) => tela));
          },
          child: const Text('Abrir cadastro'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir cadastro'));
  await tester.pumpAndSettle();
  return () => devolvido;
}

void main() {
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await SessaoService.instancia.encerrar();
  });

  testWidgets('Mostra os campos e o botão de enviar o pedido', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: _cadastro()));

    expect(find.text('Solicitar cadastro'), findsOneWidget);
    expect(find.text('Nome completo'), findsOneWidget);
    expect(find.text('CPF'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Confirmar senha'), findsOneWidget);
    expect(find.text('Enviar pedido'), findsOneWidget);
    expect(find.text('Pelo menos 6 caracteres.'), findsOneWidget);
  });

  testWidgets('Enviar sem preencher mostra os erros e não chama o controller', (
    WidgetTester tester,
  ) async {
    final controller = _ControllerEspiao();
    await tester.pumpWidget(
      MaterialApp(home: RegisterView(controller: controller)),
    );

    await _enviar(tester);

    expect(find.text('Informe seu nome completo.'), findsOneWidget);
    expect(find.text('Informe seu CPF.'), findsOneWidget);
    expect(find.text('Informe seu e-mail.'), findsOneWidget);
    expect(find.text('Repita a senha.'), findsOneWidget);
    expect(controller.dados, isNull);
  });

  testWidgets('Segue as regras da API: nome, CPF e senha', (
    WidgetTester tester,
  ) async {
    final controller = _ControllerEspiao();
    await tester.pumpWidget(
      MaterialApp(home: RegisterView(controller: controller)),
    );

    await _preencher(tester, nome: 'Jo', cpf: '123.456.789-0', senha: '12345');
    await _enviar(tester);

    expect(
      find.text('O nome precisa ter pelo menos 3 letras.'),
      findsOneWidget,
    );
    expect(find.text('O CPF tem 11 números.'), findsOneWidget);
    expect(
      find.text('A senha precisa ter pelo menos 6 caracteres.'),
      findsOneWidget,
    );
    expect(controller.dados, isNull);

    // Senha de 6 caracteres já vale, como na API.
    await _preencher(tester, senha: '123456');
    await _enviar(tester);
    expect(controller.dados?['senha'], '123456');
  });

  testWidgets('Senhas diferentes não deixam enviar', (
    WidgetTester tester,
  ) async {
    final controller = _ControllerEspiao();
    await tester.pumpWidget(
      MaterialApp(home: RegisterView(controller: controller)),
    );

    await _preencher(tester, confirmacao: 'outra-senha');
    await _enviar(tester);

    expect(find.text('As senhas não são iguais.'), findsOneWidget);
    expect(controller.dados, isNull);
  });

  testWidgets('Com os campos certos, chama o controller sem espaços', (
    WidgetTester tester,
  ) async {
    final controller = _ControllerEspiao();
    await tester.pumpWidget(
      MaterialApp(home: RegisterView(controller: controller)),
    );

    await _preencher(tester, nome: ' Maria Souza ', email: ' maria@email.com ');
    await _enviar(tester);

    expect(controller.dados, {
      'nome': 'Maria Souza',
      'cpf': '123.456.789-09',
      'email': 'maria@email.com',
      'senha': 'segredo123',
    });
  });

  testWidgets(
    'Envia para POST /auth/register e explica que a portaria libera',
    (WidgetTester tester) async {
      final chamadas = <http.Request>[];
      final devolvido = await _abrirPorCima(
        tester,
        _cadastro(cliente: _api(chamadas: chamadas)),
      );

      await _preencher(tester);
      await _enviar(tester);

      final chamada = chamadas.single;
      expect(chamada.method, 'POST');
      expect(chamada.url.path, '/auth/register');
      expect(chamada.headers['Authorization'], isNull);
      expect(jsonDecode(chamada.body), {
        'nome': 'Maria Souza',
        'email': 'maria@email.com',
        'cpf': '123.456.789-09',
        'senha': 'segredo123',
      });

      expect(find.text('Pedido enviado'), findsOneWidget);
      expect(find.textContaining(_mensagemDaApi), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('maria@email.com'),
        ),
        findsOneWidget,
      );
      // Ainda não entrou: o cadastro nasce desativado.
      expect(SessaoService.instancia.token, isNull);

      await tester.tap(find.text('Voltar ao login'));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterView), findsNothing);
      expect(devolvido(), 'maria@email.com');
    },
  );

  testWidgets('E-mail já cadastrado mostra a mensagem da API e não sai', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: _cadastro(
          cliente: _api(
            responder: () =>
                erroDaApi(409, 'CONFLITO', 'Já existe alguém com este e-mail.'),
          ),
        ),
      ),
    );

    await _preencher(tester);
    await _enviar(tester);

    expect(find.text('Já existe alguém com este e-mail.'), findsOneWidget);
    expect(find.text('Pedido enviado'), findsNothing);
    expect(find.byType(RegisterView), findsOneWidget);
  });

  testWidgets('Erro de um campo vindo da API aparece embaixo dele', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: _cadastro(
          cliente: _api(
            responder: () => respostaJson({
              'erro': {
                'codigo': 'DADOS_INVALIDOS',
                'mensagem': 'Confira os campos.',
                'detalhes': {
                  'cpf': ['CPF inválido'],
                },
              },
            }, 400),
          ),
        ),
      ),
    );

    await _preencher(tester);
    await _enviar(tester);

    expect(find.text('CPF inválido'), findsOneWidget);
    expect(find.text('Pedido enviado'), findsNothing);
  });

  testWidgets('Sem internet avisa e continua no cadastro', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: _cadastro(cliente: semInternet())),
    );

    await _preencher(tester);
    await _enviar(tester);

    expect(
      find.text(
        'Não foi possível falar com o servidor. '
        'Confira a internet e tente de novo.',
      ),
      findsOneWidget,
    );
    expect(find.byType(RegisterView), findsOneWidget);
  });

  testWidgets('Pelo login: pede o cadastro e volta com o e-mail preenchido', (
    WidgetTester tester,
  ) async {
    final chamadas = <http.Request>[];
    await tester.pumpWidget(
      MaterialApp(
        home: LoginView(
          controller: LoginController(
            auth: authFalso(cliente: _api(chamadas: chamadas)),
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Solicitar cadastro'));
    await tester.tap(find.text('Solicitar cadastro'));
    await tester.pumpAndSettle();
    expect(find.text('Voltar'), findsOneWidget);

    await _preencher(tester);
    await _enviar(tester);
    await tester.tap(find.text('Voltar ao login'));
    await tester.pumpAndSettle();

    expect(chamadas.single.url.path, '/auth/register');
    expect(find.byType(LoginView), findsOneWidget);
    expect(find.text('maria@email.com'), findsOneWidget);
  });

  testWidgets('Cabe no celular mesmo com a fonte do sistema no dobro', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _abrirPorCima(tester, _cadastro());
    await _enviar(tester);
    expect(tester.takeException(), isNull);

    await _preencher(tester);
    await _enviar(tester);
    expect(find.text('Pedido enviado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
