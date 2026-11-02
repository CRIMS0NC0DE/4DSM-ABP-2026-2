import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:public/controllers/minhas_autorizacoes_controller.dart';
import 'package:public/models/autorizacao.dart';
import 'package:public/services/api_client.dart';

import '../support/api_falsa.dart';

MinhasAutorizacoesController _controller(http.Client cliente) =>
    MinhasAutorizacoesController(
      api: ApiClient(cliente: cliente),
      auth: authFalso(),
      relogio: () => DateTime(2026, 10, 14, 9, 41),
    );

void main() {
  test('Busca em GET /me/authorizations e lê cada item', () async {
    final chamadas = <http.Request>[];
    final lista = await _controller(
      apiFalsa(
        chamadas: chamadas,
        autorizacoes: [
          autorizacaoJson(id: 'a1'),
          autorizacaoJson(id: 'a2', situacao: 'EXPIRADA'),
        ],
      ),
    ).carregar();

    expect(chamadas.single.method, 'GET');
    expect(chamadas.single.url.path, '/me/authorizations');
    expect([for (final a in lista) a.id], ['a1', 'a2']);
    expect(lista.last.situacao, SituacaoAutorizacao.expirada);
  });

  test('Sem autorizações devolve a lista vazia', () async {
    final lista = await _controller(apiFalsa(autorizacoes: [])).carregar();

    expect(lista, isEmpty);
  });

  test('Agrupa: ativas antes das agendadas; o resto em encerradas', () async {
    final controller = _controller(
      apiFalsa(
        autorizacoes: [
          autorizacaoJson(id: 'agendada', situacao: 'AGENDADA'),
          autorizacaoJson(id: 'expirada', situacao: 'EXPIRADA'),
          autorizacaoJson(id: 'ativa', situacao: 'ATIVA'),
          autorizacaoJson(id: 'cancelada', situacao: 'CANCELADA'),
          autorizacaoJson(id: 'esgotada', situacao: 'ESGOTADA'),
        ],
      ),
    );

    final (:ativas, :encerradas) = controller.agrupar(
      await controller.carregar(),
    );

    expect([for (final a in ativas) a.id], ['ativa', 'agendada']);
    expect(
      [for (final a in encerradas) a.id],
      ['expirada', 'cancelada', 'esgotada'],
    );
  });

  test('Usa o relógio recebido', () {
    expect(_controller(apiFalsa()).agora(), DateTime(2026, 10, 14, 9, 41));
  });

  test('Sem internet lança ApiException de falta de conexão', () {
    expect(
      _controller(semInternet()).carregar(),
      throwsA(
        isA<ApiException>().having((e) => e.semConexao, 'semConexao', isTrue),
      ),
    );
  });

  test('Sessão vencida lança ApiException 401', () {
    final cliente = MockClient(
      (request) async => erroDaApi(
        401,
        'NAO_AUTENTICADO',
        'Sessão inválida ou expirada. Entre de novo.',
      ),
    );

    expect(
      _controller(cliente).carregar(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.naoAutenticado,
          'naoAutenticado',
          isTrue,
        ),
      ),
    );
  });
}
