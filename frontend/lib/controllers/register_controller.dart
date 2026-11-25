import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

/// Tela de pedido de cadastro (POST /auth/register). O cadastro nasce
/// desativado: a portaria libera o acesso em Usuários, e só então a pessoa
/// consegue entrar.
class RegisterController {
  RegisterController({AuthService? auth})
    : _auth = auth ?? AuthService.instancia;

  final AuthService _auth;

  // Mesmas regras da rota de cadastro do backend.
  static const tamanhoMinimoNome = 3;
  static const tamanhoMinimoSenha = 6;
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  String? validarNome(String? valor) {
    final nome = valor?.trim() ?? '';
    if (nome.isEmpty) return 'Informe seu nome completo.';
    if (nome.length < tamanhoMinimoNome) {
      return 'O nome precisa ter pelo menos $tamanhoMinimoNome letras.';
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

  /// Envia o pedido e devolve a mensagem para a tela, ex.: "Pedido enviado.
  /// A portaria vai liberar seu acesso.". Lança ApiException com a mensagem
  /// da API (e-mail ou CPF já cadastrado, campos inválidos, sem conexão).
  Future<String> registrar({
    required String nome,
    required String cpf,
    required String email,
    required String senha,
  }) {
    debugPrint('Enviando pedido de cadastro de $email...');
    return _auth.registrar(nome: nome, cpf: cpf, email: email, senha: senha);
  }
}
