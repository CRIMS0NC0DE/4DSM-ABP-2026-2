import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:public/controllers/autorizacoes_controller.dart';
import 'package:public/controllers/historico_controller.dart';
import 'package:public/controllers/locais_controller.dart';
import 'package:public/controllers/minhas_autorizacoes_controller.dart';
import 'package:public/controllers/painel_controller.dart';
import 'package:public/controllers/perfil_controller.dart';
import 'package:public/controllers/terminais_controller.dart';
import 'package:public/controllers/usuarios_controller.dart';
import 'package:public/models/autorizacao.dart';
import 'package:public/core/theme/app_theme.dart';
import 'package:public/services/api_client.dart';
import 'package:public/services/sessao_service.dart';
import 'package:public/views/compartilhado/historico_view.dart';
import 'package:public/views/equipe/autorizacao_form_view.dart';
import 'package:public/views/equipe/autorizacoes_view.dart';
import 'package:public/views/equipe/locais_view.dart';
import 'package:public/views/equipe/painel_view.dart';
import 'package:public/views/equipe/relatorios_view.dart';
import 'package:public/views/equipe/tags_view.dart';
import 'package:public/views/equipe/terminais_view.dart';
import 'package:public/views/equipe/usuario_form_view.dart';
import 'package:public/views/equipe/usuarios_view.dart';
import 'package:public/views/equipe/visitantes_view.dart';
import 'package:public/views/user/ajuda_view.dart';
import 'package:public/views/user/inicio_view.dart';
import 'package:public/views/user/login_view.dart';
import 'package:public/views/user/minha_tag_view.dart';
import 'package:public/views/user/perfil_view.dart';

import '../../support/api_falsa.dart';

// Respostas copiadas da API real (GET de cada rota com o seed).
const _tag = {
  'id': 'tag-1',
  'uid': '04A1B2C3',
  'userId': 'u-maria',
  'ativa': true,
  'createdAt': '2026-11-02T03:07:33.882Z',
};
const _maria = {
  'id': 'u-maria',
  'nome': 'Maria Souza',
  'email': 'morador@passe.com',
  'cpf': '33333333333',
  'perfil': 'CONDOMINO',
  'ativo': true,
  'tags': [_tag],
};
const _carlos = {
  'id': 'u-carlos',
  'nome': 'Carlos Lima',
  'email': 'admin@passe.com',
  'cpf': '11111111111',
  'perfil': 'ADMIN',
  'ativo': true,
  'tags': <Object>[],
};
const _ana = {
  'id': 'u-ana',
  'nome': 'Ana Lima',
  'email': 'visitante@passe.com',
  'cpf': '44444444444',
  'perfil': 'VISITANTE',
  'ativo': true,
  'tags': <Object>[],
};
const _arvore = [
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
              {
                'id': '00000000-0000-4000-8000-000000000004',
                'nome': 'Catraca 1',
                'doorId': 'd1',
                'latitude': -23.3053,
                'longitude': -45.9658,
                'raioMetros': 100,
              },
            ],
          },
        ],
      },
    ],
  },
];
const _terminal = {
  'id': 't1',
  'nome': 'Terminal Catraca 1',
  'accessPointId': '00000000-0000-4000-8000-000000000004',
  'ultimoSinal': '2026-11-02T03:08:24.085Z',
  'latitude': null,
  'longitude': null,
  'online': true,
};
const _eventoNegado = {
  'id': 'e1',
  'metodo': 'QR',
  'resultado': 'NEGADO',
  'motivo': 'FORA_DO_HORARIO',
  'credencial': 'CQFWRZQNUDLEXEYV',
  'distanciaMetros': null,
  'createdAt': '2026-11-02T03:08:24.107Z',
  'user': {'id': 'u-maria', 'nome': 'Maria Souza'},
  'catraca': {'id': 'c1', 'nome': 'Catraca 1'},
};
// Tag desconhecida: o evento vem sem pessoa.
const _eventoSemPessoa = {
  'id': 'e2',
  'metodo': 'NFC',
  'resultado': 'NEGADO',
  'motivo': 'TAG_DESCONHECIDA',
  'credencial': 'DEADBEEF',
  'distanciaMetros': null,
  'createdAt': '2026-11-02T03:08:24.114Z',
  'user': null,
  'catraca': {'id': 'c1', 'nome': 'Catraca 1'},
};
const _eventoLiberado = {
  'id': 'e3',
  'metodo': 'QR',
  'resultado': 'LIBERADO',
  'motivo': null,
  'credencial': 'ABC',
  'distanciaMetros': 12.4,
  'createdAt': '2026-11-02T12:08:24.114Z',
  'user': {'id': 'u-maria', 'nome': 'Maria Souza'},
  'catraca': {'id': 'c1', 'nome': 'Catraca 1'},
};

