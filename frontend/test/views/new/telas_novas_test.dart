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
import 'package:public/models/evento_acesso.dart';
import 'package:public/models/local.dart';
import 'package:public/models/usuario_cadastro.dart';
import 'package:public/core/theme/app_theme.dart';
import 'package:public/services/api_client.dart';
import 'package:public/services/localizacao_service.dart';
import 'package:public/services/sessao_service.dart';
import 'package:public/views/shared/historico_view.dart';
import 'package:public/views/teams/autorizacao_form_view.dart';
import 'package:public/views/teams/autorizacoes_view.dart';
import 'package:public/views/teams/catraca_form_view.dart';
import 'package:public/views/teams/locais_view.dart';
import 'package:public/views/teams/painel_view.dart';
import 'package:public/views/teams/relatorios_view.dart';
import 'package:public/views/resident/resident_menu_view.dart';
import 'package:public/views/teams/tags_view.dart';
import 'package:public/views/teams/terminais_view.dart';
import 'package:public/views/teams/usuario_form_view.dart';
import 'package:public/views/teams/usuarios_view.dart';
import 'package:public/views/teams/visitantes_view.dart';
import 'package:public/views/user/ajuda_view.dart';
import 'package:public/views/user/inicio_view.dart';
import 'package:public/views/user/login_view.dart';
import 'package:public/views/user/minha_tag_view.dart';
import 'package:public/views/user/minhas_autorizacoes_view.dart';
import 'package:public/views/user/perfil_view.dart';
import 'package:public/views/widgets/cartao_erro.dart';

import '../../support/api_falsa.dart';

// Baseadas nas respostas da API real, com ids curtos e só os campos que o app lê.
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
const _idCatraca = '00000000-0000-4000-8000-000000000004';
const _catraca = {
  'id': _idCatraca,
  'nome': 'Catraca 1',
  'doorId': 'd1',
  'latitude': -23.3053,
  'longitude': -45.9658,
  'raioMetros': 100,
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
            'catracas': [_catraca],
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
  'titulo': 'Fora do horário permitido',
  'oQueFazer': 'Volte dentro do horário ou fale com a portaria.',
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
  'titulo': 'Tag não cadastrada',
  'oQueFazer': 'Peça para a portaria vincular sua tag.',
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
  'titulo': null,
  'oQueFazer': null,
  'credencial': 'ABC',
  'distanciaMetros': 12.4,
  'createdAt': '2026-11-02T12:08:24.114Z',
  'user': {'id': 'u-maria', 'nome': 'Maria Souza'},
  'catraca': {'id': 'c1', 'nome': 'Catraca 1'},
};

/// GPS de mentira: devolve sempre a mesma [posicao] (null = sem permissão).
class _LocalizacaoFalsa extends LocalizacaoService {
  _LocalizacaoFalsa(this.posicao);

  final Posicao? posicao;

  @override
  Future<Posicao?> posicaoAtual({
    Duration limite = const Duration(seconds: 8),
  }) async => posicao;
}

