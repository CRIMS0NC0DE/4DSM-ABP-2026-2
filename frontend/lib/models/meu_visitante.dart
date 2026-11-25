import 'autorizacao.dart';

/// Visitante que o morador cadastrou, como vem no GET /me/visitors: a
/// autorização (mesmo formato do GET /authorizations) e, em `user`, o
/// visitante.
class MeuVisitante {
  const MeuVisitante({
    required this.autorizacao,
    required this.visitanteId,
    required this.visitanteNome,
  });

  factory MeuVisitante.fromJson(Map<String, dynamic> json) {
    final visitante = json['user'];
    return MeuVisitante(
      autorizacao: Autorizacao.fromJson(json),
      visitanteId: visitante is Map ? visitante['id'] as String? : null,
      visitanteNome:
          (visitante is Map ? visitante['nome'] as String? : null) ??
          'Visitante',
    );
  }

  final Autorizacao autorizacao;
  final String? visitanteId;
  final String visitanteNome;
}

/// Catraca para onde o morador pode convidar (GET /me/visitors/catracas):
/// onde ele mesmo tem uma autorização que ainda vale.
class CatracaDoConvite {
  const CatracaDoConvite({required this.catraca, required this.ate});

  factory CatracaDoConvite.fromJson(Map<String, dynamic> json) =>
      CatracaDoConvite(
        catraca: CatracaAutorizada.fromJson(json),
        ate: DateTime.parse(json['ate'] as String),
      );

  final CatracaAutorizada catraca;

  /// Último dia da autorização do morador: o convite não pode passar dele.
  final DateTime ate;
}

/// Resposta do POST /me/visitors.
class VisitanteCriado {
  const VisitanteCriado({
    required this.nome,
    required this.email,
    required this.senhaProvisoria,
  });

  /// Lê com folga: o visitante já foi criado, então, se faltar algum campo,
  /// usa o que o morador digitou em vez de mostrar erro.
  factory VisitanteCriado.fromJson(
    Object? json, {
    required String nome,
    required String email,
  }) {
    final dados = json is Map ? json : const {};
    final visitante = dados['visitante'];
    final senha = dados['senhaProvisoria'];
    return VisitanteCriado(
      nome: (visitante is Map ? visitante['nome'] as String? : null) ?? nome,
      email: (visitante is Map ? visitante['email'] as String? : null) ?? email,
      senhaProvisoria: senha is String && senha.isNotEmpty ? senha : null,
    );
  }

  final String nome;
  final String email;

  /// Só aparece nesta resposta. null quando o visitante já tinha cadastro
  /// (mesmo e-mail e CPF): ele entra com a senha que já usa.
  final String? senhaProvisoria;
}
