import '../models/usuario.dart';
import '../models/usuario_cadastro.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class UsuariosController {
  UsuariosController({ApiClient? api, AuthService? auth})
    : _api = api ?? ApiClient.instancia,
      _auth = auth ?? AuthService.instancia;

  final ApiClient _api;
  final AuthService _auth;

  Perfil? get _perfilLogado => _auth.usuario?.perfil;

  String? get idLogado => _auth.usuario?.id;

  /// Perfis que quem está logado pode criar ou escolher no formulário.
  List<Perfil> get perfisPermitidos => _perfilLogado == Perfil.admin
      ? Perfil.values
      : const [Perfil.morador, Perfil.visitante];

  bool podeGerenciar(Perfil perfil) => perfisPermitidos.contains(perfil);

  Future<List<UsuarioCadastro>> listar({String? busca, Perfil? perfil}) async {
    final lista =
        await _api.get(
              '/users',
              query: {
                if (busca != null && busca.trim().isNotEmpty)
                  'busca': busca.trim(),
                if (perfil != null) 'perfil': perfil.api,
              },
            )
            as List<dynamic>;
    return [
      for (final json in lista)
        UsuarioCadastro.fromJson(json as Map<String, dynamic>),
    ];
  }

  Future<UsuarioCadastro> criar({
    required String nome,
    required String email,
    required String cpf,
    required String senha,
    required Perfil perfil,
  }) async {
    final json = await _api.post('/users', {
      'nome': nome,
      'email': email,
      'cpf': cpf,
      'senha': senha,
      'perfil': perfil.api,
    });
    return UsuarioCadastro.fromJson(json as Map<String, dynamic>);
  }

  Future<UsuarioCadastro> atualizar(
    String id, {
    String? nome,
    String? email,
    String? cpf,
    String? senha,
    Perfil? perfil,
    bool? ativo,
  }) async {
    final json = await _api.patch('/users/$id', {
      'nome': ?nome,
      'email': ?email,
      'cpf': ?cpf,
      'senha': ?senha,
      'perfil': ?perfil?.api,
      'ativo': ?ativo,
    });
    return UsuarioCadastro.fromJson(json as Map<String, dynamic>);
  }

  Future<TagNfc> vincularTag(String usuarioId, String uid) async {
    final json = await _api.post('/users/$usuarioId/tags', {'uid': uid});
    return TagNfc.fromJson(json as Map<String, dynamic>);
  }

  Future<void> alterarTag(String usuarioId, String tagId, bool ativa) =>
      _api.patch('/users/$usuarioId/tags/$tagId', {'ativa': ativa});

  Future<void> removerTag(String usuarioId, String tagId) =>
      _api.delete('/users/$usuarioId/tags/$tagId');
}
