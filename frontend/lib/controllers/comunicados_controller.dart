import '../models/comunicado.dart';
import '../services/api_client.dart';

/// Comunicados: todo mundo logado lê; publicar e apagar são só do admin
/// (403 para os outros perfis).
class ComunicadosController {
  ComunicadosController({ApiClient? api, DateTime Function()? relogio})
    : _api = api ?? ApiClient.instancia,
      _relogio = relogio ?? DateTime.now;

  final ApiClient _api;
  final DateTime Function() _relogio;

  /// Hora do celular, para o "Hoje às 09:12".
  DateTime agora() => _relogio();

  /// GET /announcements: os mais recentes primeiro, até 50.
  Future<List<Comunicado>> listar() async {
    final lista = await _api.get('/announcements') as List<dynamic>;
    return [
      for (final json in lista)
        Comunicado.fromJson(json as Map<String, dynamic>),
    ];
  }

  /// O mais recente, para o cartão do Início. Nunca lança: sem internet,
  /// sessão vencida ou API antiga, o Início segue sem o cartão.
  Future<Comunicado?> ultimo() async {
    try {
      return (await listar()).firstOrNull;
    } on Object {
      return null;
    }
  }

  Future<Comunicado> publicar({
    required String titulo,
    required String mensagem,
  }) async {
    final json = await _api.post('/announcements', {
      'titulo': titulo,
      'mensagem': mensagem,
    });
    return Comunicado.fromJson(json as Map<String, dynamic>);
  }

  /// 404 se outra pessoa já apagou.
  Future<void> apagar(String id) => _api.delete('/announcements/$id');
}
