class EventoAcesso {
  const EventoAcesso({
    required this.id,
    required this.liberado,
    required this.metodo,
    required this.em,
    required this.titulo,
    required this.oQueFazer,
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
    // A API manda os textos do motivo. Vem null no liberado e em motivo que ela
    // não conhece.
    titulo: json['titulo'] as String? ?? 'Acesso negado',
    oQueFazer: json['oQueFazer'] as String? ?? 'Fale com a portaria.',
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

  /// Só faz sentido quando foi negado.
  final String titulo;
  final String oQueFazer;
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