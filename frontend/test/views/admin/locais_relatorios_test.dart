import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:public/controllers/locais_controller.dart';
import 'package:public/controllers/relatorios_controller.dart';
import 'package:public/core/theme/app_theme.dart';
import 'package:public/models/relatorio_acessos.dart';
import 'package:public/services/api_client.dart';
import 'package:public/services/sessao_service.dart';
import 'package:public/views/teams/locais_view.dart';
import 'package:public/views/teams/relatorios_view.dart';
import 'package:public/views/user/login_view.dart';
import 'package:public/views/widgets/cartao_erro.dart';

import '../../support/api_falsa.dart';

const _idCatraca1 = '00000000-0000-4000-8000-000000000004';
const _idCatraca2 = '00000000-0000-4000-8000-000000000005';

Map<String, Object?> _catraca(String id, String nome) => {
  'id': id,
  'nome': nome,
  'doorId': 'd1',
  'latitude': -23.3053,
  'longitude': -45.9658,
  'raioMetros': 100,
};

final _arvore = [
  {
    'id': 'b1',
    'nome': 'FATEC Jacareí',
    'endereco': 'Av. Faria Lima, 155',
    'portarias': [
      {
        'id': 'g1',
        'nome': 'Portaria Principal',
        'buildingId': 'b1',
        'portas': [
          {
            'id': 'd1',
            'nome': 'Porta A',
            'gateId': 'g1',
            'catracas': [
              _catraca(_idCatraca1, 'Catraca 1'),
              _catraca(_idCatraca2, 'Catraca 2'),
            ],
          },
        ],
      },
    ],
  },
];

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

// ---------------------------------------------------------------- Locais

/// A árvore e as rotas de editar e apagar do contrato. [recusas] escolhe as
/// rotas ("DELETE /locations/doors/d1") que respondem 409 com a mensagem.
MockClient _apiLocais(
  List<http.Request> chamadas, {
  Map<String, String> recusas = const {},
}) => MockClient((request) async {
  chamadas.add(request);
  final rota = '${request.method} ${request.url.path}';
  if (recusas[rota] case final mensagem?) {
    return erroDaApi(409, 'CONFLITO', mensagem);
  }
  return switch (request.method) {
    'GET' when request.url.path == '/locations' => respostaJson(_arvore, 200),
    'PATCH' => respostaJson({
      'id': request.url.pathSegments.last,
      ...jsonDecode(request.body) as Map<String, dynamic>,
    }, 200),
    'DELETE' => http.Response('', 204),
    _ => erroDaApi(404, 'NAO_ENCONTRADO', '$rota não existe.'),
  };
});

Future<void> _abrirLocais(
  WidgetTester tester,
  http.Client cliente, {
  String email = 'admin@passe.com',
  double fonte = 1,
}) async {
  final auth = authFalso();
  await auth.entrar(email, senhaDemo);
  await _abrir(
    tester,
    LocaisView(
      controller: LocaisController(
        api: ApiClient(cliente: cliente),
        auth: auth,
      ),
    ),
    fonte: fonte,
  );
}

