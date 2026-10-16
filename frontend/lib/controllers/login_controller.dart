import 'package:flutter/foundation.dart';

/// Tela de login.
/// Protótipo: ainda não chama a API, só valida os campos e registra o pedido.
class LoginController {
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

  void entrar(String usuario, String senha) {
    // Lógica para autenticar na API
    debugPrint('Entrando como $usuario...');
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
