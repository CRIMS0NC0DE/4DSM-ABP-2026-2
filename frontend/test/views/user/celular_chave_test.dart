import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:public/controllers/celular_chave_controller.dart';
import 'package:public/core/theme/app_theme.dart';
import 'package:public/models/celular_nfc.dart';
import 'package:public/services/api_client.dart';
import 'package:public/services/celular_nfc_plataforma.dart';
import 'package:public/views/user/celular_chave_view.dart';

import '../../support/api_falsa.dart';

/// Faz o papel do Keystore e do serviço HCE do Android.
class PlataformaFalsa extends CelularNfcPlataforma {
  PlataformaFalsa({
    this.suportado = true,
    this.nfcLigado = true,
    this.celularId,
    this.falharChave = false,
  });

  final bool suportado;
  final bool nfcLigado;
  final bool falharChave;
  String? celularId;
  final chamadas = <String>[];

  @override
  Future<EstadoAparelho> estado() async => EstadoAparelho(
    suportado: suportado,
    nfcLigado: nfcLigado,
    celularId: celularId,
    modelo: 'SM-A546E',
  );

  @override
  Future<String> prepararChave() async {
    chamadas.add('prepararChave');
    if (falharChave) {
      throw PlatformException(code: 'CHAVE', message: 'Keystore indisponível');
    }
    return 'MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE-chave-publica';
  }

  @override
  Future<void> ativar(String celularId) async {
    chamadas.add('ativar $celularId');
    this.celularId = celularId;
  }

  @override
  Future<void> desativar() async {
    chamadas.add('desativar');
    celularId = null;
  }

  @override
  Future<void> abrirAjustesNfc() async => chamadas.add('ajustes');
}

Map<String, Object> _celular(
  String id, {
  bool ativo = true,
  String nome = 'SM-A546E',
}) => {
  'id': id,
  'userId': 'u-maria',
  'nome': nome,
  'ativo': ativo,
  'createdAt': '2026-11-24T12:00:00.000Z',
};

/// API de /me/phones em memória.
({
  MockClient cliente,
  List<http.Request> pedidos,
  List<Map<String, Object>> lista,
})
_api(List<Map<String, Object>> inicial) {
  final lista = [...inicial];
  final pedidos = <http.Request>[];
  final cliente = MockClient((request) async {
    pedidos.add(request);
    final caminho = request.url.path;
    if (request.method == 'GET' && caminho == '/me/phones') {
      return respostaJson(lista, 200);
    }
    if (request.method == 'POST' && caminho == '/me/phones') {
      final corpo = jsonDecode(request.body) as Map<String, dynamic>;
      final novo = _celular('cel-novo', nome: corpo['nome'] as String);
      lista.add(novo);
      return respostaJson(novo, 201);
    }
    if (request.method == 'DELETE' && caminho.startsWith('/me/phones/')) {
      final id = caminho.split('/').last;
      final antes = lista.length;
      lista.removeWhere((c) => c['id'] == id);
      return lista.length < antes
          ? http.Response('', 204)
          : erroDaApi(404, 'NAO_ENCONTRADO', 'Celular não encontrado(a).');
    }
    return erroDaApi(404, 'NAO_ENCONTRADO', 'Rota não encontrada');
  });
  return (cliente: cliente, pedidos: pedidos, lista: lista);
}

CelularChaveController _controller(
  http.Client cliente,
  PlataformaFalsa plataforma,
) => CelularChaveController(
  api: ApiClient(cliente: cliente),
  plataforma: plataforma,
);

