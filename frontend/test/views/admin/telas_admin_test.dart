import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:public/models/admin_models.dart';
import 'package:public/services/admin_service.dart';
import 'package:public/services/api_client.dart';
import 'package:public/services/auth_service.dart';
import 'package:public/services/sessao_service.dart';
import 'package:public/views/admin/autorizacao_form_view.dart';
import 'package:public/views/admin/autorizacoes_view.dart';
import 'package:public/views/admin/historico_view.dart';
import 'package:public/views/admin/painel_view.dart';
import 'package:public/views/admin/usuarios_view.dart';

import '../../support/api_falsa.dart';

Map<String, dynamic> _autorizacao({String situacao = 'ATIVA'}) => {
  'id': 'a1',
  'userId': 'u1',
  'accessPointId': 'c1',
  'dataInicio': '2026-10-01',
  'dataFim': '2026-10-31',
  'horaInicio': '08:00',
  'horaFim': '18:00',
  'maxUsos': 10,
  'usosRealizados': 7,
  'usosRestantes': 3,
  'situacao': situacao,
  'status': situacao == 'CANCELADA' ? 'CANCELADA' : 'ATIVA',
  'user': {'id': 'u1', 'nome': 'Maria Souza', 'perfil': 'CONDOMINO'},
  'catraca': {'id': 'c1', 'nome': 'Catraca 2'},
};

const _maria = {
  'id': 'u1',
  'nome': 'Maria Souza',
  'email': 'morador@passe.com',
  'cpf': '33333333333',
  'perfil': 'CONDOMINO',
  'ativo': true,
  'tags': [
    {'id': 't1', 'uid': '04A1B24F2A', 'ativa': true},
  ],
};

const _locais = [
  {
    'id': 'e1',
    'nome': 'Edifício Atlântico',
    'endereco': 'Av. Paulista, 1000',
    'portarias': [
      {
        'id': 'p1',
        'nome': 'Portaria Principal',
        'portas': [
          {
            'id': 'd1',
            'nome': 'Porta A',
            'catracas': [
              {
                'id': 'c1',
                'nome': 'Catraca 2',
                'doorId': 'd1',
                'latitude': -23.3,
                'longitude': -45.9,
                'raioMetros': 100,
              },
            ],
          },
        ],
      },
    ],
  },
];

