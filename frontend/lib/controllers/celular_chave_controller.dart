import 'package:flutter/services.dart';

import '../models/celular_nfc.dart';
import '../services/api_client.dart';
import '../services/celular_nfc_plataforma.dart';

/// Celular como chave NFC: liga a chave do Keystore ao cadastro da pessoa.
/// Depois de ativado, o celular abre a catraca encostando no leitor, como uma
/// tag, sem internet e com o app fechado (docs/documentacao-tecnica/celular-nfc.md).
class CelularChaveController {
  CelularChaveController({ApiClient? api, CelularNfcPlataforma? plataforma})
    : _api = api ?? ApiClient.instancia,
      _plataforma = plataforma ?? CelularNfcPlataforma.instancia;

  final ApiClient _api;
  final CelularNfcPlataforma _plataforma;

  Future<SituacaoCelular> carregar() async {
    final aparelho = await _plataforma.estado();
    final lista = await _api.get('/me/phones') as List<dynamic>;
    return SituacaoCelular(
      aparelho: aparelho,
      cadastrados: [
        for (final c in lista) CelularNfc.fromJson(c as Map<String, dynamic>),
      ],
    );
  }

  /// Começa sempre de uma chave nova: a antiga, se sobrou de outra ativação,
  /// para de valer, e o cadastro dela fica em "Outros celulares" para remover.
  Future<void> ativar(EstadoAparelho aparelho) async {
    await _noAparelho(_plataforma.desativar);
    final chave = await _noAparelho(_plataforma.prepararChave);
    final json = await _api.post('/me/phones', {
      'nome': aparelho.modelo,
      'chavePublica': chave,
    }) as Map<String, dynamic>;
    await _noAparelho(() => _plataforma.ativar(json['id'] as String));
  }

  /// Tira o cadastro da API e apaga a chave do aparelho.
  Future<void> desativar(String celularId) async {
    try {
      await _api.delete('/me/phones/$celularId');
    } on ApiException catch (e) {
      // Já tinha sido removido (por outro aparelho, por exemplo): segue e apaga a chave.
      if (e.status != 404) rethrow;
    }
    await _noAparelho(_plataforma.desativar);
  }

  /// Outro aparelho da pessoa, que ficou na lista.
  Future<void> remover(String celularId) =>
      _api.delete('/me/phones/$celularId');

  /// Sem a tela de ajustes (alguns aparelhos não têm), o aviso só continua na tela.
  Future<void> abrirAjustesNfc() async {
    try {
      await _plataforma.abrirAjustesNfc();
    } on PlatformException {
      // nada a fazer
    } on MissingPluginException {
      // nada a fazer
    }
  }

  /// Erro do Keystore ou do canal vira [ApiException], que a tela já sabe mostrar.
  Future<T> _noAparelho<T>(Future<T> Function() acao) async {
    try {
      return await acao();
    } on PlatformException catch (e) {
      throw ApiException(
        'O celular não conseguiu usar a chave (${e.message ?? e.code}). '
        'Tente de novo.',
      );
    } on MissingPluginException {
      throw const ApiException(
        'Esta versão do app não tem o celular como chave. Atualize o app.',
      );
    }
  }
}