/// API com as rotas das telas novas. Guarda cada requisição em [chamadas].
MockClient _api({List<http.Request>? chamadas, int? statusFixo}) {
  return MockClient((request) async {
    chamadas?.add(request);
    if (statusFixo != null) {
      return erroDaApi(statusFixo, 'NAO_AUTENTICADO', 'Sessão inválida.');
    }
    final rota = '${request.method} ${request.url.path}';
    final situacao = request.url.queryParameters['situacao'];
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
      'POST /locations/access-points' => respostaJson(_catraca, 201),
      'PATCH /locations/access-points/$_idCatraca' => respostaJson(_catraca, 200),
      'GET /terminals' => respostaJson([_terminal], 200),
      'GET /authorizations' => respostaJson([
        for (final a in [
          autorizacaoJson(),
          autorizacaoJson(id: 'a2', situacao: 'AGENDADA'),
        ])
          if (situacao == null || a['situacao'] == situacao) a,
      ], 200),
      'PATCH /me/tags/tag-1' => respostaJson({..._tag, 'ativa': false}, 200),
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
    'Catraca · formulário': (c) => CatracaFormView(
      portaId: 'd1',
      caminho: 'Portaria Principal › Porta A',
      controller: LocaisController(api: api(c)),
    ),
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
        expect(find.byType(CartaoErro), findsNothing);
      });

      testWidgets('$nome funciona no modo escuro', (tester) async {
        await _abrir(tester, criar(_api()), tema: AppTheme.dark);
        expect(tester.takeException(), isNull);
        expect(find.byType(CartaoErro), findsNothing);
      });

      // Os dois formulários só chamam a API ao salvar.
      if (!const {'Usuário · formulário', 'Catraca · formulário'}.contains(nome)) {
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

  testWidgets('Ajuda cabe com a fonte no dobro', (tester) async {
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
        find.text('3 registros · 1 liberado, 2 negados'),
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

    test('O texto do motivo vem da API, com um padrão quando ela não manda', () {
      final daApi = EventoAcesso.fromJson({
        ..._eventoNegado,
        'titulo': 'Texto novo',
        'oQueFazer': 'Faça outra coisa.',
      });
      expect(daApi.titulo, 'Texto novo');
      expect(daApi.oQueFazer, 'Faça outra coisa.');

      final semTexto = EventoAcesso.fromJson({
        ..._eventoNegado,
        'titulo': null,
        'oQueFazer': null,
      });
      expect(semTexto.titulo, 'Acesso negado');
      expect(semTexto.oQueFazer, 'Fale com a portaria.');
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
    test('O filtro Ativa vai para a API, que não traz as agendadas (B4)', () async {
      final chamadas = <http.Request>[];
      final controller = AutorizacoesController(
        api: ApiClient(cliente: _api(chamadas: chamadas)),
      );
      final lista = await controller.listar(
        const FiltroAutorizacoes(situacao: SituacaoAutorizacao.ativa),
      );
      expect(chamadas.single.url.queryParameters['situacao'], 'ATIVA');
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
      expect(find.text('Escolha a catraca.'), findsOneWidget);
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
      // Sem rolar, o cartão fica embaixo do botão "Novo usuário" e o toque
      // abre o formulário de cadastro em vez de tocar no admin.
      await tester.ensureVisible(find.text('Carlos Lima'));
      await tester.pumpAndSettle();
      final cartaoDoAdmin = find.ancestor(
        of: find.text('Carlos Lima'),
        matching: find.byType(InkWell),
      );
      expect(tester.widget<InkWell>(cartaoDoAdmin.first).onTap, isNull);
      await tester.tap(find.text('Carlos Lima'));
      await tester.pumpAndSettle();
      expect(find.text('Editar usuário'), findsNothing);
      // Continua na lista: nenhum formulário abriu por cima.
      expect(find.text('Nome, e-mail ou CPF'), findsOneWidget);

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

    testWidgets('Na própria conta não muda o perfil nem desativa', (
      tester,
    ) async {
      final auth = authFalso();
      await auth.entrar('admin@passe.com', senhaDemo);
      final controller = UsuariosController(
        api: ApiClient(cliente: _api()),
        auth: auth,
      );
      final euMesmo = UsuarioCadastro.fromJson({
        ..._carlos,
        'id': auth.usuario!.id,
      });

      await _abrir(
        tester,
        UsuarioFormView(usuario: euMesmo, controller: controller),
      );
      expect(find.text('Perfil'), findsNothing);
      expect(find.text('Cadastro ativo'), findsNothing);
    });

    testWidgets('Na conta de outra pessoa muda o perfil e desativa', (
      tester,
    ) async {
      final auth = authFalso();
      await auth.entrar('admin@passe.com', senhaDemo);
      await _abrir(
        tester,
        UsuarioFormView(
          usuario: UsuarioCadastro.fromJson(_maria),
          controller: UsuariosController(
            api: ApiClient(cliente: _api()),
            auth: auth,
          ),
        ),
      );
      expect(find.text('Perfil'), findsOneWidget);
      await tester.ensureVisible(find.text('Cadastro ativo'));
      expect(find.text('Cadastro ativo'), findsOneWidget);
    });
  });

  group('Formulários gravam na API', () {
    Map<String, dynamic> corpoDe(List<http.Request> chamadas, String metodo) =>
        jsonDecode(chamadas.singleWhere((c) => c.method == metodo).body)
            as Map<String, dynamic>;

    testWidgets('Usuário novo: envia os dados e volta', (tester) async {
      final chamadas = <http.Request>[];
      await _abrir(
        tester,
        _telas()['Usuário · formulário']!(_api(chamadas: chamadas)),
      );
      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), ' Vis Teste ');
      await tester.enterText(campos.at(1), '123.456.789-09');
      await tester.enterText(campos.at(2), 'vis@passe.com');
      await tester.enterText(campos.at(3), 'passe123');
      await tester.tap(find.text('Criar usuário'));
      await tester.pumpAndSettle();

      expect(chamadas.single.url.path, '/users');
      expect(corpoDe(chamadas, 'POST'), {
        'nome': 'Vis Teste',
        'email': 'vis@passe.com',
        'cpf': '123.456.789-09',
        'senha': 'passe123',
        'perfil': 'CONDOMINO',
      });
      expect(find.text('abrir'), findsOneWidget);
    });

    testWidgets('Usuário existente: senha em branco não vai', (tester) async {
      final chamadas = <http.Request>[];
      await _abrir(
        tester,
        UsuarioFormView(
          usuario: UsuarioCadastro.fromJson(_maria),
          controller: UsuariosController(
            api: ApiClient(cliente: _api(chamadas: chamadas)),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField).at(0), 'Maria Lima');
      await tester.tap(find.text('Salvar alterações'));
      await tester.pumpAndSettle();

      expect(chamadas.single.url.path, '/users/u-maria');
      final corpo = corpoDe(chamadas, 'PATCH');
      expect(corpo['nome'], 'Maria Lima');
      expect(corpo['perfil'], 'CONDOMINO');
      expect(corpo, isNot(contains('senha')));
      expect(find.text('abrir'), findsOneWidget);
    });

    testWidgets('Autorização nova: envia a pessoa, o local e o período', (
      tester,
    ) async {
      final chamadas = <http.Request>[];
      await _abrir(
        tester,
        AutorizacaoFormView(
          pessoaFixa: UsuarioCadastro.fromJson(_ana),
          controller: AutorizacoesController(
            api: ApiClient(cliente: _api(chamadas: chamadas)),
          ),
        ),
      );
      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownMenuItem<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Criar autorização'));
      await tester.pumpAndSettle();

      final corpo = corpoDe(chamadas, 'POST');
      expect(corpo['userId'], 'u-ana');
      expect(corpo['accessPointId'], _idCatraca);
      expect(corpo['dataFim'], corpo['dataInicio']);
      expect(corpo['horaInicio'], '08:00');
      expect(corpo['horaFim'], '18:00');
      expect(corpo['maxUsos'], 1);
      expect(find.text('abrir'), findsOneWidget);
    });

    testWidgets('Autorização existente: não troca a pessoa', (tester) async {
      final chamadas = <http.Request>[];
      final controller = AutorizacoesController(
        api: ApiClient(cliente: _api(chamadas: chamadas)),
      );
      final lista = await controller.listar(const FiltroAutorizacoes());
      await _abrir(
        tester,
        AutorizacaoFormView(autorizacao: lista.first, controller: controller),
      );
      await tester.enterText(find.byType(TextFormField), '20');
      await tester.tap(find.text('Salvar alterações'));
      await tester.pumpAndSettle();

      final edicao = chamadas.singleWhere((c) => c.method == 'PATCH');
      expect(edicao.url.path, '/authorizations/autorizacao-1');
      final corpo = jsonDecode(edicao.body) as Map<String, dynamic>;
      expect(corpo['maxUsos'], 20);
      expect(corpo['accessPointId'], _idCatraca);
      expect(corpo['dataInicio'], '2026-10-01');
      expect(corpo, isNot(contains('userId')));
      expect(find.text('abrir'), findsOneWidget);
    });

    testWidgets('Catraca nova: aceita vírgula e envia os números', (
      tester,
    ) async {
      final chamadas = <http.Request>[];
      await _abrir(
        tester,
        _telas()['Catraca · formulário']!(_api(chamadas: chamadas)),
      );
      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'Catraca 2');
      await tester.enterText(campos.at(1), '-23,5');
      await tester.enterText(campos.at(2), '-45,25');
      await tester.enterText(campos.at(3), '150');
      await tester.tap(find.text('Salvar local'));
      await tester.pumpAndSettle();

      expect(chamadas.single.url.path, '/locations/access-points');
      expect(corpoDe(chamadas, 'POST'), {
        'nome': 'Catraca 2',
        'doorId': 'd1',
        'latitude': -23.5,
        'longitude': -45.25,
        'raioMetros': 150,
      });
      expect(find.text('abrir'), findsOneWidget);
    });

    testWidgets('Catraca existente: edita o raio e mantém o resto', (
      tester,
    ) async {
      final chamadas = <http.Request>[];
      await _abrir(
        tester,
        CatracaFormView(
          catraca: Catraca.fromJson(_catraca),
          portaId: 'd1',
          caminho: 'Portaria Principal › Porta A',
          controller: LocaisController(
            api: ApiClient(cliente: _api(chamadas: chamadas)),
          ),
        ),
      );
      expect(find.text('Editar catraca'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(3), '200');
      await tester.tap(find.text('Salvar local'));
      await tester.pumpAndSettle();

      expect(chamadas.single.url.path, '/locations/access-points/$_idCatraca');
      expect(corpoDe(chamadas, 'PATCH'), {
        'nome': 'Catraca 1',
        'latitude': -23.3053,
        'longitude': -45.9658,
        'raioMetros': 200,
      });
    });

    testWidgets('Catraca com dados fora da faixa não envia', (tester) async {
      final chamadas = <http.Request>[];
      await _abrir(
        tester,
        _telas()['Catraca · formulário']!(_api(chamadas: chamadas)),
      );
      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(1), '91');
      await tester.enterText(campos.at(2), '181');
      await tester.enterText(campos.at(3), '5');
      await tester.tap(find.text('Salvar local'));
      await tester.pumpAndSettle();

      expect(find.text('Informe o nome.'), findsOneWidget);
      expect(find.text('A latitude vai de -90 a 90.'), findsOneWidget);
      expect(find.text('A longitude vai de -180 a 180.'), findsOneWidget);
      expect(find.text('O raio vai de 10 a 1000 metros.'), findsOneWidget);
      expect(chamadas, isEmpty);
    });

    Widget catracaComGps(Posicao? posicao) => CatracaFormView(
      portaId: 'd1',
      caminho: 'Portaria Principal › Porta A',
      controller: LocaisController(api: ApiClient(cliente: _api())),
      localizacao: _LocalizacaoFalsa(posicao),
    );

    testWidgets('Usar minha localização preenche os campos', (tester) async {
      await _abrir(tester, catracaComGps((latitude: -23.1, longitude: -45.2)));
      await tester.tap(find.text('Usar minha localização'));
      await tester.pumpAndSettle();
      expect(find.text('-23.1'), findsOneWidget);
      expect(find.text('-45.2'), findsOneWidget);
    });

    testWidgets('Usar minha localização sem GPS avisa', (tester) async {
      await _abrir(tester, catracaComGps(null));
      await tester.tap(find.text('Usar minha localização'));
      await tester.pumpAndSettle();
      expect(
        find.text('Não conseguimos sua localização. Digite os números.'),
        findsOneWidget,
      );
    });
  });

  group('Cadastro desativado', () {
    const mensagem = 'Seu cadastro está desativado. Fale com a portaria.';
    final cliente = MockClient(
      (_) async => erroDaApi(401, 'CADASTRO_DESATIVADO', mensagem),
    );
    final telas = <String, Widget Function()>{
      'Perfil': () => _telas()['Perfil']!(cliente),
      'Minhas autorizações': () => MinhasAutorizacoesView(
        controller: MinhasAutorizacoesController(
          api: ApiClient(cliente: cliente),
        ),
      ),
    };

    for (final MapEntry(key: nome, value: criar) in telas.entries) {
      testWidgets('$nome volta ao login explicando o motivo', (tester) async {
        await _abrir(tester, criar());
        expect(find.byType(LoginView), findsOneWidget);
        expect(find.text(mensagem), findsOneWidget);
      });
    }
  });

  testWidgets('Morador bloqueia a própria tag pela API', (tester) async {
    final chamadas = <http.Request>[];
    await _abrir(
      tester,
      MinhaTagView(
        podeBloquear: true,
        controller: PerfilController(
          api: ApiClient(cliente: _api(chamadas: chamadas)),
        ),
      ),
    );
    await tester.tap(find.text('Bloquear tag'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bloquear'));
    await tester.pumpAndSettle();

    final bloqueio = chamadas.singleWhere((c) => c.method == 'PATCH');
    expect(bloqueio.url.path, '/me/tags/tag-1');
    expect(jsonDecode(bloqueio.body), {'ativa': false});
  });

  testWidgets('Sair pelo Menu do Início não chama a API sem token', (
    tester,
  ) async {
    final chamadas = <http.Request>[];
    await _abrir(
      tester,
      InicioView(
        menu: ResidentMenuView(),
        controller: MinhasAutorizacoesController(
          api: ApiClient(cliente: _api(chamadas: chamadas)),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Sair da conta'), 200);
    await tester.pumpAndSettle();
    chamadas.clear();

    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginView), findsOneWidget);
    expect(chamadas, isEmpty);
  });

  testWidgets('O Menu aberto pelo Início tem Voltar', (tester) async {
    await _abrir(
      tester,
      InicioView(
        menu: ResidentMenuView(),
        controller: MinhasAutorizacoesController(
          api: ApiClient(cliente: _api()),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    expect(find.byType(ResidentMenuView), findsOneWidget);

    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();
    expect(find.byType(ResidentMenuView), findsNothing);
    expect(find.text('Escanear QR Code'), findsOneWidget);
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

    testWidgets('Admin vê cadastrar e trocar chave', (tester) async {
      final auth = authFalso();
      await auth.entrar('admin@passe.com', senhaDemo);
      await _abrir(
        tester,
        TerminaisView(
          controller: TerminaisController(
            api: ApiClient(cliente: _api()),
            auth: auth,
          ),
        ),
      );
      expect(find.text('Novo terminal'), findsOneWidget);
      expect(find.text('Trocar chave'), findsOneWidget);
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
    await tester.enterText(find.byType(TextField).first, '04:a1:b2:c3');
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
