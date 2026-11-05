import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:public/controllers/minhas_autorizacoes_controller.dart';
import 'package:public/core/theme/app_theme.dart';
import 'package:public/services/api_client.dart';
import 'package:public/services/sessao_service.dart';
import 'package:public/views/user/detalhe_autorizacao_view.dart';
import 'package:public/views/user/login_view.dart';
import 'package:public/views/user/minhas_autorizacoes_view.dart';
import 'package:public/views/user/scanner_qr_view.dart';

import '../../support/api_falsa.dart';

/// 14/10/2026, às 9:41, como no design.
final _agora = DateTime(2026, 10, 14, 9, 41);

MinhasAutorizacoesController _controller(http.Client cliente) =>
    MinhasAutorizacoesController(
      api: ApiClient(cliente: cliente),
      auth: authFalso(),
      relogio: () => _agora,
    );

/// Catraca com outro nome, para achar cada cartão na lista.
Map<String, Object?> _catraca(String nome) => {
  ...catracaAutorizadaDemo,
  'nome': nome,
};

/// Abre a U7 por cima de outra tela, como o menu faz.
Future<void> _abrir(
  WidgetTester tester, {
  http.Client? cliente,
  double fonte = 1,
  ThemeData? tema,
}) async {
  final controller = _controller(cliente ?? apiFalsa());
  await tester.pumpWidget(
    MaterialApp(
      theme: tema,
      builder: (context, tela) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(fonte)),
        child: tela!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      MinhasAutorizacoesView(controller: controller),
                ),
              ),
              child: const Text('Menu'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Menu'));
  await tester.pumpAndSettle();
}

