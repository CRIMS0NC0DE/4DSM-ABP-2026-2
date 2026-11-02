class EventoAcesso {
  const EventoAcesso({
    required this.id,
    required this.liberado,
    required this.metodo,
    required this.em,
    this.motivo,
    this.pessoa,
    this.catraca,
    this.credencial,
    this.distanciaMetros,
  });


    factory EventoAcesso.fromJson(Map<String, dynamic> json) => EventoAcesso(
    id: json['id'] as String,
    liberado: json['resultado'] == 'LIBERADO',
    metodo: json['metodo'] as String,
    em: DateTime.parse(json['createdAt'] as String).toLocal(),
    motivo: json['motivo'] as String?,
    // Tag desconhecida não tem pessoa; QR inválido não tem catraca.
    pessoa: (json['user'] as Map<String, dynamic>?)?['nome'] as String?,
    catraca: (json['catraca'] as Map<String, dynamic>?)?['nome'] as String?,
    credencial: json['credencial'] as String?,
    distanciaMetros: (json['distanciaMetros'] as num?)?.round(),
  );

  final String id;
  final bool liberado;

  /// "QR" ou "NFC".
  final String metodo;

  /// Já no horário do celular.
  final DateTime em;

  /// Só o código (ex.: FORA_DO_HORARIO). O texto está em Motivos.
  final String? motivo;
  final String? pessoa;
  final String? catraca;

  /// No NFC é o UID lido: serve para a portaria vincular uma tag nova.
  final String? credencial;
  final int? distanciaMetros;
}

/// Uma página do histórico com os totais de todos os filtrados.
class PaginaEventos {
  const PaginaEventos({
    required this.itens,
    required this.total,
    required this.liberados,
    required this.negados,
  });

  factory PaginaEventos.fromJson(Map<String, dynamic> json) => PaginaEventos(
    itens: [
      for (final item in json['itens'] as List<dynamic>)
        EventoAcesso.fromJson(item as Map<String, dynamic>),
    ],
    total: json['total'] as int,
    liberados: json['liberados'] as int,
    negados: json['negados'] as int,
  );

  final List<EventoAcesso> itens;
  final int total;
  final int liberados;
  final int negados;

  /// Junta a próxima página, para o "Carregar mais".
  PaginaEventos comMais(PaginaEventos proxima) => PaginaEventos(
    itens: [...itens, ...proxima.itens],
    total: proxima.total,
    liberados: proxima.liberados,
    negados: proxima.negados,
  );
}