Future<void> _abrir(
  WidgetTester tester,
  CelularChaveController controller,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: CelularChaveView(controller: controller),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('CelularChaveController', () {
    test('ativa com uma chave nova: apaga a antiga, cadastra a pública e guarda o id', () async {
      final api = _api([]);
      final plataforma = PlataformaFalsa(celularId: 'cel-velho');
      final controller = _controller(api.cliente, plataforma);

      await controller.ativar(await plataforma.estado());

      expect(plataforma.chamadas, [
        'desativar',
        'prepararChave',
        'ativar cel-novo',
      ]);
      final post = api.pedidos.single;
      expect(post.url.path, '/me/phones');
      expect(jsonDecode(post.body), {
        'nome': 'SM-A546E',
        'chavePublica': 'MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE-chave-publica',
      });
    });

    test(
      'erro do Keystore vira mensagem para a tela, sem chamar a API',
      () async {
        final api = _api([]);
        final plataforma = PlataformaFalsa(falharChave: true);

        await expectLater(
          _controller(
            api.cliente,
            plataforma,
          ).ativar(await plataforma.estado()),
          throwsA(
            isA<ApiException>().having(
              (e) => e.mensagem,
              'mensagem',
              contains('Keystore indisponível'),
            ),
          ),
        );
        expect(api.pedidos, isEmpty);
      },
    );

    test('desativa tirando da API e apagando a chave', () async {
      final api = _api([_celular('cel-1')]);
      final plataforma = PlataformaFalsa(celularId: 'cel-1');

      await _controller(api.cliente, plataforma).desativar('cel-1');

      expect(api.pedidos.single.method, 'DELETE');
      expect(api.pedidos.single.url.path, '/me/phones/cel-1');
      expect(plataforma.chamadas, ['desativar']);
    });

    test('se a API já tinha removido, apaga a chave do mesmo jeito', () async {
      final api = _api([]);
      final plataforma = PlataformaFalsa(celularId: 'cel-1');

      await _controller(api.cliente, plataforma).desativar('cel-1');

      expect(plataforma.chamadas, ['desativar']);
    });

    test('separa este aparelho dos outros', () async {
      final api = _api([_celular('cel-1'), _celular('cel-2', nome: 'Moto G')]);
      final situacao = await _controller(
        api.cliente,
        PlataformaFalsa(celularId: 'cel-1'),
      ).carregar();

      expect(situacao.deste?.id, 'cel-1');
      expect(situacao.outros.map((c) => c.nome), ['Moto G']);
    });

    test(
      'id guardado que a API não conhece mais conta como não ativado',
      () async {
        final api = _api([_celular('cel-2')]);
        final situacao = await _controller(
          api.cliente,
          PlataformaFalsa(celularId: 'cel-1'),
        ).carregar();

        expect(situacao.deste, isNull);
        expect(situacao.outros, hasLength(1));
      },
    );
  });

  group('CelularChaveView', () {
    testWidgets('aparelho sem HCE explica e não oferece ativar', (
      tester,
    ) async {
      final api = _api([]);
      await _abrir(
        tester,
        _controller(api.cliente, PlataformaFalsa(suportado: false)),
      );

      expect(find.text('Este aparelho não serve como chave'), findsOneWidget);
      expect(find.text('Ativar este celular'), findsNothing);
    });

    testWidgets('ativar mostra o celular como ativo', (tester) async {
      final api = _api([]);
      final plataforma = PlataformaFalsa();
      await _abrir(tester, _controller(api.cliente, plataforma));

      await tester.tap(find.text('Ativar este celular'));
      await tester.pumpAndSettle();

      expect(plataforma.celularId, 'cel-novo');
      expect(find.text('Ativo'), findsOneWidget);
      expect(find.text('Desativar este celular'), findsOneWidget);
    });

    testWidgets('celular bloqueado pela portaria aparece como bloqueado', (
      tester,
    ) async {
      final api = _api([_celular('cel-1', ativo: false)]);
      await _abrir(
        tester,
        _controller(api.cliente, PlataformaFalsa(celularId: 'cel-1')),
      );

      expect(find.text('Bloqueado'), findsOneWidget);
      expect(find.textContaining('A portaria bloqueou'), findsOneWidget);
    });

    testWidgets('com o NFC desligado, avisa e leva aos ajustes', (
      tester,
    ) async {
      final api = _api([_celular('cel-1')]);
      final plataforma = PlataformaFalsa(celularId: 'cel-1', nfcLigado: false);
      await _abrir(tester, _controller(api.cliente, plataforma));

      expect(find.text('O NFC está desligado'), findsOneWidget);
      await tester.tap(find.text('Ligar'));
      expect(plataforma.chamadas, contains('ajustes'));
    });

    testWidgets('desativar pede confirmação e volta ao botão de ativar', (
      tester,
    ) async {
      final api = _api([_celular('cel-1')]);
      final plataforma = PlataformaFalsa(celularId: 'cel-1');
      await _abrir(tester, _controller(api.cliente, plataforma));

      await tester.tap(find.text('Desativar este celular'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Desativar'));
      await tester.pumpAndSettle();

      expect(api.lista, isEmpty);
      expect(plataforma.celularId, isNull);
      expect(find.text('Ativar este celular'), findsOneWidget);
    });

    testWidgets('mostra os outros celulares e remove', (tester) async {
      final api = _api([_celular('cel-1'), _celular('cel-2', nome: 'Moto G')]);
      await _abrir(
        tester,
        _controller(api.cliente, PlataformaFalsa(celularId: 'cel-1')),
      );

      expect(find.text('Outros celulares'), findsOneWidget);
      await tester.tap(find.byTooltip('Remover'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remover'));
      await tester.pumpAndSettle();

      expect(api.lista.map((c) => c['id']), ['cel-1']);
      expect(find.text('Moto G'), findsNothing);
    });
  });
}
