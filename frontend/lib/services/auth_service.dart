import '../models/usuario.dart';
import 'api_client.dart';
import 'sessao_service.dart';

/// Login, cadastro e saída da conta, pela API (módulo auth do backend).
/// As contas de demonstração vêm do seed do backend (npm run db:seed),
/// todas com a senha passe123: admin@, portaria@, morador@ e
/// visitante@passe.com.
class AuthService {
  AuthService({ApiClient? api, SessaoService? sessao})
    : _api = api ?? ApiClient.instancia,
      _sessao = sessao ?? SessaoService.instancia;

  /// O mesmo para o app inteiro.
  static final instancia = AuthService();

  final ApiClient _api;
  final SessaoService _sessao;

  /// Quem está logado agora, ou null.
  Usuario? get usuario => _sessao.usuario;

  /// RF07 · POST /auth/login. Aceita o e-mail ou o CPF (com ou sem
  /// pontuação); a API normaliza. Guarda o token para as próximas chamadas.
  /// Lança [ApiException] com a mensagem da API (ex.: senha errada,
  /// cadastro desativado) ou de falta de conexão.
  Future<Usuario> entrar(String emailOuCpf, String senha) async {
    final resposta = await _api.post('/auth/login', {
      'login': emailOuCpf,
      'senha': senha,
    });
    final usuario = Usuario.fromJson(
      resposta['usuario'] as Map<String, dynamic>,
    );
    await _sessao.iniciar(resposta['token'] as String, usuario);
    return usuario;
  }

  /// Volta a sessão guardada ao abrir o app e confere na API se ela ainda vale:
  /// o perfil pode ter mudado e o cadastro pode ter sido desativado. Sem
  /// resposta a tempo, segue com a cópia local para o app abrir sem internet.
  /// [aviso] explica por que a pessoa voltou ao login.
  Future<({Usuario? usuario, String? aviso})> restaurar({
    Duration espera = const Duration(seconds: 3),
  }) async {
    final guardado = await _sessao.restaurar();
    if (guardado == null) return (usuario: null, aviso: null);
    try {
      final json = await _api.get('/auth/me').timeout(espera);
      final usuario = Usuario.fromJson(json as Map<String, dynamic>);
      await _sessao.iniciar(_sessao.token!, usuario);
      return (usuario: usuario, aviso: null);
    } on ApiException catch (e) {
      if (!e.naoAutenticado) return (usuario: guardado, aviso: null);
      await _sessao.encerrar();
      return (usuario: null, aviso: e.cadastroDesativado ? e.mensagem : null);
    } catch (_) {
      return (usuario: guardado, aviso: null);
    }
  }

  /// POST /auth/register (pública). O cadastro nasce desativado, como
  /// condômino: a pessoa só entra depois que a portaria liberar em Usuários
  /// (antes disso o login responde CADASTRO_DESATIVADO). Não inicia sessão.
  /// Devolve a mensagem da API para a tela. Lança [ApiException]: 409 com
  /// e-mail ou CPF já usado, 400 com os erros de cada campo, sem conexão.
  Future<String> registrar({
    required String nome,
    required String cpf,
    required String email,
    required String senha,
  }) async {
    final resposta = await _api.post('/auth/register', {
      'nome': nome,
      'email': email,
      'cpf': cpf,
      'senha': senha,
    });
    final mensagem = resposta is Map ? resposta['mensagem'] : null;
    return mensagem is String && mensagem.isNotEmpty
        ? mensagem
        : mensagemCadastroEnviado;
  }

  /// Quando a API não manda a mensagem do cadastro.
  static const mensagemCadastroEnviado =
      'Pedido enviado. A portaria vai liberar seu acesso.';

  Future<void> sair() => _sessao.encerrar();
}
