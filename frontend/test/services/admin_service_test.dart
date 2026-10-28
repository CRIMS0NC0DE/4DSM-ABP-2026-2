import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:public/models/admin_models.dart';
import 'package:public/models/usuario.dart';
import 'package:public/services/admin_service.dart';
import 'package:public/services/api_client.dart';
import 'package:public/services/auth_service.dart';
import 'package:public/services/sessao_service.dart';

import '../support/api_falsa.dart';

const _userJson = {
  'id': '00000000-0000-4000-8000-0000000000a3',
  'nome': 'Maria Souza',
  'email': 'morador@passe.com',
  'cpf': '33333333333',
  'perfil': 'CONDOMINO',
  'ativo': true,
  'tags': [
    {'id': 't1', 'uid': '04A1B2C3', 'ativa': true},
  ],
};

const _autorizacaoJson = {
  'id': 'a1',
  'userId': '00000000-0000-4000-8000-0000000000a3',
  'accessPointId': '00000000-0000-4000-8000-000000000004',
  'dataInicio': '2026-10-01',
  'dataFim': '2026-10-31',
  'horaInicio': '08:00',
  'horaFim': '18:00',
  'maxUsos': 10,
  'usosRealizados': 9,
  'usosRestantes': 1,
  'situacao': 'ATIVA',
  'status': 'ATIVA',
  'user': {'id': 'u', 'nome': 'Maria Souza', 'perfil': 'CONDOMINO'},
  'catraca': {'id': 'c', 'nome': 'Catraca 1'},
};

