import 'package:flutter/foundation.dart';

import '../models/decisao_acesso.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/localizacao_service.dart';

/// Entrada pelo QR da catraca (telas U3 a U6). O QR traz o token assinado
/// que o terminal mostra; o app manda o token e a posição para a API decidir.
class AcessoQrController {
  AcessoQrController({
    ApiClient? api,
    LocalizacaoService? localizacao,
    AuthService? auth,
  }) : _api = api ?? ApiClient.instancia,
       _localizacao = localizacao ?? LocalizacaoService.instancia,
       _auth = auth ?? AuthService.instancia;

  final ApiClient _api;
  final LocalizacaoService _localizacao;
  final AuthService _auth;

  /// Mesmos limites do qrSchema do backend (access.controller.ts). Fora
  /// deles a API responde 400, então nem é QR de uma catraca.
  bool qrDaCatraca(String texto) => texto.length >= 10 && texto.length <= 2000;

  /// RF13 · POST /access/qr. Pega a posição antes de enviar; sem ela, manda
  /// só o token e a API nega com LOCALIZACAO_AUSENTE (tela E8).
  /// Lança [ApiException] sem conexão (E3) ou com a sessão vencida (401).
  Future<DecisaoAcesso> validar(String token) async {
    final posicao = await _localizacao.posicaoAtual();
    debugPrint('Validando QR ${posicao == null ? 'sem' : 'com'} posição...');
    final resposta = await _api.post('/access/qr', {
      'token': token,
      if (posicao != null) ...{
        'latitude': posicao.latitude,
        'longitude': posicao.longitude,
      },
    });
    return DecisaoAcesso.fromJson(resposta as Map<String, dynamic>);
  }

  Future<void> permitirLocalizacao() => _localizacao.permitir();

  Future<void> abrirConfiguracoes() => _localizacao.abrirConfiguracoesDoApp();

  /// Sessão vencida: esquece o token, como o Sair dos menus.
  Future<void> sair() => _auth.sair();
}
