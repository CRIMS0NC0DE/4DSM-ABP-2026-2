class Terminal {
  const Terminal({
    required this.id,
    required this.nome,
    required this.accessPointId,
    required this.online,
    this.ultimoSinal,
    this.chave,
  });

  factory Terminal.fromJson(Map<String, dynamic> json) {
    final sinal = json['ultimoSinal'] as String?;
    return Terminal(
      id: json['id'] as String,
      nome: json['nome'] as String,
      accessPointId: json['accessPointId'] as String,
      online: json['online'] as bool,
      ultimoSinal: sinal == null ? null : DateTime.parse(sinal).toLocal(),
      chave: json['chave'] as String?,
    );
  }

  final String id;
  final String nome;

    final String accessPointId;
    final bool online;
    final DateTime? ultimoSinal;
    final String? chave;
}