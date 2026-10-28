import 'usuario.dart';

/// Modelos das telas do administrador. Cada um lê o JSON como a API devolve
/// (backend/src/modules/*/*.types.ts).

extension PerfilRotulo on Perfil {
  String get rotulo => switch (this) {
    Perfil.admin => 'Admin',
    Perfil.controladorAcesso => 'Controlador de acesso',
    Perfil.morador => 'Condômino',
    Perfil.visitante => 'Visitante',
  };

  /// Frase do formulário de usuário (A4).
  String get descricao => switch (this) {
    Perfil.admin => 'Gerencia usuários, locais e autorizações',
    Perfil.controladorAcesso => 'Cadastra moradores e visitantes',
    Perfil.morador => 'Mora ou trabalha no prédio',
    Perfil.visitante => 'Acesso por tempo limitado',
  };
}

/// Texto curto de cada motivo de negação (MotivoNegacao em
/// backend/src/modules/access/access.rules.ts).
const motivosNegacao = {
  'QR_INVALIDO': 'QR Code não reconhecido',
  'QR_EXPIRADO': 'QR Code vencido',
  'QR_JA_UTILIZADO': 'QR Code já usado',
  'TERMINAL_DESCONHECIDO': 'Catraca não cadastrada',
  'USUARIO_INATIVO': 'Cadastro desativado',
  'SEM_AUTORIZACAO': 'Sem autorização para a catraca',
  'AUTORIZACAO_CANCELADA': 'Autorização cancelada',
  'AUTORIZACAO_EXPIRADA': 'Autorização expirada',
  'AUTORIZACAO_NAO_INICIADA': 'Autorização ainda não começou',
  'FORA_DO_HORARIO': 'Fora do horário',
  'SEM_USOS': 'Sem usos restantes',
  'LOCALIZACAO_AUSENTE': 'Sem localização do celular',
  'LONGE_DO_TERMINAL': 'Mais de 100 m da catraca',
  'TAG_DESCONHECIDA': 'Tag não cadastrada',
  'TAG_BLOQUEADA': 'Tag bloqueada',
};

String rotuloMotivo(String? codigo) =>
    codigo == null ? '' : (motivosNegacao[codigo] ?? codigo);

class TagNfc {
  const TagNfc({required this.id, required this.uid, required this.ativa});

  factory TagNfc.fromJson(Map<String, dynamic> json) => TagNfc(
    id: json['id'] as String,
    uid: json['uid'] as String,
    ativa: json['ativa'] as bool? ?? true,
  );

  final String id;
  final String uid;
  final bool ativa;
}

/// Usuário como a equipe vê (GET /users). Nunca traz a senha.
class UsuarioAdmin {
  const UsuarioAdmin({
    required this.id,
    required this.nome,
    required this.email,
    required this.cpf,
    required this.perfil,
    required this.ativo,
    this.tags = const [],
  });

  factory UsuarioAdmin.fromJson(Map<String, dynamic> json) => UsuarioAdmin(
    id: json['id'] as String,
    nome: json['nome'] as String,
    email: json['email'] as String,
    cpf: json['cpf'] as String,
    perfil: Perfil.daApi(json['perfil'] as String),
    ativo: json['ativo'] as bool? ?? true,
    tags: [
      for (final t in (json['tags'] as List? ?? const []))
        TagNfc.fromJson(t as Map<String, dynamic>),
    ],
  );

  final String id;
  final String nome;
  final String email;

  /// Só os 11 números.
  final String cpf;
  final Perfil perfil;
  final bool ativo;
  final List<TagNfc> tags;

  /// Primeira tag ativa, a que aparece na lista ("Tag 4F2A").
  TagNfc? get tagAtiva {
    for (final t in tags) {
      if (t.ativa) return t;
    }
    return null;
  }
}

/// Situação calculada pela API (SituacaoAutorizacao).
enum SituacaoAutorizacao {
  ativa('ATIVA', 'Ativa'),
  agendada('AGENDADA', 'Agendada'),
  expirada('EXPIRADA', 'Expirada'),
  esgotada('ESGOTADA', 'Sem usos'),
  cancelada('CANCELADA', 'Cancelada');

  const SituacaoAutorizacao(this.api, this.rotulo);

  final String api;
  final String rotulo;

