/// Situação que a API calcula a partir das datas, dos usos e do cancelamento
/// (situacaoDe em backend/src/modules/access/access.rules.ts).
enum SituacaoAutorizacao {
  ativa('ATIVA', 'Ativa'),
  agendada('AGENDADA', 'Agendada'),
  esgotada('ESGOTADA', 'Sem usos'),
  expirada('EXPIRADA', 'Expirada'),
  cancelada('CANCELADA', 'Cancelada');

  const SituacaoAutorizacao(this.api, this.rotulo);

  /// Como a API escreve a situação.
  final String api;

  /// Texto do selo na tela, ex.: "Ativa".
  final String rotulo;

  /// Ativa e agendada ainda vão valer; as outras ficam em "Encerradas" (U7).
  bool get vigente => this == ativa || this == agendada;

  static SituacaoAutorizacao daApi(String valor) => values.firstWhere(
    (situacao) => situacao.api == valor,
    orElse: () => throw FormatException('Situação desconhecida: $valor'),
  );
}

/// Catraca da autorização, com o local onde ela fica.
class CatracaAutorizada {
  const CatracaAutorizada({
    required this.id,
    required this.nome,
    required this.edificio,
    required this.portaria,
    required this.porta,
  });

  factory CatracaAutorizada.fromJson(Map<String, dynamic> json) =>
      CatracaAutorizada(
        id: json['id'] as String,
        nome: json['nome'] as String,
        edificio: json['edificio'] as String,
        portaria: json['portaria'] as String,
        porta: json['porta'] as String,
      );

  final String id;
  final String nome;
  final String edificio;
  final String portaria;
  final String porta;

  /// "Portaria Principal › Porta A › Catraca 1" (U8, "Onde").
  String get onde => '$portaria › $porta › $nome';
}

/// Autorização de quem está logado, como vem no GET /me/authorizations
/// (AuthorizationsService.apresentar em
/// backend/src/modules/authorizations/authorizations.service.ts).
class Autorizacao {
  const Autorizacao({
    required this.id,
    required this.catraca,
    required this.dataInicio,
    required this.dataFim,
    required this.horaInicio,
    required this.horaFim,
    required this.maxUsos,
    required this.usosRestantes,
    required this.situacao,
    this.canceladaEm,
  });

  factory Autorizacao.fromJson(Map<String, dynamic> json) {
    final canceladaEm = json['canceladaEm'] as String?;
    return Autorizacao(
      id: json['id'] as String,
      catraca: CatracaAutorizada.fromJson(
        json['catraca'] as Map<String, dynamic>,
      ),
      dataInicio: DateTime.parse(json['dataInicio'] as String),
      dataFim: DateTime.parse(json['dataFim'] as String),
      horaInicio: json['horaInicio'] as String,
      horaFim: json['horaFim'] as String,
      maxUsos: json['maxUsos'] as int,
      usosRestantes: json['usosRestantes'] as int,
      situacao: SituacaoAutorizacao.daApi(json['situacao'] as String),
      canceladaEm: canceladaEm == null ? null : DateTime.parse(canceladaEm),
    );
  }

  final String id;
  final CatracaAutorizada catraca;

  /// Só a data (a API manda "AAAA-MM-DD"), à meia-noite.
  final DateTime dataInicio;
  final DateTime dataFim;

  /// "HH:MM", no fuso do prédio.
  final String horaInicio;
  final String horaFim;

  final int maxUsos;
  final int usosRestantes;
  final SituacaoAutorizacao situacao;

  /// Só quando a portaria cancelou.
  final DateTime? canceladaEm;

  /// Ainda vale hoje e só sobra um uso (U7, "Último uso disponível").
  bool get ultimoUso =>
      situacao == SituacaoAutorizacao.ativa && usosRestantes == 1;

  /// O horário vale neste momento? Aceita janelas que passam da meia-noite
  /// (ex.: 22:00 às 06:00), como dentroDoHorario no backend.
  bool dentroDoHorario(DateTime agora) {
    final minutos = agora.hour * 60 + agora.minute;
    final inicio = _minutos(horaInicio);
    final fim = _minutos(horaFim);
    if (inicio <= fim) return minutos >= inicio && minutos < fim;
    return minutos >= inicio || minutos < fim;
  }

  static int _minutos(String hora) {
    final [h, m] = hora.split(':');
    return int.parse(h) * 60 + int.parse(m);
  }
}
