import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:public/controllers/comunicados_controller.dart';
import 'package:public/controllers/minhas_autorizacoes_controller.dart';
import 'package:public/core/constants/formato.dart';
import 'package:public/core/theme/app_theme.dart';
import 'package:public/models/comunicado.dart';
import 'package:public/services/api_client.dart';
import 'package:public/services/sessao_service.dart';
import 'package:public/views/shared/comunicados_view.dart';
import 'package:public/views/user/inicio_view.dart';
import 'package:public/views/user/login_view.dart';
import 'package:public/views/widgets/cartao_erro.dart';

import '../../support/api_falsa.dart';

// Como o GET /announcements devolve (mais recentes primeiro).
const _manutencao = {
  'id': 'c1',
  'titulo': 'Manutenção da catraca 1',
  'mensagem': 'Amanhã, das 8h às 10h, use a entrada lateral.',
  'autorId': 'u-carlos',
  'createdAt': '2026-11-25T15:00:00.000Z',
  'autor': {'id': 'u-carlos', 'nome': 'Carlos Lima'},
};
// Conta de quem escreveu foi apagada: autor null.
const _boasVindas = {
  'id': 'c2',
  'titulo': 'Bem-vindos ao Passe',
  'mensagem': 'Agora a catraca abre com o QR Code do app.',
  'autorId': null,
  'createdAt': '2026-10-01T15:00:00.000Z',
  'autor': null,
};

/// Uma hora depois do comunicado mais recente, no fuso de quem roda o teste.
final _agora = DateTime.parse(_manutencao['createdAt'] as String)
    .toLocal()
    .add(const Duration(hours: 1));

String get _horaDoMaisRecente =>
    Formato.hora(DateTime.parse(_manutencao['createdAt'] as String).toLocal());

/// API com as rotas dos comunicados, guardando o que foi publicado e apagado.
/// [falha] responde todas as rotas de comunicados com esse status; enquanto
/// [offline] devolver true, nada chega na API.
MockClient _api({
  List<http.Request>? chamadas,
  List<Map<String, Object?>>? comunicados,
  int? falha,
  bool Function()? offline,
}) {
  final lista = <Map<String, Object?>>[
    ...(comunicados ?? [_manutencao, _boasVindas]),
  ];
  return MockClient((request) async {
    if (offline?.call() ?? false) throw http.ClientException('offline');
    chamadas?.add(request);
    final rota = '${request.method} ${request.url.path}';
    if (falha != null && request.url.path.startsWith('/announcements')) {
      return erroDaApi(falha, 'ERRO', 'Falhou ($falha).');
    }
    if (rota == 'GET /announcements') return respostaJson(lista, 200);
    if (rota == 'POST /announcements') {
      final corpo = jsonDecode(request.body) as Map<String, dynamic>;
      final novo = {
        'id': 'c-novo',
        ...corpo,
        'autorId': 'u-carlos',
        'createdAt': _agora.toUtc().toIso8601String(),
        'autor': {'id': 'u-carlos', 'nome': 'Carlos Lima'},
      };
      lista.insert(0, novo);
      return respostaJson(novo, 201);
    }
    if (request.method == 'DELETE' &&
        request.url.path.startsWith('/announcements/')) {
      final id = request.url.pathSegments.last;
      final antes = lista.length;
      lista.removeWhere((c) => c['id'] == id);
      return lista.length == antes
          ? erroDaApi(404, 'NAO_ENCONTRADO', 'Comunicado não encontrado.')
          : http.Response('', 204);
    }
    if (rota == 'GET /me/authorizations') {
      return respostaJson([autorizacaoJson()], 200);
    }
    return erroDaApi(404, 'ROTA_NAO_ENCONTRADA', '$rota não existe.');
  });
}

ComunicadosController _controller(http.Client cliente) => ComunicadosController(
  api: ApiClient(cliente: cliente),
  relogio: () => _agora,
);

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

Widget _comunicados(http.Client cliente, {bool admin = false}) =>
    ComunicadosView(podeGerenciar: admin, controller: _controller(cliente));

