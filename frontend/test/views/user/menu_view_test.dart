import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:public/views/admin/admin_menu_view.dart';

void main() {
  testWidgets('Verifica se todos os botões do menu são exibidos na tela', (
    WidgetTester tester,
  ) async {
    // Renderiza o Widget dentro do ambiente de teste
    await tester.pumpWidget(MaterialApp(home: AdminMenuView()));

    // Verifica a presença dos botões pelo texto
    expect(find.text('1. Entrar'), findsOneWidget);
    expect(find.text('2. Registrar'), findsOneWidget);
    expect(find.text('3. Criar conta'), findsOneWidget);
    expect(find.text('4. Fechar'), findsOneWidget);
  });

  testWidgets('Simula o clique no botão Entrar', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: AdminMenuView()));

    // Toca no botão '1. Entrar'
    await tester.tap(find.text('1. Entrar'));
    await tester.pump();

    // O teste passa se o clique for executado sem lançar exceções
  });
}
