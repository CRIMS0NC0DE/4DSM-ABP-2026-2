import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/routes/rotas.dart';
import 'core/theme/app_theme.dart';
import 'models/usuario.dart';
import 'services/sessao_service.dart';
import 'views/user/login_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Quem já entrou e o token ainda vale abre direto no menu do perfil.
  final usuario = await SessaoService.instancia.restaurar();
  runApp(PasseApp(usuario: usuario));
}

class PasseApp extends StatelessWidget {
  const PasseApp({super.key, this.usuario});

  /// Usuário da sessão restaurada; null abre o login.
  final Usuario? usuario;

  @override
  Widget build(BuildContext context) {
    final usuario = this.usuario;
    return MaterialApp(
      title: 'Passe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Segue o modo claro/escuro escolhido no celular.
      themeMode: ThemeMode.system,
      // Ícones da barra de status legíveis nas telas sem AppBar
      // (login e menus).
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: child!,
      ),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      // CORREÇÃO AQUI: Lista explícita dos delegados de localização
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: usuario == null ? LoginView() : menuDoPerfil(usuario.perfil),
    );
  }
}
