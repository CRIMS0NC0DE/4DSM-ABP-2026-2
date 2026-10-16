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
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      // CORREÇÃO AQUI: Lista explícita dos delegados de localização
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: LoginView(),
    );
  }
}
