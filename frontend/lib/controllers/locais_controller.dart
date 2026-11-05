import '../models/local.dart';
import '../services/api_client.dart';

/// Edifício › portaria › porta › catraca (RF02): A5 e A6. Criar e editar são
/// só do admin. Editar ou apagar edifício, portaria e porta ainda não existe
/// na API (B5 do backlog); só a catraca tem PATCH.
class LocaisController {
  LocaisController({ApiClient? api}) : _api = api ?? ApiClient.instancia;

  final ApiClient _api;

  Future<List<Edificio>> arvore() async {
    final lista = await _api.get('/locations') as List<dynamic>;
    return [
      for (final json in lista)
        Edificio.fromJson(json as Map<String, dynamic>),
    ];
  }

  Future<void> criarEdificio(String nome, String endereco) => _api.post(
    '/locations/buildings',
    {'nome': nome, 'endereco': endereco},
  );

  Future<void> criarPortaria(String nome, String edificioId) => _api.post(
    '/locations/gates',
    {'nome': nome, 'buildingId': edificioId},
  );

  Future<void> criarPorta(String nome, String portariaId) =>
      _api.post('/locations/doors', {'nome': nome, 'gateId': portariaId});

  Future<void> criarCatraca({
    required String nome,
    required String portaId,
    required double latitude,
    required double longitude,
    required int raioMetros,
  }) => _api.post('/locations/access-points', {
    'nome': nome,
    'doorId': portaId,
    'latitude': latitude,
    'longitude': longitude,
    'raioMetros': raioMetros,
  });

  Future<void> atualizarCatraca(
    String id, {
    required String nome,
    required double latitude,
    required double longitude,
    required int raioMetros,
  }) => _api.patch('/locations/access-points/$id', {
    'nome': nome,
    'latitude': latitude,
    'longitude': longitude,
    'raioMetros': raioMetros,
  });
}
