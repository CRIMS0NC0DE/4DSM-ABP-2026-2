import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

/// Tela de primeiro acesso (criar conta).
/// Protótipo: guarda a conta no AuthService, que ainda não chama a API.
/// Toda conta criada aqui é de morador.
class RegisterController {
  RegisterController({AuthService? auth})
    : _auth = auth ?? AuthService.instancia;

  final AuthService _auth;

  static const tamanhoMinimoSenha = 8;
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  String? validarNome(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Informe seu nome completo.';
    }
    return null;
  }

  /// Aceita o CPF com ou sem pontuação.
  String? validarCpf(String? valor) {
    final numeros = (valor ?? '').replaceAll(RegExp(r'\D'), '');
    if (numeros.isEmpty) return 'Informe seu CPF.';
    if (numeros.length != 11) return 'O CPF tem 11 números.';
    return null;
  }

  String? validarEmail(String? valor) {
    final email = valor?.trim() ?? '';
    if (email.isEmpty) return 'Informe seu e-mail.';
    if (!_email.hasMatch(email)) return 'E-mail inválido.';
    return null;
  }

  String? validarSenha(String? valor) {
    if ((valor ?? '').length < tamanhoMinimoSenha) {
      return 'A senha precisa ter pelo menos $tamanhoMinimoSenha caracteres.';
    }
    return null;
  }

  String? validarConfirmacao(String? valor, String senha) {
    if (valor == null || valor.isEmpty) return 'Repita a senha.';
    if (valor != senha) return 'As senhas não são iguais.';
    return null;
  }

  /// Devolve a mensagem de erro, ou null se a conta foi criada.
  String? registrar({
    required String nome,
    required String cpf,
    required String email,
    required String senha,
  }) {
    debugPrint('Registrando $nome ($email)...');
    final usuario = _auth.registrar(
      nome: nome,
      cpf: cpf,
      email: email,
      senha: senha,
    );
    if (usuario == null) return 'Já existe uma conta com esse e-mail ou CPF.';
    return null;
  }
}
