import 'evento_acesso.dart';

int _inteiro(Object? valor) => valor is num ? valor.toInt() : 0;

/// "2026-11-19" vira a meia-noite local desse dia. null se não vier.
DateTime? _dia(Object? valor) =>
    valor is String ? DateTime.tryParse(valor) : null;

/// Liberados e negados de uma fatia do relatório (um dia, um método...).
class ContagemAcessos {
  const ContagemAcessos({required this.liberados, required this.negados});

  final int liberados;
  final int negados;

  int get total => liberados + negados;
}

class AcessosDoDia extends ContagemAcessos {
  const AcessosDoDia({
    required this.dia,
    required super.liberados,
    required super.negados,
  });

  /// null quando o dia não vem numa data válida.
  static AcessosDoDia? fromJson(Map<String, dynamic> json) {
    final dia = _dia(json['dia']);
    if (dia == null) return null;
    return AcessosDoDia(
      dia: dia,
      liberados: _inteiro(json['liberados']),
      negados: _inteiro(json['negados']),
    );
  }

  final DateTime dia;
}

class AcessosDoMetodo extends ContagemAcessos {
  const AcessosDoMetodo({
    required this.metodo,
    required super.liberados,
    required super.negados,
  });

  factory AcessosDoMetodo.fromJson(Map<String, dynamic> json) =>
      AcessosDoMetodo(
        metodo: json['metodo'] as String? ?? 'QR',
        liberados: _inteiro(json['liberados']),
        negados: _inteiro(json['negados']),
      );

  /// "QR", "NFC" ou "CELULAR".
  final String metodo;

  /// "QR Code", "Tag NFC", "Celular".
  String get texto => rotuloDoMetodo(metodo);
}

class AcessosDaCatraca extends ContagemAcessos {
  const AcessosDaCatraca({
    required this.catracaId,
    required this.nome,
    required super.liberados,
    required super.negados,
  });

  /// A catraca vem null quando a API não soube onde foi (ex.: QR inválido).
  factory AcessosDaCatraca.fromJson(Map<String, dynamic> json) {
    final catraca = json['catraca'] as Map<String, dynamic>?;
    return AcessosDaCatraca(
      catracaId: catraca?['id'] as String?,
      nome: catraca?['nome'] as String? ?? 'Sem catraca identificada',
      liberados: _inteiro(json['liberados']),
      negados: _inteiro(json['negados']),
    );
  }

  final String? catracaId;
  final String nome;
}

class MotivoDeRecusa {
  const MotivoDeRecusa({
    required this.motivo,
    required this.titulo,
    required this.total,
  });

  factory MotivoDeRecusa.fromJson(Map<String, dynamic> json) {
    final motivo = json['motivo'] as String? ?? 'SEM_MOTIVO';
    final titulo = json['titulo'] as String?;
    return MotivoDeRecusa(
      motivo: motivo,
      titulo: titulo == null || titulo.isEmpty ? motivo : titulo,
      total: _inteiro(json['total']),
    );
  }

  /// Ex.: "FORA_DO_HORARIO".
  final String motivo;

  /// Ex.: "Fora do horário permitido".
  final String titulo;
  final int total;
}

/// GET /reports/access: os acessos do período somados pela API (todos, não
/// só uma página).
class RelatorioAcessos {
  const RelatorioAcessos({
    required this.de,
    required this.ate,
    required this.total,
    required this.liberados,
    required this.negados,
    required this.porDia,
    required this.porMetodo,
    required this.porCatraca,
    required this.porMotivo,
  });

  factory RelatorioAcessos.fromJson(Map<String, dynamic> json) {
    List<T> lista<T>(String chave, T? Function(Map<String, dynamic>) ler) => [
      for (final item in json[chave] as List<dynamic>? ?? const [])
        if (item is Map<String, dynamic>) ?ler(item),
    ];
    final liberados = _inteiro(json['liberados']);
    final negados = _inteiro(json['negados']);
    return RelatorioAcessos(
      de: _dia(json['de']),
      ate: _dia(json['ate']),
      total: json['total'] is num
          ? _inteiro(json['total'])
          : liberados + negados,
      liberados: liberados,
      negados: negados,
      porDia: lista('porDia', AcessosDoDia.fromJson),
      porMetodo: lista('porMetodo', AcessosDoMetodo.fromJson),
      porCatraca: lista('porCatraca', AcessosDaCatraca.fromJson),
      porMotivo: lista('porMotivo', MotivoDeRecusa.fromJson),
    );
  }

  /// O intervalo que a API usou. null se não vier.
  final DateTime? de;
  final DateTime? ate;
  final int total;
  final int liberados;
  final int negados;

  /// Todos os dias do intervalo, inclusive os zerados, em ordem.
  final List<AcessosDoDia> porDia;

  /// Sempre QR, NFC e celular, nessa ordem.
  final List<AcessosDoMetodo> porMetodo;

  /// Maior total primeiro.
  final List<AcessosDaCatraca> porCatraca;

  /// Só os negados, o mais comum primeiro.
  final List<MotivoDeRecusa> porMotivo;

  bool get vazio => total == 0;

  /// De 0 a 100, arredondada. 0 sem acessos.
  int get taxaLiberacao => total == 0 ? 0 : (liberados * 100 / total).round();
}
