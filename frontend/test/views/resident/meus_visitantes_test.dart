import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:public/controllers/meus_visitantes_controller.dart';
import 'package:public/core/theme/app_theme.dart';
import 'package:public/services/api_client.dart';
import 'package:public/services/sessao_service.dart';
import 'package:public/views/resident/meus_visitantes_view.dart';
import 'package:public/views/resident/visitante_form_view.dart';
import 'package:public/views/user/login_view.dart';
import 'package:public/views/widgets/cartao_erro.dart';

import '../../support/api_falsa.dart';

/// 25/11/2026, às 10:00.
final _agora = DateTime(2026, 11, 25, 10);

const _senha = 'K7M2P9QX';

/// Um convite como o GET /me/visitors devolve: a autorização, com o
/// visitante em `user`.
Map<String, Object?> _convite({
  required String id,
  required String nome,
  String situacao = 'ATIVA',
}) => {
  ...autorizacaoJson(
    id: id,
    situacao: situacao,
    dataInicio: '2026-11-25',
    dataFim: '2026-11-27',
    maxUsos: 2,
    usosRestantes: 2,
    canceladaEm: situacao == 'CANCELADA' ? '2026-11-25T13:00:00.000Z' : null,
  ),
  'criadaPorId': contasDemo[2].id,
  'user': {'id': 'v-$id', 'nome': nome, 'perfil': 'VISITANTE'},
};

final _convitesPadrao = [
  _convite(id: 'a1', nome: 'Ana Lima'),
  _convite(id: 'a2', nome: 'Bruno Dias', situacao: 'CANCELADA'),
];

const _catracaDoConvite = {...catracaAutorizadaDemo, 'ate': '2026-12-31'};

/// API das rotas /me/visitors, como no contrato. Guarda cada requisição em
/// [chamadas] e lembra o que foi cancelado, para a lista recarregar certa.
MockClient _api({
  List<http.Request>? chamadas,
  List<Map<String, Object?>>? convites,
  List<Map<String, Object?>>? catracas,
  bool jaTinhaCadastro = false,
  http.Response Function()? respostaDoPost,
  int? statusFixo,
}) {
  final cancelados = <String>{};
  return MockClient((request) async {
    chamadas?.add(request);
    if (statusFixo != null) {
      return erroDaApi(statusFixo, 'NAO_AUTENTICADO', 'Sessão inválida.');
    }
    final rota = '${request.method} ${request.url.path}';
    if (rota == 'GET /me/visitors') {
      return respostaJson([
        for (final c in convites ?? _convitesPadrao)
          cancelados.contains(c['id'])
              ? _convite(
                  id: c['id'] as String,
                  nome: (c['user'] as Map)['nome'] as String,
                  situacao: 'CANCELADA',
                )
              : c,
      ], 200);
    }
    if (rota == 'GET /me/visitors/catracas') {
      return respostaJson(catracas ?? [_catracaDoConvite], 200);
    }
    if (rota == 'POST /me/visitors') {
      if (respostaDoPost != null) return respostaDoPost();
      final corpo = jsonDecode(request.body) as Map<String, dynamic>;
      return respostaJson({
        'autorizacao': _convite(id: 'a3', nome: corpo['nome'] as String),
        'visitante': {
          'id': 'v-a3',
          'nome': corpo['nome'],
          'email': corpo['email'],
        },
        'senhaProvisoria': jaTinhaCadastro ? null : _senha,
      }, 201);
    }
    final cancelar = RegExp(r'^POST /me/visitors/(.+)/cancel$')
        .firstMatch(rota);
    if (cancelar != null) {
      cancelados.add(cancelar.group(1)!);
      return respostaJson(
        _convite(
          id: cancelar.group(1)!,
          nome: 'Ana Lima',
          situacao: 'CANCELADA',
        ),
        200,
      );
    }
    return erroDaApi(404, 'ROTA_NAO_ENCONTRADA', '$rota não existe.');
  });
}

MeusVisitantesController _controller(http.Client cliente) =>
    MeusVisitantesController(
      api: ApiClient(cliente: cliente),
      relogio: () => _agora,
    );

/// Abre a tela por cima de outra, como o menu faz.
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

Finder _campo(String rotulo) => find.descendant(
  of: find.ancestor(of: find.text(rotulo), matching: find.byType(Column)).first,
  matching: find.byType(TextField),
);