Future<void> _verDetalhes(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Ver detalhes').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Ver detalhes').first);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await SessaoService.instancia.encerrar();
  });

  testWidgets('Enquanto a API responde, mostra o carregando (E3)', (
    WidgetTester tester,
  ) async {
    final resposta = Completer<http.Response>();
    final controller = _controller(MockClient((_) => resposta.future));
    await tester.pumpWidget(
      MaterialApp(home: MinhasAutorizacoesView(controller: controller)),
    );
    await tester.pump();

    expect(find.text('Minhas autorizações'), findsOneWidget);
    expect(find.text('Carregando suas autorizações…'), findsOneWidget);

    resposta.complete(respostaJson([autorizacaoJson()], 200));
    await tester.pumpAndSettle();

    expect(find.text('Carregando suas autorizações…'), findsNothing);
    expect(find.text('Catraca 1'), findsOneWidget);
  });

  testWidgets('O cartão mostra local, período, horário e usos (U7)', (
    WidgetTester tester,
  ) async {
    await _abrir(tester);

    expect(find.text('Onde e quando você pode entrar'), findsOneWidget);
    expect(find.text('Ativas'), findsOneWidget);
    expect(find.text('Encerradas'), findsNothing);
    expect(find.text('Catraca 1'), findsOneWidget);
    expect(find.text('FATEC Jacareí'), findsOneWidget);
    expect(find.text('Ativa'), findsOneWidget);
    expect(find.text('01/10 a 31/10/2026'), findsOneWidget);
    expect(find.text('Das 08:00 às 18:00'), findsOneWidget);
    expect(find.text('3 de 10 usos restantes'), findsOneWidget);
    expect(find.text('Ver detalhes'), findsOneWidget);
  });

  testWidgets('Separa Ativas e Encerradas, cada uma com o seu selo', (
    WidgetTester tester,
  ) async {
    await _abrir(
      tester,
      cliente: apiFalsa(
        autorizacoes: [
          autorizacaoJson(
            id: 'a1',
            situacao: 'AGENDADA',
            catraca: _catraca('Catraca Agendada'),
          ),
          autorizacaoJson(
            id: 'a2',
            situacao: 'EXPIRADA',
            catraca: _catraca('Catraca Expirada'),
          ),
          autorizacaoJson(id: 'a3', catraca: _catraca('Catraca Ativa')),
          autorizacaoJson(
            id: 'a4',
            situacao: 'CANCELADA',
            catraca: _catraca('Catraca Cancelada'),
          ),
          autorizacaoJson(
            id: 'a5',
            situacao: 'ESGOTADA',
            usosRestantes: 0,
            catraca: _catraca('Catraca Esgotada'),
          ),
        ],
      ),
    );

    const ordem = [
      'Ativas',
      'Catraca Ativa',
      'Catraca Agendada',
      'Encerradas',
      'Catraca Expirada',
      'Catraca Cancelada',
      'Catraca Esgotada',
    ];
    final alturas = [
      for (final texto in ordem) tester.getTopLeft(find.text(texto)).dy,
    ];
    expect(alturas, [...alturas]..sort());
    for (final selo in ['Ativa', 'Agendada', 'Expirada', 'Cancelada']) {
      expect(find.text(selo), findsOneWidget);
    }
    expect(find.text('Sem usos'), findsOneWidget);
  });

  testWidgets('Um dia só, hoje, com o último uso em destaque', (
    WidgetTester tester,
  ) async {
    await _abrir(
      tester,
      cliente: apiFalsa(
        autorizacoes: [
          autorizacaoJson(
            dataInicio: '2026-10-14',
            dataFim: '2026-10-14',
            horaInicio: '14:00',
            horaFim: '16:00',
            maxUsos: 1,
            usosRestantes: 1,
          ),
        ],
      ),
    );

    expect(find.text('Somente hoje, 14/10'), findsOneWidget);
    expect(find.text('Das 14:00 às 16:00'), findsOneWidget);
    expect(find.text('Último uso disponível'), findsOneWidget);
    expect(find.text('1 de 1 uso restante'), findsNothing);
  });

  testWidgets('Só encerradas: avisa que nenhuma vale agora', (
    WidgetTester tester,
  ) async {
    await _abrir(
      tester,
      cliente: apiFalsa(autorizacoes: [autorizacaoJson(situacao: 'EXPIRADA')]),
    );

    expect(find.text('Ativas'), findsOneWidget);
    expect(
      find.text(
        'Nenhuma autorização vale agora. Se precisar entrar, peça uma nova '
        'à portaria.',
      ),
      findsOneWidget,
    );
    expect(find.text('Encerradas'), findsOneWidget);
  });

  testWidgets('Sem autorizações mostra o vazio (E4); Atualizar busca de novo', (
    WidgetTester tester,
  ) async {
    final chamadas = <http.Request>[];
    await _abrir(
      tester,
      cliente: apiFalsa(chamadas: chamadas, autorizacoes: []),
    );

    expect(find.text('Você ainda não tem autorizações'), findsOneWidget);
    expect(
      find.text('Quando a portaria liberar seu acesso, ele aparece aqui.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Atualizar'));
    await tester.pumpAndSettle();

    expect(chamadas, hasLength(2));
  });

  testWidgets('Sem internet avisa na tela e Tentar novamente carrega', (
    WidgetTester tester,
  ) async {
    var online = false;
    final cliente = MockClient((request) async {
      if (!online) throw http.ClientException('offline');
      return respostaJson([autorizacaoJson()], 200);
    });
    await _abrir(tester, cliente: cliente);

    expect(find.text('Minhas autorizações'), findsOneWidget);
    expect(find.text('Sem conexão com a internet'), findsOneWidget);
    expect(
      find.text(
        'Confira o Wi-Fi ou os dados móveis do celular e tente de novo.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Sem internet, sua tag NFC continua funcionando no terminal.'),
      findsOneWidget,
    );

    online = true;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.text('Sem conexão com a internet'), findsNothing);
    expect(find.text('Catraca 1'), findsOneWidget);
  });

  testWidgets('Erro do servidor mostra a mensagem da API', (
    WidgetTester tester,
  ) async {
    final cliente = MockClient(
      (request) async =>
          erroDaApi(500, 'ERRO_INTERNO', 'Erro inesperado no servidor.'),
    );
    await _abrir(tester, cliente: cliente);

    expect(find.text('Não foi possível carregar'), findsOneWidget);
    expect(find.text('Erro inesperado no servidor.'), findsOneWidget);
    expect(
      find.text('Sem internet, sua tag NFC continua funcionando no terminal.'),
      findsNothing,
    );
  });

  testWidgets('Sessão vencida volta ao login e apaga a sessão', (
    WidgetTester tester,
  ) async {
    await SessaoService.instancia.iniciar(tokenFalso(), contasDemo[2]);
    final cliente = MockClient(
      (request) async => erroDaApi(
        401,
        'NAO_AUTENTICADO',
        'Sessão inválida ou expirada. Entre de novo.',
      ),
    );
    await _abrir(tester, cliente: cliente);

    expect(find.byType(LoginView), findsOneWidget);
    expect(find.byType(MinhasAutorizacoesView), findsNothing);
    expect(SessaoService.instancia.token, isNull);
  });

  testWidgets('Puxar para atualizar sem internet avisa e mantém a lista', (
    WidgetTester tester,
  ) async {
    var chamadas = 0;
    final cliente = MockClient((request) async {
      chamadas++;
      if (chamadas > 1) throw http.ClientException('offline');
      return respostaJson([autorizacaoJson()], 200);
    });
    await _abrir(tester, cliente: cliente);

    await tester.fling(
      find.text('Minhas autorizações'),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();

    expect(chamadas, 2);
    expect(find.text('Catraca 1'), findsOneWidget);
    expect(
      find.text(
        'Não foi possível falar com o servidor. '
        'Confira a internet e tente de novo.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Ver detalhes abre a U8 com onde, período, horário e usos', (
    WidgetTester tester,
  ) async {
    await _abrir(tester);
    await _verDetalhes(tester);

    expect(find.byType(DetalheAutorizacaoView), findsOneWidget);
    expect(find.text('Catraca 1'), findsOneWidget);
    expect(find.text('FATEC Jacareí'), findsOneWidget);
    expect(find.text('Ativa'), findsOneWidget);
    expect(find.text('Você pode entrar hoje até 18:00.'), findsOneWidget);
    expect(find.text('Onde'), findsOneWidget);
    expect(
      find.text('Portaria Principal › Porta A › Catraca 1'),
      findsOneWidget,
    );
    expect(find.text('Período'), findsOneWidget);
    expect(find.text('01/10/2026 a 31/10/2026'), findsOneWidget);
    expect(find.text('Horário'), findsOneWidget);
    expect(find.text('Das 08:00 às 18:00'), findsOneWidget);
    expect(find.text('Usos'), findsOneWidget);
    expect(find.text('3 de 10 restantes'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Como passar'), findsOneWidget);
    expect(find.text('Escanear QR Code'), findsOneWidget);
  });

  testWidgets('Escanear QR Code na U8 abre o scanner', (
    WidgetTester tester,
  ) async {
    await _abrir(tester);
    await _verDetalhes(tester);

    await tester.tap(find.text('Escanear QR Code'));
    await tester.pumpAndSettle();

    expect(find.byType(ScannerQrView), findsOneWidget);
  });

  testWidgets('Autorização encerrada não mostra como passar nem o scanner', (
    WidgetTester tester,
  ) async {
    await _abrir(
      tester,
      cliente: apiFalsa(
        autorizacoes: [
          autorizacaoJson(
            situacao: 'CANCELADA',
            canceladaEm: '2026-10-12T15:00:00.000Z',
          ),
        ],
      ),
    );
    await _verDetalhes(tester);

    expect(find.text('Cancelada'), findsOneWidget);
    expect(
      find.text('A portaria cancelou esta autorização em 12/10/2026.'),
      findsOneWidget,
    );
    expect(find.text('Como passar'), findsNothing);
    expect(find.text('Escanear QR Code'), findsNothing);
  });

  testWidgets('Ao voltar da U8, a lista recarrega com os usos novos', (
    WidgetTester tester,
  ) async {
    var restantes = 3;
    final cliente = MockClient(
      (request) async =>
          respostaJson([autorizacaoJson(usosRestantes: restantes)], 200),
    );
    await _abrir(tester, cliente: cliente);
    await _verDetalhes(tester);

    // Passou pela catraca enquanto estava na U8.
    restantes = 2;
    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();

    expect(find.byType(DetalheAutorizacaoView), findsNothing);
    expect(find.text('2 de 10 usos restantes'), findsOneWidget);
  });

  for (final escuro in [false, true]) {
    testWidgets(
      'U7 e U8 cabem com fonte 2× (modo ${escuro ? 'escuro' : 'claro'})',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await _abrir(
          tester,
          fonte: 2,
          tema: escuro ? AppTheme.dark : AppTheme.light,
          cliente: apiFalsa(
            autorizacoes: [
              autorizacaoJson(maxUsos: 1, usosRestantes: 1),
              autorizacaoJson(id: 'a2', situacao: 'ESGOTADA', usosRestantes: 0),
            ],
          ),
        );
        expect(tester.takeException(), isNull);

        await _verDetalhes(tester);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('O aviso de sem internet cabe com fonte 2×', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _abrir(tester, fonte: 2, cliente: semInternet());

    expect(find.text('Sem conexão com a internet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
