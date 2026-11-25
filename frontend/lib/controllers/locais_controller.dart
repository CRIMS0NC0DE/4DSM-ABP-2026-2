import '../models/local.dart';
import '../models/usuario.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

/// Edifício › portaria › porta › catraca (RF02): A5 e A6. A equipe consulta;
/// criar, editar e apagar são só do admin (403 para a portaria).
class LocaisController {
  LocaisController({ApiClient? api, AuthService? auth})
    : _api = api ?? ApiClient.instancia,
      _auth = auth ?? AuthService.instancia;

  final ApiClient _api;
  final AuthService _auth;

  bool get podeGerenciar => _auth.usuario?.perfil == Perfil.admin;

  Future<List<Edificio>> arvore() async {
    final lista = await _api.get('/locations') as List<dynamic>;
    return [
      for (final json in lista) Edificio.fromJson(json as Map<String, dynamic>),
    ];
  }

  Future<void> criarEdificio(String nome, String endereco) =>
      _api.post('/locations/buildings', {'nome': nome, 'endereco': endereco});

  Future<void> criarPortaria(String nome, String edificioId) =>
      _api.post('/locations/gates', {'nome': nome, 'buildingId': edificioId});

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

  Future<void> editarEdificio(
    String id, {
    required String nome,
    required String endereco,
  }) => _api.patch('/locations/buildings/$id', {
    'nome': nome,
    'endereco': endereco,
  });

  Future<void> editarPortaria(String id, String nome) =>
      _api.patch('/locations/gates/$id', {'nome': nome});

  Future<void> editarPorta(String id, String nome) =>
      _api.patch('/locations/doors/$id', {'nome': nome});

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

  // Apagar: a API só deixa apagar o nível vazio. Com filhos (ou, na catraca,
  // com terminal ou autorizações) responde 409 explicando o que tirar antes.
  // O histórico de acessos nunca é apagado.

  Future<void> apagarEdificio(String id) =>
      _api.delete('/locations/buildings/$id');

  Future<void> apagarPortaria(String id) => _api.delete('/locations/gates/$id');

  Future<void> apagarPorta(String id) => _api.delete('/locations/doors/$id');

  Future<void> apagarCatraca(String id) =>
      _api.delete('/locations/access-points/$id');
}
