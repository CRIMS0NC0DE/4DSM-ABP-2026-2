import '../models/configuracoes.dart';
import '../services/api_client.dart';

/// Configurações do condomínio: todo mundo logado lê (a Ajuda mostra o
/// contato da portaria); só o admin muda (403 para os outros perfis).
class ConfiguracoesController {
  ConfiguracoesController({ApiClient? api}) : _api = api ?? ApiClient.instancia;

  final ApiClient _api;

  Future<Configuracoes> carregar() async {
    final json = await _api.get('/settings');
    return Configuracoes.fromJson(json as Map<String, dynamic>);
  }

  /// Para a Ajuda: o contato da portaria, ou null se não deu para buscar.
  /// Nunca lança, para a Ajuda funcionar sem internet.
  Future<String?> contatoPortaria() async {
    try {
      final contato = (await carregar()).contatoPortaria.trim();
      return contato.isEmpty ? null : contato;
    } on Object {
      return null;
    }
  }

  /// PATCH /settings: manda só os campos informados e devolve tudo, já salvo.
  Future<Configuracoes> salvar({
    String? nomeCondominio,
    String? contatoPortaria,
    bool? moradorPodeConvidar,
    int? visitanteMaxUsos,
    int? visitanteDiasMax,
  }) async {
    final json = await _api.patch('/settings', {
      'nomeCondominio': ?nomeCondominio,
      'contatoPortaria': ?contatoPortaria,
      'moradorPodeConvidar': ?moradorPodeConvidar,
      'visitanteMaxUsos': ?visitanteMaxUsos,
      'visitanteDiasMax': ?visitanteDiasMax,
    });
    return Configuracoes.fromJson(json as Map<String, dynamic>);
  }
}
