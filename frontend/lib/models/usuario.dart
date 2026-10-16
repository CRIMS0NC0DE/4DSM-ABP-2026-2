/// Perfis de acesso, do cargo mais alto para o mais baixo.
/// Cada um abre o seu menu depois do login.
enum Perfil { admin, controladorAcesso, morador }

/// Quem usa o app (USER no diagrama do banco).
class Usuario {
  const Usuario({
    required this.nome,
    required this.email,
    required this.cpf,
    required this.perfil,
  });

  final String nome;
  final String email;

  /// Só os 11 números, sem pontuação.
  final String cpf;

  final Perfil perfil;
}