/// API com as rotas das telas novas. Guarda cada requisição em [chamadas].
MockClient _api({List<http.Request>? chamadas, int? statusFixo}) {
  return MockClient((request) async {
    chamadas?.add(request);
    if (statusFixo != null) {
      return erroDaApi(statusFixo, 'NAO_AUTENTICADO', 'Sessão inválida.');
    }
    final rota = '${request.method} ${request.url.path}';
    final eventos = {
      'itens': [_eventoLiberado, _eventoNegado, _eventoSemPessoa],
      'total': 3,
      'liberados': 1,
      'negados': 2,
    };
    return switch (rota) {
      'GET /users' => respostaJson(
        request.url.queryParameters['perfil'] == 'VISITANTE'
            ? [_ana]
            : [_ana, _carlos, _maria],
        200,
      ),
      'POST /users' => respostaJson(_ana, 201),
      'PATCH /users/u-maria' => respostaJson(_maria, 200),
      'GET /locations' => respostaJson(_arvore, 200),
      'GET /terminals' => respostaJson([_terminal], 200),
      'GET /authorizations' => respostaJson([
        autorizacaoJson(),
        autorizacaoJson(id: 'a2', situacao: 'AGENDADA'),
      ], 200),
      'POST /authorizations' => respostaJson(autorizacaoJson(), 201),
      'PATCH /authorizations/autorizacao-1' => respostaJson(
        autorizacaoJson(),
        200,
      ),
      'POST /authorizations/autorizacao-1/cancel' => respostaJson(
        autorizacaoJson(situacao: 'CANCELADA'),
        200,
      ),
      'GET /me/authorizations' => respostaJson([autorizacaoJson()], 200),
      'GET /access-events' || 'GET /me/access-events' => respostaJson(
        eventos,
        200,
      ),
      'GET /dashboard' => respostaJson({
        'acessosHoje': 248,
        'negadosHoje': 12,
        'autorizacoesAtivas': 86,
        'negadosRecentes': [_eventoNegado, _eventoSemPessoa],
      }, 200),
      'GET /auth/me' => respostaJson(_maria, 200),
      _ => erroDaApi(404, 'ROTA_NAO_ENCONTRADA', '$rota não existe.'),
    };
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
              onPressed: () => Navigator.of(
                contexto,
              ).push(MaterialPageRoute(builder: (_) => tela)),
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

/// Cada tela nova, ligada à API de [cliente].
Map<String, Widget Function(http.Client)> _telas() {
  ApiClient api(http.Client cliente) => ApiClient(cliente: cliente);
  return {
    'Painel': (c) => PainelView(controller: PainelController(api: api(c))),
    'Autorizações': (c) =>
        AutorizacoesView(controller: AutorizacoesController(api: api(c))),
    'Autorização · formulário': (c) =>
        AutorizacaoFormView(controller: AutorizacoesController(api: api(c))),
    'Histórico da equipe': (c) => HistoricoView(
      daEquipe: true,
      controller: HistoricoController(daEquipe: true, api: api(c)),
    ),
    'Acessos negados do morador': (c) => HistoricoView(
      daEquipe: false,
      soNegados: true,
      controller: HistoricoController(daEquipe: false, api: api(c)),
    ),
    'Usuários': (c) =>
        UsuariosView(controller: UsuariosController(api: api(c))),
    'Usuário · formulário': (c) =>
        UsuarioFormView(controller: UsuariosController(api: api(c))),
    'Visitantes': (c) =>
        VisitantesView(controller: UsuariosController(api: api(c))),
    'Locais': (c) => LocaisView(controller: LocaisController(api: api(c))),
    'Tags NFC': (c) => TagsView(controller: UsuariosController(api: api(c))),
    'Terminais': (c) =>
        TerminaisView(controller: TerminaisController(api: api(c))),
    'Relatórios': (c) => RelatoriosView(
      controller: HistoricoController(daEquipe: true, api: api(c)),
    ),
    'Perfil': (c) => PerfilView(controller: PerfilController(api: api(c))),
    'Minha tag': (c) => MinhaTagView(
      podeBloquear: true,
      controller: PerfilController(api: api(c)),
    ),
    'Início': (c) => InicioView(
      menu: const SizedBox(),
      controller: MinhasAutorizacoesController(api: api(c)),
    ),
  };
}

void main() {
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await SessaoService.instancia.encerrar();
  });

  group('Todas as telas novas', () {
    for (final MapEntry(key: nome, value: criar) in _telas().entries) {
      testWidgets('$nome cabe com a fonte no dobro', (tester) async {
        await _abrir(tester, criar(_api()), fonte: 2);
        expect(tester.takeException(), isNull);
      });

      testWidgets('$nome funciona no modo escuro', (tester) async {
        await _abrir(tester, criar(_api()), tema: AppTheme.dark);
        expect(tester.takeException(), isNull);
      });

      if (nome != 'Usuário · formulário') {
        testWidgets('$nome sem internet mostra o erro', (tester) async {
          await _abrir(tester, criar(semInternet()));
          expect(find.text('Sem conexão com a internet'), findsOneWidget);
        });

        testWidgets('$nome com a sessão vencida volta ao login', (
          tester,
        ) async {
          await _abrir(tester, criar(_api(statusFixo: 401)));
          expect(find.byType(LoginView), findsOneWidget);
        });
      }
    }
  });

  testWidgets('Ajuda abre sem chamar a API', (tester) async {
    await _abrir(tester, const AjudaView(), fonte: 2);
    expect(find.text('Ajuda'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('Histórico', () {
    testWidgets('Mostra os totais, o motivo e quem não foi identificado', (
      tester,
    ) async {
      await _abrir(tester, _telas()['Histórico da equipe']!(_api()));
      expect(
        find.text('3 registros · 1 liberados, 2 negados'),
        findsOneWidget,
      );
      expect(find.text('Fora do horário permitido'), findsOneWidget);
      expect(find.text('Pessoa não identificada'), findsOneWidget);
    });

    testWidgets('Morador lê /me/access-events e vê o que fazer', (
      tester,
    ) async {
      final chamadas = <http.Request>[];
      await _abrir(
        tester,
        _telas()['Acessos negados do morador']!(_api(chamadas: chamadas)),
      );
      expect(chamadas.single.url.path, '/me/access-events');
      expect(chamadas.single.url.queryParameters['resultado'], 'NEGADO');
      expect(
        find.text('Volte dentro do horário ou fale com a portaria.'),
        findsOneWidget,
      );
    });

    test('O período vai com data e hora, cobrindo o dia inteiro', () async {
      final chamadas = <http.Request>[];
      final controller = HistoricoController(
        daEquipe: true,
        api: ApiClient(cliente: _api(chamadas: chamadas)),
        relogio: () => DateTime(2026, 11, 2, 10),
      );
      await controller.carregar(
        const FiltroEventos(periodo: PeriodoHistorico.hoje),
      );
      final query = chamadas.single.url.queryParameters;
      expect(DateTime.parse(query['de']!).toLocal(), DateTime(2026, 11, 2));
      expect(
        DateTime.parse(query['ate']!).toLocal(),
        DateTime(2026, 11, 2, 23, 59, 59),
      );
    });
  });

  group('Autorizações', () {
    test('O filtro Ativa não traz as agendadas (B4)', () async {
      final controller = AutorizacoesController(
        api: ApiClient(cliente: _api()),
      );
      final lista = await controller.listar(
        const FiltroAutorizacoes(situacao: SituacaoAutorizacao.ativa),
      );
      expect(lista.map((a) => a.autorizacao.id), ['autorizacao-1']);
    });

    testWidgets('Cancelar pede confirmação e chama a API (A10)', (
      tester,
    ) async {
      final chamadas = <http.Request>[];
      final controller = AutorizacoesController(
        api: ApiClient(cliente: _api(chamadas: chamadas)),
      );
      final lista = await controller.listar(const FiltroAutorizacoes());
      await _abrir(
        tester,
        AutorizacaoFormView(autorizacao: lista.first, controller: controller),
      );

      await tester.ensureVisible(find.text('Cancelar autorização'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar autorização'));
      await tester.pumpAndSettle();
      expect(find.text('Cancelar esta autorização?'), findsOneWidget);

      await tester.tap(find.text('Não, manter'));
      await tester.pumpAndSettle();
      expect(chamadas.where((c) => c.url.path.endsWith('/cancel')), isEmpty);

      await tester.tap(find.text('Cancelar autorização'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sim, cancelar'));
      await tester.pumpAndSettle();
      expect(chamadas.where((c) => c.url.path.endsWith('/cancel')), hasLength(1));
    });

    testWidgets('Sem escolher pessoa e local, não envia', (tester) async {
      final chamadas = <http.Request>[];
      await _abrir(
        tester,
        _telas()['Autorização · formulário']!(_api(chamadas: chamadas)),
      );
      await tester.tap(find.text('Criar autorização'));
      await tester.pumpAndSettle();
      expect(find.text('Escolha a pessoa.'), findsOneWidget);
      expect(chamadas.where((c) => c.method == 'POST'), isEmpty);
    });
  });

  group('Usuários', () {
    testWidgets('Portaria só escolhe morador e visitante, e não edita o admin', (
      tester,
    ) async {
      final auth = authFalso();
      await auth.entrar('portaria@passe.com', senhaDemo);
      final controller = UsuariosController(
        api: ApiClient(cliente: _api()),
        auth: auth,
      );
      expect(controller.podeGerenciar(contasDemo.first.perfil), isFalse);

      await _abrir(tester, UsuariosView(controller: controller));
      await tester.tap(find.text('Novo usuário'));
      await tester.pumpAndSettle();
      expect(find.text('Condômino'), findsOneWidget);
      expect(find.text('Administrador'), findsNothing);
    });

    testWidgets('Envia os dados e mostra o erro do campo vindo da API', (
      tester,
    ) async {
      final chamadas = <http.Request>[];
      final cliente = MockClient((request) async {
        chamadas.add(request);
        return respostaJson({
          'erro': {
            'codigo': 'DADOS_INVALIDOS',
            'mensagem': 'Dados inválidos.',
            'detalhes': {
              'email': ['E-mail inválido'],
            },
          },
        }, 400);
      });
      await _abrir(
        tester,
        UsuarioFormView(
          controller: UsuariosController(api: ApiClient(cliente: cliente)),
        ),
      );
      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'Vis Teste');
      await tester.enterText(campos.at(1), '123.456.789-09');
      await tester.enterText(campos.at(2), 'a@b');
      await tester.enterText(campos.at(3), 'passe123');
      await tester.tap(find.text('Criar usuário'));
      await tester.pumpAndSettle();

      final corpo = jsonDecode(chamadas.single.body) as Map<String, dynamic>;
      expect(corpo['perfil'], 'CONDOMINO');
      expect(corpo['cpf'], '123.456.789-09');
      expect(find.text('E-mail inválido'), findsOneWidget);
    });
  });

  group('Terminais', () {
    testWidgets('Cruza o terminal com o nome da catraca', (tester) async {
      await _abrir(tester, _telas()['Terminais']!(_api()));
      expect(
        find.text('Catraca 1 · Portaria Principal › Porta A'),
        findsOneWidget,
      );
      expect(find.text('No ar'), findsOneWidget);
    });

    testWidgets('Portaria não vê cadastrar nem trocar chave', (tester) async {
      final auth = authFalso();
      await auth.entrar('portaria@passe.com', senhaDemo);
      await _abrir(
        tester,
        TerminaisView(
          controller: TerminaisController(
            api: ApiClient(cliente: _api()),
            auth: auth,
          ),
        ),
      );
      expect(find.text('Novo terminal'), findsNothing);
      expect(find.text('Trocar chave'), findsNothing);
    });
  });

  testWidgets('Tags: busca filtra por UID, que a API não procura', (
    tester,
  ) async {
    await _abrir(tester, _telas()['Tags NFC']!(_api()));
    expect(find.text('Maria Souza'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'ffff');
    await tester.pump();
    expect(find.text('Nenhuma tag encontrada'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'b2c3');
    await tester.pump();
    expect(find.text('Maria Souza'), findsOneWidget);
  });

  testWidgets('Perfil mascara o CPF', (tester) async {
    await _abrir(tester, _telas()['Perfil']!(_api()));
    expect(find.text('•••.333.333-••'), findsOneWidget);
    expect(find.text('33333333333'), findsNothing);
    expect(find.text('Vinculada · final B2C3'), findsOneWidget);
  });
}