Future<void> _escolher(WidgetTester tester, String nome, String acao) async {
  await tester.ensureVisible(find.byTooltip('Opções de $nome'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Opções de $nome'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(acao).last);
  await tester.pumpAndSettle();
}

int _buscasDaArvore(List<http.Request> chamadas) => chamadas
    .where((c) => c.method == 'GET' && c.url.path == '/locations')
    .length;

http.Request _unica(List<http.Request> chamadas, String metodo) =>
    chamadas.singleWhere((c) => c.method == metodo);

// ------------------------------------------------------------ Relatórios

/// 25/11/2026 (quarta), à tarde.
DateTime _agora() => DateTime(2026, 11, 25, 15, 30);

Map<String, Object?> _relatorio({
  String de = '2026-11-19',
  String ate = '2026-11-25',
  bool vazio = false,
}) {
  if (vazio) {
    return {
      'de': de,
      'ate': ate,
      'total': 0,
      'liberados': 0,
      'negados': 0,
      'porDia': [
        for (var i = 0; i < 7; i++)
          {'dia': '2026-11-${19 + i}', 'liberados': 0, 'negados': 0},
      ],
      'porMetodo': [
        for (final m in ['QR', 'NFC', 'CELULAR'])
          {'metodo': m, 'liberados': 0, 'negados': 0},
      ],
      'porCatraca': <Object>[],
      'porMotivo': <Object>[],
    };
  }
  return {
    'de': de,
    'ate': ate,
    'total': 42,
    'liberados': 30,
    'negados': 12,
    'porDia': [
      {'dia': '2026-11-19', 'liberados': 3, 'negados': 1},
      {'dia': '2026-11-20', 'liberados': 0, 'negados': 0},
      {'dia': '2026-11-21', 'liberados': 7, 'negados': 2},
      {'dia': '2026-11-22', 'liberados': 0, 'negados': 3},
      {'dia': '2026-11-23', 'liberados': 9, 'negados': 1},
      {'dia': '2026-11-24', 'liberados': 6, 'negados': 4},
      {'dia': '2026-11-25', 'liberados': 5, 'negados': 1},
    ],
    'porMetodo': [
      {'metodo': 'QR', 'liberados': 20, 'negados': 8},
      {'metodo': 'NFC', 'liberados': 9, 'negados': 2},
      {'metodo': 'CELULAR', 'liberados': 1, 'negados': 2},
    ],
    'porCatraca': [
      {
        'catraca': {'id': _idCatraca1, 'nome': 'Catraca 1'},
        'liberados': 25,
        'negados': 6,
      },
      {
        'catraca': {'id': _idCatraca2, 'nome': 'Catraca 2'},
        'liberados': 5,
        'negados': 2,
      },
      {'catraca': null, 'liberados': 0, 'negados': 4},
    ],
    'porMotivo': [
      {
        'motivo': 'FORA_DO_HORARIO',
        'titulo': 'Fora do horário permitido',
        'total': 5,
      },
      {
        'motivo': 'SEM_AUTORIZACAO',
        'titulo': 'Você não tem autorização para esta catraca',
        'total': 4,
      },
      {
        'motivo': 'QR_INVALIDO',
        'titulo': 'QR Code não reconhecido',
        'total': 3,
      },
    ],
  };
}

/// GET /reports/access responde [relatorio] (ou o erro [status]) e
/// GET /locations a árvore (ou 500 com [semLocais]).
MockClient _apiRelatorios(
  List<http.Request> chamadas, {
  Map<String, Object?> Function()? relatorio,
  int? Function()? status,
  bool semLocais = false,
}) => MockClient((request) async {
  chamadas.add(request);
  if (request.url.path == '/locations') {
    return semLocais
        ? erroDaApi(500, 'ERRO_INTERNO', 'Erro inesperado.')
        : respostaJson(_arvore, 200);
  }
  if (request.url.path == '/reports/access') {
    final erro = status?.call();
    if (erro != null) {
      return erroDaApi(erro, 'ERRO_INTERNO', 'O relatório falhou agora.');
    }
    return respostaJson((relatorio ?? _relatorio)(), 200);
  }
  return erroDaApi(404, 'NAO_ENCONTRADO', '${request.url.path} não existe.');
});

Widget _relatorios(http.Client cliente) => RelatoriosView(
  controller: RelatoriosController(
    api: ApiClient(cliente: cliente),
    relogio: _agora,
  ),
);

Map<String, String> _ultimaBusca(List<http.Request> chamadas) => chamadas
    .lastWhere((c) => c.url.path == '/reports/access')
    .url
    .queryParameters;

void main() {
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await SessaoService.instancia.encerrar();
  });

  group('Locais', () {
    testWidgets('Admin vê criar, editar e apagar em cada nível', (
      tester,
    ) async {
      await _abrirLocais(tester, _apiLocais([]));
      expect(find.text('Novo edifício'), findsOneWidget);
      for (final nome in [
        'FATEC Jacareí',
        'Portaria Principal',
        'Porta A',
        'Catraca 1',
        'Catraca 2',
      ]) {
        expect(find.byTooltip('Opções de $nome'), findsOneWidget);
      }
    });

    testWidgets('Portaria vê a árvore sem as ações', (tester) async {
      await _abrirLocais(tester, _apiLocais([]), email: 'portaria@passe.com');
      expect(find.text('Catraca 1'), findsOneWidget);
      expect(find.text('Novo edifício'), findsNothing);
      expect(find.byIcon(Icons.more_vert), findsNothing);
      expect(find.byIcon(Icons.add_circle_outline), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('Admin com a fonte no dobro: cabe, também o menu', (
      tester,
    ) async {
      await _abrirLocais(tester, _apiLocais([]), fonte: 2);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byTooltip('Opções de Catraca 2'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Opções de Catraca 2'));
      await tester.pumpAndSettle();
      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Apagar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Editar o edifício manda nome e endereço e recarrega', (
      tester,
    ) async {
      final chamadas = <http.Request>[];
      await _abrirLocais(tester, _apiLocais(chamadas));
      await _escolher(tester, 'FATEC Jacareí', 'Editar');

      expect(find.text('Editar edifício'), findsOneWidget);
      final campos = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextFormField),
      );
      // Já vem com os valores atuais.
      expect(
        tester.widget<TextFormField>(campos.at(1)).controller!.text,
        'Av. Faria Lima, 155',
      );
      await tester.enterText(campos.at(0), '  FATEC Jacareí Centro ');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      final patch = _unica(chamadas, 'PATCH');
      expect(patch.url.path, '/locations/buildings/b1');
      expect(jsonDecode(patch.body), {
        'nome': 'FATEC Jacareí Centro',
        'endereco': 'Av. Faria Lima, 155',
      });
      expect(_buscasDaArvore(chamadas), 2);
    });

    testWidgets('Editar com o nome vazio não envia', (tester) async {
      final chamadas = <http.Request>[];
      await _abrirLocais(tester, _apiLocais(chamadas));
      await _escolher(tester, 'Porta A', 'Editar');
      await tester.enterText(find.byType(TextFormField).first, '   ');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Campo obrigatório.'), findsOneWidget);
      expect(chamadas.where((c) => c.method == 'PATCH'), isEmpty);
    });

    for (final (nome, rota, novo) in [
      ('Portaria Principal', '/locations/gates/g1', 'Portaria Norte'),
      ('Porta A', '/locations/doors/d1', 'Porta B'),
    ]) {
      testWidgets('Editar $nome manda só o nome', (tester) async {
        final chamadas = <http.Request>[];
        await _abrirLocais(tester, _apiLocais(chamadas));
        await _escolher(tester, nome, 'Editar');
        await tester.enterText(find.byType(TextFormField).first, novo);
        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();

        final patch = _unica(chamadas, 'PATCH');
        expect(patch.url.path, rota);
        expect(jsonDecode(patch.body), {'nome': novo});
        expect(_buscasDaArvore(chamadas), 2);
      });
    }

    testWidgets('Editar a catraca abre o formulário dela', (tester) async {
      await _abrirLocais(tester, _apiLocais([]));
      await _escolher(tester, 'Catraca 1', 'Editar');
      expect(find.text('Editar catraca'), findsOneWidget);
    });

    testWidgets('Apagar pede confirmação; "Não apagar" não chama a API', (
      tester,
    ) async {
      final chamadas = <http.Request>[];
      await _abrirLocais(tester, _apiLocais(chamadas));
      await _escolher(tester, 'Porta A', 'Apagar');

      expect(find.text('Apagar porta?'), findsOneWidget);
      await tester.tap(find.text('Não apagar'));
      await tester.pumpAndSettle();

      expect(chamadas.where((c) => c.method == 'DELETE'), isEmpty);
      expect(find.text('Porta A'), findsOneWidget);
    });

    for (final (nome, rota, aviso) in [
      ('FATEC Jacareí', '/locations/buildings/b1', 'Edifício apagado.'),
      ('Portaria Principal', '/locations/gates/g1', 'Portaria apagada.'),
      ('Porta A', '/locations/doors/d1', 'Porta apagada.'),
      (
        'Catraca 2',
        '/locations/access-points/$_idCatraca2',
        'Catraca apagada.',
      ),
    ]) {
      testWidgets('Apagar $nome chama $rota, avisa e recarrega', (
        tester,
      ) async {
        final chamadas = <http.Request>[];
        await _abrirLocais(tester, _apiLocais(chamadas));
        await _escolher(tester, nome, 'Apagar');
        await tester.tap(find.text('Apagar'));
        await tester.pumpAndSettle();

        expect(_unica(chamadas, 'DELETE').url.path, rota);
        expect(find.text(aviso), findsOneWidget);
        expect(_buscasDaArvore(chamadas), 2);
      });
    }

    for (final (nome, rota, mensagem) in [
      (
        'Porta A',
        'DELETE /locations/doors/d1',
        'Esta porta ainda tem catracas. Apague-as antes.',
      ),
      (
        'Catraca 1',
        'DELETE /locations/access-points/$_idCatraca1',
        'Esta catraca tem um terminal. Remova o terminal antes.',
      ),
    ]) {
      testWidgets('409 ao apagar $nome mostra a mensagem da API', (
        tester,
      ) async {
        final chamadas = <http.Request>[];
        await _abrirLocais(
          tester,
          _apiLocais(chamadas, recusas: {rota: mensagem}),
        );
        await _escolher(tester, nome, 'Apagar');
        await tester.tap(find.text('Apagar'));
        await tester.pumpAndSettle();

        expect(find.text('Ainda não dá para apagar'), findsOneWidget);
        expect(find.text(mensagem), findsOneWidget);
        await tester.tap(find.text('Entendi'));
        await tester.pumpAndSettle();

        expect(find.text(mensagem), findsNothing);
        expect(find.text(nome), findsOneWidget);
        expect(_buscasDaArvore(chamadas), 2);
      });
    }

    testWidgets('Sessão vencida ao apagar volta ao login', (tester) async {
      final cliente = MockClient((request) async {
        if (request.method == 'GET') return respostaJson(_arvore, 200);
        return erroDaApi(401, 'NAO_AUTENTICADO', 'Sessão inválida.');
      });
      await _abrirLocais(tester, cliente);
      await _escolher(tester, 'Catraca 2', 'Apagar');
      await tester.tap(find.text('Apagar'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginView), findsOneWidget);
    });
  });

  group('Relatórios', () {
    testWidgets('Abre com 7 dias e todas as catracas, com os totais', (
      tester,
    ) async {
      final chamadas = <http.Request>[];
      await _abrir(tester, _relatorios(_apiRelatorios(chamadas)));

      expect(_ultimaBusca(chamadas), {'de': '2026-11-19', 'ate': '2026-11-25'});
      expect(find.text('Período: 19/11 a 25/11/2026'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('71%'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      // Gráfico por dia: o primeiro e o último dia embaixo.
      expect(find.text('19/11'), findsOneWidget);
      expect(find.text('25/11'), findsOneWidget);
      // Por método.
      expect(find.text('QR Code'), findsOneWidget);
      expect(find.text('20 liberados · 8 negados'), findsOneWidget);
      expect(find.text('Tag NFC'), findsOneWidget);
      expect(find.text('Celular'), findsOneWidget);
      expect(find.text('1 liberado · 2 negados'), findsOneWidget);
      // Por catraca.
      expect(find.text('Catraca 1'), findsOneWidget);
      expect(find.text('Catraca 2'), findsOneWidget);
      expect(find.text('Sem catraca identificada'), findsOneWidget);
      expect(find.text('0 liberados · 4 negados'), findsOneWidget);
      // Motivos, com o título que a API manda.
      expect(find.text('Fora do horário permitido'), findsOneWidget);
      expect(
        find.text('Você não tem autorização para esta catraca'),
        findsOneWidget,
      );
      expect(find.text('QR Code não reconhecido'), findsOneWidget);
    });

    testWidgets('Hoje e 30 dias mudam as datas da busca', (tester) async {
      final chamadas = <http.Request>[];
      await _abrir(tester, _relatorios(_apiRelatorios(chamadas)));

      await tester.tap(find.text('Hoje'));
      await tester.pumpAndSettle();
      expect(_ultimaBusca(chamadas), {'de': '2026-11-25', 'ate': '2026-11-25'});

      await tester.tap(find.text('30 dias'));
      await tester.pumpAndSettle();
      expect(_ultimaBusca(chamadas), {'de': '2026-10-27', 'ate': '2026-11-25'});
    });

    testWidgets('Escolher a catraca manda o accessPointId; Todas tira', (
      tester,
    ) async {
      final chamadas = <http.Request>[];
      await _abrir(tester, _relatorios(_apiRelatorios(chamadas)));
      expect(find.text('Por catraca'), findsOneWidget);

      await tester.tap(find.text('Todas as catracas'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text('Catraca 2 · Portaria Principal › Porta A').last,
      );
      await tester.pumpAndSettle();
      expect(_ultimaBusca(chamadas)['accessPointId'], _idCatraca2);
      // Com uma catraca só, a divisão por catraca some.
      expect(find.text('Por catraca'), findsNothing);

      await tester.tap(
        find.text('Catraca 2 · Portaria Principal › Porta A').last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Todas as catracas').last);
      await tester.pumpAndSettle();
      expect(_ultimaBusca(chamadas).containsKey('accessPointId'), isFalse);
      expect(find.text('Por catraca'), findsOneWidget);
    });

    testWidgets('Sem acessos no período mostra o estado vazio', (tester) async {
      await _abrir(
        tester,
        _relatorios(
          _apiRelatorios([], relatorio: () => _relatorio(vazio: true)),
        ),
      );
      expect(find.text('Nenhum acesso no período'), findsOneWidget);
      expect(find.text('Por método'), findsNothing);
    });

    testWidgets('Erro da API mostra a mensagem e o Tentar novamente', (
      tester,
    ) async {
      int? status = 500;
      await _abrir(
        tester,
        _relatorios(_apiRelatorios([], status: () => status)),
      );
      expect(find.byType(CartaoErro), findsOneWidget);
      expect(find.text('O relatório falhou agora.'), findsOneWidget);

      status = null;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(find.byType(CartaoErro), findsNothing);
      expect(find.text('71%'), findsOneWidget);
    });

    testWidgets('Sem internet mostra o aviso de conexão', (tester) async {
      await _abrir(tester, _relatorios(semInternet()));
      expect(find.text('Sem conexão com a internet'), findsOneWidget);
    });

    testWidgets('Sem a lista de catracas, o filtro some e o resto aparece', (
      tester,
    ) async {
      await _abrir(tester, _relatorios(_apiRelatorios([], semLocais: true)));
      expect(find.text('Todas as catracas'), findsNothing);
      expect(find.text('71%'), findsOneWidget);
    });

    testWidgets('30 dias cabem com a fonte no dobro e no modo escuro', (
      tester,
    ) async {
      Map<String, Object?> trintaDias() => {
        ..._relatorio(de: '2026-10-27'),
        'porDia': [
          for (var i = 0; i < 30; i++)
            {
              'dia': DateTime(
                2026,
                10,
                27 + i,
              ).toIso8601String().substring(0, 10),
              'liberados': i * 7 % 11,
              'negados': i % 4,
            },
        ],
      };
      await _abrir(
        tester,
        _relatorios(_apiRelatorios([], relatorio: trintaDias)),
        fonte: 2,
        tema: AppTheme.dark,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('27/10'), findsOneWidget);
      expect(find.text('25/11'), findsOneWidget);
    });
  });

  group('RelatorioAcessos.fromJson', () {
    test('Taxa de liberação arredondada e zero sem acessos', () {
      final cheio = RelatorioAcessos.fromJson(_relatorio());
      expect(cheio.taxaLiberacao, 71);
      expect(cheio.porDia, hasLength(7));
      expect(cheio.porMetodo.map((m) => m.texto), [
        'QR Code',
        'Tag NFC',
        'Celular',
      ]);
      final vazio = RelatorioAcessos.fromJson(_relatorio(vazio: true));
      expect(vazio.vazio, isTrue);
      expect(vazio.taxaLiberacao, 0);
    });

    test('Aguenta campos faltando sem quebrar a tela', () {
      final r = RelatorioAcessos.fromJson({
        'liberados': 2,
        'negados': 1,
        'porDia': [
          {'dia': 'ontem', 'liberados': 1},
          {'dia': '2026-11-25', 'liberados': 1, 'negados': 1},
        ],
        'porCatraca': [
          {'catraca': null, 'liberados': 2, 'negados': 1},
        ],
        'porMotivo': [
          {'motivo': 'SEM_USOS', 'total': 1},
        ],
      });
      expect(r.de, isNull);
      expect(r.total, 3);
      expect(r.porDia.single.dia, DateTime(2026, 11, 25));
      expect(r.porMetodo, isEmpty);
      expect(r.porCatraca.single.nome, 'Sem catraca identificada');
      expect(r.porMotivo.single.titulo, 'SEM_USOS');
    });
  });
}
