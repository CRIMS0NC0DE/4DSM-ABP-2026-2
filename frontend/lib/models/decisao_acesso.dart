/// Catraca da tentativa, como vem na decisão de acesso.
class CatracaAcesso {
  const CatracaAcesso({
    required this.id,
    required this.nome,
    required this.caminho,
  });

  factory CatracaAcesso.fromJson(Map<String, dynamic> json) => CatracaAcesso(
    id: json['id'] as String,
    nome: json['nome'] as String,
    caminho: json['caminho'] as String,
  );

  final String id;
  final String nome;

  /// "Edifício › Portaria › Porta".
  final String caminho;
}

/// Resposta do POST /access/qr (DecisaoAcesso em
/// backend/src/modules/access/access.service.ts).
/// Vem sempre com status 200, mesmo negado: quem decide é [liberado].
class DecisaoAcesso {
  const DecisaoAcesso({
    required this.liberado,
    required this.titulo,
    required this.eventoId,
    required this.em,
    this.motivo,
    this.oQueFazer,
    this.catraca,
    this.usosRestantes,
    this.distanciaMetros,
  });

  factory DecisaoAcesso.fromJson(Map<String, dynamic> json) {
    final catraca = json['catraca'];
    return DecisaoAcesso(
      liberado: json['liberado'] as bool,
      motivo: json['motivo'] as String?,
      titulo: json['titulo'] as String,
      oQueFazer: json['oQueFazer'] as String?,
      catraca: catraca is Map<String, dynamic>
          ? CatracaAcesso.fromJson(catraca)
          : null,
      usosRestantes: json['usosRestantes'] as int?,
      distanciaMetros: json['distanciaMetros'] as int?,
      eventoId: json['eventoId'] as String,
      em: DateTime.parse(json['em'] as String),
    );
  }

  final bool liberado;

  /// Só quando nega. Código da API, ex.: FORA_DO_HORARIO, SEM_USOS
  /// (MotivoNegacao em backend/src/modules/access/access.rules.ts).
  final String? motivo;

  /// Texto pronto para a tela. "Acesso liberado" quando libera.
  final String titulo;

  /// Só quando nega, ex.: "Peça mais usos à portaria.".
  final String? oQueFazer;

  /// Não vem quando o QR é inválido, expirou ou a catraca não tem terminal.
  final CatracaAcesso? catraca;

  /// Só quando libera, já descontando este acesso.
  final int? usosRestantes;

  /// Distância até a catraca, depois que a API confere a posição.
  final int? distanciaMetros;

  /// Id do evento no histórico de acessos.
  final String eventoId;

  /// Quando a API decidiu.
  final DateTime em;

  /// A API não recebeu a posição do celular (tela E8).
  bool get semLocalizacao => motivo == 'LOCALIZACAO_AUSENTE';
}
