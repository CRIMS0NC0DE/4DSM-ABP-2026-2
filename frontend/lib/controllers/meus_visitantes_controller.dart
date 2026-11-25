import '../core/constants/formato.dart';
import '../models/meu_visitante.dart';
import '../services/api_client.dart';

/// Meus visitantes (só para o condômino): quem o morador convidou, o
/// formulário de convite e o cancelamento. Rotas /me/visitors.
class MeusVisitantesController {
  MeusVisitantesController({ApiClient? api, DateTime Function()? relogio})
    : _api = api ?? ApiClient.instancia,
      _relogio = relogio ?? DateTime.now;

  final ApiClient _api;
  final DateTime Function() _relogio;

  /// Hoje, sem a hora: o convite não pode começar antes.
  DateTime hoje() {
    final agora = _relogio();
    return DateTime(agora.year, agora.month, agora.day);
  }

  /// GET /me/visitors: os convites que eu criei, mais recentes primeiro.
  Future<List<MeuVisitante>> listar() async {
    final lista = await _api.get('/me/visitors');
    return _ler(
      () => [
        for (final json in lista as List<dynamic>)
          MeuVisitante.fromJson(json as Map<String, dynamic>),
      ],
    );
  }

  /// GET /me/visitors/catracas: onde eu posso convidar, e até quando.
  Future<List<CatracaDoConvite>> catracas() async {
    final lista = await _api.get('/me/visitors/catracas');
    return _ler(
      () => [
        for (final json in lista as List<dynamic>)
          CatracaDoConvite.fromJson(json as Map<String, dynamic>),
      ],
    );
  }

  /// POST /me/visitors. A API confere as regras de novo (período dentro da
  /// minha autorização, dias máximos, se o condomínio deixa convidar).
  Future<VisitanteCriado> criar({
    required String nome,
    required String email,
    required String cpf,
    required String catracaId,
    required DateTime dataInicio,
    required DateTime dataFim,
    required String horaInicio,
    required String horaFim,
  }) async {
    final resposta = await _api.post('/me/visitors', {
      'nome': nome,
      'email': email,
      'cpf': cpf,
      'accessPointId': catracaId,
      'dataInicio': Formato.dataApi(dataInicio),
      'dataFim': Formato.dataApi(dataFim),
      'horaInicio': horaInicio,
      'horaFim': horaFim,
    });
    return VisitanteCriado.fromJson(resposta, nome: nome, email: email);
  }

  /// POST /me/visitors/:id/cancel (id da autorização).
  Future<void> cancelar(String autorizacaoId) =>
      _api.post('/me/visitors/$autorizacaoId/cancel');

  /// Resposta fora do formato vira erro na tela, em vez de deixar a tela
  /// carregando para sempre.
  static T _ler<T>(T Function() ler) {
    try {
      return ler();
    } catch (_) {
      // Com status: a resposta chegou, então não é falta de internet.
      throw const ApiException(
        'O servidor respondeu num formato inesperado. Tente de novo.',
        status: 200,
      );
    }
  }
}
