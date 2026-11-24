/// Celular cadastrado como chave NFC (GET /me/phones).
class CelularNfc {
  const CelularNfc({
    required this.id,
    required this.nome,
    required this.ativo,
    required this.criadoEm,
  });

  factory CelularNfc.fromJson(Map<String, dynamic> json) => CelularNfc(
    id: json['id'] as String,
    nome: json['nome'] as String,
    ativo: json['ativo'] as bool,
    criadoEm: DateTime.parse(json['createdAt'] as String).toLocal(),
  );

  final String id;
  final String nome;

  /// false: a portaria bloqueou.
  final bool ativo;
  final DateTime criadoEm;
}

/// O que o próprio aparelho sabe: se emula cartão (HCE), se o NFC está ligado
/// e o id que a chave do Keystore tem no Passe.
class EstadoAparelho {
  const EstadoAparelho({
    required this.suportado,
    required this.nfcLigado,
    this.celularId,
    this.modelo = 'Celular Android',
  });

  /// iPhone, navegador e Android sem NFC.
  static const semSuporte = EstadoAparelho(suportado: false, nfcLigado: false);

  final bool suportado;
  final bool nfcLigado;

  /// null: este aparelho ainda não foi ativado (ou a chave foi apagada).
  final String? celularId;

  /// Nome que vai para a lista, ex.: "SM-A546E".
  final String modelo;
}

/// O que a tela "Celular como chave" mostra.
class SituacaoCelular {
  const SituacaoCelular({required this.aparelho, required this.cadastrados});

  final EstadoAparelho aparelho;

  /// Todos os celulares da pessoa na API, inclusive este.
  final List<CelularNfc> cadastrados;

  /// Este aparelho, se a chave dele continua cadastrada.
  CelularNfc? get deste {
    final id = aparelho.celularId;
    if (id == null) return null;
    for (final c in cadastrados) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Os outros aparelhos da pessoa (trocou de celular, reinstalou o app).
  List<CelularNfc> get outros => [
    for (final c in cadastrados)
      if (c.id != deste?.id) c,
  ];
}
