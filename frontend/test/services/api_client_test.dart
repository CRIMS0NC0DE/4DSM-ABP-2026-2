import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:public/services/api_client.dart';
import 'package:public/services/sessao_service.dart';

import '../support/api_falsa.dart';

void main() {
  late SessaoService sessao;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    sessao = SessaoService();
  });

  ApiClient cliente(Future<http.Response> Function(http.Request) responder) =>
      ApiClient(
        cliente: MockClient(responder),
        sessao: sessao,
        baseUrl: 'http://api.teste',
      );

  test('Manda o token da sessão e os filtros na URL', () async {
    await sessao.iniciar('meu-token', contasDemo.first);
    late http.Request enviada;
    final api = cliente((request) async {
      enviada = request;
      return respostaJson([], 200);
    });

    await api.get('/authorizations', query: {'situacao': 'ATIVA'});

    expect(
      enviada.url.toString(),
      'http://api.teste/authorizations?situacao=ATIVA',
    );
    expect(enviada.headers['Authorization'], 'Bearer meu-token');
  });

  test('Sem sessão não manda Authorization', () async {
    late http.Request enviada;
    final api = cliente((request) async {
      enviada = request;
      return respostaJson({'status': 'ok'}, 200);
    });

    expect(await api.get('/health'), {'status': 'ok'});
    expect(enviada.headers.containsKey('Authorization'), isFalse);
  });

  test('Erro 400 traz a mensagem e os campos inválidos', () async {
    final api = cliente(
      (_) async => respostaJson({
        'erro': {
          'codigo': 'DADOS_INVALIDOS',
          'mensagem': 'Dados inválidos.',
          'detalhes': {
            'horaInicio': ['Use o formato HH:MM'],
          },
        },
      }, 400),
    );

    await expectLater(
      api.post('/authorizations', {'horaInicio': '8h'}),
      throwsA(
        isA<ApiException>()
            .having((e) => e.status, 'status', 400)
            .having((e) => e.codigo, 'codigo', 'DADOS_INVALIDOS')
            .having((e) => e.campos, 'campos', {
              'horaInicio': ['Use o formato HH:MM'],
            }),
      ),
    );
  });

  test('Resposta 204 sem corpo devolve null', () async {
    final api = cliente((_) async => http.Response('', 204));
    expect(await api.delete('/users/1/tags/2'), isNull);
  });

  test('Erro sem o formato da API vira mensagem genérica', () async {
    final api = cliente(
      (_) async => http.Response('<html>Bad Gateway</html>', 502),
    );

    await expectLater(
      api.get('/dashboard'),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 502)),
    );
  });

  test('Sem resposta no tempo limite conta como sem conexão', () async {
    final api = ApiClient(
      cliente: MockClient((_) => Completer<http.Response>().future),
      sessao: sessao,
      timeout: const Duration(milliseconds: 10),
    );

    await expectLater(
      api.get('/health'),
      throwsA(
        isA<ApiException>().having((e) => e.semConexao, 'semConexao', true),
      ),
    );
  });
}
