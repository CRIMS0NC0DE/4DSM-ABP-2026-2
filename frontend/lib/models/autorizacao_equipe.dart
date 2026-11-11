import 'autorizacao.dart';
import 'usuario.dart';

class AutorizacaoEquipe {
  const AutorizacaoEquipe({
    required this.autorizacao,
    required this.pessoaId,
    required this.pessoaNome,
    required this.pessoaPerfil,
  });

  factory AutorizacaoEquipe.fromJson(Map<String, dynamic> json) {
    final pessoa = json['user'] as Map<String, dynamic>;
    return AutorizacaoEquipe(
      autorizacao: Autorizacao.fromJson(json),
      pessoaId: pessoa['id'] as String,
      pessoaNome: pessoa['nome'] as String,
      pessoaPerfil: Perfil.daApi(pessoa['perfil'] as String),
    );
  }

  final Autorizacao autorizacao;
  final String pessoaId;
  final String pessoaNome;
  final Perfil pessoaPerfil;
}