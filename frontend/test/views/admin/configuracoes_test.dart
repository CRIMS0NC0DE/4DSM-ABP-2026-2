import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:public/controllers/configuracoes_controller.dart';
import 'package:public/core/theme/app_theme.dart';
import 'package:public/models/configuracoes.dart';
import 'package:public/services/api_client.dart';
import 'package:public/services/sessao_service.dart';
import 'package:public/views/teams/configuracoes_view.dart';
import 'package:public/views/user/ajuda_view.dart';
import 'package:public/views/user/login_view.dart';
import 'package:public/views/widgets/cartao_erro.dart';

import '../../support/api_falsa.dart';

// Como o GET /settings devolve.
const _configuracoes = {
  'nomeCondominio': 'FATEC Jacareí',
  'contatoPortaria': 'Portaria: (12) 3953-0000, das 7h às 22h',
  'moradorPodeConvidar': true,
  'visitanteMaxUsos': 2,
  'visitanteDiasMax': 7,
  'atualizadoEm': '2026-11-25T12:00:00.000Z',
  'sistema': {
    'fuso': 'America/Sao_Paulo',
    'qrTrocaSegundos': 10,
    'qrValidadeSegundos': 30,
    'raioPadraoMetros': 100,
  },
};

/// API com GET e PATCH /settings. O PATCH junta o corpo ao que já estava.
/// [falha] responde todas as rotas com esse status.
MockClient _api({List<http.Request>? chamadas, int? falha}) {
  var atuais = Map<String, Object?>.of(_configuracoes);
  return MockClient((request) async {
    chamadas?.add(request);
    if (falha != null) return erroDaApi(falha, 'ERRO', 'Falhou ($falha).');
    final rota = '${request.method} ${request.url.path}';
    if (rota == 'GET /settings') return respostaJson(atuais, 200);
    if (rota == 'PATCH /settings') {
      final corpo = jsonDecode(request.body) as Map<String, dynamic>;
      atuais = {...atuais, ...corpo};
      return respostaJson(atuais, 200);
    }
    return erroDaApi(404, 'ROTA_NAO_ENCONTRADA', '$rota não existe.');
  });
}

