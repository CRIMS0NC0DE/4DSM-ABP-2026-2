import 'package:flutter_test/flutter_test.dart';

import 'package:public/main.dart';
import 'package:public/views/user/login_view.dart';

void main() {
  testWidgets('App abre na tela de login', (WidgetTester tester) async {
    await tester.pumpWidget(const PasseApp());

    expect(find.byType(LoginView), findsOneWidget);
  });
}