void main() {
  late List<http.Request> chamadas;
  late SessaoService sessao;

  AdminService servico(Future<http.Response> Function(http.Request) responder) {
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

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    sessao = SessaoService();
    await sessao.iniciar(tokenFalso(), contasDemo.first);
    chamadas = [];
  });

  group('Usuários', () {
    test('Lista com busca e perfil na URL e lê as tags', () async {
      final s = servico((_) async => respostaJson([_userJson], 200));

      final lista = await s.usuarios(busca: ' Maria ', perfil: Perfil.morador);

      expect(chamadas.single.url.path, '/users');
      expect(chamadas.single.url.queryParameters, {
        'busca': 'Maria',
        'perfil': 'CONDOMINO',
      });
      expect(lista.single.perfil, Perfil.morador);
      expect(lista.single.tagAtiva?.uid, '04A1B2C3');
    });

    test('Cria usuário mandando o perfil como a API escreve', () async {
      final s = servico((_) async => respostaJson(_userJson, 201));

      await s.criarUsuario(
        nome: 'Maria Souza',
        email: 'morador@passe.com',
        cpf: '33333333333',
        senha: 'passe123',
        perfil: Perfil.visitante,
      );

      final chamada = chamadas.single;
      expect(chamada.method, 'POST');
      expect(chamada.url.path, '/users');
      expect(jsonDecode(chamada.body)['perfil'], 'VISITANTE');
    });

    test('Edita sem mandar senha vazia nem campos que não mudaram', () async {
      final s = servico((_) async => respostaJson(_userJson, 200));

      await s.atualizarUsuario('u1', nome: 'Maria S.', senha: '', ativo: false);

      final chamada = chamadas.single;
      expect(chamada.method, 'PATCH');
      expect(jsonDecode(chamada.body), {'nome': 'Maria S.', 'ativo': false});
    });

    test('Vincula, bloqueia e remove tag', () async {
      final s = servico((request) async {
        if (request.method == 'DELETE') return http.Response('', 204);
        return respostaJson({'id': 't1', 'uid': '04A1B2C3', 'ativa': false}, 200);
      });

      await s.vincularTag('u1', '04A1B2C3');
      final tag = await s.alterarTag('u1', 't1', false);
      await s.removerTag('u1', 't1');

      expect(tag.ativa, isFalse);
      expect([for (final c in chamadas) '${c.method} ${c.url.path}'], [
        'POST /users/u1/tags',
        'PATCH /users/u1/tags/t1',
        'DELETE /users/u1/tags/t1',
      ]);
    });

    test('Admin gerencia todos; portaria só condômino e visitante', () async {
      final s = servico((_) async => respostaJson([], 200));
      expect(s.podeGerenciar(Perfil.admin), isTrue);
      expect(s.souAdmin, isTrue);

      await sessao.iniciar(tokenFalso(), contasDemo[1]);
      expect(s.souAdmin, isFalse);
      expect(s.podeGerenciar(Perfil.morador), isTrue);
      expect(s.podeGerenciar(Perfil.visitante), isTrue);
      expect(s.podeGerenciar(Perfil.admin), isFalse);
      expect(s.podeGerenciar(Perfil.controladorAcesso), isFalse);
    });

    test('Mostra a mensagem da API quando o CPF já existe', () async {
      final s = servico(
        (_) async => erroDaApi(409, 'CONFLITO', 'Já existe alguém com este CPF.'),
      );

      await expectLater(
        s.criarUsuario(
          nome: 'Maria',
          email: 'm@x.com',
          cpf: '33333333333',
          senha: 'passe123',
          perfil: Perfil.morador,
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.mensagem,
            'mensagem',
            'Já existe alguém com este CPF.',
          ),
        ),
      );
    });
  });

  group('Autorizações', () {
    test('Lista com filtros e calcula "último uso"', () async {
      final s = servico((_) async => respostaJson([_autorizacaoJson], 200));

      final lista = await s.autorizacoes(
        situacao: 'ATIVA',
        de: '2026-10-01',
        ate: '2026-10-31',
      );

      expect(chamadas.single.url.queryParameters, {
        'situacao': 'ATIVA',
        'de': '2026-10-01',
        'ate': '2026-10-31',
      });
      expect(lista.single.nomeCatraca, 'Catraca 1');
      expect(lista.single.ultimoUso, isTrue);
      expect(lista.single.editavel, isTrue);
    });

    test('Cria, edita e cancela pelas rotas certas', () async {
      final s = servico((_) async => respostaJson(_autorizacaoJson, 200));

      await s.criarAutorizacao(
        userId: 'u',
        accessPointId: 'c',
        dataInicio: '2026-10-01',
        dataFim: '2026-10-31',
        horaInicio: '08:00',
        horaFim: '18:00',
        maxUsos: 10,
      );
      await s.atualizarAutorizacao(
        'a1',
        accessPointId: 'c',
        dataInicio: '2026-10-01',
        dataFim: '2026-11-30',
        horaInicio: '08:00',
        horaFim: '18:00',
        maxUsos: 20,
      );
      await s.cancelarAutorizacao('a1');

      expect([for (final c in chamadas) '${c.method} ${c.url.path}'], [
        'POST /authorizations',
        'PATCH /authorizations/a1',
        'POST /authorizations/a1/cancel',
      ]);
      // Na edição a pessoa não vai no corpo: a API não permite trocar.
      expect(jsonDecode(chamadas[1].body).containsKey('userId'), isFalse);
    });

    test('Autorização cancelada não é editável', () {
      final cancelada = Autorizacao.fromJson({
        ..._autorizacaoJson,
        'situacao': 'CANCELADA',
      });
      expect(cancelada.editavel, isFalse);
      expect(cancelada.ultimoUso, isFalse);
    });
  });

  group('Painel, histórico e locais', () {
    test('Lê o resumo do painel', () async {
      final s = servico(
        (_) async => respostaJson({
          'acessosHoje': 248,
          'negadosHoje': 12,
          'autorizacoesAtivas': 86,
          'negadosRecentes': [
            {
              'id': 'e1',
              'metodo': 'QR',
              'resultado': 'NEGADO',
              'motivo': 'FORA_DO_HORARIO',
              'createdAt': '2026-10-14T11:57:00.000Z',
              'credencial': null,
              'user': {'id': 'u', 'nome': 'Ana Lima'},
              'catraca': {'id': 'c', 'nome': 'Catraca 1'},
            },
          ],
        }, 200),
      );

      final resumo = await s.painel();

      expect(chamadas.single.url.path, '/dashboard');
      expect(resumo.acessosHoje, 248);
      expect(resumo.autorizacoesAtivas, 86);
      final negado = resumo.negadosRecentes.single;
      expect(negado.liberado, isFalse);
      expect(rotuloMotivo(negado.motivo), 'Fora do horário');
    });

    test('Histórico manda filtros e paginação', () async {
      final s = servico(
        (_) async => respostaJson({
          'itens': [],
          'total': 0,
          'liberados': 0,
          'negados': 0,
        }, 200),
      );

      await s.eventos(liberado: false, metodo: 'NFC', accessPointId: 'c', pular: 50);

      expect(chamadas.single.url.queryParameters, {
        'resultado': 'NEGADO',
        'metodo': 'NFC',
        'accessPointId': 'c',
        'limite': '50',
        'pular': '50',
      });
    });

    test('Achata a árvore de locais em catracas com caminho', () async {
      final s = servico(
        (_) async => respostaJson([
          {
            'id': 'e',
            'nome': 'FATEC Jacareí',
            'endereco': 'Av. Faria Lima, 155',
            'portarias': [
              {
                'id': 'p',
                'nome': 'Portaria Principal',
                'portas': [
                  {
                    'id': 'd',
                    'nome': 'Porta A',
                    'catracas': [
                      {
                        'id': 'c',
                        'nome': 'Catraca 1',
                        'doorId': 'd',
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
        ], 200),
      );

      final catracas = (await s.locais()).catracas;

      expect(catracas.single.rotulo,
          'Catraca 1 · FATEC Jacareí › Portaria Principal › Porta A');
      expect(catracas.single.catraca.raioMetros, 100);
    });

    test('Terminal novo traz a chave só na resposta do cadastro', () async {
      final s = servico(
        (request) async => respostaJson({
          'id': 't',
          'nome': 'Terminal 1',
          'accessPointId': 'c',
          'online': false,
          'ultimoSinal': null,
          if (request.method == 'POST') 'chave': 'abc123',
        }, 200),
      );

      final novo = await s.cadastrarTerminal('Terminal 1', 'c');
      final lista = await s.terminais();

      expect(novo.chave, 'abc123');
      expect(lista.single.chave, isNull);
    });
  });
}
