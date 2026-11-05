import '../models/local.dart';
import '../models/painel.dart';
import '../services/api_client.dart';

/// A1 · Painel: os números do GET /dashboard e o nome do prédio.
class PainelController {
  PainelController({ApiClient? api}) : _api = api ?? ApiClient.instancia;

  final ApiClient _api;

  Future<({Painel painel, String? predio})> carregar() async {
    final [painel, locais] = await Future.wait([
      _api.get('/dashboard'),
      _api.get('/locations'),
    ]);
    final edificios = locais as List<dynamic>;
    return (
      painel: Painel.fromJson(painel as Map<String, dynamic>),
      predio: edificios.isEmpty
          ? null
          : Edificio.fromJson(edificios.first as Map<String, dynamic>).nome,
    );
  }
}
