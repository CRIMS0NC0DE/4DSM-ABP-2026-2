import 'package:flutter_test/flutter_test.dart';

import 'package:public/main.dart';
import 'package:public/models/usuario.dart';
import 'package:public/views/admin/admin_menu_view.dart';
import 'package:public/views/resident/resident_menu_view.dart';
import 'package:public/views/user/login_view.dart';

import 'support/api_falsa.dart';

void main() {
  testWidgets('App abre na tela de login', (WidgetTester tester) async {
    await tester.pumpWidget(const PasseApp());

    expect(find.byType(LoginView), findsOneWidget);
  });

  testWidgets('Com sessão guardada, abre direto no menu do perfil', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(PasseApp(usuario: contasDemo.first));

    expect(find.byType(AdminMenuView), findsOneWidget);
    expect(find.byType(LoginView), findsNothing);
  });

  testWidgets('Visitante usa o menu do morador', (WidgetTester tester) async {
    final visitante = contasDemo.firstWhere(
      (conta) => conta.perfil == Perfil.visitante,
    );
    await tester.pumpWidget(PasseApp(usuario: visitante));

    expect(find.byType(ResidentMenuView), findsOneWidget);
  });
}
