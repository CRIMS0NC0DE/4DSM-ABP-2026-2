import '../models/usuario.dart';

typedef _Conta = ({Usuario usuario, String senha});

/// Login e cadastro de contas.
/// Protótipo: enquanto a API não existe, as contas ficam só na memória
/// (somem ao fechar o app) e já começam com uma conta de demonstração de
/// cada perfil, todas com a senha [senhaDemo]:
///
/// | Perfil                | E-mail             | CPF            |
/// |-----------------------|--------------------|----------------|
/// | Admin                 | admin@passe.com    | 111.111.111-11 |
/// | Controlador de acesso | portaria@passe.com | 222.222.222-22 |
/// | Morador               | morador@passe.com  | 333.333.333-33 |
class AuthService {
  AuthService()
    : _contas = [
        for (final usuario in contasDemo) (usuario: usuario, senha: senhaDemo),
      ];

  /// A mesma para o app inteiro, para o login achar as contas criadas
  /// no cadastro.
  static final instancia = AuthService();

  static const senhaDemo = 'passe123';

  static const contasDemo = [
    Usuario(
      nome: 'Carlos Lima',
      email: 'admin@passe.com',
      cpf: '11111111111',
      perfil: Perfil.admin,
    ),
    Usuario(
      nome: 'Paula Rocha',
      email: 'portaria@passe.com',
      cpf: '22222222222',
      perfil: Perfil.controladorAcesso,
    ),
    Usuario(
      nome: 'Maria Souza',
      email: 'morador@passe.com',
      cpf: '33333333333',
      perfil: Perfil.morador,
    ),
  ];

  final List<_Conta> _contas;

  /// Aceita o e-mail ou o CPF (com ou sem pontuação).
  /// Devolve null se a conta não existir ou a senha estiver errada.
  Usuario? entrar(String emailOuCpf, String senha) {
    final conta = _buscar(emailOuCpf);
    if (conta == null || conta.senha != senha) return null;
    return conta.usuario;
  }

  /// O cadastro do app sempre cria morador: admin e controlador de acesso
  /// só o admin pode criar.
  /// Devolve null se já existir conta com o mesmo e-mail ou CPF.
  Usuario? registrar({
    required String nome,
    required String cpf,
    required String email,
    required String senha,
  }) {
    if (_buscar(email) != null || _buscar(cpf) != null) return null;

    final usuario = Usuario(
      nome: nome.trim(),
      email: email.trim().toLowerCase(),
      cpf: _numeros(cpf),
      perfil: Perfil.morador,
    );
    _contas.add((usuario: usuario, senha: senha));
    return usuario;
  }

  _Conta? _buscar(String emailOuCpf) {
    final texto = emailOuCpf.trim().toLowerCase();
    if (texto.contains('@')) {
      return _contas.where((conta) => conta.usuario.email == texto).firstOrNull;
    }
    final cpf = _numeros(texto);
    return _contas.where((conta) => conta.usuario.cpf == cpf).firstOrNull;
  }

  static String _numeros(String texto) => texto.replaceAll(RegExp(r'\D'), '');
}
