import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:public/views/widgets/logo_passe.dart';
import 'package:public/views/widgets/tela_carregando.dart';

/// Tela de partida com um botão que abre o carregamento.
/// O erro relançado pela tela de carregamento vai para [onErro].
Widget _app(Future<Widget> Function() tarefa, {ValueChanged<Object>? onErro}) =>
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            try {
              await TelaCarregando.abrir(
                context,
                mensagem: 'Entrando…',
                tarefa: tarefa,
              );
            } catch (erro) {
              onErro?.call(erro);
            }
          },
          child: const Text('Abrir'),
        ),
      ),
    );

Future<void> _abrir(WidgetTester tester) async {
  await tester.tap(find.text('Abrir'));
  await tester.pump();
  // Espera o fade de entrada.
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('Mostra o logo, a barra e a mensagem enquanto espera', (
    WidgetTester tester,
  ) async {
    final resposta = Completer<Widget>();
    await tester.pumpWidget(_app(() => resposta.future));

    await _abrir(tester);

    expect(find.byType(LogoPasse), findsOneWidget);
    expect(find.text('Entrando…'), findsOneWidget);
    // A barra lê a mensagem e quanto já encheu para o leitor de tela.
    expect(find.bySemanticsLabel('Entrando…'), findsOneWidget);

    resposta.complete(const Text('Menu'));
    await tester.pumpAndSettle();
  });

  testWidgets('Ao terminar, abre a tela devolvida e limpa o histórico', (
    WidgetTester tester,
  ) async {
    final resposta = Completer<Widget>();
    await tester.pumpWidget(_app(() => resposta.future));
    await _abrir(tester);

    resposta.complete(const Text('Menu'));
    await tester.pumpAndSettle();

    expect(find.text('Menu'), findsOneWidget);
    expect(find.byType(TelaCarregando), findsNothing);
    expect(find.text('Abrir', skipOffstage: false), findsNothing);
    expect(Navigator.of(tester.element(find.text('Menu'))).canPop(), isFalse);
  });

  testWidgets('Mesmo com resposta na hora, não só pisca na tela', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_app(() async => const Text('Menu')));
    await _abrir(tester);

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(TelaCarregando), findsOneWidget);
    expect(find.text('Menu'), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text('Menu'), findsOneWidget);
  });

  testWidgets('Se a tarefa falha, volta para a tela de antes com o erro', (
    WidgetTester tester,
  ) async {
    Object? erro;
    await tester.pumpWidget(
      _app(
        () async => throw StateError('senha errada'),
        onErro: (e) => erro = e,
      ),
    );

    await _abrir(tester);
    await tester.pumpAndSettle();

    expect(erro, isA<StateError>());
    expect(find.text('Abrir'), findsOneWidget);
    expect(find.byType(TelaCarregando), findsNothing);
  });

  testWidgets('O Voltar do celular não interrompe o carregamento', (
    WidgetTester tester,
  ) async {
    final resposta = Completer<Widget>();
    await tester.pumpWidget(_app(() => resposta.future));
    await _abrir(tester);

    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(TelaCarregando), findsOneWidget);

    resposta.complete(const Text('Menu'));
    await tester.pumpAndSettle();
    expect(find.text('Menu'), findsOneWidget);
  });
}
