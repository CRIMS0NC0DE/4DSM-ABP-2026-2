import 'package:flutter_test/flutter_test.dart';

import 'package:public/main.dart';
import 'package:public/models/usuario.dart';
import 'package:public/views/teams/admin/admin_menu_view.dart';
import 'package:public/views/user/inicio_view.dart';
import 'package:public/views/user/login_view.dart';

import 'support/api_falsa.dart';

void main() {
  testWidgets('App abre na tela de login', (WidgetTester tester) async {
    await tester.pumpWidget(const PasseApp());

    expect(find.byType(LoginView), findsOneWidget);
  });

  testWidgets('Sessão que não vale mais abre o login explicando o motivo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PasseApp(aviso: 'Cadastro desativado.'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginView), findsOneWidget);
    expect(find.text('Cadastro desativado.'), findsOneWidget);
  });

  testWidgets('Com sessão guardada, abre direto no menu do perfil', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(PasseApp(usuario: contasDemo.first));

    expect(find.byType(AdminMenuView), findsOneWidget);
    expect(find.byType(LoginView), findsNothing);
  });

  testWidgets('Visitante abre o Início', (WidgetTester tester) async {
    final visitante = contasDemo.firstWhere(
      (conta) => conta.perfil == Perfil.visitante,
    );
    await tester.pumpWidget(PasseApp(usuario: visitante));

    expect(find.byType(InicioView), findsOneWidget);
  });
}
