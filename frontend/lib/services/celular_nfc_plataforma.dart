import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/celular_nfc.dart';

/// Ponte com o Android para o "celular como chave". A chave fica no Keystore
/// (ChaveCelular.kt) e quem responde ao terminal é o PasseHceService.kt, mesmo
/// com o app fechado. No iPhone e na web não existe: lá, [estado] diz que não
/// tem suporte e o resto não é chamado.
class CelularNfcPlataforma {
  CelularNfcPlataforma();

  /// O mesmo para o app inteiro.
  static final instancia = CelularNfcPlataforma();

  static const _canal = MethodChannel('passe/celular_nfc');

  bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<EstadoAparelho> estado() async {
    if (!_android) return EstadoAparelho.semSuporte;
    final Map<String, Object?> m;
    try {
      m = await _canal.invokeMapMethod<String, Object?>('estado') ?? {};
    } on MissingPluginException {
      // Build sem o código nativo do canal: trata como aparelho sem suporte.
      return EstadoAparelho.semSuporte;
    } on PlatformException {
      return EstadoAparelho.semSuporte;
    }
    return EstadoAparelho(
      suportado: m['suportado'] == true,
      nfcLigado: m['nfcLigado'] == true,
      celularId: m['celularId'] as String?,
      modelo: m['modelo'] as String? ?? 'Celular Android',
    );
  }

  /// Cria o par de chaves (se ainda não existe) e devolve a pública, em base64.
  Future<String> prepararChave() async =>
      (await _canal.invokeMethod<String>('prepararChave'))!;

  /// Guarda no aparelho o id que a API deu: é ele que o celular manda ao terminal.
  Future<void> ativar(String celularId) =>
      _canal.invokeMethod('ativar', {'celularId': celularId});

  /// Apaga a chave e o id: o celular para de responder ao terminal.
  Future<void> desativar() => _canal.invokeMethod('desativar');

  Future<void> abrirAjustesNfc() => _canal.invokeMethod('abrirAjustesNfc');
}
