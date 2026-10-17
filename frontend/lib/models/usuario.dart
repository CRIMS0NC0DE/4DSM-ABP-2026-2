/// Perfis de acesso, do cargo mais alto para o mais baixo.
/// Cada um abre o seu menu depois do login.
enum Perfil {
  admin('ADMIN'),
  controladorAcesso('CONTROLADOR_ACESSO'),
  morador('CONDOMINO'),
  visitante('VISITANTE');

  const Perfil(this.api);

  /// Como a API escreve o perfil.
  final String api;

  static Perfil daApi(String valor) => values.firstWhere(
    (perfil) => perfil.api == valor,
    orElse: () => throw FormatException('Perfil desconhecido: $valor'),
  );
}

/// Quem usa o app (USER no diagrama do banco).
class Usuario {
  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.cpf,
    required this.perfil,
  });

  /// Lê o usuário como a API devolve (POST /auth/login, GET /auth/me).
  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    id: json['id'] as String,
    nome: json['nome'] as String,
    email: json['email'] as String,
    cpf: json['cpf'] as String,
    perfil: Perfil.daApi(json['perfil'] as String),
  );

  /// UUID do usuário na API.
  final String id;

  final String nome;
  final String email;

  /// Só os 11 números, sem pontuação.
  final String cpf;

  final Perfil perfil;

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'email': email,
    'cpf': cpf,
    'perfil': perfil.api,
  };
}
