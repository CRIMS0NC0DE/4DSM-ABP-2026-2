import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:public/controllers/acesso_qr_controller.dart';
import 'package:public/services/api_client.dart';
import 'package:public/services/localizacao_service.dart';
import 'package:public/services/sessao_service.dart';
import 'package:public/views/user/acesso_liberado_view.dart';
import 'package:public/views/user/acesso_negado_view.dart';
import 'package:public/views/user/login_view.dart';
import 'package:public/views/user/validando_acesso_view.dart';

import '../../support/api_falsa.dart';

/// GPS de mentira: devolve sempre a mesma [posicao] (null = sem permissão).
class _LocalizacaoFalsa extends LocalizacaoService {
  _LocalizacaoFalsa([this.posicao]);

  final Posicao? posicao;
  var pediuPermissao = false;

  @override
  Future<Posicao?> posicaoAtual({
    Duration limite = const Duration(seconds: 8),
  }) async => posicao;

  @override
  Future<void> permitir() async => pediuPermissao = true;
}

const _perto = (latitude: -23.3053, longitude: -45.9658);

/// Abre a validação por cima de outra tela, como o scanner faz, e devolve o
/// que ela respondeu ao fechar (true = ler o QR de novo).
Future<List<bool?>> _validar(
  WidgetTester tester,
  String token, {
  http.Client? cliente,
  LocalizacaoService? localizacao,
  double fonte = 1,
}) async {
  final respostas = <bool?>[];
  final controller = AcessoQrController(
    api: ApiClient(cliente: cliente ?? apiFalsa()),
    localizacao: localizacao ?? _LocalizacaoFalsa(_perto),
    auth: authFalso(),
  );
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, tela) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(fonte)),
        child: tela!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async => respostas.add(
                await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => ValidandoAcessoView(
                      token: token,
                      controller: controller,
                    ),
                  ),
                ),
              ),
              child: const Text('Scanner'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Scanner'));
  await tester.pumpAndSettle();
  return respostas;
}

void main() {
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await SessaoService.instancia.encerrar();
  });

  testWidgets('Enquanto a API responde, mostra Verificando seu acesso…', (
    WidgetTester tester,
  ) async {
    final resposta = Completer<http.Response>();
    final cliente = MockClient((request) => resposta.future);
    final controller = AcessoQrController(
      api: ApiClient(cliente: cliente),
      localizacao: _LocalizacaoFalsa(_perto),
      auth: authFalso(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ValidandoAcessoView(token: 'P1.LIBERADO', controller: controller),
      ),
    );
    await tester.pump();

    expect(find.text('Verificando seu acesso…'), findsOneWidget);
    expect(find.text('QR Code lido'), findsOneWidget);

    resposta.complete(respostaDoQr('P1.LIBERADO'));
    await tester.pumpAndSettle();

    expect(find.byType(AcessoLiberadoView), findsOneWidget);
  });

  testWidgets('Liberado mostra a catraca, o caminho e os usos restantes', (
    WidgetTester tester,
  ) async {
    await _validar(tester, 'P1.LIBERADO');

    expect(find.byType(AcessoLiberadoView), findsOneWidget);
    expect(find.text('Acesso liberado'), findsOneWidget);
    expect(find.text('Pode passar pela catraca.'), findsOneWidget);
    expect(find.text('Catraca 1'), findsOneWidget);
    expect(
      find.text('FATEC Jacareí › Portaria Principal › Porta A'),
      findsOneWidget,
    );
    expect(find.text('Restam 999 usos'), findsOneWidget);
  });

  testWidgets('Voltar ao início fecha a validação sem reabrir o scanner', (
    WidgetTester tester,
  ) async {
    final respostas = await _validar(tester, 'P1.LIBERADO');

    await tester.tap(find.text('Voltar ao início'));
    await tester.pumpAndSettle();

    expect(find.byType(ValidandoAcessoView), findsNothing);
    expect(respostas, [false]);
  });

  for (final MapEntry(key: motivo, value: (titulo, oQueFazer))
      in motivosDoQr.entries) {
    if (motivo == 'LOCALIZACAO_AUSENTE') continue;
    testWidgets('$motivo mostra o acesso negado com o texto da API', (
      WidgetTester tester,
    ) async {
      await _validar(tester, 'P1.$motivo');

      expect(find.byType(AcessoNegadoView), findsOneWidget);
      expect(find.text('Acesso negado'), findsOneWidget);
      expect(find.text(titulo), findsOneWidget);
      expect(find.text(oQueFazer), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
      expect(find.text('Voltar ao início'), findsOneWidget);
    });
  }

  testWidgets('Tentar novamente fecha a validação para ler o QR de novo', (
    WidgetTester tester,
  ) async {
    final respostas = await _validar(tester, 'P1.QR_EXPIRADO');

    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(respostas, [true]);
  });

  testWidgets('Longe da catraca mostra a distância', (
    WidgetTester tester,
  ) async {
    await _validar(tester, 'P1.LONGE_DO_TERMINAL');

    expect(find.text('Você está a 1043 m da catraca.'), findsOneWidget);
  });

  testWidgets('Sem localização manda só o token e mostra a E8', (
    WidgetTester tester,
  ) async {
    final chamadas = <http.Request>[];
    final localizacao = _LocalizacaoFalsa();
    final respostas = await _validar(
      tester,
      'P1.LOCALIZACAO_AUSENTE',
      cliente: apiFalsa(chamadas: chamadas),
      localizacao: localizacao,
    );

    expect(jsonDecode(chamadas.single.body), {
      'token': 'P1.LOCALIZACAO_AUSENTE',
    });
    expect(find.text('Não conseguimos sua localização'), findsOneWidget);
    expect(
      find.text('Permita a localização no celular e tente de novo.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Permitir localização'));
    await tester.pumpAndSettle();

    expect(localizacao.pediuPermissao, isTrue);
    expect(respostas, [true]);
  });

  testWidgets('Sem internet mostra a E3 com a dica da tag NFC', (
    WidgetTester tester,
  ) async {
    final respostas = await _validar(
      tester,
      'P1.LIBERADO',
      cliente: semInternet(),
    );

    expect(find.text('Sem conexão com a internet'), findsOneWidget);
    expect(
      find.text('Sem internet, sua tag NFC continua funcionando no terminal.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(respostas, [true]);
  });

  testWidgets('Erro inesperado da API mostra a mensagem dela', (
    WidgetTester tester,
  ) async {
    final cliente = MockClient(
      (request) async =>
          erroDaApi(500, 'ERRO_INTERNO', 'Erro inesperado no servidor.'),
    );
    await _validar(tester, 'P1.LIBERADO', cliente: cliente);

    expect(find.text('Não foi possível validar'), findsOneWidget);
    expect(find.text('Erro inesperado no servidor.'), findsOneWidget);
  });

  testWidgets('Sessão vencida volta ao login e apaga a sessão', (
    WidgetTester tester,
  ) async {
    await SessaoService.instancia.iniciar(tokenFalso(), contasDemo[2]);

    await _validar(tester, qrSessaoVencida);

    expect(find.byType(LoginView), findsOneWidget);
    expect(find.byType(ValidandoAcessoView), findsNothing);
    expect(SessaoService.instancia.token, isNull);
  });

  for (final token in ['P1.LIBERADO', 'P1.LONGE_DO_TERMINAL']) {
    testWidgets('$token cabe na tela com fonte 2×', (
      WidgetTester tester,
    ) async {
      await _validar(tester, token, fonte: 2);

      expect(tester.takeException(), isNull);
      expect(find.text('Voltar ao início'), findsOneWidget);
    });
  }
}
