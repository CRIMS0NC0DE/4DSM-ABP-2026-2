import 'package:flutter/foundation.dart';

import '../models/usuario.dart';
import '../services/auth_service.dart';

/// Tela de login.
/// Protótipo: confere as contas do AuthService, que ainda não chama a API.
class LoginController {
  LoginController({AuthService? auth}) : _auth = auth ?? AuthService.instancia;

  final AuthService _auth;

  String? validarUsuario(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Informe seu e-mail ou CPF.';
    }
    return null;
  }

  String? validarSenha(String? valor) {
    if (valor == null || valor.isEmpty) return 'Informe sua senha.';
    return null;
  }

  /// Devolve quem entrou, ou null se o e-mail/CPF ou a senha estiverem errados.
  /// O perfil do usuário diz qual menu abrir.
  Usuario? entrar(String usuario, String senha) {
    debugPrint('Entrando como $usuario...');
    return _auth.entrar(usuario, senha);
  }

  void entrarComNfc() {
    // Lógica para ler a tag NFC
    debugPrint('Entrando com NFC...');
  }

  void esqueciSenha() {
    debugPrint('Esqueci minha senha...');
  }

  void registrar() {
    debugPrint('Navegando para a tela de Registrar...');
  }
}
