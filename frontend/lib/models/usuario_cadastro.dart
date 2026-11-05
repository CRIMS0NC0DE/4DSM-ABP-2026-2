import 'usuario.dart';

class TagNfc {
  const TagNfc({required this.id, required this.uid, required this.ativa});

  factory TagNfc.fromJson(Map<String, dynamic> json) => TagNfc(
    id: json['id'] as String,
    uid: json['uid'] as String,
    ativa: json['ativa'] as bool,
  );

  final String id;
  final String uid;
  final bool ativa;
}

class UsuarioCadastro {
  const UsuarioCadastro({
    required this.id,
    required this.nome,
    required this.email,
    required this.cpf,
    required this.perfil,
    required this.ativo,
    this.tags = const [],
  });

  factory UsuarioCadastro.fromJson(Map<String, dynamic> json) =>
      UsuarioCadastro(
        id: json['id'] as String,
        nome: json['nome'] as String,
        email: json['email'] as String,
        cpf: json['cpf'] as String,
        perfil: Perfil.daApi(json['perfil'] as String),
        ativo: json['ativo'] as bool,
        // POST e PATCH /users respondem sem as tags.
        tags: [
          for (final tag in json['tags'] as List<dynamic>? ?? const [])
            TagNfc.fromJson(tag as Map<String, dynamic>),
        ],
      );

  final String id;
  final String nome;
  final String email;

  final String cpf;
  final Perfil perfil;
  final bool ativo;
  final List<TagNfc> tags;
}