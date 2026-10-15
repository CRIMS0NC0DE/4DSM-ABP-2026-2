import 'package:flutter_test/flutter_test.dart';

import 'package:public/main.dart';
import 'package:public/views/admin/admin_menu_view.dart';

void main() {
  testWidgets('App abre na tela de menu', (WidgetTester tester) async {
    await tester.pumpWidget(const PasseApp());

    expect(find.byType(AdminMenuView), findsOneWidget);
  });
}
