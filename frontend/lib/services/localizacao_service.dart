import 'package:geolocator/geolocator.dart';

typedef Posicao = ({double latitude, double longitude});

/// Posição do celular, para a API conferir se a pessoa está perto da
/// catraca (RF13: até 100 m, por padrão).
class LocalizacaoService {
  LocalizacaoService();

  /// O mesmo para o app inteiro.
  static final instancia = LocalizacaoService();

  /// Pede a permissão se ainda não pediu. Devolve null sem permissão, com o
  /// GPS desligado ou se passar de [limite]: o QR vale só 30 s, então não dá
  /// para esperar muito. Sem posição, a API nega com LOCALIZACAO_AUSENTE.
  Future<Posicao?> posicaoAtual({
    Duration limite = const Duration(seconds: 8),
  }) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }
      if (permissao == LocationPermission.denied ||
          permissao == LocationPermission.deniedForever) {
        return null;
      }
      final posicao = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: limite,
        ),
      );
      return (latitude: posicao.latitude, longitude: posicao.longitude);
    } on Exception {
      // Tempo esgotado, permissão sendo pedida em outro lugar, etc.
      return null;
    }
  }

  /// "Permitir localização" (E8): pede de novo quando o celular ainda deixa;
  /// senão abre as configurações (GPS desligado ou permissão negada de vez).
  Future<void> permitir() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      return;
    }
    final permissao = await Geolocator.requestPermission();
    if (permissao == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
    }
  }

  /// Configurações do app no celular, onde ficam as permissões de câmera e
  /// localização ("Abrir configurações" da E7).
  Future<void> abrirConfiguracoesDoApp() => Geolocator.openAppSettings();
}
