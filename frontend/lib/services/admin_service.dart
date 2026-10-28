import '../models/admin_models.dart';
import '../models/usuario.dart';
import 'api_client.dart';
import 'auth_service.dart';

/// Chamadas da área do administrador (e da portaria, nas rotas que ela pode).
/// Cada método aponta para a rota do backend que ele usa. Todos lançam
/// [ApiException] com a mensagem pronta para a tela.
class AdminService {
  AdminService({ApiClient? api, AuthService? auth})
    : _api = api ?? ApiClient.instancia,
      _auth = auth ?? AuthService.instancia;

  /// O mesmo para o app inteiro.
  static final instancia = AdminService();

  final ApiClient _api;
  final AuthService _auth;

  /// Só o admin cadastra locais e terminais (somenteAdmin no backend).
  bool get souAdmin => _auth.usuario?.perfil == Perfil.admin;

  /// A portaria só gerencia condôminos e visitantes (users.service.ts).
  bool podeGerenciar(Perfil alvo) =>
      souAdmin ||
      (_auth.usuario?.perfil == Perfil.controladorAcesso &&
          (alvo == Perfil.morador || alvo == Perfil.visitante));

  List<Map<String, dynamic>> _lista(dynamic json) => [
    for (final item in json as List) item as Map<String, dynamic>,
  ];

  // Painel (A1) ---------------------------------------------------------

  Future<ResumoPainel> painel() async => ResumoPainel.fromJson(
    await _api.get('/dashboard') as Map<String, dynamic>,
  );

  // Usuários (RF01) -----------------------------------------------------

  Future<List<UsuarioAdmin>> usuarios({String? busca, Perfil? perfil}) async {
    final json = await _api.get(
      '/users',
      query: {
        if (busca != null && busca.trim().isNotEmpty) 'busca': busca.trim(),
        if (perfil != null) 'perfil': perfil.api,
      },
    );
    return [for (final u in _lista(json)) UsuarioAdmin.fromJson(u)];
  }

  Future<UsuarioAdmin> usuario(String id) async => UsuarioAdmin.fromJson(
    await _api.get('/users/$id') as Map<String, dynamic>,
  );

  Future<UsuarioAdmin> criarUsuario({
    required String nome,
    required String email,
    required String cpf,
    required String senha,
    required Perfil perfil,
  }) async => UsuarioAdmin.fromJson(
    await _api.post('/users', {
          'nome': nome,
          'email': email,
          'cpf': cpf,
          'senha': senha,
          'perfil': perfil.api,
        })
        as Map<String, dynamic>,
  );

  /// Só manda o que mudou; [senha] vazia mantém a atual.
  Future<UsuarioAdmin> atualizarUsuario(
    String id, {
    String? nome,
    String? email,
    String? cpf,
    String? senha,
    Perfil? perfil,
    bool? ativo,
  }) async => UsuarioAdmin.fromJson(
    await _api.patch('/users/$id', {
          'nome': ?nome,
          'email': ?email,
          'cpf': ?cpf,
          if (senha != null && senha.isNotEmpty) 'senha': senha,
          if (perfil != null) 'perfil': perfil.api,
          'ativo': ?ativo,
        })
        as Map<String, dynamic>,
  );

  Future<TagNfc> vincularTag(String userId, String uid) async =>
      TagNfc.fromJson(
        await _api.post('/users/$userId/tags', {'uid': uid})
            as Map<String, dynamic>,
      );

  Future<TagNfc> alterarTag(String userId, String tagId, bool ativa) async =>
      TagNfc.fromJson(
        await _api.patch('/users/$userId/tags/$tagId', {'ativa': ativa})
            as Map<String, dynamic>,
      );

  Future<void> removerTag(String userId, String tagId) async {
    await _api.delete('/users/$userId/tags/$tagId');
  }

  // Locais (RF02) -------------------------------------------------------

  Future<List<Edificio>> locais() async => [
    for (final e in _lista(await _api.get('/locations'))) Edificio.fromJson(e),
  ];

  Future<void> criarEdificio(String nome, String endereco) async {
    await _api.post('/locations/buildings', {
      'nome': nome,
      'endereco': endereco,
    });
  }

  Future<void> criarPortaria(String nome, String buildingId) async {
    await _api.post('/locations/gates', {
      'nome': nome,
      'buildingId': buildingId,
    });
  }

  Future<void> criarPorta(String nome, String gateId) async {
    await _api.post('/locations/doors', {'nome': nome, 'gateId': gateId});
  }

