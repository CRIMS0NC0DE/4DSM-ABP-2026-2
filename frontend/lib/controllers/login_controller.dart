import 'package:flutter/foundation.dart';

import '../models/usuario.dart';
import '../services/auth_service.dart';
import 'register_controller.dart';

/// Tela de login. Entra pela API (POST /auth/login).
class LoginController {
  LoginController({AuthService? auth}) : _auth = auth ?? AuthService.instancia;

  final AuthService _auth;

  // Mesmas regras do loginSchema do backend (auth.controller.ts).
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

  /// Devolve quem entrou; o perfil diz qual menu abrir.
  /// Lança ApiException com a mensagem para a tela (senha errada,
  /// cadastro desativado ou sem conexão).
  Future<Usuario> entrar(String usuario, String senha) {
    debugPrint('Entrando como $usuario...');
    return _auth.entrar(usuario, senha);
  }

  void esqueciSenha() {
    // Sem rota na API: a portaria troca a senha (PATCH /users/:id).
    debugPrint('Esqueci minha senha...');
  }

  /// Abre o pedido de cadastro (POST /auth/register). Não existe login por
  /// NFC: a tag funciona direto na catraca, sem o app.
  void registrar() {
    debugPrint('Abrindo o pedido de cadastro...');
  }

  /// Controller da tela de cadastro, com a mesma API do login.
  RegisterController cadastro() => RegisterController(auth: _auth);
}