  static SituacaoAutorizacao daApi(String valor) => values.firstWhere(
    (s) => s.api == valor,
    orElse: () => SituacaoAutorizacao.ativa,
  );
}

/// Autorização com a pessoa e a catraca (GET /authorizations).
class Autorizacao {
  const Autorizacao({
    required this.id,
    required this.userId,
    required this.nomeUsuario,
    required this.accessPointId,
    required this.nomeCatraca,
    required this.dataInicio,
    required this.dataFim,
    required this.horaInicio,
    required this.horaFim,
    required this.maxUsos,
    required this.usosRealizados,
    required this.usosRestantes,
    required this.situacao,
  });

  factory Autorizacao.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    final catraca = json['catraca'] as Map<String, dynamic>;
    return Autorizacao(
      id: json['id'] as String,
      userId: json['userId'] as String,
      nomeUsuario: user['nome'] as String,
      accessPointId: json['accessPointId'] as String,
      nomeCatraca: catraca['nome'] as String,
      dataInicio: json['dataInicio'] as String,
      dataFim: json['dataFim'] as String,
      horaInicio: json['horaInicio'] as String,
      horaFim: json['horaFim'] as String,
      maxUsos: json['maxUsos'] as int,
      usosRealizados: json['usosRealizados'] as int? ?? 0,
      usosRestantes: json['usosRestantes'] as int? ?? 0,
      situacao: SituacaoAutorizacao.daApi(json['situacao'] as String),
    );
  }

  final String id;
  final String userId;
  final String nomeUsuario;
  final String accessPointId;
  final String nomeCatraca;

  /// AAAA-MM-DD
  final String dataInicio;
  final String dataFim;

  /// HH:MM
  final String horaInicio;
  final String horaFim;
  final int maxUsos;
  final int usosRealizados;
  final int usosRestantes;
  final SituacaoAutorizacao situacao;

  bool get cancelada => situacao == SituacaoAutorizacao.cancelada;

  /// Dá para editar ou cancelar (a API não deixa mexer em cancelada).
  bool get editavel => !cancelada;

  bool get ultimoUso =>
      situacao == SituacaoAutorizacao.ativa && usosRestantes == 1;
}

/// Uma tentativa de acesso (GET /access-events).
class EventoAcesso {
  const EventoAcesso({
    required this.id,
    required this.metodo,
    required this.liberado,
    required this.motivo,
    required this.nomeUsuario,
    required this.nomeCatraca,
    required this.quando,
    required this.credencial,
  });

  factory EventoAcesso.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final catraca = json['catraca'];
    return EventoAcesso(
      id: json['id'] as String,
      metodo: json['metodo'] as String,
      liberado: json['resultado'] == 'LIBERADO',
      motivo: json['motivo'] as String?,
      nomeUsuario: user is Map ? user['nome'] as String : null,
      nomeCatraca: catraca is Map ? catraca['nome'] as String : null,
      quando: DateTime.parse(json['createdAt'] as String).toLocal(),
      credencial: json['credencial'] as String?,
    );
  }

  final String id;

  /// QR ou NFC.
  final String metodo;
  final bool liberado;

  /// Código do motivo, só quando negado.
  final String? motivo;

  /// Null quando a API não soube quem era (QR inválido, tag desconhecida).
  final String? nomeUsuario;
  final String? nomeCatraca;
  final DateTime quando;
  final String? credencial;

  bool get porNfc => metodo == 'NFC';
}

class PaginaEventos {
  const PaginaEventos({
    required this.itens,
    required this.total,
    required this.liberados,
    required this.negados,
  });

  factory PaginaEventos.fromJson(Map<String, dynamic> json) => PaginaEventos(
    itens: [
      for (final e in json['itens'] as List)
        EventoAcesso.fromJson(e as Map<String, dynamic>),
    ],
    total: json['total'] as int,
    liberados: json['liberados'] as int,
    negados: json['negados'] as int,
  );

  final List<EventoAcesso> itens;
  final int total;
  final int liberados;
  final int negados;
}

/// GET /dashboard (tela A1).
class ResumoPainel {
  const ResumoPainel({
    required this.acessosHoje,
    required this.negadosHoje,
    required this.autorizacoesAtivas,
    required this.negadosRecentes,
  });