  Future<void> criarCatraca({
    required String nome,
    required String doorId,
    required double latitude,
    required double longitude,
    required int raioMetros,
  }) async {
    await _api.post('/locations/access-points', {
      'nome': nome,
      'doorId': doorId,
      'latitude': latitude,
      'longitude': longitude,
      'raioMetros': raioMetros,
    });
  }

  Future<void> atualizarCatraca(
    String id, {
    required String nome,
    required double latitude,
    required double longitude,
    required int raioMetros,
  }) async {
    await _api.patch('/locations/access-points/$id', {
      'nome': nome,
      'latitude': latitude,
      'longitude': longitude,
      'raioMetros': raioMetros,
    });
  }

  // Autorizações (RF03, RF04, RF05) ------------------------------------

  /// [situacao] em maiúsculas como a API: ATIVA, EXPIRADA ou CANCELADA.
  /// [de] e [ate] em AAAA-MM-DD.
  Future<List<Autorizacao>> autorizacoes({
    String? situacao,
    String? userId,
    String? accessPointId,
    String? de,
    String? ate,
  }) async {
    final json = await _api.get(
      '/authorizations',
      query: {
        'situacao': ?situacao,
        'userId': ?userId,
        'accessPointId': ?accessPointId,
        'de': ?de,
        'ate': ?ate,
      },
    );
    return [for (final a in _lista(json)) Autorizacao.fromJson(a)];
  }

  Future<Autorizacao> criarAutorizacao({
    required String userId,
    required String accessPointId,
    required String dataInicio,
    required String dataFim,
    required String horaInicio,
    required String horaFim,
    required int maxUsos,
  }) async => Autorizacao.fromJson(
    await _api.post('/authorizations', {
          'userId': userId,
          'accessPointId': accessPointId,
          'dataInicio': dataInicio,
          'dataFim': dataFim,
          'horaInicio': horaInicio,
          'horaFim': horaFim,
          'maxUsos': maxUsos,
        })
        as Map<String, dynamic>,
  );

  Future<Autorizacao> atualizarAutorizacao(
    String id, {
    required String accessPointId,
    required String dataInicio,
    required String dataFim,
    required String horaInicio,
    required String horaFim,
    required int maxUsos,
  }) async => Autorizacao.fromJson(
    await _api.patch('/authorizations/$id', {
          'accessPointId': accessPointId,
          'dataInicio': dataInicio,
          'dataFim': dataFim,
          'horaInicio': horaInicio,
          'horaFim': horaFim,
          'maxUsos': maxUsos,
        })
        as Map<String, dynamic>,
  );

  /// A API não apaga autorização: cancelar é o jeito de "excluir".
  Future<Autorizacao> cancelarAutorizacao(String id) async =>
      Autorizacao.fromJson(
        await _api.post('/authorizations/$id/cancel') as Map<String, dynamic>,
      );

  // Histórico (RF06) ----------------------------------------------------

  Future<PaginaEventos> eventos({
    DateTime? de,
    DateTime? ate,
    bool? liberado,
    String? metodo,
    String? accessPointId,
    int limite = 50,
    int pular = 0,
  }) async => PaginaEventos.fromJson(
    await _api.get(
          '/access-events',
          query: {
            if (de != null) 'de': de.toUtc().toIso8601String(),
            if (ate != null) 'ate': ate.toUtc().toIso8601String(),
            if (liberado != null) 'resultado': liberado ? 'LIBERADO' : 'NEGADO',
            'metodo': ?metodo,
            'accessPointId': ?accessPointId,
            'limite': '$limite',
            'pular': '$pular',
          },
        )
        as Map<String, dynamic>,
  );

  // Terminais -----------------------------------------------------------

  Future<List<TerminalAdmin>> terminais() async => [
    for (final t in _lista(await _api.get('/terminals')))
      TerminalAdmin.fromJson(t),
  ];

  /// A chave vem só nesta resposta: mostre e peça para gravar no firmware.
  Future<TerminalAdmin> cadastrarTerminal(
    String nome,
    String accessPointId,
  ) async => TerminalAdmin.fromJson(
    await _api.post('/terminals', {
          'nome': nome,
          'accessPointId': accessPointId,
        })
        as Map<String, dynamic>,
  );

  Future<TerminalAdmin> trocarChave(String id) async => TerminalAdmin.fromJson(
    await _api.post('/terminals/$id/rotate-key') as Map<String, dynamic>,
  );
}
