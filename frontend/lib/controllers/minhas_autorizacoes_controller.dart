import '../models/autorizacao.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

/// Telas U7 (Minhas autorizações) e U8 (Detalhe): onde e quando quem está
/// logado pode entrar.
class MinhasAutorizacoesController {
  MinhasAutorizacoesController({
    ApiClient? api,
    AuthService? auth,
    DateTime Function()? relogio,
  }) : _api = api ?? ApiClient.instancia,
       _auth = auth ?? AuthService.instancia,
       _relogio = relogio ?? DateTime.now;

  final ApiClient _api;
  final AuthService _auth;
  final DateTime Function() _relogio;

  /// Hora do celular, usada em "Somente hoje" e "Você pode entrar hoje até".
  DateTime agora() => _relogio();

  /// RF08 · GET /me/authorizations. Lança [ApiException] sem conexão ou com
  /// a sessão vencida (401).
  Future<List<Autorizacao>> carregar() async {
    final lista = await _api.get('/me/authorizations') as List<dynamic>;
    return [
      for (final json in lista)
        Autorizacao.fromJson(json as Map<String, dynamic>),
    ];
  }

  /// Separa como na U7: "Ativas" (as que valem hoje antes das agendadas) e
  /// "Encerradas". Dentro de cada grupo mantém a ordem da API, que traz as
  /// mais recentes primeiro.
  ({List<Autorizacao> ativas, List<Autorizacao> encerradas}) agrupar(
    List<Autorizacao> lista,
  ) => (
    ativas: [
      ...lista.where((a) => a.situacao == SituacaoAutorizacao.ativa),
      ...lista.where((a) => a.situacao == SituacaoAutorizacao.agendada),
    ],
    encerradas: [
      for (final a in lista)
        if (!a.situacao.vigente) a,
    ],
  );

  /// Sessão vencida: esquece o token, como o Sair dos menus.
  Future<void> sair() => _auth.sair();
}
