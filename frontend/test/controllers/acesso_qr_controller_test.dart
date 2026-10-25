import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:public/controllers/acesso_qr_controller.dart';
import 'package:public/services/api_client.dart';
import 'package:public/services/localizacao_service.dart';

import '../support/api_falsa.dart';

/// GPS de mentira: devolve sempre a mesma [posicao] (null = sem permissão).
class _LocalizacaoFalsa extends LocalizacaoService {
  _LocalizacaoFalsa([this.posicao]);

  final Posicao? posicao;

  @override
  Future<Posicao?> posicaoAtual({
    Duration limite = const Duration(seconds: 8),
  }) async => posicao;
}

const _token = 'P1.token-assinado-pelo-terminal';
const _perto = (latitude: -23.3053, longitude: -45.9658);

final _liberado = {
  'liberado': true,
  'titulo': 'Acesso liberado',
  'catraca': {'id': 'c1', 'nome': 'Catraca 1', 'caminho': 'A › B › C'},
  'usosRestantes': 999,
  'eventoId': 'evento-1',
  'em': '2026-10-25T17:30:00.000Z',
};

AcessoQrController _controller(http.Client cliente, [Posicao? posicao]) =>
    AcessoQrController(
      api: ApiClient(cliente: cliente),
      localizacao: _LocalizacaoFalsa(posicao),
      auth: authFalso(),
    );

void main() {
  test('Manda o token sem alterar e a posição do celular', () async {
    final chamadas = <http.Request>[];
    final cliente = MockClient((request) async {
      chamadas.add(request);
      return respostaJson(_liberado, 200);
    });

    final decisao = await _controller(cliente, _perto).validar(_token);

    expect(decisao.liberado, isTrue);
    expect(chamadas.single.method, 'POST');
    expect(chamadas.single.url.path, '/access/qr');
    expect(jsonDecode(chamadas.single.body), {
      'token': _token,
      'latitude': -23.3053,
      'longitude': -45.9658,
    });
  });

  test('Sem posição, manda só o token e a API decide', () async {
    final chamadas = <http.Request>[];
    final cliente = MockClient((request) async {
      chamadas.add(request);
      return respostaJson({
        'liberado': false,
        'motivo': 'LOCALIZACAO_AUSENTE',
        'titulo': 'Não conseguimos sua localização',
        'oQueFazer': 'Permita a localização no celular e tente de novo.',
        'eventoId': 'evento-2',
        'em': '2026-10-25T17:30:00.000Z',
      }, 200);
    });

    final decisao = await _controller(cliente).validar(_token);

    expect(jsonDecode(chamadas.single.body), {'token': _token});
    expect(decisao.semLocalizacao, isTrue);
  });

  test('Negado também chega como decisão, porque a API responde 200', () async {
    final cliente = MockClient(
      (request) async => respostaJson({
        'liberado': false,
        'motivo': 'SEM_USOS',
        'titulo': 'Você não tem mais usos',
        'oQueFazer': 'Peça mais usos à portaria.',
        'eventoId': 'evento-3',
        'em': '2026-10-25T17:30:00.000Z',
      }, 200),
    );

    final decisao = await _controller(cliente, _perto).validar(_token);

    expect(decisao.liberado, isFalse);
    expect(decisao.motivo, 'SEM_USOS');
  });

  test('Sem internet lança ApiException de falta de conexão', () {
    expect(
      _controller(semInternet(), _perto).validar(_token),
      throwsA(
        isA<ApiException>().having((e) => e.semConexao, 'semConexao', isTrue),
      ),
    );
  });

  test('Sessão vencida lança ApiException 401', () {
    final cliente = MockClient(
      (request) async =>
          erroDaApi(401, 'NAO_AUTENTICADO', 'Sua sessão expirou.'),
    );

    expect(
      _controller(cliente, _perto).validar(_token),
      throwsA(
        isA<ApiException>().having(
          (e) => e.naoAutenticado,
          'naoAutenticado',
          isTrue,
        ),
      ),
    );
  });

  test('Só aceita como QR da catraca textos de 10 a 2000 caracteres', () {
    final controller = _controller(semInternet());

    expect(controller.qrDaCatraca('curto'), isFalse);
    expect(controller.qrDaCatraca('a' * 10), isTrue);
    expect(controller.qrDaCatraca(_token), isTrue);
    expect(controller.qrDaCatraca('a' * 2000), isTrue);
    expect(controller.qrDaCatraca('a' * 2001), isFalse);
  });
}
