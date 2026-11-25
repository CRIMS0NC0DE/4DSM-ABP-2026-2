import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'core/routes/rotas.dart';
import 'core/theme/app_theme.dart';
import 'models/usuario.dart';
import 'services/auth_service.dart';
import 'views/user/login_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // No navegador, o leitor de QR baixaria o ZXing do unpkg.com ao abrir a
  // câmera; sem internet (rede da sala, roteador do celular sem dados) a
  // leitura falhava. A cópia em web/vendor/ vem junto com o app.
  if (kIsWeb) {
    MobileScannerPlatform.instance.setBarcodeLibraryScriptUrl(
      'vendor/zxing-library-0.23.0.min.js',
    );
  }
  // Quem já entrou e o token ainda vale abre direto na tela do perfil.
  final sessao = await AuthService.instancia.restaurar();
  runApp(PasseApp(usuario: sessao.usuario, aviso: sessao.aviso));
}

class PasseApp extends StatelessWidget {
  const PasseApp({super.key, this.usuario, this.aviso});

  /// Usuário da sessão restaurada; null abre o login.
  final Usuario? usuario;

  /// Por que a sessão guardada não vale mais (ex.: cadastro desativado).
  final String? aviso;

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
      home: usuario == null
          ? LoginView(aviso: aviso)
          : menuDoPerfil(usuario.perfil),
    );
  }
}