void main() {
  late List<http.Request> chamadas;

  Future<AdminService> servico(
    Future<http.Response> Function(http.Request) responder,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    final sessao = SessaoService();
    await sessao.iniciar(tokenFalso(), contasDemo.first);
    final api = ApiClient(
      cliente: MockClient((request) {
        chamadas.add(request);
        return responder(request);
      }),
      sessao: sessao,
      baseUrl: 'http://api.teste',
    );
    return AdminService(api: api, auth: AuthService(api: api, sessao: sessao));
  }

  Future<void> abrir(WidgetTester tester, Widget tela) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: tela));
    await tester.pumpAndSettle();
  }

  /// Abre a tela por cima de outra, como no app: assim o Voltar e o
  /// "fechar depois de salvar" têm uma rota para onde voltar.
  Future<void> abrirPorCima(WidgetTester tester, Widget tela) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => tela),
                ),
                child: const Text('ir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ir'));
    await tester.pumpAndSettle();
  }

  setUp(() => chamadas = []);

  testWidgets('Painel mostra os números de hoje e os negados recentes', (
    tester,
  ) async {
    final s = await servico(
      (_) async => respostaJson({
        'acessosHoje': 248,
        'negadosHoje': 12,
        'autorizacoesAtivas': 86,
        'negadosRecentes': [
          {
            'id': 'e1',
            'metodo': 'QR',
            'resultado': 'NEGADO',
            'motivo': 'LONGE_DO_TERMINAL',
            'createdAt': '2026-10-14T11:57:00.000Z',
            'credencial': null,
            'user': {'id': 'u', 'nome': 'Ana Lima'},
            'catraca': {'id': 'c', 'nome': 'Catraca G1'},
          },
        ],
      }, 200),
    );

    await abrir(tester, PainelView(servico: s));

    expect(find.text('248'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('86'), findsOneWidget);
    expect(find.text('Acessos hoje'), findsOneWidget);
    expect(find.textContaining('Ana Lima'), findsOneWidget);
    expect(find.textContaining('Mais de 100 m da catraca'), findsOneWidget);
  });

  testWidgets('Sem internet, mostra o erro e deixa tentar de novo', (
    tester,
  ) async {
    var falhar = true;
    final s = await servico((_) async {
      if (falhar) throw http.ClientException('sem rede');
      return respostaJson({
        'acessosHoje': 1,
        'negadosHoje': 0,
        'autorizacoesAtivas': 1,
        'negadosRecentes': [],
      }, 200);
    });

    await abrir(tester, PainelView(servico: s));
    expect(find.textContaining('Não foi possível falar com o servidor'), findsOneWidget);

    falhar = false;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.text('Acessos hoje'), findsOneWidget);
    expect(find.text('Nenhum acesso negado hoje'), findsOneWidget);
  });

  testWidgets('Usuários lista com CPF mascarado, perfil e tag', (tester) async {
    final s = await servico((_) async => respostaJson([_maria], 200));

    await abrir(tester, UsuariosView(servico: s));

    expect(find.text('Maria Souza'), findsOneWidget);
    expect(find.textContaining('CPF •••.'), findsOneWidget);
    expect(find.text('Condômino'), findsWidgets);
    expect(find.text('Tag 4F2A'), findsOneWidget);
    expect(find.text('1 usuário encontrado'), findsOneWidget);
  });

  testWidgets('Usuários sem resultado mostra o estado vazio', (tester) async {
    final s = await servico((_) async => respostaJson([], 200));

    await abrir(tester, UsuariosView(servico: s));

    expect(find.text('Nenhum usuário encontrado'), findsOneWidget);
  });

  testWidgets('Autorizações mostra situação, período, horário e usos', (
    tester,
  ) async {
    final s = await servico((_) async => respostaJson([_autorizacao()], 200));

    await abrir(tester, AutorizacoesView(servico: s));

    expect(find.text('Maria Souza'), findsOneWidget);
    expect(find.text('Ativa'), findsWidgets);
    expect(find.text('01/10/2026 a 31/10/2026'), findsOneWidget);
    expect(find.text('Das 08:00 às 18:00'), findsOneWidget);
    expect(find.text('3 de 10 usos restantes'), findsOneWidget);
    // Começa filtrando as ativas.
    expect(chamadas.first.url.queryParameters['situacao'], 'ATIVA');
  });

  testWidgets('Cancelar uma autorização pede confirmação e chama a API', (
    tester,
  ) async {
    final s = await servico((request) async {
      if (request.url.path == '/users') return respostaJson([_maria], 200);
      if (request.url.path == '/locations') return respostaJson(_locais, 200);
      return respostaJson(_autorizacao(situacao: 'CANCELADA'), 200);
    });
    final autorizacao = Autorizacao.fromJson(_autorizacao());

    await abrirPorCima(
      tester,
      AutorizacaoFormView(autorizacao: autorizacao, servico: s),
    );
    await tester.scrollUntilVisible(
      find.text('Cancelar esta autorização'),
      200,
    );
    await tester.tap(find.text('Cancelar esta autorização'));
    await tester.pumpAndSettle();

    expect(find.text('Cancelar esta autorização?'), findsOneWidget);
    // Antes de confirmar, nada foi cancelado.
    expect(chamadas.where((c) => c.url.path.endsWith('/cancel')), isEmpty);

    await tester.tap(find.text('Não, manter'));
    await tester.pumpAndSettle();
    expect(chamadas.where((c) => c.url.path.endsWith('/cancel')), isEmpty);

    await tester.tap(find.text('Cancelar esta autorização'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sim, cancelar'));
    await tester.pumpAndSettle();

    expect(
      chamadas.where((c) => c.method == 'POST' && c.url.path == '/authorizations/a1/cancel'),
      hasLength(1),
    );
  });

  testWidgets('Autorização cancelada abre só para leitura', (tester) async {
    final s = await servico((request) async {
      if (request.url.path == '/users') return respostaJson([_maria], 200);
      return respostaJson(_locais, 200);
    });
    final cancelada = Autorizacao.fromJson(_autorizacao(situacao: 'CANCELADA'));

    await abrir(tester, AutorizacaoFormView(autorizacao: cancelada, servico: s));

    expect(find.textContaining('foi cancelada'), findsOneWidget);
    expect(find.text('Salvar alterações'), findsNothing);
    expect(find.text('Cancelar esta autorização'), findsNothing);
  });

  testWidgets('Histórico sem resultado oferece limpar os filtros', (
    tester,
  ) async {
    final s = await servico(
      (_) async => respostaJson({
        'itens': [],
        'total': 0,
        'liberados': 0,
        'negados': 0,
      }, 200),
    );

    await abrir(tester, HistoricoView(servico: s));

    expect(find.text('Nenhum acesso encontrado'), findsOneWidget);
    // Começa em "Hoje": manda a data inicial e nenhum outro filtro.
    expect(chamadas.first.url.queryParameters.containsKey('de'), isTrue);
    expect(find.text('Atualizar'), findsOneWidget);

    await tester.tap(find.text('Negados'));
    await tester.pumpAndSettle();
    expect(chamadas.last.url.queryParameters['resultado'], 'NEGADO');

    await tester.tap(find.text('Limpar filtros'));
    await tester.pumpAndSettle();

    // "Tudo" não manda data inicial nem resultado.
    expect(chamadas.last.url.queryParameters.containsKey('de'), isFalse);
    expect(chamadas.last.url.queryParameters.containsKey('resultado'), isFalse);
  });
}