Future<void> _abrir(
  WidgetTester tester,
  Widget tela, {
  double fonte = 1,
  ThemeData? tema,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = fonte;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    MaterialApp(
      theme: tema ?? AppTheme.light,
      home: Builder(
        builder: (contexto) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () =>
                  Navigator.of(contexto)
                      .push(MaterialPageRoute(builder: (_) => tela)),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

ConfiguracoesController _controller(http.Client cliente) =>
    ConfiguracoesController(api: ApiClient(cliente: cliente));

Widget _tela(http.Client cliente) =>
    ConfiguracoesView(controller: _controller(cliente));

/// O campo de texto embaixo do [rotulo] (os rótulos ficam em cima, fora do
/// TextField).
Finder _campo(String rotulo) => find.descendant(
  of: find.ancestor(of: find.text(rotulo), matching: find.byType(Column)).first,
  matching: find.byType(TextField),
);

Future<void> _digitar(WidgetTester tester, String rotulo, String texto) async {
  await tester.ensureVisible(_campo(rotulo));
  await tester.enterText(_campo(rotulo), texto);
}

Future<void> _salvar(WidgetTester tester) async {
  await tester.tap(find.text('Salvar configurações'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await SessaoService.instancia.encerrar();
  });

  test('Lê as configurações e os valores do sistema', () {
    final c = Configuracoes.fromJson(_configuracoes);
    expect(c.nomeCondominio, 'FATEC Jacareí');
    expect(c.moradorPodeConvidar, isTrue);
    expect(c.visitanteMaxUsos, 2);
    expect(c.visitanteDiasMax, 7);
    expect(c.atualizadoEm, DateTime.utc(2026, 11, 25, 12).toLocal());
    expect(c.sistema!.fuso, 'America/Sao_Paulo');
    expect(c.sistema!.qrTrocaSegundos, 10);
    expect(c.sistema!.qrValidadeSegundos, 30);
    expect(c.sistema!.raioPadraoMetros, 100);
  });

  group('Configurações', () {
    testWidgets('Preenche o formulário e mostra o sistema só para ler', (
      tester,
    ) async {
      await _abrir(tester, _tela(_api()));
      expect(find.text('FATEC Jacareí'), findsOneWidget);
      expect(
        find.text('Portaria: (12) 3953-0000, das 7h às 22h'),
        findsOneWidget,
      );
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue,
      );
      expect(find.text('2'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      // A tela não é lista preguiçosa: o que está fora da tela também conta.
      expect(find.text('Raio padrão: 100 metros'), findsOneWidget);
      expect(find.text('Fuso horário: America/Sao_Paulo'), findsOneWidget);
      expect(find.text('Troca do QR Code: A cada 10 segundos'), findsOneWidget);
      expect(find.text('Validade do QR Code: 30 segundos'), findsOneWidget);
      expect(
        find.text('O terminal da catraca mostra um QR novo nesse intervalo.'),
        findsOneWidget,
      );
      // Os valores do sistema não são campos.
      expect(find.byType(TextField), findsNWidgets(4));
    });

    testWidgets('Salva com PATCH /settings e avisa', (tester) async {
      final chamadas = <http.Request>[];
      await _abrir(tester, _tela(_api(chamadas: chamadas)));
      await _digitar(tester, 'Nome do condomínio', '  Residencial Passe  ');
      await tester.ensureVisible(find.byType(SwitchListTile));
      await tester.tap(find.byType(SwitchListTile));
      await _digitar(tester, 'Usos por visita', '5');
      await _digitar(tester, 'Máximo de dias de uma visita', '30');
      await _salvar(tester);

      final edicao = chamadas.singleWhere((c) => c.method == 'PATCH');
      expect(edicao.url.path, '/settings');
      expect(jsonDecode(edicao.body), {
        'nomeCondominio': 'Residencial Passe',
        'contatoPortaria': 'Portaria: (12) 3953-0000, das 7h às 22h',
        'moradorPodeConvidar': false,
        'visitanteMaxUsos': 5,
        'visitanteDiasMax': 30,
      });
      expect(find.text('Configurações salvas.'), findsOneWidget);
      // Fica na tela, com o que a API devolveu.
      expect(find.text('Residencial Passe'), findsOneWidget);
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );
    });

    testWidgets('Fora das faixas da API não envia', (tester) async {
      final chamadas = <http.Request>[];
      await _abrir(tester, _tela(_api(chamadas: chamadas)));
      await _digitar(tester, 'Nome do condomínio', '   ');
      await _digitar(tester, 'Contato da portaria', 'x' * 201);
      await _digitar(tester, 'Usos por visita', '21');
      await _digitar(tester, 'Máximo de dias de uma visita', '0');
      await _salvar(tester);

      expect(find.text('Informe o nome do condomínio.'), findsOneWidget);
      expect(find.text('Use até 200 caracteres.'), findsOneWidget);
      expect(find.text('Use um número de 1 a 20.'), findsOneWidget);
      expect(find.text('Use um número de 1 a 30.'), findsOneWidget);
      expect(chamadas.where((c) => c.method == 'PATCH'), isEmpty);
    });

    testWidgets('Número que não é número não envia', (tester) async {
      final chamadas = <http.Request>[];
      await _abrir(tester, _tela(_api(chamadas: chamadas)));
      await _digitar(tester, 'Usos por visita', '2,5');
      await _salvar(tester);
      expect(find.text('Use um número de 1 a 20.'), findsOneWidget);
      expect(chamadas.where((c) => c.method == 'PATCH'), isEmpty);
    });

    testWidgets('Mostra o erro do campo vindo da API', (tester) async {
      final cliente = MockClient((request) async {
        if (request.method == 'GET') return respostaJson(_configuracoes, 200);
        return respostaJson({
          'erro': {
            'codigo': 'DADOS_INVALIDOS',
            'mensagem': 'Dados inválidos.',
            'detalhes': {
              'visitanteMaxUsos': ['Use até 20 usos'],
            },
          },
        }, 400);
      });
      await _abrir(tester, _tela(cliente));
      await _salvar(tester);
      expect(find.text('Use até 20 usos'), findsOneWidget);
    });

    testWidgets('Sem permissão no salvar vira aviso', (tester) async {
      final cliente = MockClient((request) async {
        if (request.method == 'GET') return respostaJson(_configuracoes, 200);
        return erroDaApi(403, 'SEM_PERMISSAO', 'Só o administrador muda.');
      });
      await _abrir(tester, _tela(cliente));
      await _salvar(tester);
      expect(find.text('Só o administrador muda.'), findsOneWidget);
    });

    testWidgets('Sem internet mostra o erro', (tester) async {
      await _abrir(tester, _tela(semInternet()));
      expect(find.text('Sem conexão com a internet'), findsOneWidget);
      expect(find.text('Salvar configurações'), findsNothing);
    });

    testWidgets('Com a sessão vencida volta ao login', (tester) async {
      await _abrir(tester, _tela(_api(falha: 401)));
      expect(find.byType(LoginView), findsOneWidget);
    });

    testWidgets('Cabe com a fonte no dobro', (tester) async {
      await _abrir(tester, _tela(_api()), fonte: 2);
      expect(tester.takeException(), isNull);
      expect(find.byType(CartaoErro), findsNothing);
    });

    testWidgets('Funciona no modo escuro', (tester) async {
      await _abrir(tester, _tela(_api()), tema: AppTheme.dark);
      expect(tester.takeException(), isNull);
      expect(find.byType(CartaoErro), findsNothing);
    });
  });

  group('Ajuda', () {
    testWidgets('Mostra o contato da portaria das Configurações', (
      tester,
    ) async {
      await _abrir(tester, AjudaView(controller: _controller(_api())));
      expect(
        find.text('Portaria: (12) 3953-0000, das 7h às 22h'),
        findsOneWidget,
      );
      expect(find.text('(12) 0000-0000'), findsNothing);
      expect(find.text('Dúvidas comuns'), findsOneWidget);
    });

    final falhas = <String, http.Client Function()>{
      'sem internet': semInternet,
      'com a sessão vencida': () => _api(falha: 401),
      'com erro na API': () => _api(falha: 500),
      'com a API sem a rota': () => _api(falha: 404),
    };
    for (final MapEntry(key: caso, value: cliente) in falhas.entries) {
      testWidgets('$caso mostra o contato de reserva', (tester) async {
        await _abrir(tester, AjudaView(controller: _controller(cliente())));
        expect(find.text('(12) 0000-0000'), findsOneWidget);
        expect(find.text('Todos os dias, das 06:00 às 22:00'), findsOneWidget);
        expect(find.byType(LoginView), findsNothing);
        expect(find.text('Dúvidas comuns'), findsOneWidget);
      });
    }

    testWidgets('Contato em branco usa o de reserva', (tester) async {
      final cliente = MockClient(
        (_) async =>
            respostaJson({..._configuracoes, 'contatoPortaria': '  '}, 200),
      );
      await _abrir(tester, AjudaView(controller: _controller(cliente)));
      expect(find.text('(12) 0000-0000'), findsOneWidget);
    });

    testWidgets('Enquanto busca, avisa e já mostra as dúvidas', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: AjudaView(controller: _controller(_api()))),
      );
      expect(find.text('Buscando o contato da portaria…'), findsOneWidget);
      expect(find.text('Dúvidas comuns'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Buscando o contato da portaria…'), findsNothing);
    });

    testWidgets('Com o contato da API, cabe com a fonte no dobro', (
      tester,
    ) async {
      await _abrir(
        tester,
        AjudaView(controller: _controller(_api())),
        fonte: 2,
        tema: AppTheme.dark,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