Widget _inicio(http.Client cliente) => InicioView(
  menu: const SizedBox(),
  controller: MinhasAutorizacoesController(api: ApiClient(cliente: cliente)),
  comunicados: _controller(cliente),
);

void main() {
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await SessaoService.instancia.encerrar();
  });

  group('Comunicado', () {
    Comunicado criadoEm(DateTime em) =>
        Comunicado(id: 'c', titulo: 't', mensagem: 'm', criadoEm: em);
    final agora = DateTime(2026, 11, 25, 15, 30);

    test('Mostra a data curta, relativa a agora', () {
      expect(
        criadoEm(DateTime(2026, 11, 25, 15, 30)).quando(agora),
        'Agora há pouco',
      );
      expect(
        criadoEm(DateTime(2026, 11, 25, 15, 5)).quando(agora),
        'Há 25 min',
      );
      expect(
        criadoEm(DateTime(2026, 11, 25, 9, 12)).quando(agora),
        'Hoje às 09:12',
      );
      expect(
        criadoEm(DateTime(2026, 11, 24, 18, 0)).quando(agora),
        'Ontem às 18:00',
      );
      expect(criadoEm(DateTime(2026, 10, 14, 8, 0)).quando(agora), '14/10');
      expect(
        criadoEm(DateTime(2025, 10, 14, 8, 0)).quando(agora),
        '14/10/2025',
      );
      // Relógio do celular atrasado: não mostra "Há -3 min".
      expect(
        criadoEm(DateTime(2026, 11, 25, 15, 33)).quando(agora),
        'Agora há pouco',
      );
    });

    test('Lê o autor e aceita autor null', () {
      expect(Comunicado.fromJson(_manutencao).autor, 'Carlos Lima');
      expect(Comunicado.fromJson(_boasVindas).autor, isNull);
    });
  });

  group('Comunicados', () {
    testWidgets('Lista título, mensagem, autor e data', (tester) async {
      await _abrir(tester, _comunicados(_api()));
      expect(find.text('Manutenção da catraca 1'), findsOneWidget);
      expect(
        find.text('Amanhã, das 8h às 10h, use a entrada lateral.'),
        findsOneWidget,
      );
      expect(
        find.text('Carlos Lima · Hoje às $_horaDoMaisRecente'),
        findsOneWidget,
      );
      expect(find.text('Administração · 01/10'), findsOneWidget);
    });

    testWidgets('Só leitura: sem publicar nem apagar', (tester) async {
      await _abrir(tester, _comunicados(_api()));
      expect(find.text('Novo comunicado'), findsNothing);
      expect(find.text('Apagar'), findsNothing);
    });

    testWidgets('Vazio explica o que aparece ali', (tester) async {
      await _abrir(tester, _comunicados(_api(comunicados: [])));
      expect(find.text('Nenhum comunicado'), findsOneWidget);
      expect(
        find.text(
          'Quando a administração publicar um aviso, ele aparece aqui.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Sem internet mostra o erro', (tester) async {
      await _abrir(tester, _comunicados(semInternet()));
      expect(find.text('Sem conexão com a internet'), findsOneWidget);
    });

    testWidgets('Erro da API mostra a mensagem e tenta de novo', (
      tester,
    ) async {
      await _abrir(tester, _comunicados(_api(falha: 500)));
      expect(find.text('Não foi possível carregar'), findsOneWidget);
      expect(find.text('Falhou (500).'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
    });

    testWidgets('Com a sessão vencida volta ao login', (tester) async {
      await _abrir(tester, _comunicados(_api(falha: 401)));
      expect(find.byType(LoginView), findsOneWidget);
    });

    for (final admin in [false, true]) {
      final quem = admin ? 'do admin' : 'só leitura';
      testWidgets('Tela $quem cabe com a fonte no dobro', (tester) async {
        await _abrir(tester, _comunicados(_api(), admin: admin), fonte: 2);
        expect(tester.takeException(), isNull);
        expect(find.byType(CartaoErro), findsNothing);
      });

      testWidgets('Tela $quem funciona no modo escuro', (tester) async {
        await _abrir(
          tester,
          _comunicados(_api(), admin: admin),
          tema: AppTheme.dark,
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(CartaoErro), findsNothing);
      });
    }
  });

  group('Comunicados do admin', () {
    Future<void> abrirFormulario(WidgetTester tester, http.Client api) async {
      await _abrir(tester, _comunicados(api, admin: true));
      await tester.tap(find.text('Novo comunicado'));
      await tester.pumpAndSettle();
      expect(find.text('Publicar comunicado'), findsOneWidget);
    }

    testWidgets('Vazio convida a publicar', (tester) async {
      await _abrir(tester, _comunicados(_api(comunicados: []), admin: true));
      expect(
        find.text('Toque em "Novo comunicado" para avisar quem usa o prédio.'),
        findsOneWidget,
      );
      expect(find.text('Novo comunicado'), findsOneWidget);
    });

    testWidgets('Sem título e mensagem não envia', (tester) async {
      final chamadas = <http.Request>[];
      await abrirFormulario(tester, _api(chamadas: chamadas));
      // Só espaços conta como vazio, como na API.
      await tester.enterText(find.byType(TextFormField).at(0), '   ');
      await tester.tap(find.text('Publicar comunicado'));
      await tester.pumpAndSettle();

      expect(find.text('Informe o título.'), findsOneWidget);
      expect(find.text('Escreva a mensagem.'), findsOneWidget);
      expect(chamadas.where((c) => c.method == 'POST'), isEmpty);
    });

    testWidgets('Os campos param no limite da API', (tester) async {
      await abrirFormulario(tester, _api());
      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'x' * 130);
      await tester.enterText(campos.at(1), 'y' * 2100);
      await tester.pump();
      final titulo = tester.widget<TextField>(
        find.descendant(of: campos.at(0), matching: find.byType(TextField)),
      );
      final mensagem = tester.widget<TextField>(
        find.descendant(of: campos.at(1), matching: find.byType(TextField)),
      );
      expect(titulo.controller!.text, hasLength(120));
      expect(mensagem.controller!.text, hasLength(2000));
    });

    testWidgets('Publica sem os espaços das pontas e volta à lista', (
      tester,
    ) async {
      final chamadas = <http.Request>[];
      await abrirFormulario(tester, _api(chamadas: chamadas));
      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), '  Água desligada  ');
      await tester.enterText(campos.at(1), ' Hoje, das 14h às 16h. ');
      await tester.tap(find.text('Publicar comunicado'));
      await tester.pumpAndSettle();

      final publicacao = chamadas.singleWhere((c) => c.method == 'POST');
      expect(publicacao.url.path, '/announcements');
      expect(jsonDecode(publicacao.body), {
        'titulo': 'Água desligada',
        'mensagem': 'Hoje, das 14h às 16h.',
      });
      expect(find.text('Comunicado publicado.'), findsOneWidget);
      // De volta à lista, já com o novo.
      expect(find.text('Publicar comunicado'), findsNothing);
      expect(find.text('Água desligada'), findsOneWidget);
    });

    testWidgets('Mostra o erro do campo vindo da API', (tester) async {
      final cliente = MockClient((request) async {
        if (request.method == 'GET') return respostaJson([_manutencao], 200);
        return respostaJson({
          'erro': {
            'codigo': 'DADOS_INVALIDOS',
            'mensagem': 'Dados inválidos.',
            'detalhes': {
              'titulo': ['Use até 120 caracteres'],
            },
          },
        }, 400);
      });
      await abrirFormulario(tester, cliente);
      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'Aviso');
      await tester.enterText(campos.at(1), 'Mensagem');
      await tester.tap(find.text('Publicar comunicado'));
      await tester.pumpAndSettle();

      expect(find.text('Use até 120 caracteres'), findsOneWidget);
      expect(find.text('Publicar comunicado'), findsOneWidget);
    });

    testWidgets('Apagar pede confirmação e chama a API', (tester) async {
      final chamadas = <http.Request>[];
      await _abrir(tester, _comunicados(_api(chamadas: chamadas), admin: true));
      expect(find.text('Apagar'), findsNWidgets(2));

      await tester.tap(find.text('Apagar').first);
      await tester.pumpAndSettle();
      expect(find.text('Apagar este comunicado?'), findsOneWidget);
      await tester.tap(find.text('Não, manter'));
      await tester.pumpAndSettle();
      expect(chamadas.where((c) => c.method == 'DELETE'), isEmpty);
      expect(find.text('Manutenção da catraca 1'), findsOneWidget);

      await tester.tap(find.text('Apagar').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sim, apagar'));
      await tester.pumpAndSettle();
      final apagar = chamadas.singleWhere((c) => c.method == 'DELETE');
      expect(apagar.url.path, '/announcements/c1');
      expect(find.text('Manutenção da catraca 1'), findsNothing);
      expect(find.text('Bem-vindos ao Passe'), findsOneWidget);
      expect(find.text('Comunicado apagado.'), findsOneWidget);
    });

    testWidgets('Apagar sem internet avisa e mantém na lista', (tester) async {
      var online = true;
      final cliente = _api(offline: () => !online);
      await _abrir(tester, _comunicados(cliente, admin: true));
      online = false;
      await tester.tap(find.text('Apagar').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sim, apagar'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Não foi possível falar com o servidor'),
        findsOneWidget,
      );
      expect(find.text('Manutenção da catraca 1'), findsOneWidget);
    });

    testWidgets('Formulário cabe com a fonte no dobro', (tester) async {
      await _abrir(tester, _comunicados(_api(), admin: true), fonte: 2);
      await tester.tap(find.text('Novo comunicado'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Publicar comunicado'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Início', () {
    testWidgets('Mostra o comunicado mais recente e abre a lista só leitura', (
      tester,
    ) async {
      await _abrir(tester, _inicio(_api()));
      expect(
        find.text('Comunicado · Hoje às $_horaDoMaisRecente'),
        findsOneWidget,
      );
      expect(find.text('Manutenção da catraca 1'), findsOneWidget);
      expect(find.text('Bem-vindos ao Passe'), findsNothing);
      // O resto do Início continua igual.
      expect(find.text('Sua próxima autorização'), findsOneWidget);
      expect(find.text('Escanear QR Code'), findsOneWidget);

      await tester.ensureVisible(find.text('Manutenção da catraca 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Manutenção da catraca 1'));
      await tester.pumpAndSettle();
      expect(find.byType(ComunicadosView), findsOneWidget);
      expect(find.text('Bem-vindos ao Passe'), findsOneWidget);
      expect(find.text('Novo comunicado'), findsNothing);
      expect(find.text('Apagar'), findsNothing);
    });

    testWidgets('Sem comunicados, fica sem o cartão', (tester) async {
      await _abrir(tester, _inicio(_api(comunicados: [])));
      expect(find.textContaining('Comunicado ·'), findsNothing);
      expect(find.text('Sua próxima autorização'), findsOneWidget);
    });

    for (final falha in [404, 500, 401]) {
      testWidgets('Comunicados com erro $falha: Início como antes', (
        tester,
      ) async {
        await _abrir(tester, _inicio(_api(falha: falha)));
        expect(find.textContaining('Comunicado ·'), findsNothing);
        expect(find.byType(CartaoErro), findsNothing);
        expect(find.byType(LoginView), findsNothing);
        expect(find.text('Sua próxima autorização'), findsOneWidget);
      });
    }

    testWidgets('Sem internet mostra só o erro das autorizações', (
      tester,
    ) async {
      await _abrir(tester, _inicio(semInternet()));
      expect(find.text('Sem conexão com a internet'), findsOneWidget);
      expect(find.textContaining('Comunicado ·'), findsNothing);
    });

    testWidgets('Com o cartão, cabe com a fonte no dobro e no escuro', (
      tester,
    ) async {
      await _abrir(tester, _inicio(_api()), fonte: 2, tema: AppTheme.dark);
      expect(tester.takeException(), isNull);
      expect(find.text('Manutenção da catraca 1'), findsOneWidget);
    });
  });
}
