import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'views/user/login_view.dart';

void main() {
  runApp(const PasseApp());
}

class PasseApp extends StatelessWidget {
  const PasseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Passe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Textos dos componentes do Flutter (datas, "Voltar", copiar/colar) em português.
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const LoginView(),
    );
  }
}