Future<void> _tocar(WidgetTester tester, Finder alvo) async {
  await tester.ensureVisible(alvo);
  await tester.pumpAndSettle();
  await tester.tap(alvo);
  await tester.pumpAndSettle();
}

Future<void> _preencher(WidgetTester tester) async {
  await tester.enterText(_campo('Nome completo'), ' João Pereira ');
  await tester.enterText(_campo('E-mail'), 'joao@email.com');
  await tester.enterText(_campo('CPF'), '765.430.123-00');
}

List<http.Request> _posts(List<http.Request> chamadas) =>
    chamadas.where((c) => c.method == 'POST').toList();

void main() {
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await SessaoService.instancia.encerrar();
  });

  group('Lista', () {
    testWidgets('Mostra cada visitante com situação, catraca, data e horário', (
      tester,
    ) async {
      final chamadas = <http.Request>[];
      await _abrir(
        tester,
        MeusVisitantesView(controller: _controller(_api(chamadas: chamadas))),
      );

      expect(chamadas.single.url.path, '/me/visitors');
      expect(find.text('Meus visitantes'), findsOneWidget);
      expect(find.text('Ana Lima'), findsOneWidget);
      expect(find.text('Bruno Dias'), findsOneWidget);
      expect(find.text('Ativa'), findsOneWidget);
      expect(find.text('Cancelada'), findsOneWidget);
      expect(find.text('Catraca 1 · FATEC Jacareí'), findsNWidgets(2));
      expect(find.text('25/11 a 27/11/2026'), findsNWidgets(2));
      expect(find.text('Das 08:00 às 18:00'), findsNWidgets(2));
      expect(find.text('2 de 2 usos restantes'), findsNWidgets(2));
      // Só o que ainda vale pode ser cancelado.
      expect(find.text('Cancelar acesso'), findsOneWidget);
      expect(find.text('Novo visitante'), findsOneWidget);
    });

    testWidgets('Sem visitantes mostra o vazio', (tester) async {
      await _abrir(
        tester,
        MeusVisitantesView(controller: _controller(_api(convites: []))),
      );

      expect(find.text('Você ainda não cadastrou visitantes'), findsOneWidget);
      expect(find.text('Novo visitante'), findsOneWidget);
    });

    testWidgets('Sem internet mostra o erro e tenta de novo', (tester) async {
      await _abrir(
        tester,
        MeusVisitantesView(controller: _controller(semInternet())),
      );

      expect(find.text('Sem conexão com a internet'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
    });

    testWidgets('Com a sessão vencida volta ao login', (tester) async {
      await _abrir(
        tester,
        MeusVisitantesView(controller: _controller(_api(statusFixo: 401))),
      );

      expect(find.byType(LoginView), findsOneWidget);
    });

    testWidgets('Quem não é condômino vê a mensagem da API', (tester) async {
      final cliente = MockClient(
        (request) async => erroDaApi(
          403,
          'SEM_PERMISSAO',
          'Você não tem permissão para isso.',
        ),
      );
      await _abrir(
        tester,
        MeusVisitantesView(controller: _controller(cliente)),
      );

      expect(find.byType(CartaoErro), findsOneWidget);
      expect(find.text('Você não tem permissão para isso.'), findsOneWidget);
    });

    testWidgets(
      'Resposta fora do formato vira erro, sem carregar para sempre',
      (tester) async {
        final cliente = MockClient(
          (request) async => respostaJson([
            {'id': 'a1'},
          ], 200),
        );
        await _abrir(
          tester,
          MeusVisitantesView(controller: _controller(cliente)),
        );

        expect(find.byType(CartaoErro), findsOneWidget);
        expect(
          find.text(
            'O servidor respondeu num formato inesperado. Tente de novo.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('Cancelar pede confirmação, chama a API e recarrega', (
      tester,
    ) async {
      final chamadas = <http.Request>[];
      await _abrir(
        tester,
        MeusVisitantesView(controller: _controller(_api(chamadas: chamadas))),
      );

      await _tocar(tester, find.text('Cancelar acesso'));
      expect(find.text('Cancelar o acesso de Ana Lima?'), findsOneWidget);

      await tester.tap(find.text('Não, manter'));
      await tester.pumpAndSettle();
      expect(_posts(chamadas), isEmpty);

      await _tocar(tester, find.text('Cancelar acesso'));
      await tester.tap(find.text('Sim, cancelar'));
      await tester.pumpAndSettle();

      expect(_posts(chamadas).single.url.path, '/me/visitors/a1/cancel');
      expect(find.text('Acesso de Ana Lima cancelado.'), findsOneWidget);
      // Recarregou: agora os dois estão cancelados.
      expect(chamadas.where((c) => c.url.path == '/me/visitors'), hasLength(2));
      expect(find.text('Cancelada'), findsNWidgets(2));
      expect(find.text('Cancelar acesso'), findsNothing);
    });
  });

  group('Novo visitante', () {
    testWidgets('Cria, mostra a senha provisória, copia e volta à lista', (
      tester,
    ) async {
      String? copiado;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (chamada) async {
          if (chamada.method == 'Clipboard.setData') {
            copiado = (chamada.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final chamadas = <http.Request>[];
      await _abrir(
        tester,
        MeusVisitantesView(controller: _controller(_api(chamadas: chamadas))),
      );

      await _tocar(tester, find.text('Novo visitante'));
      expect(find.byType(VisitanteFormView), findsOneWidget);
      expect(chamadas.last.url.path, '/me/visitors/catracas');
      // Com uma catraca só, ela já vem escolhida, com o limite do morador.
      expect(find.text('Catraca 1 · FATEC Jacareí'), findsOneWidget);
      expect(
        find.textContaining('Você pode convidar até 31/12/2026.'),
        findsOneWidget,
      );

      await _preencher(tester);
      // Último dia: 27/11, pelo seletor de data.
      await _tocar(tester, find.text('25/11/2026').last);
      await tester.tap(find.text('27'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('27/11/2026'), findsOneWidget);

      await _tocar(tester, find.text('Cadastrar visitante'));

      final post = _posts(chamadas).single;
      expect(post.url.path, '/me/visitors');
      expect(jsonDecode(post.body), {
        'nome': 'João Pereira',
        'email': 'joao@email.com',
        'cpf': '765.430.123-00',
        'accessPointId': catracaAutorizadaDemo['id'],
        'dataInicio': '2026-11-25',
        'dataFim': '2026-11-27',
        'horaInicio': '08:00',
        'horaFim': '18:00',
      });

      expect(find.text('Visitante cadastrado'), findsOneWidget);
      expect(find.text('Senha provisória'), findsOneWidget);
      expect(find.text(_senha), findsOneWidget);
      expect(
        find.text(
          'João Pereira pode entrar pela Catraca 1 de 25/11/2026 a '
          '27/11/2026, das 08:00 às 18:00.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Ela aparece só agora.'), findsOneWidget);

      await _tocar(tester, find.text('Copiar senha'));
      expect(copiado, _senha);
      expect(find.text('Senha copiada.'), findsOneWidget);

      await _tocar(tester, find.text('Concluir'));
      expect(find.byType(VisitanteFormView), findsNothing);
      expect(find.byType(MeusVisitantesView), findsOneWidget);
      expect(chamadas.where((c) => c.url.path == '/me/visitors'), hasLength(3));
    });

    testWidgets(
      'Visitante que já tinha cadastro: explica que usa a senha dele',
      (tester) async {
        await _abrir(
          tester,
          VisitanteFormView(
            controller: _controller(_api(jaTinhaCadastro: true)),
          ),
        );

        await _preencher(tester);
        await _tocar(tester, find.text('Cadastrar visitante'));

        expect(find.text('Visitante cadastrado'), findsOneWidget);
        expect(find.text('Senha provisória'), findsNothing);
        expect(find.text('Copiar senha'), findsNothing);
        expect(
          find.textContaining('já tinha cadastro no Passe'),
          findsOneWidget,
        );
        expect(find.textContaining('a senha que já usa'), findsOneWidget);
      },
    );

    testWidgets('Sem preencher, mostra os erros e não envia', (tester) async {
      final chamadas = <http.Request>[];
      await _abrir(
        tester,
        VisitanteFormView(
          controller: _controller(
            _api(
              chamadas: chamadas,
              // Duas catracas: nenhuma vem escolhida.
              catracas: [
                _catracaDoConvite,
                {..._catracaDoConvite, 'id': 'c2', 'nome': 'Catraca 2'},
              ],
            ),
          ),
        ),
      );

      await _tocar(tester, find.text('Cadastrar visitante'));

      expect(
        find.text('Informe o nome completo do visitante.'),
        findsOneWidget,
      );
      expect(find.text('Informe o e-mail do visitante.'), findsOneWidget);
      expect(find.text('O CPF precisa ter 11 números.'), findsOneWidget);
      expect(find.text('Escolha a catraca.'), findsOneWidget);
      expect(_posts(chamadas), isEmpty);
    });

    testWidgets('Horário inicial igual ao final não envia', (tester) async {
      final chamadas = <http.Request>[];
      await _abrir(
        tester,
        VisitanteFormView(controller: _controller(_api(chamadas: chamadas))),
      );

      await _preencher(tester);
      // "Até": troca 18:00 por 08:00 no seletor de hora.
      await _tocar(tester, find.text('18:00'));
      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();
      final campos = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(campos.first, '8');
      await tester.enterText(campos.last, '00');
      await tester.tap(find.text('AM'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('08:00'), findsNWidgets(2));

      await _tocar(tester, find.text('Cadastrar visitante'));

      expect(
        find.text('O horário inicial e o final não podem ser iguais.'),
        findsOneWidget,
      );
      expect(_posts(chamadas), isEmpty);
    });

    testWidgets('Sem catraca para convidar, explica e não mostra o botão', (
      tester,
    ) async {
      await _abrir(
        tester,
        VisitanteFormView(controller: _controller(_api(catracas: []))),
      );

      expect(find.text('Nenhuma catraca para convidar'), findsOneWidget);
      expect(find.text('Cadastrar visitante'), findsNothing);
    });

    testWidgets('Regra da API (403) vira aviso e continua no formulário', (
      tester,
    ) async {
      const mensagem =
          'O condomínio não permite que moradores cadastrem visitantes. '
          'Fale com a portaria.';
      await _abrir(
        tester,
        VisitanteFormView(
          controller: _controller(
            _api(
              respostaDoPost: () => erroDaApi(403, 'SEM_PERMISSAO', mensagem),
            ),
          ),
        ),
      );

      await _preencher(tester);
      await _tocar(tester, find.text('Cadastrar visitante'));

      expect(find.text(mensagem), findsOneWidget);
      expect(find.text('Visitante cadastrado'), findsNothing);
      expect(find.text('Cadastrar visitante'), findsOneWidget);
    });

    testWidgets('E-mail de outra pessoa (409) mostra a mensagem da API', (
      tester,
    ) async {
      await _abrir(
        tester,
        VisitanteFormView(
          controller: _controller(
            _api(
              respostaDoPost: () => erroDaApi(
                409,
                'CONFLITO',
                'Já existe alguém com este e-mail.',
              ),
            ),
          ),
        ),
      );

      await _preencher(tester);
      await _tocar(tester, find.text('Cadastrar visitante'));

      expect(find.text('Já existe alguém com este e-mail.'), findsOneWidget);
      expect(find.text('Visitante cadastrado'), findsNothing);
    });

    testWidgets('Erro de campo da API aparece embaixo dele', (tester) async {
      await _abrir(
        tester,
        VisitanteFormView(
          controller: _controller(
            _api(
              respostaDoPost: () => respostaJson({
                'erro': {
                  'codigo': 'DADOS_INVALIDOS',
                  'mensagem': 'Confira os campos.',
                  'detalhes': {
                    'cpf': ['CPF inválido'],
                    'dataFim': ['No máximo 7 dias.'],
                  },
                },
              }, 400),
            ),
          ),
        ),
      );

      await _preencher(tester);
      await _tocar(tester, find.text('Cadastrar visitante'));

      expect(find.text('CPF inválido'), findsOneWidget);
      // As datas não têm onde mostrar o erro embaixo: vira aviso.
      expect(find.text('No máximo 7 dias.'), findsOneWidget);
    });

    testWidgets('Sem internet ao abrir mostra o erro', (tester) async {
      await _abrir(
        tester,
        VisitanteFormView(controller: _controller(semInternet())),
      );

      expect(find.text('Sem conexão com a internet'), findsOneWidget);
    });
  });

  group('Cabe na tela', () {
    for (final (nome, fonte, tema) in [
      ('com a fonte no dobro', 2.0, AppTheme.light),
      ('no modo escuro', 1.0, AppTheme.dark),
    ]) {
      testWidgets('Lista, formulário e senha $nome', (tester) async {
        await _abrir(
          tester,
          MeusVisitantesView(controller: _controller(_api())),
          fonte: fonte,
          tema: tema,
        );
        expect(tester.takeException(), isNull);

        await _tocar(tester, find.text('Novo visitante'));
        expect(tester.takeException(), isNull);

        await _preencher(tester);
        await _tocar(tester, find.text('Cadastrar visitante'));
        expect(find.text(_senha), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
