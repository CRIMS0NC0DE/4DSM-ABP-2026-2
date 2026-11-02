import '../models/usuario_cadastro.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

/// U9 · Perfil e Minha tag NFC: os dados de quem está logado.
class PerfilController {
  PerfilController({ApiClient? api, AuthService? auth})
    : _api = api ?? ApiClient.instancia,
      _auth = auth ?? AuthService.instancia;

  final ApiClient _api;
  final AuthService _auth;

  /// GET /auth/me traz também as tags.
  Future<UsuarioCadastro> carregar() async {
    final json = await _api.get('/auth/me');
    return UsuarioCadastro.fromJson(json as Map<String, dynamic>);
  }

  /// Só funciona depois da B6 (PATCH /me/tags/:tagId). Hoje responde 404.
  Future<void> bloquearTag(String tagId) =>
      _api.patch('/me/tags/$tagId', {'ativa': false});

  Future<void> sair() => _auth.sair();
}