  factory ResumoPainel.fromJson(Map<String, dynamic> json) => ResumoPainel(
    acessosHoje: json['acessosHoje'] as int,
    negadosHoje: json['negadosHoje'] as int,
    autorizacoesAtivas: json['autorizacoesAtivas'] as int,
    negadosRecentes: [
      for (final e in json['negadosRecentes'] as List)
        EventoAcesso.fromJson(e as Map<String, dynamic>),
    ],
  );

  final int acessosHoje;
  final int negadosHoje;
  final int autorizacoesAtivas;
  final List<EventoAcesso> negadosRecentes;
}

/// Catraca da árvore de locais.
class Catraca {
  const Catraca({
    required this.id,
    required this.nome,
    required this.doorId,
    required this.latitude,
    required this.longitude,
    required this.raioMetros,
  });

  factory Catraca.fromJson(Map<String, dynamic> json) => Catraca(
    id: json['id'] as String,
    nome: json['nome'] as String,
    doorId: json['doorId'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    raioMetros: (json['raioMetros'] as num).toInt(),
  );

  final String id;
  final String nome;
  final String doorId;
  final double latitude;
  final double longitude;
  final int raioMetros;
}

class Porta {
  const Porta({required this.id, required this.nome, required this.catracas});

  factory Porta.fromJson(Map<String, dynamic> json) => Porta(
    id: json['id'] as String,
    nome: json['nome'] as String,
    catracas: [
      for (final c in json['catracas'] as List)
        Catraca.fromJson(c as Map<String, dynamic>),
    ],
  );

  final String id;
  final String nome;
  final List<Catraca> catracas;
}

class Portaria {
  const Portaria({required this.id, required this.nome, required this.portas});

  factory Portaria.fromJson(Map<String, dynamic> json) => Portaria(
    id: json['id'] as String,
    nome: json['nome'] as String,
    portas: [
      for (final p in json['portas'] as List)
        Porta.fromJson(p as Map<String, dynamic>),
    ],
  );

  final String id;
  final String nome;
  final List<Porta> portas;
}

class Edificio {
  const Edificio({
    required this.id,
    required this.nome,
    required this.endereco,
    required this.portarias,
  });

  factory Edificio.fromJson(Map<String, dynamic> json) => Edificio(
    id: json['id'] as String,
    nome: json['nome'] as String,
    endereco: json['endereco'] as String,
    portarias: [
      for (final p in json['portarias'] as List)
        Portaria.fromJson(p as Map<String, dynamic>),
    ],
  );

  final String id;
  final String nome;
  final String endereco;
  final List<Portaria> portarias;
}

/// Catraca com o caminho, para os seletores ("Catraca 1 · Porta A").
class CatracaComCaminho {
  const CatracaComCaminho({required this.catraca, required this.caminho});

  final Catraca catraca;

  /// "Edifício › Portaria › Porta".
  final String caminho;

  String get rotulo => '${catraca.nome} · $caminho';
}

extension ArvoreDeLocais on List<Edificio> {
  /// Todas as catracas da árvore, com o caminho de cada uma.
  List<CatracaComCaminho> get catracas => [
    for (final e in this)
      for (final p in e.portarias)
        for (final porta in p.portas)
          for (final c in porta.catracas)
            CatracaComCaminho(
              catraca: c,
              caminho: '${e.nome} › ${p.nome} › ${porta.nome}',
            ),
  ];
}

/// Terminal (GET /terminals). A [chave] só vem ao cadastrar e ao trocar.
class TerminalAdmin {
  const TerminalAdmin({
    required this.id,
    required this.nome,
    required this.accessPointId,
    required this.online,
    this.ultimoSinal,
    this.chave,
  });

  factory TerminalAdmin.fromJson(Map<String, dynamic> json) => TerminalAdmin(
    id: json['id'] as String,
    nome: json['nome'] as String,
    accessPointId: json['accessPointId'] as String,
    online: json['online'] as bool? ?? false,
    ultimoSinal: json['ultimoSinal'] == null
        ? null
        : DateTime.parse(json['ultimoSinal'] as String).toLocal(),
    chave: json['chave'] as String?,
  );

  final String id;
  final String nome;
  final String accessPointId;
  final bool online;
  final DateTime? ultimoSinal;
  final String? chave;
}
