import '../models/local.dart';
import '../models/terminal.dart';
import '../models/usuario.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

typedef DadosTerminais = ({
  List<Terminal> terminais,
  List<CatracaNoLocal> catracas,
});

/// Terminais das catracas. A equipe consulta; cadastrar e trocar a chave são
/// só do admin (403 para a portaria).
class TerminaisController {
  TerminaisController({ApiClient? api, AuthService? auth})
    : _api = api ?? ApiClient.instancia,
      _auth = auth ?? AuthService.instancia;

  final ApiClient _api;
  final AuthService _auth;

  bool get podeGerenciar => _auth.usuario?.perfil == Perfil.admin;

  /// GET /terminals só traz o accessPointId: cruza com GET /locations para
  /// mostrar o nome da catraca.
  Future<DadosTerminais> carregar() async {
    final [terminais, locais] = await Future.wait([
      _api.get('/terminals'),
      _api.get('/locations'),
    ]);
    return (
      terminais: [
        for (final json in terminais as List<dynamic>)
          Terminal.fromJson(json as Map<String, dynamic>),
      ],
      catracas: catracasDe([
        for (final json in locais as List<dynamic>)
          Edificio.fromJson(json as Map<String, dynamic>),
      ]),
    );
  }

  /// A resposta traz a [Terminal.chave], que só aparece desta vez. Uma catraca
  /// só tem um terminal (409).
  Future<Terminal> cadastrar(String nome, String catracaId) async {
    final json = await _api.post('/terminals', {
      'nome': nome,
      'accessPointId': catracaId,
    });
    return Terminal.fromJson(json as Map<String, dynamic>);
  }

  /// A chave antiga para de funcionar: grave a nova no firmware e no broker.
  Future<Terminal> trocarChave(String id) async {
    final json = await _api.post('/terminals/$id/rotate-key');
    return Terminal.fromJson(json as Map<String, dynamic>);
  }
}
