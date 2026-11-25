/// Configurações do condomínio, como vêm no GET /settings. O admin muda as
/// cinco primeiras pelo PATCH /settings; [sistema] é só leitura.
class Configuracoes {
  const Configuracoes({
    required this.nomeCondominio,
    required this.contatoPortaria,
    required this.moradorPodeConvidar,
    required this.visitanteMaxUsos,
    required this.visitanteDiasMax,
    this.atualizadoEm,
    this.sistema,
  });

  factory Configuracoes.fromJson(Map<String, dynamic> json) {
    final atualizadoEm = json['atualizadoEm'] as String?;
    final sistema = json['sistema'] as Map<String, dynamic>?;
    return Configuracoes(
      nomeCondominio: json['nomeCondominio'] as String,
      contatoPortaria: json['contatoPortaria'] as String,
      moradorPodeConvidar: json['moradorPodeConvidar'] as bool,
      visitanteMaxUsos: (json['visitanteMaxUsos'] as num).toInt(),
      visitanteDiasMax: (json['visitanteDiasMax'] as num).toInt(),
      atualizadoEm: atualizadoEm == null
          ? null
          : DateTime.parse(atualizadoEm).toLocal(),
      sistema: sistema == null ? null : ConfiguracoesSistema.fromJson(sistema),
    );
  }

  /// Limites do PATCH /settings.
  static const maxNome = 80;
  static const maxContato = 200;
  static const faixaUsos = (min: 1, max: 20);
  static const faixaDias = (min: 1, max: 30);

  /// Ex.: "FATEC Jacareí".
  final String nomeCondominio;

  /// Texto livre que aparece na Ajuda, ex.: "Portaria: (12) 3953-0000, das
  /// 7h às 22h".
  final String contatoPortaria;

  /// Desligado, só a portaria cadastra visitantes (POST /me/visitors dá 403).
  final bool moradorPodeConvidar;

  /// Usos de cada visita que o morador cria.
  final int visitanteMaxUsos;

  /// Quantos dias uma visita criada pelo morador pode durar.
  final int visitanteDiasMax;

  /// Já no horário do celular. null se nunca foram salvas.
  final DateTime? atualizadoEm;

  final ConfiguracoesSistema? sistema;
}

/// Valores fixos do servidor, que o app só mostra.
class ConfiguracoesSistema {
  const ConfiguracoesSistema({
    required this.fuso,
    required this.qrTrocaSegundos,
    required this.qrValidadeSegundos,
    required this.raioPadraoMetros,
  });

  factory ConfiguracoesSistema.fromJson(Map<String, dynamic> json) =>
      ConfiguracoesSistema(
        fuso: json['fuso'] as String,
        qrTrocaSegundos: (json['qrTrocaSegundos'] as num).toInt(),
        qrValidadeSegundos: (json['qrValidadeSegundos'] as num).toInt(),
        raioPadraoMetros: (json['raioPadraoMetros'] as num).toInt(),
      );

  /// Ex.: "America/Sao_Paulo".
  final String fuso;
  final int qrTrocaSegundos;
  final int qrValidadeSegundos;
  final int raioPadraoMetros;
}
