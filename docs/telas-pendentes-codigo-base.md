# Código-base das telas pendentes

Código para copiar, colar e ajustar. A lista de prioridades está em [`telas-pendentes.md`](telas-pendentes.md).

Nada aqui foi aplicado no projeto: todo o código abaixo foi escrito e testado numa cópia, e este documento foi gerado a partir dela. Os resultados dos testes estão na seção 10 da lista.

## Como usar

1. **Cole na ordem deste documento.** Uma tela pode abrir outra: o Painel abre o Histórico e as Autorizações, por exemplo. Cada seção diz do que depende.
2. **Crie cada arquivo novo** no caminho indicado, relativo à raiz do repositório. As pastas `lib/views/equipe/` e `lib/views/compartilhado/` não existem ainda.
3. **Depois de cada seção, rode** `cd frontend && flutter analyze`. Tem que dar "No issues found!".
4. **Ligue as telas nos menus** com as trocas da seção 3. Sem isso, os menus continuam mostrando "tela em construção".
5. **Ajuste os 4 testes** da seção 5. Eles conferem o aviso "em construção" em opções que agora abrem tela.

Para ver rodando:

```bash
docker compose -f docker-compose.dev.yml up --build database mqtt backend
cd frontend && flutter run -d chrome --dart-define=API_URL=http://localhost:3000
```

Contas de teste, todas com a senha `passe123`: `admin@passe.com`, `portaria@passe.com`, `morador@passe.com` e `visitante@passe.com`.

## Índice

| Seção | Conteúdo |
|---|---|
| [1](#1-fundação) | Fundação: modelos e peças reaproveitadas |
| [2](#2-telas) | As 13 telas, na ordem de colar |
| [3](#3-ligar-as-telas-nos-menus) | Ligar as telas nos 4 menus |
| [4](#4-início-opcional-decisão-d2) | Início (opcional, decisão D2) |
| [5](#5-ajustar-os-testes-que-quebram) | Ajustar os 4 testes que quebram |
| [6](#6-testes-das-telas-novas) | Testes das telas novas |
| [7](#7-backend-b2-b3-b4-e-b6) | Backend: B2, B3, B4 e B6 |
| [8](#8-backend-que-ainda-não-tem-código) | Backend que ainda não tem código |

## 1. Fundação

Cole tudo antes das telas. Nada aqui altera arquivo existente.

- **`CarregaDados`** é o principal: dá os estados de carregando e erro e trata o 401 num lugar só. A tela implementa `buscar()` e monta o conteúdo com `conteudo(...)`.
- **`TelaBase`** é a estrutura da U7: Voltar com texto, título, largura máxima de 480.
- **`Motivos`** é a cópia da tabela do backend. Pode sair se o grupo fizer a B2.

**Arquivo novo:** `frontend/lib/core/constants/motivos.dart`

```dart
/// Textos de cada motivo de negação, para as telas de histórico: os eventos
/// (GET /access-events e /me/access-events) só trazem o código em "motivo".
/// Cópia de MOTIVOS em backend/src/modules/access/access.rules.ts. Se o grupo
/// fizer a B2 (a API mandar o texto junto), este arquivo pode sair.
abstract final class Motivos {
  static const _textos = {
    'QR_INVALIDO': (
      'QR Code não reconhecido',
      'Escaneie o QR que aparece na tela da catraca.',
    ),
    'QR_EXPIRADO': (
      'O QR Code já mudou',
      'Escaneie o código novo que está na tela.',
    ),
    'QR_JA_UTILIZADO': (
      'Este QR Code já foi usado',
      'Espere o código novo aparecer e escaneie de novo.',
    ),
    'TERMINAL_DESCONHECIDO': ('Catraca não cadastrada', 'Fale com a portaria.'),
    'TAG_DESCONHECIDA': (
      'Tag não cadastrada',
      'Peça para a portaria vincular sua tag.',
    ),
    'TAG_BLOQUEADA': ('Sua tag está bloqueada', 'Fale com a portaria.'),
    'USUARIO_INATIVO': ('Seu cadastro está desativado', 'Fale com a portaria.'),
    'SEM_AUTORIZACAO': (
      'Você não tem autorização para esta catraca',
      'Peça uma autorização à portaria.',
    ),
    'AUTORIZACAO_CANCELADA': (
      'Sua autorização foi cancelada',
      'Fale com a portaria para saber mais.',
    ),
    'AUTORIZACAO_EXPIRADA': (
      'Sua autorização expirou',
      'Peça uma nova autorização à portaria.',
    ),
    'AUTORIZACAO_NAO_INICIADA': (
      'Sua autorização ainda não começou',
      'Volte na data de início.',
    ),
    'FORA_DO_HORARIO': (
      'Fora do horário permitido',
      'Volte dentro do horário ou fale com a portaria.',
    ),
    'SEM_USOS': ('Você não tem mais usos', 'Peça mais usos à portaria.'),
    'LOCALIZACAO_AUSENTE': (
      'Não conseguimos sua localização',
      'Permita a localização no celular e tente de novo.',
    ),
    'LONGE_DO_TERMINAL': (
      'Você está longe da catraca',
      'Chegue mais perto da catraca e tente de novo.',
    ),
  };

  static String titulo(String? codigo) =>
      _textos[codigo]?.$1 ?? 'Acesso negado';

  static String oQueFazer(String? codigo) =>
      _textos[codigo]?.$2 ?? 'Fale com a portaria.';
}
```

**Arquivo novo:** `frontend/lib/core/constants/formato.dart`

```dart
import 'package:flutter/material.dart' show TimeOfDay;

import '../../models/usuario.dart';

/// Datas, horas e documentos como as telas mostram e como a API espera.
abstract final class Formato {
  static const _semana = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];
  static const _meses = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  static String _dois(int n) => n.toString().padLeft(2, '0');

  /// "AAAA-MM-DD", como a API recebe as datas das autorizações.
  static String dataApi(DateTime d) =>
      '${d.year}-${_dois(d.month)}-${_dois(d.day)}';

  /// "HH:MM", como a API recebe os horários.
  static String horaApi(TimeOfDay h) => '${_dois(h.hour)}:${_dois(h.minute)}';

  /// "HH:MM" da API de volta para o seletor de hora.
  static TimeOfDay horaDaApi(String hora) {
    final [h, m] = hora.split(':');
    return TimeOfDay(hour: int.parse(h), minute: int.parse(m));
  }

  /// "14/10/2026".
  static String data(DateTime d) =>
      '${_dois(d.day)}/${_dois(d.month)}/${d.year}';

  /// "14/10".
  static String diaMes(DateTime d) => '${_dois(d.day)}/${_dois(d.month)}';

  /// "09:12".
  static String hora(DateTime d) => '${_dois(d.hour)}:${_dois(d.minute)}';

  /// "Quarta-feira, 14 de outubro" (U2).
  static String dataPorExtenso(DateTime d) =>
      '${_semana[d.weekday - 1]}, ${d.day} de ${_meses[d.month - 1]}';

  /// "•••.456.789-••": a tela não mostra o CPF inteiro (U9, A3).
  static String cpfMascarado(String cpf) => cpf.length == 11
      ? '•••.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-••'
      : cpf;

  /// "123.456.789-00", para o campo do formulário (A4).
  static String cpf(String cpf) => cpf.length == 11
      ? '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.'
            '${cpf.substring(6, 9)}-${cpf.substring(9)}'
      : cpf;

  /// "MS", para o círculo com as iniciais (U9, A3).
  static String iniciais(String nome) {
    final partes = nome.trim().split(RegExp(r'\s+'));
    final primeira = partes.first.isEmpty ? '?' : partes.first[0];
    final ultima = partes.length > 1 ? partes.last[0] : '';
    return '$primeira$ultima'.toUpperCase();
  }

  /// "4F2A": os 4 últimos caracteres da tag (U9).
  static String finalTag(String uid) =>
      uid.length <= 4 ? uid : uid.substring(uid.length - 4);

  /// "Condômino", "Administrador"... (A3, A4, U9).
  static String perfil(Perfil perfil) => switch (perfil) {
    Perfil.admin => 'Administrador',
    Perfil.controladorAcesso => 'Controlador de acesso',
    Perfil.morador => 'Condômino',
    Perfil.visitante => 'Visitante',
  };
}
```

**Arquivo novo:** `frontend/lib/models/evento_acesso.dart`

```dart
/// Uma tentativa de acesso, como vem em GET /access-events e
/// GET /me/access-events.
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
```

**Arquivo novo:** `frontend/lib/models/usuario_cadastro.dart`

```dart
import 'usuario.dart';

/// Tag NFC vinculada a uma pessoa.
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

/// Pessoa como vem em GET /users, GET /users/:id e GET /auth/me. O [Usuario]
/// é o da sessão; este tem também a situação do cadastro e as tags.
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

  /// Só os 11 números, sem pontuação.
  final String cpf;
  final Perfil perfil;
  final bool ativo;
  final List<TagNfc> tags;
}
```

**Arquivo novo:** `frontend/lib/models/local.dart`

```dart
/// Árvore do GET /locations: edifício › portaria › porta › catraca.
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
      for (final item in json['portarias'] as List<dynamic>)
        Portaria.fromJson(item as Map<String, dynamic>),
    ],
  );

  final String id;
  final String nome;
  final String endereco;
  final List<Portaria> portarias;
}

class Portaria {
  const Portaria({required this.id, required this.nome, required this.portas});

  factory Portaria.fromJson(Map<String, dynamic> json) => Portaria(
    id: json['id'] as String,
    nome: json['nome'] as String,
    portas: [
      for (final item in json['portas'] as List<dynamic>)
        Porta.fromJson(item as Map<String, dynamic>),
    ],
  );

  final String id;
  final String nome;
  final List<Porta> portas;
}

class Porta {
  const Porta({required this.id, required this.nome, required this.catracas});

  factory Porta.fromJson(Map<String, dynamic> json) => Porta(
    id: json['id'] as String,
    nome: json['nome'] as String,
    catracas: [
      for (final item in json['catracas'] as List<dynamic>)
        Catraca.fromJson(item as Map<String, dynamic>),
    ],
  );

  final String id;
  final String nome;
  final List<Catraca> catracas;
}

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
    raioMetros: json['raioMetros'] as int,
  );

  final String id;
  final String nome;
  final String doorId;
  final double latitude;
  final double longitude;
  final int raioMetros;
}

/// Catraca com o caminho até ela, para os seletores dos formulários.
typedef CatracaNoLocal = ({Catraca catraca, String caminho});

/// Achata a árvore: "Catraca 1 · Portaria Principal › Porta A".
List<CatracaNoLocal> catracasDe(List<Edificio> edificios) => [
  for (final edificio in edificios)
    for (final portaria in edificio.portarias)
      for (final porta in portaria.portas)
        for (final catraca in porta.catracas)
          (
            catraca: catraca,
            caminho: '${catraca.nome} · ${portaria.nome} › ${porta.nome}',
          ),
];
```

**Arquivo novo:** `frontend/lib/models/terminal.dart`

```dart
/// Terminal de uma catraca, como vem em GET /terminals.
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

  /// A lista não traz o nome da catraca: a tela cruza com GET /locations.
  final String accessPointId;

  /// A API considera online com sinal nos últimos 90 s.
  final bool online;
  final DateTime? ultimoSinal;

  /// Só vem ao cadastrar ou trocar a chave, uma única vez.
  final String? chave;
}
```

**Arquivo novo:** `frontend/lib/models/autorizacao_equipe.dart`

```dart
import 'autorizacao.dart';
import 'usuario.dart';

/// Autorização como a equipe vê em GET /authorizations: a mesma do morador,
/// mais a pessoa autorizada.
class AutorizacaoEquipe {
  const AutorizacaoEquipe({
    required this.autorizacao,
    required this.pessoaId,
    required this.pessoaNome,
    required this.pessoaPerfil,
  });

  factory AutorizacaoEquipe.fromJson(Map<String, dynamic> json) {
    final pessoa = json['user'] as Map<String, dynamic>;
    return AutorizacaoEquipe(
      autorizacao: Autorizacao.fromJson(json),
      pessoaId: pessoa['id'] as String,
      pessoaNome: pessoa['nome'] as String,
      pessoaPerfil: Perfil.daApi(pessoa['perfil'] as String),
    );
  }

  final Autorizacao autorizacao;
  final String pessoaId;
  final String pessoaNome;
  final Perfil pessoaPerfil;
}
```

**Arquivo novo:** `frontend/lib/models/painel.dart`

```dart
import 'evento_acesso.dart';

/// Números do GET /dashboard (A1).
class Painel {
  const Painel({
    required this.acessosHoje,
    required this.negadosHoje,
    required this.autorizacoesAtivas,
    required this.negadosRecentes,
  });

  factory Painel.fromJson(Map<String, dynamic> json) => Painel(
    acessosHoje: json['acessosHoje'] as int,
    negadosHoje: json['negadosHoje'] as int,
    autorizacoesAtivas: json['autorizacoesAtivas'] as int,
    negadosRecentes: [
      for (final item in json['negadosRecentes'] as List<dynamic>)
        EventoAcesso.fromJson(item as Map<String, dynamic>),
    ],
  );

  final int acessosHoje;
  final int negadosHoje;

  /// Hoje também conta as agendadas e sem usos (B4 do backlog).
  final int autorizacoesAtivas;
  final List<EventoAcesso> negadosRecentes;
}
```

**Arquivo novo:** `frontend/lib/views/widgets/tela_base.dart`

```dart
import 'package:flutter/material.dart';

/// Estrutura das telas novas, igual à da U7: Voltar com texto, título,
/// subtítulo e conteúdo com no máximo 480 de largura. Com [onAtualizar], puxar
/// para baixo recarrega.
class TelaBase extends StatelessWidget {
  const TelaBase({
    super.key,
    required this.titulo,
    required this.filhos,
    this.subtitulo,
    this.onAtualizar,
    this.botaoFlutuante,
    this.rodape,
  });

  final String titulo;
  final String? subtitulo;
  final List<Widget> filhos;
  final Future<void> Function()? onAtualizar;

  /// Ex.: "+ Novo usuário" (A3).
  final Widget? botaoFlutuante;

  /// Fixo embaixo, ex.: "Salvar alterações" (A4).
  final Widget? rodape;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final rolagem = SingleChildScrollView(
      // Puxar para atualizar funciona mesmo com a lista curta.
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            // Sobra embaixo para o botão flutuante não cobrir o último item.
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              botaoFlutuante == null ? 24 : 96,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (Navigator.of(context).canPop())
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Voltar'),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(titulo, style: textTheme.headlineMedium),
                if (subtitulo != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitulo!,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ...filhos,
              ],
            ),
          ),
        ),
      ),
    );

    final atualizar = onAtualizar;
    return Scaffold(
      floatingActionButton: botaoFlutuante,
      body: SafeArea(
        child: atualizar == null
            ? rolagem
            : RefreshIndicator(onRefresh: atualizar, child: rolagem),
      ),
      bottomNavigationBar: rodape == null
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                  child: Center(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 432),
                      child: SizedBox(width: double.infinity, child: rodape),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
```

**Arquivo novo:** `frontend/lib/views/widgets/estado_vazio.dart`

```dart
import 'package:flutter/material.dart';

/// Indicador das listas enquanto a primeira resposta não volta.
class Carregando extends StatelessWidget {
  const Carregando({super.key, this.mensagem = 'Carregando…'});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(mensagem, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// Lista sem nada para mostrar, como a E4 e a A12: ícone, explicação e, se
/// fizer sentido, uma ação (ex.: "Limpar filtros").
class EstadoVazio extends StatelessWidget {
  const EstadoVazio({
    super.key,
    required this.icone,
    required this.titulo,
    required this.texto,
    this.rotuloAcao,
    this.iconeAcao,
    this.onAcao,
  });

  final IconData icone;
  final String titulo;
  final String texto;
  final String? rotuloAcao;
  final IconData? iconeAcao;
  final VoidCallback? onAcao;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: Icon(icone, size: 40),
            ),
          ),
          const SizedBox(height: 24),
          Text(titulo, textAlign: TextAlign.center, style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (rotuloAcao != null) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onAcao,
              icon: Icon(iconeAcao ?? Icons.refresh),
              label: Text(rotuloAcao!),
            ),
          ],
        ],
      ),
    );
  }
}
```

**Arquivo novo:** `frontend/lib/views/widgets/carrega_dados.dart`

```dart
import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../user/login_view.dart';
import 'cartao_erro.dart';
import 'estado_vazio.dart';
import 'tela_carregando.dart';

/// Sessão vencida (401): esquece o token e volta ao login, como o Sair dos
/// menus. Um lugar só para todas as telas novas (F2 do backlog).
Future<void> voltarAoLogin(BuildContext context) => TelaCarregando.abrir(
  context,
  mensagem: 'Sua sessão venceu. Voltando ao login…',
  tarefa: () async {
    await AuthService.instancia.sair();
    return LoginView();
  },
);

void avisar(BuildContext context, String mensagem) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mensagem)));
}

/// Trata o erro de uma ação (salvar, cancelar...): 401 volta ao login e o
/// resto vira aviso. Nos formulários, mostre antes os erros de [ApiException.campos].
Future<void> tratarErro(BuildContext context, ApiException erro) async {
  if (erro.naoAutenticado) {
    await voltarAoLogin(context);
  } else {
    avisar(context, erro.mensagem);
  }
}

/// Carrega os dados da tela ao abrir e guarda os estados da U7: carregando,
/// erro e pronto. A tela só implementa [buscar] e monta o conteúdo com
/// [conteudo].
mixin CarregaDados<T, W extends StatefulWidget> on State<W> {
  /// null enquanto carrega pela primeira vez.
  T? dados;
  ApiException? erro;

  Future<T> buscar();

  @override
  void initState() {
    super.initState();
    carregar();
  }

  /// Busca sem apagar o que está na tela (puxar para atualizar, voltar de um
  /// formulário). Se falhar com a lista já na tela, só avisa.
  Future<void> carregar() async {
    try {
      final novos = await buscar();
      if (!mounted) return;
      setState(() {
        dados = novos;
        erro = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.naoAutenticado) {
        await voltarAoLogin(context);
      } else if (dados == null) {
        setState(() => erro = e);
      } else {
        avisar(context, e.mensagem);
      }
    }
  }

  /// Volta ao carregando e busca de novo ("Tentar novamente", trocar filtro).
  void recarregar() {
    setState(() {
      dados = null;
      erro = null;
    });
    carregar();
  }

  /// Os filhos da tela: o erro, o carregando ou o que [pronto] montar.
  List<Widget> conteudo(List<Widget> Function(T dados) pronto) {
    if (erro case final e?) {
      return [
        CartaoErro(
          icone: e.semConexao ? Icons.wifi_off : Icons.error_outline,
          titulo: e.semConexao
              ? 'Sem conexão com a internet'
              : 'Não foi possível carregar',
          texto: e.semConexao
              ? 'Confira o Wi-Fi ou os dados móveis do celular e tente de novo.'
              : e.mensagem,
          onTentarDeNovo: recarregar,
        ),
      ];
    }
    final atuais = dados;
    if (atuais == null) return const [Carregando()];
    return pronto(atuais);
  }
}
```

**Arquivo novo:** `frontend/lib/views/widgets/selo.dart`

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/opcao_menu.dart';

/// Selo pequeno com ícone e texto, ex.: "Liberado", "Condômino", "Online".
/// Usa os mesmos tons do menu, para a cor acompanhar o modo do celular.
class Selo extends StatelessWidget {
  const Selo({
    super.key,
    required this.texto,
    required this.icone,
    this.tom = TomOpcao.padrao,
  });

  final String texto;
  final IconData icone;
  final TomOpcao tom;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = StatusColors.of(context);
    final (fundo, cor) = switch (tom) {
      TomOpcao.padrao => (
        colorScheme.primaryContainer,
        colorScheme.onPrimaryContainer,
      ),
      TomOpcao.sucesso => (status.successContainer, status.onSuccessContainer),
      TomOpcao.atencao => (status.warningContainer, status.onWarningContainer),
      TomOpcao.perigo => (
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
      ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 16, color: cor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                texto,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: cor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Arquivo novo:** `frontend/lib/views/widgets/campo_selecao.dart`

```dart
import 'package:flutter/material.dart';

/// Campo que abre um seletor em vez do teclado (data e hora em A8 e A9).
class CampoSelecao extends StatelessWidget {
  const CampoSelecao({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.icone,
    required this.onTocar,
  });

  final String rotulo;
  final String valor;
  final IconData icone;
  final VoidCallback onTocar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: '$rotulo: $valor',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(rotulo, style: textTheme.labelLarge),
          const SizedBox(height: 8),
          InkWell(
            onTap: onTocar,
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
              decoration: InputDecoration(prefixIcon: Icon(icone)),
              child: Text(valor, style: textTheme.bodyLarge),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista de escolha com o rótulo em cima, como o [CampoTexto].
class CampoEscolha<T> extends StatelessWidget {
  const CampoEscolha({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.opcoes,
    required this.onMudar,
    required this.icone,
    this.validator,
  });

  final String rotulo;
  final T? valor;

  /// Valor e texto de cada opção. Um valor null serve para "Todas".
  final List<(T, String)> opcoes;

  /// null desabilita (ex.: a pessoa não muda ao editar uma autorização).
  final ValueChanged<T?>? onMudar;
  final IconData icone;
  final FormFieldValidator<T>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(rotulo, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          initialValue: valor,
          isExpanded: true,
          // Sem isto, o campo vazio não mostra nem anuncia nada.
          hint: const Text('Escolha…'),
          validator: validator,
          decoration: InputDecoration(prefixIcon: Icon(icone)),
          onChanged: onMudar,
          items: [
            for (final (valor, texto) in opcoes)
              DropdownMenuItem(
                value: valor,
                child: Text(texto, overflow: TextOverflow.ellipsis),
              ),
          ],
        ),
      ],
    );
  }
}

/// Uma escolha entre poucas opções, em chips (Status em A8, Resultado em A11).
class EscolhaEmChips<T> extends StatelessWidget {
  const EscolhaEmChips({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.opcoes,
    required this.onMudar,
  });

  final String rotulo;
  final T valor;
  final List<(T, String)> opcoes;
  final ValueChanged<T> onMudar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(rotulo, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (opcao, texto) in opcoes)
              ChoiceChip(
                label: Text(texto),
                selected: opcao == valor,
                onSelected: (_) => onMudar(opcao),
              ),
          ],
        ),
      ],
    );
  }
}

/// Botão "Filtrar" das listas (A7, A11). Um botão de verdade: o ActionChip é
/// anunciado como caixa de seleção pelo leitor de tela.
class BotaoFiltrar extends StatelessWidget {
  const BotaoFiltrar({super.key, required this.onTocar});

  final VoidCallback onTocar;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTocar,
      icon: const Icon(Icons.tune),
      label: const Text('Filtrar'),
      style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
    );
  }
}
```

**Arquivo novo:** `frontend/lib/views/widgets/item_evento.dart`

```dart
import 'package:flutter/material.dart';

import '../../core/constants/formato.dart';
import '../../core/constants/motivos.dart';
import '../../models/evento_acesso.dart';
import '../../models/opcao_menu.dart';
import 'selo.dart';

/// Uma linha do histórico (A11) e dos negados recentes (A1).
class ItemEvento extends StatelessWidget {
  const ItemEvento({
    super.key,
    required this.evento,
    this.mostrarPessoa = true,
    this.mostrarOQueFazer = false,
  });

  final EventoAcesso evento;

  /// A equipe vê quem tentou; o morador só vê os próprios acessos.
  final bool mostrarPessoa;

  /// O morador vê como resolver; a equipe só o motivo.
  final bool mostrarOQueFazer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final titulo = mostrarPessoa
        ? (evento.pessoa ?? 'Pessoa não identificada')
        : (evento.catraca ?? 'Catraca não identificada');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 64,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Formato.hora(evento.em), style: textTheme.titleMedium),
                    Text(
                      Formato.diaMes(evento.em),
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: textTheme.titleMedium),
                    if (mostrarPessoa && evento.catraca != null)
                      Text(evento.catraca!, style: textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        evento.liberado
                            ? const Selo(
                                texto: 'Liberado',
                                icone: Icons.check_circle,
                                tom: TomOpcao.sucesso,
                              )
                            : const Selo(
                                texto: 'Negado',
                                icone: Icons.cancel,
                                tom: TomOpcao.perigo,
                              ),
                        Selo(
                          texto: evento.metodo == 'NFC' ? 'Tag NFC' : 'QR Code',
                          icone: evento.metodo == 'NFC'
                              ? Icons.contactless_outlined
                              : Icons.qr_code_2,
                        ),
                      ],
                    ),
                    if (!evento.liberado) ...[
                      const SizedBox(height: 8),
                      Text(
                        Motivos.titulo(evento.motivo),
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (mostrarOQueFazer)
                        Text(
                          Motivos.oQueFazer(evento.motivo),
                          style: textTheme.bodySmall,
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## 2. Telas

Cada tela tem o que colar e o que você provavelmente vai querer mudar.

### C1. Histórico de acessos e Acessos negados (A11, A12, S2 e S3)

A mesma tela serve aos 4 perfis. `daEquipe` escolhe a rota; `soNegados` fixa o filtro.

**Arquivo novo:** `frontend/lib/controllers/historico_controller.dart`

```dart
import '../core/constants/formato.dart';
import '../models/evento_acesso.dart';
import '../models/local.dart';
import '../services/api_client.dart';

/// Período do filtro do histórico (A8, A11).
enum PeriodoHistorico {
  tudo('Tudo'),
  hoje('Hoje'),
  seteDias('7 dias'),
  trintaDias('30 dias');

  const PeriodoHistorico(this.rotulo);

  final String rotulo;
}

/// Filtros do histórico. null = sem esse filtro.
class FiltroEventos {
  const FiltroEventos({
    this.periodo = PeriodoHistorico.tudo,
    this.negados,
    this.metodo,
    this.catracaId,
    this.catracaNome,
  });

  final PeriodoHistorico periodo;

  /// true só negados, false só liberados.
  final bool? negados;

  /// "QR" ou "NFC".
  final String? metodo;
  final String? catracaId;
  final String? catracaNome;

  bool get vazio =>
      periodo == PeriodoHistorico.tudo &&
      negados == null &&
      metodo == null &&
      catracaId == null;
}

/// Histórico de acessos. A equipe lê todos em /access-events; morador e
/// visitante só os próprios em /me/access-events (403 no outro).
class HistoricoController {
  HistoricoController({
    required this.daEquipe,
    ApiClient? api,
    DateTime Function()? relogio,
  }) : _api = api ?? ApiClient.instancia,
       _relogio = relogio ?? DateTime.now;

  final bool daEquipe;
  final ApiClient _api;
  final DateTime Function() _relogio;

  /// A API aceita de 1 a 200 por página.
  static const porPagina = 50;

  DateTime agora() => _relogio();

  Future<PaginaEventos> carregar(
    FiltroEventos filtro, {
    int pular = 0,
    int limite = porPagina,
  }) async {
    final resposta = await _api.get(
      daEquipe ? '/access-events' : '/me/access-events',
      query: {
        ..._periodo(filtro.periodo),
        if (filtro.negados != null)
          'resultado': filtro.negados! ? 'NEGADO' : 'LIBERADO',
        if (filtro.metodo != null) 'metodo': filtro.metodo!,
        if (filtro.catracaId != null) 'accessPointId': filtro.catracaId!,
        'limite': '$limite',
        'pular': '$pular',
      },
    );
    return PaginaEventos.fromJson(resposta as Map<String, dynamic>);
  }

  /// Vai sempre com data e hora: "2026-11-02" sozinho a API lê como meia-noite
  /// em UTC, então o "ate" cortaria o dia inteiro.
  Map<String, String> _periodo(PeriodoHistorico periodo) {
    if (periodo == PeriodoHistorico.tudo) return const {};
    final hoje = agora();
    final dias = switch (periodo) {
      PeriodoHistorico.seteDias => 6,
      PeriodoHistorico.trintaDias => 29,
      _ => 0,
    };
    final inicio = DateTime(hoje.year, hoje.month, hoje.day - dias);
    final fim = DateTime(hoje.year, hoje.month, hoje.day, 23, 59, 59);
    return {
      'de': inicio.toUtc().toIso8601String(),
      'ate': fim.toUtc().toIso8601String(),
    };
  }

  /// Catracas para o filtro. Só a equipe pode ler GET /locations.
  Future<List<CatracaNoLocal>> catracas() async {
    if (!daEquipe) return const [];
    final lista = await _api.get('/locations') as List<dynamic>;
    return catracasDe([
      for (final json in lista)
        Edificio.fromJson(json as Map<String, dynamic>),
    ]);
  }

  /// "Hoje, 14/10" no chip do filtro.
  String rotuloPeriodo(PeriodoHistorico periodo) =>
      periodo == PeriodoHistorico.hoje
      ? 'Hoje, ${Formato.diaMes(agora())}'
      : periodo.rotulo;
}
```

**Arquivo novo:** `frontend/lib/views/compartilhado/historico_view.dart`

```dart
import 'package:flutter/material.dart';

import '../../controllers/historico_controller.dart';
import '../../models/evento_acesso.dart';
import '../../models/local.dart';
import '../../services/api_client.dart';
import '../widgets/botao_acao.dart';
import '../widgets/campo_selecao.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/estado_vazio.dart';
import '../widgets/item_evento.dart';
import '../widgets/tela_base.dart';

/// A11 · Histórico de acessos, com A12 (sem resultados) e os filtros. É a
/// mesma tela para os quatro perfis e para "Acessos negados" ([soNegados]).
class HistoricoView extends StatefulWidget {
  HistoricoView({
    super.key,
    required this.daEquipe,
    this.soNegados = false,
    HistoricoController? controller,
  }) : controller = controller ?? HistoricoController(daEquipe: daEquipe);

  /// true: todos os acessos (/access-events). false: só os de quem está logado.
  final bool daEquipe;
  final bool soNegados;
  final HistoricoController controller;

  @override
  State<HistoricoView> createState() => _HistoricoViewState();
}

class _HistoricoViewState extends State<HistoricoView>
    with CarregaDados<PaginaEventos, HistoricoView> {
  var _filtro = const FiltroEventos();
  var _carregandoMais = false;

  HistoricoController get controller => widget.controller;

  FiltroEventos get _filtroDaTela => FiltroEventos(
    periodo: _filtro.periodo,
    negados: widget.soNegados ? true : _filtro.negados,
    metodo: _filtro.metodo,
    catracaId: _filtro.catracaId,
    catracaNome: _filtro.catracaNome,
  );

  @override
  Future<PaginaEventos> buscar() => controller.carregar(_filtroDaTela);

  Future<void> _carregarMais(PaginaEventos atual) async {
    setState(() => _carregandoMais = true);
    try {
      final proxima = await controller.carregar(
        _filtroDaTela,
        pular: atual.itens.length,
      );
      if (mounted) setState(() => dados = atual.comMais(proxima));
    } on ApiException catch (e) {
      if (mounted) await tratarErro(context, e);
    } finally {
      if (mounted) setState(() => _carregandoMais = false);
    }
  }

  void _aplicar(FiltroEventos filtro) {
    _filtro = filtro;
    recarregar();
  }

  Future<void> _abrirFiltros() async {
    final filtro = await showModalBottomSheet<FiltroEventos>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FiltrosHistorico(
        inicial: _filtro,
        soNegados: widget.soNegados,
        controller: controller,
      ),
    );
    if (filtro != null) _aplicar(filtro);
  }

  List<Widget> _chips() {
    return [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          BotaoFiltrar(onTocar: _abrirFiltros),
          if (_filtro.periodo != PeriodoHistorico.tudo)
            InputChip(
              label: Text(controller.rotuloPeriodo(_filtro.periodo)),
              onDeleted: () => _aplicar(
                FiltroEventos(
                  negados: _filtro.negados,
                  metodo: _filtro.metodo,
                  catracaId: _filtro.catracaId,
                  catracaNome: _filtro.catracaNome,
                ),
              ),
            ),
          if (_filtro.negados != null)
            InputChip(
              label: Text(_filtro.negados! ? 'Negados' : 'Liberados'),
              onDeleted: () => _aplicar(
                FiltroEventos(
                  periodo: _filtro.periodo,
                  metodo: _filtro.metodo,
                  catracaId: _filtro.catracaId,
                  catracaNome: _filtro.catracaNome,
                ),
              ),
            ),
          if (_filtro.metodo != null)
            InputChip(
              label: Text(_filtro.metodo == 'NFC' ? 'Tag NFC' : 'QR Code'),
              onDeleted: () => _aplicar(
                FiltroEventos(
                  periodo: _filtro.periodo,
                  negados: _filtro.negados,
                  catracaId: _filtro.catracaId,
                  catracaNome: _filtro.catracaNome,
                ),
              ),
            ),
          if (_filtro.catracaId != null)
            InputChip(
              label: Text(_filtro.catracaNome ?? 'Catraca'),
              onDeleted: () => _aplicar(
                FiltroEventos(
                  periodo: _filtro.periodo,
                  negados: _filtro.negados,
                  metodo: _filtro.metodo,
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 16),
    ];
  }

  String _resumo(PaginaEventos p) => widget.soNegados
      ? '${p.total} ${p.total == 1 ? 'acesso negado' : 'acessos negados'}'
      : '${p.total} registros · ${p.liberados} liberados, ${p.negados} negados';

  List<Widget> _lista(PaginaEventos pagina) {
    if (pagina.itens.isEmpty) {
      return [
        EstadoVazio(
          icone: Icons.search_off,
          titulo: 'Nenhum acesso encontrado',
          texto: _filtro.vazio
              ? 'Quando alguém passar pela catraca, o acesso aparece aqui.'
              : 'Mude os filtros ou escolha outro período.',
          rotuloAcao: _filtro.vazio ? null : 'Limpar filtros',
          iconeAcao: Icons.filter_alt_off,
          onAcao: () => _aplicar(const FiltroEventos()),
        ),
      ];
    }
    return [
      Text(_resumo(pagina), style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 12),
      for (final evento in pagina.itens)
        ItemEvento(
          evento: evento,
          mostrarPessoa: widget.daEquipe,
          mostrarOQueFazer: !widget.daEquipe,
        ),
      if (pagina.itens.length < pagina.total)
        OutlinedButton.icon(
          onPressed: _carregandoMais ? null : () => _carregarMais(pagina),
          icon: const Icon(Icons.expand_more),
          label: Text(_carregandoMais ? 'Carregando…' : 'Carregar mais'),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      titulo: widget.soNegados ? 'Acessos negados' : 'Histórico de acessos',
      subtitulo: widget.soNegados
          ? (widget.daEquipe ? 'Motivo de cada recusa' : 'Motivo e o que fazer')
          : (widget.daEquipe
                ? 'Entradas liberadas e negadas'
                : 'Suas entradas liberadas e negadas'),
      onAtualizar: carregar,
      filhos: [..._chips(), ...conteudo(_lista)],
    );
  }
}

class _FiltrosHistorico extends StatefulWidget {
  const _FiltrosHistorico({
    required this.inicial,
    required this.soNegados,
    required this.controller,
  });

  final FiltroEventos inicial;
  final bool soNegados;
  final HistoricoController controller;

  @override
  State<_FiltrosHistorico> createState() => _FiltrosHistoricoState();
}

class _FiltrosHistoricoState extends State<_FiltrosHistorico> {
  late var _periodo = widget.inicial.periodo;
  late var _negados = widget.inicial.negados;
  late var _metodo = widget.inicial.metodo;
  late var _catracaId = widget.inicial.catracaId;
  List<CatracaNoLocal> _catracas = const [];

  @override
  void initState() {
    super.initState();
    _carregarCatracas();
  }

  Future<void> _carregarCatracas() async {
    try {
      final lista = await widget.controller.catracas();
      if (mounted) setState(() => _catracas = lista);
    } on ApiException {
      // Sem a lista, o filtro de local só não aparece.
    }
  }

  void _mostrar() {
    final catraca = _catracas
        .where((c) => c.catraca.id == _catracaId)
        .firstOrNull;
    Navigator.of(context).pop(
      FiltroEventos(
        periodo: _periodo,
        negados: _negados,
        metodo: _metodo,
        catracaId: _catracaId,
        catracaNome: catraca?.catraca.nome ?? widget.inicial.catracaNome,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Filtrar histórico',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            EscolhaEmChips<PeriodoHistorico>(
              rotulo: 'Período',
              valor: _periodo,
              opcoes: [for (final p in PeriodoHistorico.values) (p, p.rotulo)],
              onMudar: (p) => setState(() => _periodo = p),
            ),
            if (!widget.soNegados) ...[
              const SizedBox(height: 20),
              EscolhaEmChips<bool?>(
                rotulo: 'Resultado',
                valor: _negados,
                opcoes: const [
                  (null, 'Todos'),
                  (false, 'Liberados'),
                  (true, 'Negados'),
                ],
                onMudar: (v) => setState(() => _negados = v),
              ),
            ],
            const SizedBox(height: 20),
            EscolhaEmChips<String?>(
              rotulo: 'Como entrou',
              valor: _metodo,
              opcoes: const [
                (null, 'Todos'),
                ('QR', 'QR Code'),
                ('NFC', 'Tag NFC'),
              ],
              onMudar: (v) => setState(() => _metodo = v),
            ),
            if (_catracas.isNotEmpty) ...[
              const SizedBox(height: 20),
              CampoEscolha<String?>(
                rotulo: 'Local',
                valor: _catracaId,
                icone: Icons.location_on_outlined,
                opcoes: [
                  (null, 'Todos os locais'),
                  for (final c in _catracas) (c.catraca.id, c.caminho),
                ],
                onMudar: (v) => setState(() => _catracaId = v),
              ),
            ],
            const SizedBox(height: 24),
            BotaoAcao(
              rotulo: 'Mostrar resultados',
              icone: Icons.check,
              onTocar: _mostrar,
            ),
          ],
        ),
      ),
    );
  }
}
```

**Para ajustar:**

- Agrupar por dia, se quiser ficar mais perto do design.
- O filtro usa períodos prontos (Hoje, 7 dias, 30 dias). Para o design completo, troque por seletores de data, como na A8.

### C2. Autorizações (A7, A8, A9 e A10)

Lista, filtros, formulário e confirmação de cancelamento.

**Arquivo novo:** `frontend/lib/controllers/autorizacoes_controller.dart`

```dart
import '../core/constants/formato.dart';
import '../models/autorizacao.dart';
import '../models/autorizacao_equipe.dart';
import '../models/local.dart';
import '../models/usuario_cadastro.dart';
import '../services/api_client.dart';

/// Filtros da A7/A8. null = sem esse filtro. A API só filtra por ativa,
/// expirada e cancelada.
class FiltroAutorizacoes {
  const FiltroAutorizacoes({
    this.pessoaId,
    this.pessoaNome,
    this.catracaId,
    this.catracaNome,
    this.situacao,
    this.de,
    this.ate,
  });

  final String? pessoaId;
  final String? pessoaNome;
  final String? catracaId;
  final String? catracaNome;
  final SituacaoAutorizacao? situacao;
  final DateTime? de;
  final DateTime? ate;
}

/// Os dados que o formulário precisa para os seletores.
typedef OpcoesAutorizacao = ({
  List<UsuarioCadastro> pessoas,
  List<CatracaNoLocal> catracas,
});

/// Autorizações pela equipe (RF03, RF04, RF05): A7, A8, A9 e A10.
class AutorizacoesController {
  AutorizacoesController({ApiClient? api}) : _api = api ?? ApiClient.instancia;

  final ApiClient _api;

  Future<List<AutorizacaoEquipe>> listar(FiltroAutorizacoes filtro) async {
    final lista =
        await _api.get(
              '/authorizations',
              query: {
                if (filtro.pessoaId != null) 'userId': filtro.pessoaId!,
                if (filtro.catracaId != null) 'accessPointId': filtro.catracaId!,
                if (filtro.situacao != null) 'situacao': filtro.situacao!.api,
                if (filtro.de != null) 'de': Formato.dataApi(filtro.de!),
                if (filtro.ate != null) 'ate': Formato.dataApi(filtro.ate!),
              },
            )
            as List<dynamic>;
    final todas = [
      for (final json in lista)
        AutorizacaoEquipe.fromJson(json as Map<String, dynamic>),
    ];
    // O filtro ATIVA da API também traz agendadas e sem usos (B4 do backlog).
    return filtro.situacao == SituacaoAutorizacao.ativa
        ? [
            for (final a in todas)
              if (a.autorizacao.situacao == SituacaoAutorizacao.ativa) a,
          ]
        : todas;
  }

  /// Pessoas de GET /users e catracas de GET /locations, para os seletores.
  Future<OpcoesAutorizacao> opcoes() async {
    final [usuarios, locais] = await Future.wait([
      _api.get('/users'),
      _api.get('/locations'),
    ]);
    return (
      pessoas: [
        for (final json in usuarios as List<dynamic>)
          UsuarioCadastro.fromJson(json as Map<String, dynamic>),
      ],
      catracas: catracasDe([
        for (final json in locais as List<dynamic>)
          Edificio.fromJson(json as Map<String, dynamic>),
      ]),
    );
  }

  Future<void> criar({
    required String pessoaId,
    required String catracaId,
    required DateTime dataInicio,
    required DateTime dataFim,
    required String horaInicio,
    required String horaFim,
    required int maxUsos,
  }) => _api.post('/authorizations', {
    'userId': pessoaId,
    'accessPointId': catracaId,
    'dataInicio': Formato.dataApi(dataInicio),
    'dataFim': Formato.dataApi(dataFim),
    'horaInicio': horaInicio,
    'horaFim': horaFim,
    'maxUsos': maxUsos,
  });

  /// A pessoa não muda; autorização cancelada não se edita (409) e os usos
  /// não podem ficar abaixo do que já foi usado (400).
  Future<void> atualizar(
    String id, {
    required String catracaId,
    required DateTime dataInicio,
    required DateTime dataFim,
    required String horaInicio,
    required String horaFim,
    required int maxUsos,
  }) => _api.patch('/authorizations/$id', {
    'accessPointId': catracaId,
    'dataInicio': Formato.dataApi(dataInicio),
    'dataFim': Formato.dataApi(dataFim),
    'horaInicio': horaInicio,
    'horaFim': horaFim,
    'maxUsos': maxUsos,
  });

  Future<void> cancelar(String id) => _api.post('/authorizations/$id/cancel');
}
```

**Arquivo novo:** `frontend/lib/views/equipe/autorizacoes_view.dart`

```dart
import 'package:flutter/material.dart';

import '../../controllers/autorizacoes_controller.dart';
import '../../core/constants/formato.dart';
import '../../models/autorizacao.dart';
import '../../models/autorizacao_equipe.dart';
import '../../services/api_client.dart';
import '../user/autorizacao_textos.dart';
import '../widgets/botao_acao.dart';
import '../widgets/campo_selecao.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/estado_vazio.dart';
import '../widgets/selo_situacao.dart';
import '../widgets/tela_base.dart';
import 'autorizacao_form_view.dart';

/// A7 · Autorizações, com a A8 (filtros) num painel que sobe de baixo.
class AutorizacoesView extends StatefulWidget {
  AutorizacoesView({super.key, AutorizacoesController? controller})
    : controller = controller ?? AutorizacoesController();

  final AutorizacoesController controller;

  @override
  State<AutorizacoesView> createState() => _AutorizacoesViewState();
}

class _AutorizacoesViewState extends State<AutorizacoesView>
    with CarregaDados<List<AutorizacaoEquipe>, AutorizacoesView> {
  var _filtro = const FiltroAutorizacoes();

  AutorizacoesController get controller => widget.controller;

  @override
  Future<List<AutorizacaoEquipe>> buscar() => controller.listar(_filtro);

  void _aplicar(FiltroAutorizacoes filtro) {
    _filtro = filtro;
    recarregar();
  }

  Future<void> _abrirFiltros() async {
    final filtro = await showModalBottomSheet<FiltroAutorizacoes>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          _FiltrosAutorizacoes(inicial: _filtro, controller: controller),
    );
    if (filtro != null) _aplicar(filtro);
  }

  Future<void> _abrirFormulario([AutorizacaoEquipe? autorizacao]) async {
    final salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AutorizacaoFormView(
          autorizacao: autorizacao,
          controller: controller,
        ),
      ),
    );
    if (salvou == true && mounted) await carregar();
  }

  List<Widget> _lista(List<AutorizacaoEquipe> lista) {
    if (lista.isEmpty) {
      return [
        EstadoVazio(
          icone: Icons.event_busy,
          titulo: 'Nenhuma autorização encontrada',
          texto: 'Mude os filtros ou crie uma nova autorização.',
          rotuloAcao: 'Limpar filtros',
          iconeAcao: Icons.filter_alt_off,
          onAcao: () => _aplicar(const FiltroAutorizacoes()),
        ),
      ];
    }
    final hoje = DateTime.now();
    return [
      Text(
        '${lista.length} ${lista.length == 1 ? 'autorização' : 'autorizações'}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 12),
      for (final item in lista)
        _CartaoAutorizacaoEquipe(
          item: item,
          hoje: hoje,
          onEditar: () => _abrirFormulario(item),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final f = _filtro;
    return TelaBase(
      titulo: 'Autorizações',
      subtitulo: 'Quem pode entrar, onde e quando',
      onAtualizar: carregar,
      botaoFlutuante: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        icon: const Icon(Icons.add),
        label: const Text('Nova autorização'),
      ),
      filhos: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            BotaoFiltrar(onTocar: _abrirFiltros),
            if (f.situacao != null)
              Chip(label: Text('Status: ${f.situacao!.rotulo}')),
            if (f.pessoaNome != null) Chip(label: Text(f.pessoaNome!)),
            if (f.catracaNome != null) Chip(label: Text(f.catracaNome!)),
            if (f.de != null) Chip(label: Text('De ${Formato.data(f.de!)}')),
            if (f.ate != null) Chip(label: Text('Até ${Formato.data(f.ate!)}')),
          ],
        ),
        const SizedBox(height: 16),
        ...conteudo(_lista),
      ],
    );
  }
}

class _CartaoAutorizacaoEquipe extends StatelessWidget {
  const _CartaoAutorizacaoEquipe({
    required this.item,
    required this.hoje,
    required this.onEditar,
  });

  final AutorizacaoEquipe item;
  final DateTime hoje;
  final VoidCallback onEditar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final a = item.autorizacao;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onEditar,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.pessoaNome, style: textTheme.titleMedium),
                          Text(
                            '${a.catraca.nome} · ${a.catraca.edificio}',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SeloSituacao(situacao: a.situacao),
                  ],
                ),
                const Divider(height: 24),
                _Linha(Icons.event_outlined, a.periodoCurto(hoje)),
                _Linha(Icons.schedule, a.horario),
                _Linha(Icons.confirmation_number_outlined, a.usos),
                TextButton(
                  onPressed: onEditar,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: Text('Ver e editar')),
                      Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha(this.icone, this.texto);

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icone,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texto, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// A8 · Filtros.
class _FiltrosAutorizacoes extends StatefulWidget {
  const _FiltrosAutorizacoes({required this.inicial, required this.controller});

  final FiltroAutorizacoes inicial;
  final AutorizacoesController controller;

  @override
  State<_FiltrosAutorizacoes> createState() => _FiltrosAutorizacoesState();
}

class _FiltrosAutorizacoesState extends State<_FiltrosAutorizacoes> {
  late var _pessoaId = widget.inicial.pessoaId;
  late var _catracaId = widget.inicial.catracaId;
  late var _situacao = widget.inicial.situacao;
  late var _de = widget.inicial.de;
  late var _ate = widget.inicial.ate;
  OpcoesAutorizacao? _opcoes;

  @override
  void initState() {
    super.initState();
    _carregarOpcoes();
  }

  Future<void> _carregarOpcoes() async {
    try {
      final opcoes = await widget.controller.opcoes();
      if (mounted) setState(() => _opcoes = opcoes);
    } on ApiException catch (e) {
      if (mounted) await tratarErro(context, e);
    }
  }

  Future<void> _escolherData(bool inicio) async {
    final atual = inicio ? _de : _ate;
    final hoje = DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: atual ?? hoje,
      firstDate: DateTime(hoje.year - 5),
      lastDate: DateTime(hoje.year + 5),
    );
    if (data != null) setState(() => inicio ? _de = data : _ate = data);
  }

  void _mostrar() {
    final opcoes = _opcoes;
    Navigator.of(context).pop(
      FiltroAutorizacoes(
        pessoaId: _pessoaId,
        pessoaNome: opcoes?.pessoas
            .where((p) => p.id == _pessoaId)
            .firstOrNull
            ?.nome,
        catracaId: _catracaId,
        catracaNome: opcoes?.catracas
            .where((c) => c.catraca.id == _catracaId)
            .firstOrNull
            ?.catraca
            .nome,
        situacao: _situacao,
        de: _de,
        ate: _ate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final opcoes = _opcoes;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Filtrar autorizações',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            if (opcoes == null)
              const Carregando(mensagem: 'Carregando pessoas e locais…')
            else ...[
              CampoEscolha<String?>(
                rotulo: 'Pessoa',
                valor: _pessoaId,
                icone: Icons.person_outline,
                opcoes: [
                  (null, 'Todas as pessoas'),
                  for (final p in opcoes.pessoas) (p.id, p.nome),
                ],
                onMudar: (v) => setState(() => _pessoaId = v),
              ),
              const SizedBox(height: 16),
              CampoEscolha<String?>(
                rotulo: 'Local',
                valor: _catracaId,
                icone: Icons.location_on_outlined,
                opcoes: [
                  (null, 'Todos os locais'),
                  for (final c in opcoes.catracas) (c.catraca.id, c.caminho),
                ],
                onMudar: (v) => setState(() => _catracaId = v),
              ),
            ],
            const SizedBox(height: 16),
            EscolhaEmChips<SituacaoAutorizacao?>(
              rotulo: 'Status',
              valor: _situacao,
              opcoes: const [
                (null, 'Todas'),
                (SituacaoAutorizacao.ativa, 'Ativa'),
                (SituacaoAutorizacao.expirada, 'Expirada'),
                (SituacaoAutorizacao.cancelada, 'Cancelada'),
              ],
              onMudar: (v) => setState(() => _situacao = v),
            ),
            const SizedBox(height: 16),
            CampoSelecao(
              rotulo: 'Início do período',
              valor: _de == null ? 'Qualquer data' : Formato.data(_de!),
              icone: Icons.event_outlined,
              onTocar: () => _escolherData(true),
            ),
            const SizedBox(height: 16),
            CampoSelecao(
              rotulo: 'Fim do período',
              valor: _ate == null ? 'Qualquer data' : Formato.data(_ate!),
              icone: Icons.event_outlined,
              onTocar: () => _escolherData(false),
            ),
            const SizedBox(height: 24),
            BotaoAcao(
              rotulo: 'Mostrar resultados',
              icone: Icons.check,
              onTocar: _mostrar,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(const FiltroAutorizacoes()),
              child: const Text('Limpar filtros'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Arquivo novo:** `frontend/lib/views/equipe/autorizacao_form_view.dart`

```dart
import 'package:flutter/material.dart';

import '../../controllers/autorizacoes_controller.dart';
import '../../core/constants/formato.dart';
import '../../models/autorizacao.dart';
import '../../models/autorizacao_equipe.dart';
import '../../models/usuario_cadastro.dart';
import '../../services/api_client.dart';
import '../widgets/botao_acao.dart';
import '../widgets/campo_selecao.dart';
import '../widgets/campo_texto.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/tela_base.dart';

/// A9 · Autorização · formulário, com a A10 (confirmar cancelamento). Ao salvar
/// ou cancelar, volta com true para a lista recarregar.
class AutorizacaoFormView extends StatefulWidget {
  AutorizacaoFormView({
    super.key,
    this.autorizacao,
    this.pessoaFixa,
    AutorizacoesController? controller,
  }) : controller = controller ?? AutorizacoesController();

  /// null cria uma nova.
  final AutorizacaoEquipe? autorizacao;

  /// Já escolhe a pessoa, ex.: passo 2 do cadastro de visitante.
  final UsuarioCadastro? pessoaFixa;
  final AutorizacoesController controller;

  @override
  State<AutorizacaoFormView> createState() => _AutorizacaoFormViewState();
}

class _AutorizacaoFormViewState extends State<AutorizacaoFormView>
    with CarregaDados<OpcoesAutorizacao, AutorizacaoFormView> {
  final _form = GlobalKey<FormState>();
  late final _a = widget.autorizacao?.autorizacao;
  late var _pessoaId = widget.autorizacao?.pessoaId ?? widget.pessoaFixa?.id;
  late var _catracaId = _a?.catraca.id;
  late var _inicio = _a?.dataInicio ?? DateTime.now();
  late var _fim = _a?.dataFim ?? DateTime.now();
  late var _horaInicio = _a == null
      ? const TimeOfDay(hour: 8, minute: 0)
      : Formato.horaDaApi(_a.horaInicio);
  late var _horaFim = _a == null
      ? const TimeOfDay(hour: 18, minute: 0)
      : Formato.horaDaApi(_a.horaFim);
  late final _usos = TextEditingController(text: '${_a?.maxUsos ?? 1}');
  var _salvando = false;

  bool get _nova => _a == null;
  bool get _cancelada => _a?.situacao == SituacaoAutorizacao.cancelada;

  @override
  Future<OpcoesAutorizacao> buscar() => widget.controller.opcoes();

  @override
  void dispose() {
    _usos.dispose();
    super.dispose();
  }

  Future<void> _escolherData(bool inicio) async {
    final hoje = DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: inicio ? _inicio : _fim,
      firstDate: DateTime(hoje.year - 5),
      lastDate: DateTime(hoje.year + 5),
    );
    if (data == null) return;
    setState(() {
      if (inicio) {
        _inicio = data;
        // Mantém o período válido sem obrigar a abrir o outro campo.
        if (_fim.isBefore(data)) _fim = data;
      } else {
        _fim = data;
      }
    });
  }

  Future<void> _escolherHora(bool inicio) async {
    final hora = await showTimePicker(
      context: context,
      initialTime: inicio ? _horaInicio : _horaFim,
    );
    if (hora != null) {
      setState(() => inicio ? _horaInicio = hora : _horaFim = hora);
    }
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    if (_fim.isBefore(_inicio)) {
      avisar(context, 'A data de término precisa ser depois da de início.');
      return;
    }
    if (_horaInicio == _horaFim) {
      avisar(context, 'O horário inicial e o final não podem ser iguais.');
      return;
    }
    setState(() => _salvando = true);
    try {
      final horaInicio = Formato.horaApi(_horaInicio);
      final horaFim = Formato.horaApi(_horaFim);
      final maxUsos = int.parse(_usos.text.trim());
      if (_nova) {
        await widget.controller.criar(
          pessoaId: _pessoaId!,
          catracaId: _catracaId!,
          dataInicio: _inicio,
          dataFim: _fim,
          horaInicio: horaInicio,
          horaFim: horaFim,
          maxUsos: maxUsos,
        );
      } else {
        await widget.controller.atualizar(
          _a!.id,
          catracaId: _catracaId!,
          dataInicio: _inicio,
          dataFim: _fim,
          horaInicio: horaInicio,
          horaFim: horaFim,
          maxUsos: maxUsos,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) await tratarErro(context, e);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  /// A10 · Cancelar · confirmação.
  Future<void> _cancelar() async {
    final nome = widget.autorizacao!.pessoaNome;
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        actionsOverflowButtonSpacing: 8,
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(contexto).colorScheme.error,
          size: 36,
        ),
        title: const Text('Cancelar esta autorização?'),
        content: Text(
          '$nome não vai mais conseguir passar pela ${_a!.catraca.nome}. Para '
          'liberar de novo, é preciso criar outra autorização.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Não, manter'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(contexto).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(contexto).colorScheme.error,
              foregroundColor: Theme.of(contexto).colorScheme.onError,
            ),
            icon: const Icon(Icons.block),
            label: const Text('Sim, cancelar'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    setState(() => _salvando = true);
    try {
      await widget.controller.cancelar(_a!.id);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) await tratarErro(context, e);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  List<Widget> _formulario(OpcoesAutorizacao opcoes) {
    // Só oferece quem está ativo. A pessoa já escolhida fica na lista mesmo
    // sem vir no GET /users, ou o seletor quebra sem o valor entre as opções.
    final pessoas = [
      for (final p in opcoes.pessoas)
        if (p.id != _pessoaId && p.ativo) (p.id, p.nome),
      if (_pessoaId case final id?)
        (
          id,
          widget.autorizacao?.pessoaNome ??
              widget.pessoaFixa?.nome ??
              opcoes.pessoas.where((p) => p.id == id).firstOrNull?.nome ??
              'Pessoa selecionada',
        ),
    ];
    return [
      Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CampoEscolha<String>(
              rotulo: 'Pessoa',
              valor: _pessoaId,
              icone: Icons.person_outline,
              opcoes: pessoas,
              // A API não deixa trocar a pessoa na edição.
              onMudar: _nova && widget.pessoaFixa == null
                  ? (v) => setState(() => _pessoaId = v)
                  : null,
              validator: (v) => v == null ? 'Escolha a pessoa.' : null,
            ),
            const SizedBox(height: 20),
            CampoEscolha<String>(
              rotulo: 'Local',
              valor: _catracaId,
              icone: Icons.location_on_outlined,
              opcoes: [
                for (final c in opcoes.catracas) (c.catraca.id, c.caminho),
              ],
              onMudar: (v) => setState(() => _catracaId = v),
              validator: (v) => v == null ? 'Escolha a catraca.' : null,
            ),
            const SizedBox(height: 20),
            CampoSelecao(
              rotulo: 'Início',
              valor: Formato.data(_inicio),
              icone: Icons.event_outlined,
              onTocar: () => _escolherData(true),
            ),
            const SizedBox(height: 20),
            CampoSelecao(
              rotulo: 'Fim',
              valor: Formato.data(_fim),
              icone: Icons.event_outlined,
              onTocar: () => _escolherData(false),
            ),
            const SizedBox(height: 20),
            CampoSelecao(
              rotulo: 'Das',
              valor: Formato.horaApi(_horaInicio),
              icone: Icons.schedule,
              onTocar: () => _escolherHora(true),
            ),
            const SizedBox(height: 20),
            CampoSelecao(
              rotulo: 'Até',
              valor: Formato.horaApi(_horaFim),
              icone: Icons.schedule,
              onTocar: () => _escolherHora(false),
            ),
            const SizedBox(height: 20),
            CampoTexto(
              rotulo: 'Quantidade de usos',
              controller: _usos,
              icone: Icons.confirmation_number_outlined,
              teclado: TextInputType.number,
              acao: TextInputAction.done,
              validator: (v) {
                final usos = int.tryParse((v ?? '').trim());
                return usos == null || usos < 1 || usos > 10000
                    ? 'Informe de 1 a 10000 usos.'
                    : null;
              },
            ),
            if (!_nova && !_cancelada) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _salvando ? null : _cancelar,
                icon: const Icon(Icons.block),
                label: const Text('Cancelar autorização'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.error,
                    width: 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      titulo: _nova ? 'Nova autorização' : 'Editar autorização',
      subtitulo: _cancelada
          ? 'Cancelada: não pode ser editada. Crie outra.'
          : widget.pessoaFixa != null
          ? 'Passo 2 de 2: onde e quando pode entrar'
          : null,
      rodape: _cancelada || dados == null
          ? null
          : BotaoAcao(
              rotulo: _nova ? 'Criar autorização' : 'Salvar alterações',
              icone: Icons.check,
              carregando: _salvando,
              onTocar: _salvar,
            ),
      filhos: conteudo(_formulario),
    );
  }
}
```

**Para ajustar:**

- O design põe Início e Fim lado a lado. Aqui ficam um embaixo do outro, para caber com fonte grande.
- Os chips de filtro ativos não têm o "×". O Histórico tem: dá para copiar de lá.

### C3. Usuários (A3 e A4)

A portaria só escolhe morador e visitante e não edita a equipe: a tela nem oferece, porque a API responde 403.

**Arquivo novo:** `frontend/lib/controllers/usuarios_controller.dart`

```dart
import '../models/usuario.dart';
import '../models/usuario_cadastro.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

/// Pessoas e tags (RF01): A3, A4, Tags NFC e Visitantes.
/// O controlador de acesso só gerencia morador e visitante; nos outros a API
/// responde 403, então a tela nem oferece.
class UsuariosController {
  UsuariosController({ApiClient? api, AuthService? auth})
    : _api = api ?? ApiClient.instancia,
      _auth = auth ?? AuthService.instancia;

  final ApiClient _api;
  final AuthService _auth;

  Perfil? get _perfilLogado => _auth.usuario?.perfil;

  String? get idLogado => _auth.usuario?.id;

  /// Perfis que quem está logado pode criar ou escolher no formulário.
  List<Perfil> get perfisPermitidos => _perfilLogado == Perfil.admin
      ? Perfil.values
      : const [Perfil.morador, Perfil.visitante];

  bool podeGerenciar(Perfil perfil) => perfisPermitidos.contains(perfil);

  Future<List<UsuarioCadastro>> listar({String? busca, Perfil? perfil}) async {
    final lista =
        await _api.get(
              '/users',
              query: {
                if (busca != null && busca.trim().isNotEmpty)
                  'busca': busca.trim(),
                if (perfil != null) 'perfil': perfil.api,
              },
            )
            as List<dynamic>;
    return [
      for (final json in lista)
        UsuarioCadastro.fromJson(json as Map<String, dynamic>),
    ];
  }

  Future<UsuarioCadastro> criar({
    required String nome,
    required String email,
    required String cpf,
    required String senha,
    required Perfil perfil,
  }) async {
    final json = await _api.post('/users', {
      'nome': nome,
      'email': email,
      'cpf': cpf,
      'senha': senha,
      'perfil': perfil.api,
    });
    return UsuarioCadastro.fromJson(json as Map<String, dynamic>);
  }

  /// Manda só o que mudou. "senha" é como a portaria resolve o "Esqueci
  /// minha senha": não existe recuperação por e-mail.
  Future<UsuarioCadastro> atualizar(
    String id, {
    String? nome,
    String? email,
    String? cpf,
    String? senha,
    Perfil? perfil,
    bool? ativo,
  }) async {
    final json = await _api.patch('/users/$id', {
      'nome': ?nome,
      'email': ?email,
      'cpf': ?cpf,
      'senha': ?senha,
      'perfil': ?perfil?.api,
      'ativo': ?ativo,
    });
    return UsuarioCadastro.fromJson(json as Map<String, dynamic>);
  }

  /// UID em hexadecimal; a API normaliza ("04:A1-B2" vira "04A1B2").
  /// Tag já vinculada a outra pessoa responde 409.
  Future<TagNfc> vincularTag(String usuarioId, String uid) async {
    final json = await _api.post('/users/$usuarioId/tags', {'uid': uid});
    return TagNfc.fromJson(json as Map<String, dynamic>);
  }

  Future<void> alterarTag(String usuarioId, String tagId, bool ativa) =>
      _api.patch('/users/$usuarioId/tags/$tagId', {'ativa': ativa});

  Future<void> removerTag(String usuarioId, String tagId) =>
      _api.delete('/users/$usuarioId/tags/$tagId');
}
```

**Arquivo novo:** `frontend/lib/views/equipe/usuarios_view.dart`

```dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../controllers/usuarios_controller.dart';
import '../../core/constants/formato.dart';
import '../../models/opcao_menu.dart';
import '../../models/usuario.dart';
import '../../models/usuario_cadastro.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/estado_vazio.dart';
import '../widgets/selo.dart';
import '../widgets/tela_base.dart';
import 'usuario_form_view.dart';

/// A3 · Usuários: busca por nome, e-mail ou CPF, e filtro por perfil.
class UsuariosView extends StatefulWidget {
  UsuariosView({super.key, UsuariosController? controller})
    : controller = controller ?? UsuariosController();

  final UsuariosController controller;

  @override
  State<UsuariosView> createState() => _UsuariosViewState();
}

class _UsuariosViewState extends State<UsuariosView>
    with CarregaDados<List<UsuarioCadastro>, UsuariosView> {
  final _busca = TextEditingController();
  Timer? _espera;
  Perfil? _perfil;

  UsuariosController get controller => widget.controller;

  @override
  Future<List<UsuarioCadastro>> buscar() =>
      controller.listar(busca: _busca.text, perfil: _perfil);

  @override
  void dispose() {
    _espera?.cancel();
    _busca.dispose();
    super.dispose();
  }

  /// Espera parar de digitar, para não chamar a API a cada letra.
  void _aoDigitar(String _) {
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 400), carregar);
  }

  Future<void> _abrir(UsuarioCadastro? usuario) async {
    final salvo = await Navigator.of(context).push<UsuarioCadastro>(
      MaterialPageRoute(
        builder: (_) =>
            UsuarioFormView(usuario: usuario, controller: controller),
      ),
    );
    if (salvo != null && mounted) await carregar();
  }

  List<Widget> _lista(List<UsuarioCadastro> lista) {
    if (lista.isEmpty) {
      return const [
        EstadoVazio(
          icone: Icons.person_search,
          titulo: 'Ninguém encontrado',
          texto: 'Tente outro nome, e-mail ou CPF.',
        ),
      ];
    }
    return [
      Text(
        '${lista.length} ${lista.length == 1 ? 'usuário' : 'usuários'}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 12),
      for (final usuario in lista)
        _CartaoUsuario(
          usuario: usuario,
          // Sem permissão a API responde 403: a tela nem oferece a edição.
          onTocar: controller.podeGerenciar(usuario.perfil)
              ? () => _abrir(usuario)
              : null,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      titulo: 'Usuários',
      subtitulo: 'Pessoas, perfis e documentos',
      onAtualizar: carregar,
      botaoFlutuante: FloatingActionButton.extended(
        onPressed: () => _abrir(null),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Novo usuário'),
      ),
      filhos: [
        TextField(
          controller: _busca,
          onChanged: _aoDigitar,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Nome, e-mail ou CPF',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Todos'),
              selected: _perfil == null,
              onSelected: (_) {
                _perfil = null;
                recarregar();
              },
            ),
            for (final perfil in Perfil.values)
              ChoiceChip(
                label: Text(Formato.perfil(perfil)),
                selected: _perfil == perfil,
                onSelected: (_) {
                  _perfil = perfil;
                  recarregar();
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        ...conteudo(_lista),
      ],
    );
  }
}

class _CartaoUsuario extends StatelessWidget {
  const _CartaoUsuario({required this.usuario, required this.onTocar});

  final UsuarioCadastro usuario;
  final VoidCallback? onTocar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final tagsAtivas = usuario.tags.where((t) => t.ativa).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTocar,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  child: Text(Formato.iniciais(usuario.nome)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(usuario.nome, style: textTheme.titleMedium),
                      Text(
                        'CPF ${Formato.cpfMascarado(usuario.cpf)}',
                        style: textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Selo(
                            texto: Formato.perfil(usuario.perfil),
                            icone: Icons.badge_outlined,
                          ),
                          if (!usuario.ativo)
                            const Selo(
                              texto: 'Desativado',
                              icone: Icons.block,
                              tom: TomOpcao.perigo,
                            ),
                          Selo(
                            texto: usuario.tags.isEmpty
                                ? 'Sem tag'
                                : tagsAtivas == 0
                                ? 'Tag bloqueada'
                                : 'Tag ${Formato.finalTag(usuario.tags.first.uid)}',
                            icone: Icons.contactless_outlined,
                            tom: usuario.tags.isNotEmpty && tagsAtivas == 0
                                ? TomOpcao.atencao
                                : TomOpcao.padrao,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onTocar != null) const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

**Arquivo novo:** `frontend/lib/views/equipe/usuario_form_view.dart`

```dart
import 'package:flutter/material.dart';

import '../../controllers/usuarios_controller.dart';
import '../../core/constants/formato.dart';
import '../../models/usuario.dart';
import '../../models/usuario_cadastro.dart';
import '../../services/api_client.dart';
import '../widgets/botao_acao.dart';
import '../widgets/campo_texto.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/tela_base.dart';

/// A4 · Usuário · formulário: cria ou edita. Ao salvar, devolve o usuário
/// para quem abriu a tela (Visitantes usa isso para seguir à autorização).
class UsuarioFormView extends StatefulWidget {
  UsuarioFormView({
    super.key,
    this.usuario,
    this.perfilFixo,
    this.rotuloSalvar,
    UsuariosController? controller,
  }) : controller = controller ?? UsuariosController();

  /// null cria um novo.
  final UsuarioCadastro? usuario;

  /// Esconde a escolha de perfil, ex.: cadastro de visitante.
  final Perfil? perfilFixo;
  final String? rotuloSalvar;
  final UsuariosController controller;

  @override
  State<UsuarioFormView> createState() => _UsuarioFormViewState();
}

class _UsuarioFormViewState extends State<UsuarioFormView> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.usuario?.nome);
  late final _cpf = TextEditingController(
    text: widget.usuario == null ? null : Formato.cpf(widget.usuario!.cpf),
  );
  late final _email = TextEditingController(text: widget.usuario?.email);
  final _senha = TextEditingController();
  late var _perfil =
      widget.perfilFixo ?? widget.usuario?.perfil ?? Perfil.morador;
  late var _ativo = widget.usuario?.ativo ?? true;
  var _salvando = false;

  /// Erros de cada campo que a API devolveu no 400.
  Map<String, List<String>> _errosDaApi = const {};

  bool get _novo => widget.usuario == null;

  @override
  void dispose() {
    _nome.dispose();
    _cpf.dispose();
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  String? _erroDaApi(String campo) => _errosDaApi[campo]?.first;

  Future<void> _salvar() async {
    _errosDaApi = const {};
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final senha = _senha.text;
      final salvo = _novo
          ? await widget.controller.criar(
              nome: _nome.text.trim(),
              email: _email.text.trim(),
              cpf: _cpf.text.trim(),
              senha: senha,
              perfil: _perfil,
            )
          : await widget.controller.atualizar(
              widget.usuario!.id,
              nome: _nome.text.trim(),
              email: _email.text.trim(),
              cpf: _cpf.text.trim(),
              senha: senha.isEmpty ? null : senha,
              perfil: _perfil,
              ativo: _ativo,
            );
      if (mounted) Navigator.of(context).pop(salvo);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.campos.isNotEmpty) {
        _errosDaApi = e.campos;
        _form.currentState!.validate();
      } else {
        await tratarErro(context, e);
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final eleMesmo = widget.usuario?.id == widget.controller.idLogado;

    return TelaBase(
      titulo: _novo
          ? (widget.perfilFixo == Perfil.visitante
                ? 'Novo visitante'
                : 'Novo usuário')
          : 'Editar usuário',
      subtitulo: widget.perfilFixo == Perfil.visitante
          ? 'Passo 1 de 2: dados da pessoa'
          : null,
      rodape: BotaoAcao(
        rotulo: widget.rotuloSalvar ??
            (_novo ? 'Criar usuário' : 'Salvar alterações'),
        icone: Icons.check,
        carregando: _salvando,
        onTocar: _salvar,
      ),
      filhos: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CampoTexto(
                rotulo: 'Nome completo',
                controller: _nome,
                icone: Icons.person_outline,
                validator: (v) => (v ?? '').trim().length < 3
                    ? 'Informe o nome completo.'
                    : _erroDaApi('nome'),
              ),
              const SizedBox(height: 20),
              CampoTexto(
                rotulo: 'Documento (CPF)',
                controller: _cpf,
                icone: Icons.badge_outlined,
                dica: '123.456.789-00',
                ajuda: 'Pode digitar só os números.',
                teclado: TextInputType.number,
                validator: (v) =>
                    (v ?? '').replaceAll(RegExp(r'\D'), '').length != 11
                    ? 'O CPF precisa ter 11 números.'
                    : _erroDaApi('cpf'),
              ),
              const SizedBox(height: 20),
              CampoTexto(
                rotulo: 'E-mail',
                controller: _email,
                icone: Icons.mail_outline,
                teclado: TextInputType.emailAddress,
                validator: (v) => !(v ?? '').contains('@')
                    ? 'Informe um e-mail válido.'
                    : _erroDaApi('email'),
              ),
              const SizedBox(height: 20),
              CampoTexto(
                rotulo: _novo ? 'Senha inicial' : 'Nova senha',
                controller: _senha,
                icone: Icons.lock_outline,
                senha: true,
                acao: TextInputAction.done,
                ajuda: _novo
                    ? 'A pessoa entra com esta senha.'
                    : 'Deixe em branco para manter a atual.',
                validator: (v) {
                  final senha = v ?? '';
                  if (_novo || senha.isNotEmpty) {
                    if (senha.length < 6) {
                      return 'A senha precisa de pelo menos 6 caracteres.';
                    }
                  }
                  return _erroDaApi('senha');
                },
              ),
              if (widget.perfilFixo == null) ...[
                const SizedBox(height: 20),
                Text('Perfil', style: textTheme.labelLarge),
                const SizedBox(height: 8),
                RadioGroup<Perfil>(
                  groupValue: _perfil,
                  onChanged: (perfil) {
                    if (perfil != null) setState(() => _perfil = perfil);
                  },
                  child: Column(
                    children: [
                      for (final perfil in widget.controller.perfisPermitidos)
                        RadioListTile<Perfil>(
                          value: perfil,
                          title: Text(Formato.perfil(perfil)),
                          subtitle: Text(switch (perfil) {
                            Perfil.admin =>
                              'Gerencia usuários, locais e autorizações',
                            Perfil.controladorAcesso =>
                              'Cuida da portaria no dia a dia',
                            Perfil.morador => 'Mora ou trabalha no prédio',
                            Perfil.visitante => 'Acesso por tempo limitado',
                          }),
                        ),
                    ],
                  ),
                ),
              ],
              // Quem está logado não desativa a própria conta.
              if (!_novo && !eleMesmo) ...[
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _ativo,
                  onChanged: (v) => setState(() => _ativo = v),
                  title: const Text('Cadastro ativo'),
                  subtitle: const Text(
                    'Desativado, a pessoa não passa na catraca.',
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
```

**Para ajustar:**

- "Esqueci minha senha" se resolve aqui: o campo Nova senha faz `PATCH /users/:id {senha}`.
- A busca espera 400 ms depois da última letra. Ajuste em `_aoDigitar`.

### C4. Visitantes (sem tela no design)

Dois passos com os formulários de C2 e C3, então cole C2 e C3 antes.

**Arquivo novo:** `frontend/lib/views/equipe/visitantes_view.dart`

```dart
import 'package:flutter/material.dart';

import '../../controllers/usuarios_controller.dart';
import '../../core/constants/formato.dart';
import '../../models/usuario.dart';
import '../../models/usuario_cadastro.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/estado_vazio.dart';
import '../widgets/tela_base.dart';
import 'autorizacao_form_view.dart';
import 'usuario_form_view.dart';

/// Visitantes (equipe): a API não tem rota única, então são dois passos, com
/// os formulários que já existem. Passo 1: cria a pessoa (POST /users). Passo
/// 2: cria a autorização (POST /authorizations). Se a pessoa sair no passo 2,
/// o visitante fica na lista e o toque nele retoma daí.
class VisitantesView extends StatefulWidget {
  VisitantesView({super.key, UsuariosController? controller})
    : controller = controller ?? UsuariosController();

  final UsuariosController controller;

  @override
  State<VisitantesView> createState() => _VisitantesViewState();
}

class _VisitantesViewState extends State<VisitantesView>
    with CarregaDados<List<UsuarioCadastro>, VisitantesView> {
  UsuariosController get controller => widget.controller;

  @override
  Future<List<UsuarioCadastro>> buscar() =>
      controller.listar(perfil: Perfil.visitante);

  Future<void> _novo() async {
    final visitante = await Navigator.of(context).push<UsuarioCadastro>(
      MaterialPageRoute(
        builder: (_) => UsuarioFormView(
          perfilFixo: Perfil.visitante,
          rotuloSalvar: 'Continuar',
          controller: controller,
        ),
      ),
    );
    if (visitante == null || !mounted) return;
    await carregar();
    if (mounted) await _liberar(visitante);
  }

  Future<void> _liberar(UsuarioCadastro visitante) =>
      Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => AutorizacaoFormView(pessoaFixa: visitante),
        ),
      );

  List<Widget> _lista(List<UsuarioCadastro> visitantes) {
    if (visitantes.isEmpty) {
      return const [
        EstadoVazio(
          icone: Icons.schedule,
          titulo: 'Nenhum visitante cadastrado',
          texto: 'Cadastre quem vai chegar e libere o acesso por tempo limitado.',
        ),
      ];
    }
    return [
      for (final visitante in visitantes)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: CircleAvatar(
                child: Text(Formato.iniciais(visitante.nome)),
              ),
              title: Text(visitante.nome),
              subtitle: Text(
                'CPF ${Formato.cpfMascarado(visitante.cpf)}\n'
                'Toque para liberar um acesso',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _liberar(visitante),
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      titulo: 'Visitantes',
      subtitulo: 'Acessos por tempo limitado',
      onAtualizar: carregar,
      botaoFlutuante: FloatingActionButton.extended(
        onPressed: _novo,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Novo visitante'),
      ),
      filhos: conteudo(_lista),
    );
  }
}
```

**Para ajustar:**

- Hoje o formulário abre com 1 uso e o dia de hoje. Para visitante, são bons padrões; para outros perfis, ajuste no `AutorizacaoFormView`.

### S1. Painel (A1)

Abre as telas de C1 e C2, então cole C1 e C2 antes.

**Arquivo novo:** `frontend/lib/controllers/painel_controller.dart`

```dart
import '../models/local.dart';
import '../models/painel.dart';
import '../services/api_client.dart';

/// A1 · Painel: os números do GET /dashboard e o nome do prédio.
class PainelController {
  PainelController({ApiClient? api}) : _api = api ?? ApiClient.instancia;

  final ApiClient _api;

  Future<({Painel painel, String? predio})> carregar() async {
    final [painel, locais] = await Future.wait([
      _api.get('/dashboard'),
      _api.get('/locations'),
    ]);
    final edificios = locais as List<dynamic>;
    return (
      painel: Painel.fromJson(painel as Map<String, dynamic>),
      predio: edificios.isEmpty
          ? null
          : Edificio.fromJson(edificios.first as Map<String, dynamic>).nome,
    );
  }
}
```

**Arquivo novo:** `frontend/lib/views/equipe/painel_view.dart`

```dart
import 'package:flutter/material.dart';

import '../../controllers/painel_controller.dart';
import '../../core/constants/formato.dart';
import '../../core/theme/app_colors.dart';
import '../../models/painel.dart';
import '../compartilhado/historico_view.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/item_evento.dart';
import '../widgets/tela_base.dart';
import 'autorizacao_form_view.dart';
import 'autorizacoes_view.dart';

/// A1 · Painel: o resumo de hoje para o admin e a portaria.
class PainelView extends StatefulWidget {
  PainelView({super.key, PainelController? controller})
    : controller = controller ?? PainelController();

  final PainelController controller;

  @override
  State<PainelView> createState() => _PainelViewState();
}

class _PainelViewState extends State<PainelView>
    with CarregaDados<({Painel painel, String? predio}), PainelView> {
  @override
  Future<({Painel painel, String? predio})> buscar() =>
      widget.controller.carregar();

  Future<void> _ir(Widget tela) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => tela));
    if (mounted) await carregar();
  }

  List<Widget> _resumo(({Painel painel, String? predio}) dados) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final status = StatusColors.of(context);
    final painel = dados.painel;

    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _Numero(
              icone: Icons.login,
              cor: status.success,
              fundo: status.successContainer,
              valor: painel.acessosHoje,
              rotulo: 'Acessos hoje',
              acao: 'Ver histórico',
              onTocar: () => _ir(HistoricoView(daEquipe: true)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Numero(
              icone: Icons.block,
              cor: colorScheme.error,
              fundo: colorScheme.errorContainer,
              valor: painel.negadosHoje,
              rotulo: 'Negados hoje',
              acao: 'Ver motivos',
              onTocar: () =>
                  _ir(HistoricoView(daEquipe: true, soNegados: true)),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _Numero(
        icone: Icons.badge_outlined,
        cor: colorScheme.primary,
        fundo: colorScheme.primaryContainer,
        valor: painel.autorizacoesAtivas,
        rotulo: 'Autorizações ativas',
        acao: 'Ver autorizações',
        onTocar: () => _ir(AutorizacoesView()),
      ),
      const SizedBox(height: 24),
      Text('Negados recentes', style: textTheme.titleMedium),
      const SizedBox(height: 12),
      if (painel.negadosRecentes.isEmpty)
        Text('Nenhum acesso negado hoje.', style: textTheme.bodyMedium),
      for (final evento in painel.negadosRecentes) ItemEvento(evento: evento),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final predio = dados?.predio;
    final hoje = Formato.diaMes(DateTime.now());
    return TelaBase(
      titulo: 'Painel',
      subtitulo: predio == null ? 'Hoje, $hoje' : '$predio · hoje, $hoje',
      onAtualizar: carregar,
      botaoFlutuante: FloatingActionButton.extended(
        onPressed: () => _ir(AutorizacaoFormView()),
        icon: const Icon(Icons.add),
        label: const Text('Nova autorização'),
      ),
      filhos: conteudo(_resumo),
    );
  }
}

class _Numero extends StatelessWidget {
  const _Numero({
    required this.icone,
    required this.cor,
    required this.fundo,
    required this.valor,
    required this.rotulo,
    required this.acao,
    required this.onTocar,
  });

  final IconData icone;
  final Color cor;
  final Color fundo;
  final int valor;
  final String rotulo;
  final String acao;
  final VoidCallback onTocar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTocar,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: fundo,
                child: Icon(icone, color: cor),
              ),
              const SizedBox(height: 12),
              Text('$valor', style: textTheme.headlineMedium),
              Text(rotulo, style: textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(
                '$acao ›',
                style: textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Para ajustar:**

- O número "Autorizações ativas" vem do `/dashboard`: sai errado até a B4 entrar.

### C5. Locais (A5 e A6)

Cria edifício, portaria, porta e catraca e edita a catraca. Editar o resto depende da B5.

**Arquivo novo:** `frontend/lib/controllers/locais_controller.dart`

```dart
import '../models/local.dart';
import '../services/api_client.dart';

/// Edifício › portaria › porta › catraca (RF02): A5 e A6. Criar e editar são
/// só do admin. Editar ou apagar edifício, portaria e porta ainda não existe
/// na API (B5 do backlog); só a catraca tem PATCH.
class LocaisController {
  LocaisController({ApiClient? api}) : _api = api ?? ApiClient.instancia;

  final ApiClient _api;

  Future<List<Edificio>> arvore() async {
    final lista = await _api.get('/locations') as List<dynamic>;
    return [
      for (final json in lista)
        Edificio.fromJson(json as Map<String, dynamic>),
    ];
  }

  Future<void> criarEdificio(String nome, String endereco) => _api.post(
    '/locations/buildings',
    {'nome': nome, 'endereco': endereco},
  );

  Future<void> criarPortaria(String nome, String edificioId) => _api.post(
    '/locations/gates',
    {'nome': nome, 'buildingId': edificioId},
  );

  Future<void> criarPorta(String nome, String portariaId) =>
      _api.post('/locations/doors', {'nome': nome, 'gateId': portariaId});

  Future<void> criarCatraca({
    required String nome,
    required String portaId,
    required double latitude,
    required double longitude,
    required int raioMetros,
  }) => _api.post('/locations/access-points', {
    'nome': nome,
    'doorId': portaId,
    'latitude': latitude,
    'longitude': longitude,
    'raioMetros': raioMetros,
  });

  Future<void> atualizarCatraca(
    String id, {
    required String nome,
    required double latitude,
    required double longitude,
    required int raioMetros,
  }) => _api.patch('/locations/access-points/$id', {
    'nome': nome,
    'latitude': latitude,
    'longitude': longitude,
    'raioMetros': raioMetros,
  });
}
```

**Arquivo novo:** `frontend/lib/views/equipe/locais_view.dart`

```dart
import 'package:flutter/material.dart';

import '../../controllers/locais_controller.dart';
import '../../models/local.dart';
import '../../models/opcao_menu.dart';
import '../../services/api_client.dart';
import '../widgets/campo_texto.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/estado_vazio.dart';
import '../widgets/selo.dart';
import '../widgets/tela_base.dart';
import 'catraca_form_view.dart';

/// A5 · Locais: a árvore do prédio. O "+" de cada nível cria o nível de baixo.
class LocaisView extends StatefulWidget {
  LocaisView({super.key, LocaisController? controller})
    : controller = controller ?? LocaisController();

  final LocaisController controller;

  @override
  State<LocaisView> createState() => _LocaisViewState();
}

class _LocaisViewState extends State<LocaisView>
    with CarregaDados<List<Edificio>, LocaisView> {
  LocaisController get controller => widget.controller;

  @override
  Future<List<Edificio>> buscar() => controller.arvore();

  /// Pede o nome (e o endereço, no edifício), salva e recarrega a árvore.
  Future<void> _novo({
    required String titulo,
    required Future<void> Function(String nome, String endereco) salvar,
    bool comEndereco = false,
  }) async {
    final valores = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _DialogoNome(titulo: titulo, comEndereco: comEndereco),
    );
    if (valores == null) return;
    try {
      await salvar(valores.$1, valores.$2);
      if (mounted) await carregar();
    } on ApiException catch (e) {
      if (mounted) await tratarErro(context, e);
    }
  }

  Future<void> _abrirCatraca({
    required String portaId,
    required String caminho,
    Catraca? catraca,
  }) async {
    final salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CatracaFormView(
          catraca: catraca,
          portaId: portaId,
          caminho: caminho,
          controller: controller,
        ),
      ),
    );
    if (salvou == true && mounted) await carregar();
  }

  List<Widget> _arvore(List<Edificio> edificios) {
    if (edificios.isEmpty) {
      return const [
        EstadoVazio(
          icone: Icons.apartment,
          titulo: 'Nenhum local cadastrado',
          texto: 'Comece pelo edifício.',
        ),
      ];
    }
    return [
      for (final edificio in edificios) ...[
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Nivel(
                  recuo: 0,
                  icone: Icons.apartment,
                  rotulo: 'Edifício',
                  nome: edificio.nome,
                  detalhe: edificio.endereco,
                  rotuloAdicionar: 'Nova portaria',
                  onAdicionar: () => _novo(
                    titulo: 'Nova portaria',
                    salvar: (nome, _) =>
                        controller.criarPortaria(nome, edificio.id),
                  ),
                ),
                for (final portaria in edificio.portarias) ...[
                  _Nivel(
                    recuo: 1,
                    icone: Icons.meeting_room_outlined,
                    rotulo: 'Portaria',
                    nome: portaria.nome,
                    rotuloAdicionar: 'Nova porta',
                    onAdicionar: () => _novo(
                      titulo: 'Nova porta',
                      salvar: (nome, _) =>
                          controller.criarPorta(nome, portaria.id),
                    ),
                  ),
                  for (final porta in portaria.portas) ...[
                    _Nivel(
                      recuo: 2,
                      icone: Icons.door_front_door_outlined,
                      rotulo: 'Porta',
                      nome: porta.nome,
                      rotuloAdicionar: 'Nova catraca',
                      onAdicionar: () => _abrirCatraca(
                        portaId: porta.id,
                        caminho: '${portaria.nome} › ${porta.nome}',
                      ),
                    ),
                    for (final catraca in porta.catracas)
                      _Nivel(
                        recuo: 3,
                        icone: Icons.qr_code_2,
                        rotulo: 'Catraca',
                        nome: catraca.nome,
                        selo: Selo(
                          texto: 'Raio de ${catraca.raioMetros} m',
                          icone: Icons.location_on_outlined,
                          tom: TomOpcao.sucesso,
                        ),
                        onTocar: () => _abrirCatraca(
                          portaId: porta.id,
                          caminho: '${portaria.nome} › ${porta.nome}',
                          catraca: catraca,
                        ),
                      ),
                  ],
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      titulo: 'Locais',
      subtitulo: 'Edifício › Portaria › Porta › Catraca',
      onAtualizar: carregar,
      botaoFlutuante: FloatingActionButton.extended(
        onPressed: () => _novo(
          titulo: 'Novo edifício',
          comEndereco: true,
          salvar: controller.criarEdificio,
        ),
        icon: const Icon(Icons.add),
        label: const Text('Novo edifício'),
      ),
      filhos: conteudo(_arvore),
    );
  }
}

class _Nivel extends StatelessWidget {
  const _Nivel({
    required this.recuo,
    required this.icone,
    required this.rotulo,
    required this.nome,
    this.detalhe,
    this.selo,
    this.rotuloAdicionar,
    this.onAdicionar,
    this.onTocar,
  });

  final int recuo;
  final IconData icone;
  final String rotulo;
  final String nome;
  final String? detalhe;
  final Widget? selo;
  final String? rotuloAdicionar;
  final VoidCallback? onAdicionar;
  final VoidCallback? onTocar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTocar,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12.0 + 12 * recuo, 8, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rotulo, style: textTheme.bodySmall),
                  Text(nome, style: textTheme.titleMedium),
                  if (detalhe != null)
                    Text(detalhe!, style: textTheme.bodySmall),
                  if (selo != null) ...[const SizedBox(height: 4), selo!],
                ],
              ),
            ),
            if (onAdicionar != null)
              IconButton(
                onPressed: onAdicionar,
                tooltip: rotuloAdicionar,
                icon: const Icon(Icons.add_circle_outline),
              ),
            if (onTocar != null) const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _DialogoNome extends StatefulWidget {
  const _DialogoNome({required this.titulo, required this.comEndereco});

  final String titulo;
  final bool comEndereco;

  @override
  State<_DialogoNome> createState() => _DialogoNomeState();
}

class _DialogoNomeState extends State<_DialogoNome> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _endereco = TextEditingController();

  @override
  void dispose() {
    _nome.dispose();
    _endereco.dispose();
    super.dispose();
  }

  String? _obrigatorio(String? valor) =>
      (valor ?? '').trim().isEmpty ? 'Campo obrigatório.' : null;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CampoTexto(
                rotulo: 'Nome',
                controller: _nome,
                icone: Icons.edit_outlined,
                validator: _obrigatorio,
              ),
              if (widget.comEndereco) ...[
                const SizedBox(height: 16),
                CampoTexto(
                  rotulo: 'Endereço',
                  controller: _endereco,
                  icone: Icons.place_outlined,
                  validator: _obrigatorio,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Voltar'),
        ),
        TextButton(
          onPressed: () {
            if (_form.currentState!.validate()) {
              Navigator.of(
                context,
              ).pop((_nome.text.trim(), _endereco.text.trim()));
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
```

**Arquivo novo:** `frontend/lib/views/equipe/catraca_form_view.dart`

```dart
import 'package:flutter/material.dart';

import '../../controllers/locais_controller.dart';
import '../../models/local.dart';
import '../../services/api_client.dart';
import '../../services/localizacao_service.dart';
import '../widgets/botao_acao.dart';
import '../widgets/campo_texto.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/tela_base.dart';

/// A6 · Local · localização: cria ou edita a catraca. O design mostra um mapa;
/// sem pacote de mapa no pubspec, começa com os campos e o "Usar minha
/// localização", que resolve para quem está ao lado da catraca.
class CatracaFormView extends StatefulWidget {
  CatracaFormView({
    super.key,
    this.catraca,
    required this.portaId,
    required this.caminho,
    LocaisController? controller,
    LocalizacaoService? localizacao,
  }) : controller = controller ?? LocaisController(),
       localizacao = localizacao ?? LocalizacaoService.instancia;

  /// null cria uma nova.
  final Catraca? catraca;
  final String portaId;

  /// "Portaria Principal › Porta A".
  final String caminho;
  final LocaisController controller;
  final LocalizacaoService localizacao;

  @override
  State<CatracaFormView> createState() => _CatracaFormViewState();
}

class _CatracaFormViewState extends State<CatracaFormView> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.catraca?.nome);
  late final _latitude = TextEditingController(
    text: widget.catraca?.latitude.toString(),
  );
  late final _longitude = TextEditingController(
    text: widget.catraca?.longitude.toString(),
  );
  late final _raio = TextEditingController(
    text: '${widget.catraca?.raioMetros ?? 100}',
  );
  var _salvando = false;
  var _localizando = false;

  @override
  void dispose() {
    _nome.dispose();
    _latitude.dispose();
    _longitude.dispose();
    _raio.dispose();
    super.dispose();
  }

  /// Aceita vírgula, que é o que o teclado em português costuma ter.
  double? _numero(String? texto) =>
      double.tryParse((texto ?? '').trim().replaceAll(',', '.'));

  String? _validarFaixa(String? texto, double limite, String nome) {
    final valor = _numero(texto);
    return valor == null || valor.abs() > limite
        ? '$nome vai de -${limite.toInt()} a ${limite.toInt()}.'
        : null;
  }

  Future<void> _usarMinhaLocalizacao() async {
    setState(() => _localizando = true);
    final posicao = await widget.localizacao.posicaoAtual();
    if (!mounted) return;
    setState(() {
      _localizando = false;
      if (posicao != null) {
        _latitude.text = posicao.latitude.toString();
        _longitude.text = posicao.longitude.toString();
      }
    });
    if (posicao == null) {
      avisar(context, 'Não conseguimos sua localização. Digite os números.');
    }
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final catraca = widget.catraca;
      if (catraca == null) {
        await widget.controller.criarCatraca(
          nome: _nome.text.trim(),
          portaId: widget.portaId,
          latitude: _numero(_latitude.text)!,
          longitude: _numero(_longitude.text)!,
          raioMetros: int.parse(_raio.text.trim()),
        );
      } else {
        await widget.controller.atualizarCatraca(
          catraca.id,
          nome: _nome.text.trim(),
          latitude: _numero(_latitude.text)!,
          longitude: _numero(_longitude.text)!,
          raioMetros: int.parse(_raio.text.trim()),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) await tratarErro(context, e);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const teclado = TextInputType.numberWithOptions(
      decimal: true,
      signed: true,
    );

    return TelaBase(
      titulo: widget.catraca == null ? 'Nova catraca' : 'Editar catraca',
      subtitulo: widget.caminho,
      rodape: BotaoAcao(
        rotulo: 'Salvar local',
        icone: Icons.check,
        carregando: _salvando,
        onTocar: _salvar,
      ),
      filhos: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CampoTexto(
                rotulo: 'Nome',
                controller: _nome,
                icone: Icons.edit_outlined,
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Informe o nome.' : null,
              ),
              const SizedBox(height: 20),
              CampoTexto(
                rotulo: 'Latitude',
                controller: _latitude,
                icone: Icons.explore_outlined,
                dica: '-23.3053',
                teclado: teclado,
                validator: (v) => _validarFaixa(v, 90, 'A latitude'),
              ),
              const SizedBox(height: 20),
              CampoTexto(
                rotulo: 'Longitude',
                controller: _longitude,
                icone: Icons.explore_outlined,
                dica: '-45.9658',
                teclado: teclado,
                validator: (v) => _validarFaixa(v, 180, 'A longitude'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _localizando ? null : _usarMinhaLocalizacao,
                icon: const Icon(Icons.my_location),
                label: Text(
                  _localizando ? 'Localizando…' : 'Usar minha localização',
                ),
              ),
              const SizedBox(height: 20),
              CampoTexto(
                rotulo: 'Raio permitido (metros)',
                controller: _raio,
                icone: Icons.radar,
                ajuda: 'A pessoa precisa estar a essa distância para passar.',
                teclado: TextInputType.number,
                acao: TextInputAction.done,
                validator: (v) {
                  final raio = int.tryParse((v ?? '').trim());
                  return raio == null || raio < 10 || raio > 1000
                      ? 'O raio vai de 10 a 1000 metros.'
                      : null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

**Para ajustar:**

- O design mostra um mapa na A6. Sem pacote de mapa, a tela usa campos e "Usar minha localização". Para ter o mapa, adicione `flutter_map` ao `pubspec.yaml`.

### C6. Tags NFC (sem tela no design)

O UID é digitado. Ele aparece no histórico quando a tag é lida numa catraca.

**Arquivo novo:** `frontend/lib/views/equipe/tags_view.dart`

```dart
import 'package:flutter/material.dart';

import '../../controllers/usuarios_controller.dart';
import '../../core/constants/formato.dart';
import '../../models/usuario_cadastro.dart';
import '../../services/api_client.dart';
import '../widgets/botao_acao.dart';
import '../widgets/campo_selecao.dart';
import '../widgets/campo_texto.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/estado_vazio.dart';
import '../widgets/tela_base.dart';

/// Tags NFC (sem tela no design): vincular, bloquear e remover. A API não tem
/// lista só de tags nem busca por UID, então lê GET /users e filtra aqui.
class TagsView extends StatefulWidget {
  TagsView({super.key, UsuariosController? controller})
    : controller = controller ?? UsuariosController();

  final UsuariosController controller;

  @override
  State<TagsView> createState() => _TagsViewState();
}

class _TagsViewState extends State<TagsView>
    with CarregaDados<List<UsuarioCadastro>, TagsView> {
  final _busca = TextEditingController();

  UsuariosController get controller => widget.controller;

  @override
  Future<List<UsuarioCadastro>> buscar() => controller.listar();

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  Future<void> _executar(Future<void> Function() acao) async {
    try {
      await acao();
      if (mounted) await carregar();
    } on ApiException catch (e) {
      if (mounted) await tratarErro(context, e);
    }
  }

  Future<void> _vincular(List<UsuarioCadastro> pessoas) async {
    final permitidas = [
      for (final p in pessoas)
        if (p.ativo && controller.podeGerenciar(p.perfil)) p,
    ];
    final dados = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FormularioTag(pessoas: permitidas),
    );
    if (dados == null) return;
    await _executar(() => controller.vincularTag(dados.$1, dados.$2));
  }

  Future<void> _remover(UsuarioCadastro pessoa, TagNfc tag) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Remover esta tag?'),
        content: Text(
          'A tag final ${Formato.finalTag(tag.uid)} deixa de ser de '
          '${pessoa.nome}. Se ela só perdeu a tag, prefira bloquear.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Manter'),
          ),
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmou == true) {
      await _executar(() => controller.removerTag(pessoa.id, tag.id));
    }
  }

  List<Widget> _lista(List<UsuarioCadastro> pessoas) {
    final busca = _busca.text.trim().toLowerCase();
    final comTag = [
      for (final p in pessoas)
        if (p.tags.isNotEmpty &&
            (p.nome.toLowerCase().contains(busca) ||
                p.tags.any((t) => t.uid.toLowerCase().contains(busca))))
          p,
    ];
    if (comTag.isEmpty) {
      return const [
        EstadoVazio(
          icone: Icons.contactless_outlined,
          titulo: 'Nenhuma tag encontrada',
          texto: 'Vincule uma tag ou busque por outro nome.',
        ),
      ];
    }
    return [
      for (final pessoa in comTag)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    pessoa.nome,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    Formato.perfil(pessoa.perfil),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  for (final tag in pessoa.tags)
                    _LinhaTag(
                      tag: tag,
                      // O controlador não mexe nas tags da equipe (403).
                      podeMudar: controller.podeGerenciar(pessoa.perfil),
                      onAtiva: (ativa) => _executar(
                        () => controller.alterarTag(pessoa.id, tag.id, ativa),
                      ),
                      onRemover: () => _remover(pessoa, tag),
                    ),
                ],
              ),
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final atual = dados;
    return TelaBase(
      titulo: 'Tags NFC',
      subtitulo: 'Vincular e bloquear tags',
      onAtualizar: carregar,
      botaoFlutuante: atual == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _vincular(atual),
              icon: const Icon(Icons.add),
              label: const Text('Vincular tag'),
            ),
      filhos: [
        TextField(
          controller: _busca,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Nome ou UID da tag',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 16),
        ...conteudo(_lista),
      ],
    );
  }
}

class _LinhaTag extends StatelessWidget {
  const _LinhaTag({
    required this.tag,
    required this.podeMudar,
    required this.onAtiva,
    required this.onRemover,
  });

  final TagNfc tag;
  final bool podeMudar;
  final ValueChanged<bool> onAtiva;
  final VoidCallback onRemover;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Icon(Icons.contactless_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tag.uid),
                Text(
                  tag.ativa ? 'Ativa' : 'Bloqueada',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (podeMudar) ...[
            Semantics(
              label: tag.ativa ? 'Bloquear tag' : 'Desbloquear tag',
              child: Switch(value: tag.ativa, onChanged: onAtiva),
            ),
            IconButton(
              onPressed: onRemover,
              tooltip: 'Remover tag',
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ],
      ),
    );
  }
}

class _FormularioTag extends StatefulWidget {
  const _FormularioTag({required this.pessoas});

  final List<UsuarioCadastro> pessoas;

  @override
  State<_FormularioTag> createState() => _FormularioTagState();
}

class _FormularioTagState extends State<_FormularioTag> {
  final _form = GlobalKey<FormState>();
  final _uid = TextEditingController();
  String? _pessoaId;

  /// Mesma regra da API (tagSchema em users.controller.ts).
  static final _formatoUid = RegExp(r'^[0-9a-fA-F:\s-]{4,40}$');

  @override
  void dispose() {
    _uid.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Vincular tag',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              CampoEscolha<String>(
                rotulo: 'Pessoa',
                valor: _pessoaId,
                icone: Icons.person_outline,
                opcoes: [for (final p in widget.pessoas) (p.id, p.nome)],
                onMudar: (v) => setState(() => _pessoaId = v),
                validator: (v) => v == null ? 'Escolha a pessoa.' : null,
              ),
              const SizedBox(height: 20),
              CampoTexto(
                rotulo: 'UID da tag',
                controller: _uid,
                icone: Icons.contactless_outlined,
                dica: '04:A1:B2:C3',
                ajuda: 'Aparece no histórico quando a tag é lida na catraca.',
                acao: TextInputAction.done,
                validator: (v) => _formatoUid.hasMatch((v ?? '').trim())
                    ? null
                    : 'Use de 4 a 40 caracteres em hexadecimal.',
              ),
              const SizedBox(height: 24),
              BotaoAcao(
                rotulo: 'Vincular',
                icone: Icons.check,
                onTocar: () {
                  if (_form.currentState!.validate()) {
                    Navigator.of(context).pop((_pessoaId!, _uid.text.trim()));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Para ajustar:**

- Para ler a tag pelo celular: use `nfc_manager`, que já está no `pubspec.yaml`, e acrescente a permissão de NFC no Android e no iOS (F6).

### C7. Terminais (sem tela no design)

A chave só aparece uma vez, então o diálogo não fecha tocando fora dele.

**Arquivo novo:** `frontend/lib/controllers/terminais_controller.dart`

```dart
import '../models/local.dart';
import '../models/terminal.dart';
import '../models/usuario.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

typedef DadosTerminais = ({
  List<Terminal> terminais,
  List<CatracaNoLocal> catracas,
});

/// Terminais das catracas. A equipe consulta; cadastrar e trocar a chave são
/// só do admin (403 para a portaria).
class TerminaisController {
  TerminaisController({ApiClient? api, AuthService? auth})
    : _api = api ?? ApiClient.instancia,
      _auth = auth ?? AuthService.instancia;

  final ApiClient _api;
  final AuthService _auth;

  bool get podeGerenciar => _auth.usuario?.perfil == Perfil.admin;

  /// GET /terminals só traz o accessPointId: cruza com GET /locations para
  /// mostrar o nome da catraca.
  Future<DadosTerminais> carregar() async {
    final [terminais, locais] = await Future.wait([
      _api.get('/terminals'),
      _api.get('/locations'),
    ]);
    return (
      terminais: [
        for (final json in terminais as List<dynamic>)
          Terminal.fromJson(json as Map<String, dynamic>),
      ],
      catracas: catracasDe([
        for (final json in locais as List<dynamic>)
          Edificio.fromJson(json as Map<String, dynamic>),
      ]),
    );
  }

  /// A resposta traz a [Terminal.chave], que só aparece desta vez. Uma catraca
  /// só tem um terminal (409).
  Future<Terminal> cadastrar(String nome, String catracaId) async {
    final json = await _api.post('/terminals', {
      'nome': nome,
      'accessPointId': catracaId,
    });
    return Terminal.fromJson(json as Map<String, dynamic>);
  }

  /// A chave antiga para de funcionar: grave a nova no firmware e no broker.
  Future<Terminal> trocarChave(String id) async {
    final json = await _api.post('/terminals/$id/rotate-key');
    return Terminal.fromJson(json as Map<String, dynamic>);
  }
}
```

**Arquivo novo:** `frontend/lib/views/equipe/terminais_view.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/terminais_controller.dart';
import '../../core/constants/formato.dart';
import '../../models/local.dart';
import '../../models/opcao_menu.dart';
import '../../models/terminal.dart';
import '../../services/api_client.dart';
import '../widgets/botao_acao.dart';
import '../widgets/campo_selecao.dart';
import '../widgets/campo_texto.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/estado_vazio.dart';
import '../widgets/selo.dart';
import '../widgets/tela_base.dart';

/// Terminais (sem tela no design): quem está no ar e, para o admin, cadastrar
/// e trocar a chave.
class TerminaisView extends StatefulWidget {
  TerminaisView({super.key, TerminaisController? controller})
    : controller = controller ?? TerminaisController();

  final TerminaisController controller;

  @override
  State<TerminaisView> createState() => _TerminaisViewState();
}

class _TerminaisViewState extends State<TerminaisView>
    with CarregaDados<DadosTerminais, TerminaisView> {
  TerminaisController get controller => widget.controller;

  @override
  Future<DadosTerminais> buscar() => controller.carregar();

  /// A chave só aparece uma vez: a tela insiste para copiar antes de fechar.
  Future<void> _mostrarChave(Terminal terminal) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DialogoChave(terminal: terminal),
  );

  Future<void> _cadastrar(DadosTerminais atual) async {
    final ocupadas = {for (final t in atual.terminais) t.accessPointId};
    final livres = [
      for (final c in atual.catracas)
        if (!ocupadas.contains(c.catraca.id)) c,
    ];
    if (livres.isEmpty) {
      avisar(context, 'Todas as catracas já têm terminal.');
      return;
    }
    final novo = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FormularioTerminal(catracas: livres),
    );
    if (novo == null) return;
    try {
      final terminal = await controller.cadastrar(novo.$1, novo.$2);
      if (!mounted) return;
      await _mostrarChave(terminal);
      if (mounted) await carregar();
    } on ApiException catch (e) {
      if (mounted) await tratarErro(context, e);
    }
  }

  Future<void> _trocarChave(Terminal terminal) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Trocar a chave?'),
        content: Text(
          '${terminal.nome} para de funcionar até a chave nova ser gravada no '
          'firmware e no broker.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Não trocar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            child: const Text('Trocar chave'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;
    try {
      final atualizado = await controller.trocarChave(terminal.id);
      if (!mounted) return;
      await _mostrarChave(atualizado);
    } on ApiException catch (e) {
      if (mounted) await tratarErro(context, e);
    }
  }

  List<Widget> _lista(DadosTerminais d) {
    if (d.terminais.isEmpty) {
      return const [
        EstadoVazio(
          icone: Icons.qr_code_2,
          titulo: 'Nenhum terminal cadastrado',
          texto: 'Cada catraca tem um terminal, que mostra o QR rotativo.',
        ),
      ];
    }
    return [
      for (final terminal in d.terminais)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _CartaoTerminal(
            terminal: terminal,
            caminho: d.catracas
                .where((c) => c.catraca.id == terminal.accessPointId)
                .firstOrNull
                ?.caminho,
            onTrocarChave: controller.podeGerenciar
                ? () => _trocarChave(terminal)
                : null,
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final atual = dados;
    return TelaBase(
      titulo: 'Terminais',
      subtitulo: 'Leitores de QR Code das catracas',
      onAtualizar: carregar,
      botaoFlutuante: controller.podeGerenciar && atual != null
          ? FloatingActionButton.extended(
              onPressed: () => _cadastrar(atual),
              icon: const Icon(Icons.add),
              label: const Text('Novo terminal'),
            )
          : null,
      filhos: conteudo(_lista),
    );
  }
}

class _CartaoTerminal extends StatelessWidget {
  const _CartaoTerminal({
    required this.terminal,
    required this.caminho,
    required this.onTrocarChave,
  });

  final Terminal terminal;
  final String? caminho;
  final VoidCallback? onTrocarChave;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final sinal = terminal.ultimoSinal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(terminal.nome, style: textTheme.titleMedium),
                ),
                const SizedBox(width: 8),
                terminal.online
                    ? const Selo(
                        texto: 'No ar',
                        icone: Icons.check_circle,
                        tom: TomOpcao.sucesso,
                      )
                    : const Selo(
                        texto: 'Fora do ar',
                        icone: Icons.cloud_off,
                        tom: TomOpcao.perigo,
                      ),
              ],
            ),
            if (caminho != null) Text(caminho!, style: textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(
              sinal == null
                  ? 'Ainda não deu sinal'
                  : 'Último sinal: ${Formato.data(sinal)} às ${Formato.hora(sinal)}',
              style: textTheme.bodyMedium,
            ),
            if (onTrocarChave != null)
              TextButton.icon(
                onPressed: onTrocarChave,
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                icon: const Icon(Icons.key_outlined),
                label: const Text('Trocar chave'),
              ),
          ],
        ),
      ),
    );
  }
}

class _FormularioTerminal extends StatefulWidget {
  const _FormularioTerminal({required this.catracas});

  final List<CatracaNoLocal> catracas;

  @override
  State<_FormularioTerminal> createState() => _FormularioTerminalState();
}

class _FormularioTerminalState extends State<_FormularioTerminal> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  String? _catracaId;

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Novo terminal',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              CampoTexto(
                rotulo: 'Nome',
                controller: _nome,
                icone: Icons.edit_outlined,
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Informe o nome.' : null,
              ),
              const SizedBox(height: 20),
              CampoEscolha<String>(
                rotulo: 'Catraca',
                valor: _catracaId,
                icone: Icons.location_on_outlined,
                opcoes: [
                  for (final c in widget.catracas) (c.catraca.id, c.caminho),
                ],
                onMudar: (v) => setState(() => _catracaId = v),
                validator: (v) => v == null ? 'Escolha a catraca.' : null,
              ),
              const SizedBox(height: 24),
              BotaoAcao(
                rotulo: 'Cadastrar',
                icone: Icons.check,
                onTocar: () {
                  if (_form.currentState!.validate()) {
                    Navigator.of(context).pop((_nome.text.trim(), _catracaId!));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogoChave extends StatelessWidget {
  const _DialogoChave({required this.terminal});

  final Terminal terminal;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final chave = terminal.chave ?? '';

    return AlertDialog(
      title: const Text('Copie a chave agora'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ela não aparece de novo. Grave no firmware e no broker.',
            ),
            const SizedBox(height: 16),
            Text('Id do terminal', style: textTheme.labelMedium),
            SelectableText(terminal.id),
            const SizedBox(height: 12),
            Text('Chave', style: textTheme.labelMedium),
            SelectableText(chave),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: chave));
            if (context.mounted) avisar(context, 'Chave copiada.');
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copiar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Já guardei'),
        ),
      ],
    );
  }
}
```

**Para ajustar:**

- A lista não se atualiza sozinha. Para acompanhar o "No ar", dá para recarregar com um `Timer` a cada 30 s.

### C8. Relatórios (sem tela no design)

Os totais são exatos. Os detalhes somam os 200 acessos mais recentes do período, e a tela avisa quando há mais que isso.

**Arquivo novo:** `frontend/lib/views/equipe/relatorios_view.dart`

```dart
import 'package:flutter/material.dart';

import '../../controllers/historico_controller.dart';
import '../../core/constants/motivos.dart';
import '../../models/evento_acesso.dart';
import '../widgets/campo_selecao.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/tela_base.dart';

/// Relatórios (só admin, sem tela no design). A API não tem rota agregada: os
/// totais vêm prontos de /access-events e os detalhes são somados aqui sobre
/// os [_limite] acessos mais recentes do período.
class RelatoriosView extends StatefulWidget {
  RelatoriosView({super.key, HistoricoController? controller})
    : controller = controller ?? HistoricoController(daEquipe: true);

  final HistoricoController controller;

  @override
  State<RelatoriosView> createState() => _RelatoriosViewState();
}

/// O máximo que a API devolve por página.
const _limite = 200;

class _RelatoriosViewState extends State<RelatoriosView>
    with CarregaDados<PaginaEventos, RelatoriosView> {
  var _periodo = PeriodoHistorico.seteDias;

  @override
  Future<PaginaEventos> buscar() => widget.controller.carregar(
    FiltroEventos(periodo: _periodo),
    limite: _limite,
  );

  Map<String, int> _contar(Iterable<String> chaves) {
    final contagem = <String, int>{};
    for (final chave in chaves) {
      contagem[chave] = (contagem[chave] ?? 0) + 1;
    }
    return Map.fromEntries(
      contagem.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  List<Widget> _relatorio(PaginaEventos p) {
    final textTheme = Theme.of(context).textTheme;
    final porLocal = _contar(p.itens.map((e) => e.catraca ?? 'Sem catraca'));
    final porMotivo = _contar(
      p.itens.where((e) => !e.liberado).map((e) => Motivos.titulo(e.motivo)),
    );

    return [
      Row(
        children: [
          Expanded(child: _Total(rotulo: 'Liberados', valor: p.liberados)),
          const SizedBox(width: 12),
          Expanded(child: _Total(rotulo: 'Negados', valor: p.negados)),
        ],
      ),
      if (p.total > _limite) ...[
        const SizedBox(height: 12),
        Text(
          'Os detalhes abaixo somam os $_limite acessos mais recentes de '
          '${p.total}.',
          style: textTheme.bodySmall,
        ),
      ],
      const SizedBox(height: 24),
      Text('Acessos por local', style: textTheme.titleMedium),
      const SizedBox(height: 8),
      if (porLocal.isEmpty) const Text('Nenhum acesso no período.'),
      for (final MapEntry(:key, :value) in porLocal.entries)
        _Barra(rotulo: key, valor: value, maximo: porLocal.values.first),
      const SizedBox(height: 24),
      Text('Motivos de recusa', style: textTheme.titleMedium),
      const SizedBox(height: 8),
      if (porMotivo.isEmpty) const Text('Nenhuma recusa no período.'),
      for (final MapEntry(:key, :value) in porMotivo.entries)
        _Barra(rotulo: key, valor: value, maximo: porMotivo.values.first),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      titulo: 'Relatórios',
      subtitulo: 'Acessos por período e local',
      onAtualizar: carregar,
      filhos: [
        EscolhaEmChips<PeriodoHistorico>(
          rotulo: 'Período',
          valor: _periodo,
          opcoes: [for (final p in PeriodoHistorico.values) (p, p.rotulo)],
          onMudar: (p) {
            _periodo = p;
            recarregar();
          },
        ),
        const SizedBox(height: 20),
        ...conteudo(_relatorio),
      ],
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.rotulo, required this.valor});

  final String rotulo;
  final int valor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$valor', style: textTheme.headlineMedium),
            Text(rotulo, style: textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra({
    required this.rotulo,
    required this.valor,
    required this.maximo,
  });

  final String rotulo;
  final int valor;
  final int maximo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(rotulo)),
              const SizedBox(width: 8),
              Text('$valor'),
            ],
          ),
          const SizedBox(height: 4),
          ExcludeSemantics(
            child: LinearProgressIndicator(
              value: maximo == 0 ? 0 : valor / maximo,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Para ajustar:**

- Para detalhes exatos, crie uma rota agregada no backend (B12).

### S4. Ajuda (sem tela no design)

Texto fixo, sem API.

**Arquivo novo:** `frontend/lib/views/user/ajuda_view.dart`

```dart
import 'package:flutter/material.dart';

import '../widgets/tela_base.dart';

/// Ajuda: texto fixo, sem chamar a API.
class AjudaView extends StatelessWidget {
  const AjudaView({super.key});

  // TROQUE pelos dados reais do prédio.
  static const _telefone = '(12) 0000-0000';
  static const _horario = 'Todos os dias, das 06:00 às 22:00';

  static const _perguntas = [
    (
      'O QR Code não abre a catraca',
      'Confira se a localização do celular está ligada e chegue mais perto da '
          'catraca. O QR troca a cada 10 segundos: espere o novo e escaneie de '
          'novo.',
    ),
    (
      'Perdi minha tag NFC',
      'Avise a portaria o quanto antes para ela bloquear a tag.',
    ),
    (
      'Esqueci minha senha',
      'A portaria cria uma senha nova para você. Leve um documento.',
    ),
    (
      'Minha autorização venceu',
      'Peça uma nova autorização à portaria ou à pessoa que recebe você.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return TelaBase(
      titulo: 'Ajuda',
      subtitulo: 'Contato da portaria',
      filhos: [
        const Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.phone_outlined),
                title: Text('Telefone'),
                subtitle: Text(_telefone),
              ),
              ListTile(
                leading: Icon(Icons.schedule),
                title: Text('Atendimento'),
                subtitle: Text(_horario),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Dúvidas comuns', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (pergunta, resposta) in _perguntas)
                ExpansionTile(
                  title: Text(pergunta),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text(resposta)],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
```

**Para ajustar:**

- **Troque** o telefone e o horário de exemplo em `_telefone` e `_horario`.

### S5. Perfil (U9)

Abre a Ajuda, então cole S4 antes.

**Arquivo novo:** `frontend/lib/controllers/perfil_controller.dart`

```dart
import '../models/usuario_cadastro.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

/// U9 · Perfil e Minha tag NFC: os dados de quem está logado.
class PerfilController {
  PerfilController({ApiClient? api, AuthService? auth})
    : _api = api ?? ApiClient.instancia,
      _auth = auth ?? AuthService.instancia;

  final ApiClient _api;
  final AuthService _auth;

  /// GET /auth/me traz também as tags.
  Future<UsuarioCadastro> carregar() async {
    final json = await _api.get('/auth/me');
    return UsuarioCadastro.fromJson(json as Map<String, dynamic>);
  }

  /// Só funciona depois da B6 (PATCH /me/tags/:tagId). Hoje responde 404.
  Future<void> bloquearTag(String tagId) =>
      _api.patch('/me/tags/$tagId', {'ativa': false});

  Future<void> sair() => _auth.sair();
}
```

**Arquivo novo:** `frontend/lib/views/user/perfil_view.dart`

```dart
import 'package:flutter/material.dart';

import '../../controllers/perfil_controller.dart';
import '../../core/constants/formato.dart';
import '../../models/usuario_cadastro.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/tela_base.dart';
import '../widgets/tela_carregando.dart';
import 'ajuda_view.dart';
import 'login_view.dart';

/// U9 · Perfil / Sair.
class PerfilView extends StatefulWidget {
  PerfilView({super.key, PerfilController? controller})
    : controller = controller ?? PerfilController();

  final PerfilController controller;

  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView>
    with CarregaDados<UsuarioCadastro, PerfilView> {
  @override
  Future<UsuarioCadastro> buscar() => widget.controller.carregar();

  Future<void> _sair() => TelaCarregando.abrir(
    context,
    mensagem: 'Saindo…',
    tarefa: () async {
      await widget.controller.sair();
      return LoginView();
    },
  );

  List<Widget> _dados(UsuarioCadastro usuario) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final tag = usuario.tags.firstOrNull;

    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                child: Text(Formato.iniciais(usuario.nome)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(usuario.nome, style: textTheme.titleLarge),
                    Text(
                      Formato.perfil(usuario.perfil),
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('E-mail'),
              subtitle: Text(usuario.email),
            ),
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('CPF'),
              subtitle: Text(Formato.cpfMascarado(usuario.cpf)),
            ),
            ListTile(
              leading: const Icon(Icons.contactless_outlined),
              title: const Text('Tag NFC'),
              subtitle: Text(
                tag == null
                    ? 'Nenhuma tag vinculada'
                    : '${tag.ativa ? 'Vinculada' : 'Bloqueada'} · '
                          'final ${Formato.finalTag(tag.uid)}',
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text('Ajuda e contato da portaria'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AjudaView()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Sobre o Passe'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'Passe',
                applicationVersion: 'Versão 1.0',
                applicationLegalese: 'ABP 4º DSM · FATEC Jacareí, 2026',
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      OutlinedButton.icon(
        onPressed: _sair,
        icon: const Icon(Icons.logout),
        label: const Text('Sair da conta'),
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.error,
          side: BorderSide(color: colorScheme.error, width: 1.5),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      titulo: 'Perfil',
      onAtualizar: carregar,
      filhos: conteudo(_dados),
    );
  }
}
```

**Para ajustar:**

- O design mostra o prédio embaixo do nome. O morador não pode ler `/locations` (403): para mostrar, use o `edificio` de `GET /me/authorizations`.

### S6. Minha tag NFC (sem tela no design)

Ver funciona hoje. Só passe `podeBloquear: true` depois da B6.

**Arquivo novo:** `frontend/lib/views/user/minha_tag_view.dart`

```dart
import 'package:flutter/material.dart';

import '../../controllers/perfil_controller.dart';
import '../../core/constants/formato.dart';
import '../../models/opcao_menu.dart';
import '../../models/usuario_cadastro.dart';
import '../../services/api_client.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/estado_vazio.dart';
import '../widgets/selo.dart';
import '../widgets/tela_base.dart';

/// Minha tag NFC. Ver funciona hoje. Com [podeBloquear], o morador bloqueia a
/// própria tag: só ligue depois da B6 (PATCH /me/tags/:tagId).
class MinhaTagView extends StatefulWidget {
  MinhaTagView({
    super.key,
    this.podeBloquear = false,
    PerfilController? controller,
  }) : controller = controller ?? PerfilController();

  final bool podeBloquear;
  final PerfilController controller;

  @override
  State<MinhaTagView> createState() => _MinhaTagViewState();
}

class _MinhaTagViewState extends State<MinhaTagView>
    with CarregaDados<UsuarioCadastro, MinhaTagView> {
  @override
  Future<UsuarioCadastro> buscar() => widget.controller.carregar();

  Future<void> _bloquear(TagNfc tag) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Bloquear esta tag?'),
        content: const Text(
          'Ela para de abrir a catraca. Para usar de novo, só a portaria '
          'consegue liberar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Manter'),
          ),
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            child: const Text('Bloquear'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;
    try {
      await widget.controller.bloquearTag(tag.id);
      if (mounted) await carregar();
    } on ApiException catch (e) {
      if (mounted) await tratarErro(context, e);
    }
  }

  List<Widget> _tags(UsuarioCadastro usuario) {
    if (usuario.tags.isEmpty) {
      return const [
        EstadoVazio(
          icone: Icons.contactless_outlined,
          titulo: 'Você não tem tag vinculada',
          texto: 'Peça na portaria para vincular uma tag ao seu cadastro.',
        ),
      ];
    }
    final textTheme = Theme.of(context).textTheme;
    return [
      for (final tag in usuario.tags)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Final ${Formato.finalTag(tag.uid)}',
                          style: textTheme.titleLarge,
                        ),
                      ),
                      tag.ativa
                          ? const Selo(
                              texto: 'Ativa',
                              icone: Icons.check_circle,
                              tom: TomOpcao.sucesso,
                            )
                          : const Selo(
                              texto: 'Bloqueada',
                              icone: Icons.block,
                              tom: TomOpcao.perigo,
                            ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tag.ativa
                        ? 'Aproxime do terminal da catraca para passar.'
                        : 'Fale com a portaria para liberar.',
                    style: textTheme.bodyMedium,
                  ),
                  if (widget.podeBloquear && tag.ativa) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _bloquear(tag),
                      icon: const Icon(Icons.block),
                      label: const Text('Bloquear tag'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      Text(
        'Perdeu a tag? Avise a portaria o quanto antes.',
        style: textTheme.bodySmall,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return TelaBase(
      titulo: 'Minha tag NFC',
      subtitulo: 'Passe aproximando a tag do terminal',
      onAtualizar: carregar,
      filhos: conteudo(_tags),
    );
  }
}
```

**Para ajustar:**

- Sem a B6, o botão de bloquear recebe 404. Por isso ele começa desligado.

### S7. Início (U2, E1 e E2)

Não entra nos menus: depende da decisão D2. O passo a passo está na seção 4.

**Arquivo novo:** `frontend/lib/views/user/inicio_view.dart`

```dart
import 'package:flutter/material.dart';

import '../../controllers/minhas_autorizacoes_controller.dart';
import '../../core/constants/formato.dart';
import '../../models/autorizacao.dart';
import '../../services/auth_service.dart';
import '../widgets/botao_acao.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/selo_situacao.dart';
import '../widgets/tela_base.dart';
import 'autorizacao_textos.dart';
import 'detalhe_autorizacao_view.dart';
import 'scanner_qr_view.dart';

/// U2 · Início, com o carregando (E1) e o sem internet (E2): a próxima
/// autorização e o atalho para o scanner. [menu] é o menu em grade do perfil.
/// Depende da decisão D2 do backlog: só entra no lugar do menu se o grupo
/// quiser.
class InicioView extends StatefulWidget {
  InicioView({
    super.key,
    required this.menu,
    MinhasAutorizacoesController? controller,
  }) : controller = controller ?? MinhasAutorizacoesController();

  final Widget menu;
  final MinhasAutorizacoesController controller;

  @override
  State<InicioView> createState() => _InicioViewState();
}

class _InicioViewState extends State<InicioView>
    with CarregaDados<List<Autorizacao>, InicioView> {
  MinhasAutorizacoesController get controller => widget.controller;

  @override
  Future<List<Autorizacao>> buscar() => controller.carregar();

  Future<void> _ir(Widget tela) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => tela));
    if (mounted) await carregar();
  }

  List<Widget> _resumo(List<Autorizacao> lista) {
    final textTheme = Theme.of(context).textTheme;
    final agora = controller.agora();
    final proxima = controller.agrupar(lista).ativas.firstOrNull;

    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: proxima == null
              ? const Text(
                  'Você não tem autorização válida. Peça uma à portaria.',
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sua próxima autorização',
                                style: textTheme.bodySmall,
                              ),
                              Text(
                                proxima.catraca.nome,
                                style: textTheme.titleLarge,
                              ),
                              Text(
                                proxima.catraca.edificio,
                                style: textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SeloSituacao(situacao: proxima.situacao),
                      ],
                    ),
                    const Divider(height: 28),
                    Text('Válida até ${Formato.data(proxima.dataFim)}'),
                    Text(proxima.horario),
                    Text(proxima.usos),
                    TextButton(
                      onPressed: () => _ir(
                        DetalheAutorizacaoView(
                          autorizacao: proxima,
                          agora: agora,
                        ),
                      ),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Text('Ver detalhes ›'),
                    ),
                  ],
                ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final nome = AuthService.instancia.usuario?.nome.split(' ').first;

    return TelaBase(
      titulo: nome == null ? 'Olá' : 'Olá, $nome',
      subtitulo: Formato.dataPorExtenso(controller.agora()),
      onAtualizar: carregar,
      filhos: [
        ...conteudo(_resumo),
        const SizedBox(height: 16),
        BotaoAcao(
          rotulo: 'Escanear QR Code',
          icone: Icons.qr_code_scanner,
          onTocar: () => _ir(ScannerQrView()),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _ir(widget.menu),
          icon: const Icon(Icons.menu),
          label: const Text('Menu'),
        ),
      ],
    );
  }
}
```

**Para ajustar:**

- A dica "Sem internet, sua tag NFC continua funcionando" do design não está no `CarregaDados`. Dá para acrescentar com o `dica` do `CartaoErro`.

## 3. Ligar as telas nos menus

Cada menu ganha os imports e um `_abrir` novo. As opções sem tela continuam com o aviso "em construção": Comunicados e Configurações no admin, Meus visitantes no morador.

Se você colou só parte das telas, apague da lista os imports e as linhas do `switch` das que ainda não existem.

### Administrador

**Em** `frontend/lib/views/admin/admin_menu_view.dart`, **troque:**

```dart
import '../widgets/menu_grade.dart';
```

**por:**

```dart
import '../compartilhado/historico_view.dart';
import '../equipe/autorizacoes_view.dart';
import '../equipe/painel_view.dart';
import '../equipe/tags_view.dart';
import '../equipe/terminais_view.dart';
import '../equipe/usuarios_view.dart';
import '../equipe/visitantes_view.dart';
import '../equipe/locais_view.dart';
import '../equipe/relatorios_view.dart';
import '../widgets/menu_grade.dart';
```

**Em** `frontend/lib/views/admin/admin_menu_view.dart`, **troque:**

```dart
  void _abrir(BuildContext context, OpcaoMenu opcao) {
    controller.abrir(opcao);
    // Protótipo: as telas ainda não existem, então só avisa.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${opcao.titulo}: tela em construção.')),
      );
  }
```

**por:**

```dart
  void _abrir(BuildContext context, OpcaoMenu opcao) {
    controller.abrir(opcao);
    final tela = switch (opcao.titulo) {
      'Painel' => PainelView(),
      'Autorizações' => AutorizacoesView(),
      'Histórico de acessos' => HistoricoView(daEquipe: true),
      'Acessos negados' => HistoricoView(daEquipe: true, soNegados: true),
      'Usuários' => UsuariosView(),
      'Visitantes' => VisitantesView(),
      'Tags NFC' => TagsView(),
      'Terminais' => TerminaisView(),
      'Locais' => LocaisView(),
      'Relatórios' => RelatoriosView(),
      _ => null,
    };
    if (tela != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));
      return;
    }
    // Protótipo: as outras telas ainda não existem, então só avisa.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${opcao.titulo}: tela em construção.')),
      );
  }
```

### Controlador de acesso

**Em** `frontend/lib/views/access_controller/access_controller_menu_view.dart`, **troque:**

```dart
import '../widgets/menu_grade.dart';
```

**por:**

```dart
import '../compartilhado/historico_view.dart';
import '../equipe/autorizacoes_view.dart';
import '../equipe/painel_view.dart';
import '../equipe/tags_view.dart';
import '../equipe/terminais_view.dart';
import '../equipe/usuarios_view.dart';
import '../equipe/visitantes_view.dart';
import '../widgets/menu_grade.dart';
```

**Em** `frontend/lib/views/access_controller/access_controller_menu_view.dart`, **troque:**

```dart
  void _abrir(BuildContext context, OpcaoMenu opcao) {
    controller.abrir(opcao);
    // Protótipo: as telas ainda não existem, então só avisa.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${opcao.titulo}: tela em construção.')),
      );
  }
```

**por:**

```dart
  void _abrir(BuildContext context, OpcaoMenu opcao) {
    controller.abrir(opcao);
    final tela = switch (opcao.titulo) {
      'Painel' => PainelView(),
      'Autorizações' => AutorizacoesView(),
      'Histórico de acessos' => HistoricoView(daEquipe: true),
      'Acessos negados' => HistoricoView(daEquipe: true, soNegados: true),
      'Usuários' => UsuariosView(),
      'Visitantes' => VisitantesView(),
      'Tags NFC' => TagsView(),
      'Terminais' => TerminaisView(),
      _ => null,
    };
    if (tela != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));
      return;
    }
    // Protótipo: as outras telas ainda não existem, então só avisa.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${opcao.titulo}: tela em construção.')),
      );
  }
```

### Morador

**Em** `frontend/lib/views/resident/resident_menu_view.dart`, **troque:**

```dart
import '../widgets/menu_grade.dart';
```

**por:**

```dart
import '../compartilhado/historico_view.dart';
import '../user/ajuda_view.dart';
import '../user/minha_tag_view.dart';
import '../user/perfil_view.dart';
import '../widgets/menu_grade.dart';
```

**Em** `frontend/lib/views/resident/resident_menu_view.dart`, **troque:**

```dart
  void _abrir(BuildContext context, OpcaoMenu opcao) {
    controller.abrir(opcao);
    final tela = switch (opcao.titulo) {
      'Escanear QR Code' => ScannerQrView(),
      'Minhas autorizações' => MinhasAutorizacoesView(),
      _ => null,
    };
    if (tela != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));
      return;
    }
    // Protótipo: as outras telas ainda não existem, então só avisa.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${opcao.titulo}: tela em construção.')),
      );
  }
```

**por:**

```dart
  void _abrir(BuildContext context, OpcaoMenu opcao) {
    controller.abrir(opcao);
    final tela = switch (opcao.titulo) {
      'Escanear QR Code' => ScannerQrView(),
      'Minhas autorizações' => MinhasAutorizacoesView(),
      'Histórico de acessos' => HistoricoView(daEquipe: false),
      'Acessos negados' => HistoricoView(daEquipe: false, soNegados: true),
      'Minha tag NFC' => MinhaTagView(),
      'Perfil' => PerfilView(),
      'Ajuda' => const AjudaView(),
      _ => null,
    };
    if (tela != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));
      return;
    }
    // Protótipo: as outras telas ainda não existem, então só avisa.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${opcao.titulo}: tela em construção.')),
      );
  }
```

### Visitante

**Em** `frontend/lib/views/visitor/visitor_menu_view.dart`, **troque:**

```dart
import '../widgets/menu_grade.dart';
```

**por:**

```dart
import '../compartilhado/historico_view.dart';
import '../user/ajuda_view.dart';
import '../user/minha_tag_view.dart';
import '../user/perfil_view.dart';
import '../widgets/menu_grade.dart';
```

**Em** `frontend/lib/views/visitor/visitor_menu_view.dart`, **troque:**

```dart
  void _abrir(BuildContext context, OpcaoMenu opcao) {
    controller.abrir(opcao);
    final tela = switch (opcao.titulo) {
      'Escanear QR Code' => ScannerQrView(),
      'Minhas autorizações' => MinhasAutorizacoesView(),
      _ => null,
    };
    if (tela != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));
      return;
    }
    // Protótipo: as outras telas ainda não existem, então só avisa.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${opcao.titulo}: tela em construção.')),
      );
  }
```

**por:**

```dart
  void _abrir(BuildContext context, OpcaoMenu opcao) {
    controller.abrir(opcao);
    final tela = switch (opcao.titulo) {
      'Escanear QR Code' => ScannerQrView(),
      'Minhas autorizações' => MinhasAutorizacoesView(),
      'Histórico de acessos' => HistoricoView(daEquipe: false),
      'Acessos negados' => HistoricoView(daEquipe: false, soNegados: true),
      'Minha tag NFC' => MinhaTagView(),
      'Perfil' => PerfilView(),
      'Ajuda' => const AjudaView(),
      _ => null,
    };
    if (tela != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));
      return;
    }
    // Protótipo: as outras telas ainda não existem, então só avisa.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${opcao.titulo}: tela em construção.')),
      );
  }
```

## 4. Início (opcional, decisão D2)

Só faça isto se o grupo decidir que a U2 vira a primeira tela. A `InicioView` recebe o menu do perfil, que abre pelo botão Menu.

**Em** `frontend/lib/core/routes/rotas.dart`, **troque:**

```dart
  Perfil.morador => ResidentMenuView(),
  Perfil.visitante => VisitorMenuView(),
```

**por:**

```dart
  Perfil.morador => InicioView(menu: ResidentMenuView()),
  Perfil.visitante => InicioView(menu: VisitorMenuView()),
```


Acrescente também `import '../../views/user/inicio_view.dart';` no `rotas.dart`.

Isso muda a tela depois do login, então os testes que esperam o menu logo depois de entrar (`widget_test.dart` e `login_view_test.dart`) vão precisar de ajuste. Esta troca **não** foi testada junto com o resto: a `InicioView` foi testada sozinha.

## 5. Ajustar os testes que quebram

Depois de ligar os menus, exatamente estes 4 testes falham, porque esperam "tela em construção". Com as trocas abaixo, a suíte inteira passa.

### Administrador: usa uma opção que continua sem tela

**Em** `frontend/test/views/admin/admin_menu_view_test.dart`, **troque:**

```dart
    await tester.scrollUntilVisible(find.text('Usuários'), 200);
    await tester.pump();
    await tester.tap(find.text('Usuários'));
    await tester.pump();

    expect(controller.abertas, ['Usuários']);
    expect(find.text('Usuários: tela em construção.'), findsOneWidget);
```

**por:**

```dart
    await tester.scrollUntilVisible(find.text('Comunicados'), 200);
    await tester.pump();
    await tester.tap(find.text('Comunicados'));
    await tester.pump();

    expect(controller.abertas, ['Comunicados']);
    expect(find.text('Comunicados: tela em construção.'), findsOneWidget);
```

### Morador: usa uma opção que continua sem tela

**Em** `frontend/test/views/resident/resident_menu_view_test.dart`, **troque:**

```dart
    await tester.tap(find.text('Histórico de acessos'));
    await tester.pump();

    expect(controller.abertas, ['Histórico de acessos']);
    expect(
      find.text('Histórico de acessos: tela em construção.'),
      findsOneWidget,
    );
```

**por:**

```dart
    await tester.scrollUntilVisible(find.text('Meus visitantes'), 200);
    await tester.pump();
    await tester.tap(find.text('Meus visitantes'));
    await tester.pump();

    expect(controller.abertas, ['Meus visitantes']);
    expect(find.text('Meus visitantes: tela em construção.'), findsOneWidget);
```

### Controlador de acesso: todas as opções agora abrem tela

**Em** `frontend/test/views/access_controller/access_controller_menu_view_test.dart`, **troque:**

```dart
import 'package:public/views/access_controller/access_controller_menu_view.dart';
```

**por:**

```dart
import 'package:public/views/access_controller/access_controller_menu_view.dart';
import 'package:public/views/equipe/visitantes_view.dart';
```



**Em** `frontend/test/views/access_controller/access_controller_menu_view_test.dart`, **troque:**

```dart
    await tester.tap(find.text('Visitantes'));
    await tester.pump();

    expect(controller.abertas, ['Visitantes']);
    expect(find.text('Visitantes: tela em construção.'), findsOneWidget);
```

**por:**

```dart
    await tester.tap(find.text('Visitantes'));
    await tester.pumpAndSettle();

    expect(controller.abertas, ['Visitantes']);
    expect(find.byType(VisitantesView), findsOneWidget);
```

### Visitante: todas as opções agora abrem tela

**Em** `frontend/test/views/visitor/visitor_menu_view_test.dart`, **troque:**

```dart
import 'package:public/views/user/login_view.dart';
```

**por:**

```dart
import 'package:public/views/compartilhado/historico_view.dart';
import 'package:public/views/user/login_view.dart';
```



**Em** `frontend/test/views/visitor/visitor_menu_view_test.dart`, **troque:**

```dart
    await tester.tap(find.text('Histórico de acessos'));
    await tester.pump();

    expect(controller.abertas, ['Histórico de acessos']);
    expect(
      find.text('Histórico de acessos: tela em construção.'),
      findsOneWidget,
    );
```

**por:**

```dart
    await tester.tap(find.text('Histórico de acessos'));
    await tester.pumpAndSettle();

    expect(controller.abertas, ['Histórico de acessos']);
    expect(find.byType(HistoricoView), findsOneWidget);
```


Nos dois últimos, vale também trocar o nome do teste de "Tocar numa opção chama o controller e avisa" para "Tocar numa opção chama o controller e abre a tela".

## 6. Testes das telas novas

Um arquivo com 71 testes: fonte em 2×, modo escuro, sem internet e sessão vencida em cada tela, além das regras principais. Ele usa `test/support/api_falsa.dart`, que já existe. As respostas de exemplo foram copiadas da API real.

Ele importa todas as telas, então só compila depois de colar todas. Se colar aos poucos, comente as que faltam no início do arquivo e no mapa `_telas()`.

**Arquivo novo:** `frontend/test/views/novas/telas_novas_test.dart`

```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:public/controllers/autorizacoes_controller.dart';
import 'package:public/controllers/historico_controller.dart';
import 'package:public/controllers/locais_controller.dart';
import 'package:public/controllers/minhas_autorizacoes_controller.dart';
import 'package:public/controllers/painel_controller.dart';
import 'package:public/controllers/perfil_controller.dart';
import 'package:public/controllers/terminais_controller.dart';
import 'package:public/controllers/usuarios_controller.dart';
import 'package:public/models/autorizacao.dart';
import 'package:public/core/theme/app_theme.dart';
import 'package:public/services/api_client.dart';
import 'package:public/services/sessao_service.dart';
import 'package:public/views/compartilhado/historico_view.dart';
import 'package:public/views/equipe/autorizacao_form_view.dart';
import 'package:public/views/equipe/autorizacoes_view.dart';
import 'package:public/views/equipe/locais_view.dart';
import 'package:public/views/equipe/painel_view.dart';
import 'package:public/views/equipe/relatorios_view.dart';
import 'package:public/views/equipe/tags_view.dart';
import 'package:public/views/equipe/terminais_view.dart';
import 'package:public/views/equipe/usuario_form_view.dart';
import 'package:public/views/equipe/usuarios_view.dart';
import 'package:public/views/equipe/visitantes_view.dart';
import 'package:public/views/user/ajuda_view.dart';
import 'package:public/views/user/inicio_view.dart';
import 'package:public/views/user/login_view.dart';
import 'package:public/views/user/minha_tag_view.dart';
import 'package:public/views/user/perfil_view.dart';

import '../../support/api_falsa.dart';

// Respostas copiadas da API real (GET de cada rota com o seed).
const _tag = {
  'id': 'tag-1',
  'uid': '04A1B2C3',
  'userId': 'u-maria',
  'ativa': true,
  'createdAt': '2026-11-02T03:07:33.882Z',
};
const _maria = {
  'id': 'u-maria',
  'nome': 'Maria Souza',
  'email': 'morador@passe.com',
  'cpf': '33333333333',
  'perfil': 'CONDOMINO',
  'ativo': true,
  'tags': [_tag],
};
const _carlos = {
  'id': 'u-carlos',
  'nome': 'Carlos Lima',
  'email': 'admin@passe.com',
  'cpf': '11111111111',
  'perfil': 'ADMIN',
  'ativo': true,
  'tags': <Object>[],
};
const _ana = {
  'id': 'u-ana',
  'nome': 'Ana Lima',
  'email': 'visitante@passe.com',
  'cpf': '44444444444',
  'perfil': 'VISITANTE',
  'ativo': true,
  'tags': <Object>[],
};
const _arvore = [
  {
    'id': 'b1',
    'nome': 'FATEC Jacareí',
    'endereco': 'Av. Faria Lima, 155',
    'portarias': [
      {
        'id': 'g1',
        'nome': 'Portaria Principal',
        'buildingId': 'b1',
        'portas': [
          {
            'id': 'd1',
            'nome': 'Porta A',
            'gateId': 'g1',
            'catracas': [
              {
                'id': '00000000-0000-4000-8000-000000000004',
                'nome': 'Catraca 1',
                'doorId': 'd1',
                'latitude': -23.3053,
                'longitude': -45.9658,
                'raioMetros': 100,
              },
            ],
          },
        ],
      },
    ],
  },
];
const _terminal = {
  'id': 't1',
  'nome': 'Terminal Catraca 1',
  'accessPointId': '00000000-0000-4000-8000-000000000004',
  'ultimoSinal': '2026-11-02T03:08:24.085Z',
  'latitude': null,
  'longitude': null,
  'online': true,
};
const _eventoNegado = {
  'id': 'e1',
  'metodo': 'QR',
  'resultado': 'NEGADO',
  'motivo': 'FORA_DO_HORARIO',
  'credencial': 'CQFWRZQNUDLEXEYV',
  'distanciaMetros': null,
  'createdAt': '2026-11-02T03:08:24.107Z',
  'user': {'id': 'u-maria', 'nome': 'Maria Souza'},
  'catraca': {'id': 'c1', 'nome': 'Catraca 1'},
};
// Tag desconhecida: o evento vem sem pessoa.
const _eventoSemPessoa = {
  'id': 'e2',
  'metodo': 'NFC',
  'resultado': 'NEGADO',
  'motivo': 'TAG_DESCONHECIDA',
  'credencial': 'DEADBEEF',
  'distanciaMetros': null,
  'createdAt': '2026-11-02T03:08:24.114Z',
  'user': null,
  'catraca': {'id': 'c1', 'nome': 'Catraca 1'},
};
const _eventoLiberado = {
  'id': 'e3',
  'metodo': 'QR',
  'resultado': 'LIBERADO',
  'motivo': null,
  'credencial': 'ABC',
  'distanciaMetros': 12.4,
  'createdAt': '2026-11-02T12:08:24.114Z',
  'user': {'id': 'u-maria', 'nome': 'Maria Souza'},
  'catraca': {'id': 'c1', 'nome': 'Catraca 1'},
};

/// API com as rotas das telas novas. Guarda cada requisição em [chamadas].
MockClient _api({List<http.Request>? chamadas, int? statusFixo}) {
  return MockClient((request) async {
    chamadas?.add(request);
    if (statusFixo != null) {
      return erroDaApi(statusFixo, 'NAO_AUTENTICADO', 'Sessão inválida.');
    }
    final rota = '${request.method} ${request.url.path}';
    final eventos = {
      'itens': [_eventoLiberado, _eventoNegado, _eventoSemPessoa],
      'total': 3,
      'liberados': 1,
      'negados': 2,
    };
    return switch (rota) {
      'GET /users' => respostaJson(
        request.url.queryParameters['perfil'] == 'VISITANTE'
            ? [_ana]
            : [_ana, _carlos, _maria],
        200,
      ),
      'POST /users' => respostaJson(_ana, 201),
      'PATCH /users/u-maria' => respostaJson(_maria, 200),
      'GET /locations' => respostaJson(_arvore, 200),
      'GET /terminals' => respostaJson([_terminal], 200),
      'GET /authorizations' => respostaJson([
        autorizacaoJson(),
        autorizacaoJson(id: 'a2', situacao: 'AGENDADA'),
      ], 200),
      'POST /authorizations' => respostaJson(autorizacaoJson(), 201),
      'PATCH /authorizations/autorizacao-1' => respostaJson(
        autorizacaoJson(),
        200,
      ),
      'POST /authorizations/autorizacao-1/cancel' => respostaJson(
        autorizacaoJson(situacao: 'CANCELADA'),
        200,
      ),
      'GET /me/authorizations' => respostaJson([autorizacaoJson()], 200),
      'GET /access-events' || 'GET /me/access-events' => respostaJson(
        eventos,
        200,
      ),
      'GET /dashboard' => respostaJson({
        'acessosHoje': 248,
        'negadosHoje': 12,
        'autorizacoesAtivas': 86,
        'negadosRecentes': [_eventoNegado, _eventoSemPessoa],
      }, 200),
      'GET /auth/me' => respostaJson(_maria, 200),
      _ => erroDaApi(404, 'ROTA_NAO_ENCONTRADA', '$rota não existe.'),
    };
  });
}

Future<void> _abrir(
  WidgetTester tester,
  Widget tela, {
  double fonte = 1,
  ThemeData? tema,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = fonte;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    MaterialApp(
      theme: tema ?? AppTheme.light,
      home: Builder(
        builder: (contexto) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(
                contexto,
              ).push(MaterialPageRoute(builder: (_) => tela)),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

/// Cada tela nova, ligada à API de [cliente].
Map<String, Widget Function(http.Client)> _telas() {
  ApiClient api(http.Client cliente) => ApiClient(cliente: cliente);
  return {
    'Painel': (c) => PainelView(controller: PainelController(api: api(c))),
    'Autorizações': (c) =>
        AutorizacoesView(controller: AutorizacoesController(api: api(c))),
    'Autorização · formulário': (c) =>
        AutorizacaoFormView(controller: AutorizacoesController(api: api(c))),
    'Histórico da equipe': (c) => HistoricoView(
      daEquipe: true,
      controller: HistoricoController(daEquipe: true, api: api(c)),
    ),
    'Acessos negados do morador': (c) => HistoricoView(
      daEquipe: false,
      soNegados: true,
      controller: HistoricoController(daEquipe: false, api: api(c)),
    ),
    'Usuários': (c) =>
        UsuariosView(controller: UsuariosController(api: api(c))),
    'Usuário · formulário': (c) =>
        UsuarioFormView(controller: UsuariosController(api: api(c))),
    'Visitantes': (c) =>
        VisitantesView(controller: UsuariosController(api: api(c))),
    'Locais': (c) => LocaisView(controller: LocaisController(api: api(c))),
    'Tags NFC': (c) => TagsView(controller: UsuariosController(api: api(c))),
    'Terminais': (c) =>
        TerminaisView(controller: TerminaisController(api: api(c))),
    'Relatórios': (c) => RelatoriosView(
      controller: HistoricoController(daEquipe: true, api: api(c)),
    ),
    'Perfil': (c) => PerfilView(controller: PerfilController(api: api(c))),
    'Minha tag': (c) => MinhaTagView(
      podeBloquear: true,
      controller: PerfilController(api: api(c)),
    ),
    'Início': (c) => InicioView(
      menu: const SizedBox(),
      controller: MinhasAutorizacoesController(api: api(c)),
    ),
  };
}

void main() {
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await SessaoService.instancia.encerrar();
  });

  group('Todas as telas novas', () {
    for (final MapEntry(key: nome, value: criar) in _telas().entries) {
      testWidgets('$nome cabe com a fonte no dobro', (tester) async {
        await _abrir(tester, criar(_api()), fonte: 2);
        expect(tester.takeException(), isNull);
      });

      testWidgets('$nome funciona no modo escuro', (tester) async {
        await _abrir(tester, criar(_api()), tema: AppTheme.dark);
        expect(tester.takeException(), isNull);
      });

      if (nome != 'Usuário · formulário') {
        testWidgets('$nome sem internet mostra o erro', (tester) async {
          await _abrir(tester, criar(semInternet()));
          expect(find.text('Sem conexão com a internet'), findsOneWidget);
        });

        testWidgets('$nome com a sessão vencida volta ao login', (
          tester,
        ) async {
          await _abrir(tester, criar(_api(statusFixo: 401)));
          expect(find.byType(LoginView), findsOneWidget);
        });
      }
    }
  });

  testWidgets('Ajuda abre sem chamar a API', (tester) async {
    await _abrir(tester, const AjudaView(), fonte: 2);
    expect(find.text('Ajuda'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('Histórico', () {
    testWidgets('Mostra os totais, o motivo e quem não foi identificado', (
      tester,
    ) async {
      await _abrir(tester, _telas()['Histórico da equipe']!(_api()));
      expect(
        find.text('3 registros · 1 liberados, 2 negados'),
        findsOneWidget,
      );
      expect(find.text('Fora do horário permitido'), findsOneWidget);
      expect(find.text('Pessoa não identificada'), findsOneWidget);
    });

    testWidgets('Morador lê /me/access-events e vê o que fazer', (
      tester,
    ) async {
      final chamadas = <http.Request>[];
      await _abrir(
        tester,
        _telas()['Acessos negados do morador']!(_api(chamadas: chamadas)),
      );
      expect(chamadas.single.url.path, '/me/access-events');
      expect(chamadas.single.url.queryParameters['resultado'], 'NEGADO');
      expect(
        find.text('Volte dentro do horário ou fale com a portaria.'),
        findsOneWidget,
      );
    });

    test('O período vai com data e hora, cobrindo o dia inteiro', () async {
      final chamadas = <http.Request>[];
      final controller = HistoricoController(
        daEquipe: true,
        api: ApiClient(cliente: _api(chamadas: chamadas)),
        relogio: () => DateTime(2026, 11, 2, 10),
      );
      await controller.carregar(
        const FiltroEventos(periodo: PeriodoHistorico.hoje),
      );
      final query = chamadas.single.url.queryParameters;
      expect(DateTime.parse(query['de']!).toLocal(), DateTime(2026, 11, 2));
      expect(
        DateTime.parse(query['ate']!).toLocal(),
        DateTime(2026, 11, 2, 23, 59, 59),
      );
    });
  });

  group('Autorizações', () {
    test('O filtro Ativa não traz as agendadas (B4)', () async {
      final controller = AutorizacoesController(
        api: ApiClient(cliente: _api()),
      );
      final lista = await controller.listar(
        const FiltroAutorizacoes(situacao: SituacaoAutorizacao.ativa),
      );
      expect(lista.map((a) => a.autorizacao.id), ['autorizacao-1']);
    });

    testWidgets('Cancelar pede confirmação e chama a API (A10)', (
      tester,
    ) async {
      final chamadas = <http.Request>[];
      final controller = AutorizacoesController(
        api: ApiClient(cliente: _api(chamadas: chamadas)),
      );
      final lista = await controller.listar(const FiltroAutorizacoes());
      await _abrir(
        tester,
        AutorizacaoFormView(autorizacao: lista.first, controller: controller),
      );

      await tester.ensureVisible(find.text('Cancelar autorização'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar autorização'));
      await tester.pumpAndSettle();
      expect(find.text('Cancelar esta autorização?'), findsOneWidget);

      await tester.tap(find.text('Não, manter'));
      await tester.pumpAndSettle();
      expect(chamadas.where((c) => c.url.path.endsWith('/cancel')), isEmpty);

      await tester.tap(find.text('Cancelar autorização'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sim, cancelar'));
      await tester.pumpAndSettle();
      expect(chamadas.where((c) => c.url.path.endsWith('/cancel')), hasLength(1));
    });

    testWidgets('Sem escolher pessoa e local, não envia', (tester) async {
      final chamadas = <http.Request>[];
      await _abrir(
        tester,
        _telas()['Autorização · formulário']!(_api(chamadas: chamadas)),
      );
      await tester.tap(find.text('Criar autorização'));
      await tester.pumpAndSettle();
      expect(find.text('Escolha a pessoa.'), findsOneWidget);
      expect(chamadas.where((c) => c.method == 'POST'), isEmpty);
    });
  });

  group('Usuários', () {
    testWidgets('Portaria só escolhe morador e visitante, e não edita o admin', (
      tester,
    ) async {
      final auth = authFalso();
      await auth.entrar('portaria@passe.com', senhaDemo);
      final controller = UsuariosController(
        api: ApiClient(cliente: _api()),
        auth: auth,
      );
      expect(controller.podeGerenciar(contasDemo.first.perfil), isFalse);

      await _abrir(tester, UsuariosView(controller: controller));
      await tester.tap(find.text('Novo usuário'));
      await tester.pumpAndSettle();
      expect(find.text('Condômino'), findsOneWidget);
      expect(find.text('Administrador'), findsNothing);
    });

    testWidgets('Envia os dados e mostra o erro do campo vindo da API', (
      tester,
    ) async {
      final chamadas = <http.Request>[];
      final cliente = MockClient((request) async {
        chamadas.add(request);
        return respostaJson({
          'erro': {
            'codigo': 'DADOS_INVALIDOS',
            'mensagem': 'Dados inválidos.',
            'detalhes': {
              'email': ['E-mail inválido'],
            },
          },
        }, 400);
      });
      await _abrir(
        tester,
        UsuarioFormView(
          controller: UsuariosController(api: ApiClient(cliente: cliente)),
        ),
      );
      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'Vis Teste');
      await tester.enterText(campos.at(1), '123.456.789-09');
      await tester.enterText(campos.at(2), 'a@b');
      await tester.enterText(campos.at(3), 'passe123');
      await tester.tap(find.text('Criar usuário'));
      await tester.pumpAndSettle();

      final corpo = jsonDecode(chamadas.single.body) as Map<String, dynamic>;
      expect(corpo['perfil'], 'CONDOMINO');
      expect(corpo['cpf'], '123.456.789-09');
      expect(find.text('E-mail inválido'), findsOneWidget);
    });
  });

  group('Terminais', () {
    testWidgets('Cruza o terminal com o nome da catraca', (tester) async {
      await _abrir(tester, _telas()['Terminais']!(_api()));
      expect(
        find.text('Catraca 1 · Portaria Principal › Porta A'),
        findsOneWidget,
      );
      expect(find.text('No ar'), findsOneWidget);
    });

    testWidgets('Portaria não vê cadastrar nem trocar chave', (tester) async {
      final auth = authFalso();
      await auth.entrar('portaria@passe.com', senhaDemo);
      await _abrir(
        tester,
        TerminaisView(
          controller: TerminaisController(
            api: ApiClient(cliente: _api()),
            auth: auth,
          ),
        ),
      );
      expect(find.text('Novo terminal'), findsNothing);
      expect(find.text('Trocar chave'), findsNothing);
    });
  });

  testWidgets('Tags: busca filtra por UID, que a API não procura', (
    tester,
  ) async {
    await _abrir(tester, _telas()['Tags NFC']!(_api()));
    expect(find.text('Maria Souza'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'ffff');
    await tester.pump();
    expect(find.text('Nenhuma tag encontrada'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'b2c3');
    await tester.pump();
    expect(find.text('Maria Souza'), findsOneWidget);
  });

  testWidgets('Perfil mascara o CPF', (tester) async {
    await _abrir(tester, _telas()['Perfil']!(_api()));
    expect(find.text('•••.333.333-••'), findsOneWidget);
    expect(find.text('33333333333'), findsNothing);
    expect(find.text('Vinculada · final B2C3'), findsOneWidget);
  });
}
```

## 7. Backend: B2, B3, B4 e B6

Trocas pequenas, independentes entre si. Depois de cada uma, rode `cd backend && npm run lint && npm run typecheck && npm test`. Os testes das quatro estão no fim desta seção.

### B2. Texto do motivo nos eventos

Com isso, o app pode usar `titulo` e `oQueFazer` do evento e dispensar o `motivos.dart`.

**Em** `backend/src/modules/events/events.service.ts`, **troque:**

```ts
import type { EventFilter, EventsRepository } from './events.types.js';

/** RF06: histórico das tentativas de acesso. */
export class EventsService {
  constructor(private readonly events: EventsRepository) {}

  listar(filtro: EventFilter) {
    return this.events.list(filtro);
  }
```

**por:**

```ts
import { MOTIVOS, type MotivoNegacao } from '../access/access.rules.js';
import type { AccessEventView, EventFilter, EventsRepository } from './events.types.js';

/** Acrescenta o texto do motivo, para o app não repetir a tabela (telas de histórico). */
function comTexto(evento: AccessEventView) {
  const texto = evento.motivo ? MOTIVOS[evento.motivo as MotivoNegacao] : undefined;
  return { ...evento, titulo: texto?.titulo ?? null, oQueFazer: texto?.oQueFazer ?? null };
}

/** RF06: histórico das tentativas de acesso. */
export class EventsService {
  constructor(private readonly events: EventsRepository) {}

  async listar(filtro: EventFilter) {
    const pagina = await this.events.list(filtro);
    return { ...pagina, itens: pagina.itens.map(comTexto) };
  }
```



**Em** `backend/src/modules/events/events.service.ts`, **troque:**

```ts
negadosRecentes: pagina.itens,
```

**por:**

```ts
negadosRecentes: pagina.itens.map(comTexto),
```


### B3. Quem foi desativado perde o acesso na hora

Faz uma consulta ao banco a cada chamada autenticada. Em troca, o perfil também passa a vir do banco, e não do token.

**Em** `backend/src/shared/http/auth.ts`, **troque:**

```ts
/** Exige "Authorization: Bearer <jwt>" de um usuário. */
export function autenticar(secret: string): RequestHandler {
  return (req, _res, next) => {
    const [tipo, token] = (req.headers.authorization ?? '').split(' ');
    if (tipo !== 'Bearer' || !token) throw unauthorized();
    try {
      const payload = jwtPayloadSchema.parse(jwt.verify(token, secret));
      req.auth = { userId: payload.sub, perfil: payload.perfil };
    } catch {
      throw unauthorized('Sessão inválida ou expirada. Entre de novo.');
    }
    next();
  };
}
```

**por:**

```ts
/**
 * Exige "Authorization: Bearer <jwt>" de um usuário que continua com o cadastro ativo.
 * Com aceitarInativo, quem foi desativado passa: a rota decide o que fazer com ele.
 */
export function autenticar(
  secret: string,
  users: Pick<UsersRepository, 'findById'>,
  { aceitarInativo = false } = {},
): RequestHandler {
  return async (req, _res, next) => {
    const [tipo, token] = (req.headers.authorization ?? '').split(' ');
    if (tipo !== 'Bearer' || !token) throw unauthorized();
    let payload: z.infer<typeof jwtPayloadSchema>;
    try {
      payload = jwtPayloadSchema.parse(jwt.verify(token, secret));
    } catch {
      throw unauthorized('Sessão inválida ou expirada. Entre de novo.');
    }
    // O token vale 8 h: sem isto, quem foi desativado continuaria usando a API até ele vencer.
    const user = await users.findById(payload.sub);
    if (!user) throw unauthorized('Sessão inválida ou expirada. Entre de novo.');
    if (!user.ativo && !aceitarInativo) throw cadastroDesativado();
    req.auth = { userId: payload.sub, perfil: user.perfil };
    next();
  };
}
```

`cadastroDesativado` fica em `backend/src/shared/errors.ts`: é um 401 com o código `CADASTRO_DESATIVADO`, para o app explicar o motivo. Em `backend/src/app.ts`, monte `/access` com `autenticar(c.config.jwtSecret, c.repos.users, { aceitarInativo: true })`: sem isso, o QR de quem foi desativado responde 401 e a tentativa não vira evento (RF17).



**Em** `backend/src/shared/http/auth.ts`, **troque:**

```ts
import { PERFIS, type Perfil } from '../../modules/users/users.types.js';
```

**por:**

```ts
import { PERFIS, type Perfil, type UsersRepository } from '../../modules/users/users.types.js';
```



**Em** `backend/src/app.ts`, **troque:**

```ts
const autenticado = autenticar(c.config.jwtSecret);
```

**por:**

```ts
const autenticado = autenticar(c.config.jwtSecret, c.repos.users);
```


### B4. "Ativa" é o que vale hoje

Depende da decisão D6. Corrige o filtro e também o número do Painel, que usa o mesmo filtro. Depois dela, o filtro local em `AutorizacoesController.listar` pode sair.

**Em** `backend/src/modules/authorizations/authorizations.service.ts`, **troque:**

```ts
    return lista.map((a) => this.apresentar(a));
  }

  /** RF08
```

**por:**

```ts
    return lista
      .map((a) => this.apresentar(a))
      // ATIVA quer dizer "vale hoje": o banco também traz as agendadas e as sem usos.
      .filter((a) => !filtro.situacao || a.situacao === filtro.situacao);
  }

  /** RF08
```


### B6. A pessoa bloqueia a própria tag

Só bloqueia: desbloquear continua com a portaria. Depois dela, passe `podeBloquear: true` no `MinhaTagView` do menu do morador.

**Em** `backend/src/modules/users/users.service.ts`, **troque:**

```ts
  private async tagDoUsuario(
```

**por:**

```ts
  /** O dono pode bloquear a própria tag; desbloquear continua com a portaria. */
  async bloquearMinhaTag(userId: string, tagId: string) {
    const tag = await this.users.findTagById(tagId);
    if (!tag || tag.userId !== userId) throw notFound('Tag');
    return this.users.updateTag(tagId, { ativa: false });
  }

  private async tagDoUsuario(
```



**Em** `backend/src/app.ts`, **troque:**

```ts
  return router;
}

/** Meia-noite
```

**por:**

```ts
  // "Minha tag NFC": só bloqueia. Desbloquear continua com a portaria.
  router.patch('/tags/:tagId', async (req, res) => {
    const { tagId } = parse(z.object({ tagId: id }), req.params);
    parse(z.object({ ativa: z.literal(false) }), req.body);
    res.json(await c.services.users.bloquearMinhaTag(authDe(req).userId, tagId));
  });

  return router;
}

/** Meia-noite
```



**Em** `backend/src/app.ts`, **troque:**

```ts
import helmet from 'helmet';
```

**por:**

```ts
import helmet from 'helmet';
import { z } from 'zod';
```



**Em** `backend/src/app.ts`, **troque:**

```ts
import { parse } from './shared/http/validate.js';
```

**por:**

```ts
import { id } from './shared/http/schemas.js';
import { parse } from './shared/http/validate.js';
```


### Testes das quatro

Cada teste só passa com a sua troca. Se aplicar só algumas, apague os testes das outras.

**Arquivo novo:** `backend/tests/api/telas-novas.test.ts`

```ts
import { describe, expect, it } from 'vitest';
import { montarCenario } from '../support/test-app.js';

describe('O que as telas novas pedem ao backend', () => {
  it('B2: histórico e painel trazem o texto do motivo', async () => {
    const c = await montarCenario();
    await c.api.post('/terminal/nfc').set(c.terminalHeaders).send({ uid: 'FFFFFFFF' });
    const auth = { Authorization: `Bearer ${await c.tokenDe('paula@passe.com')}` };

    const historico = await c.api.get('/access-events').set(auth);
    expect(historico.body.itens[0]).toMatchObject({
      motivo: 'TAG_DESCONHECIDA',
      titulo: 'Tag não cadastrada',
      oQueFazer: 'Peça para a portaria vincular sua tag.',
    });
    const painel = await c.api.get('/dashboard').set(auth);
    expect(painel.body.negadosRecentes[0].titulo).toBe('Tag não cadastrada');
  });

  it('B3: quem foi desativado perde o acesso na hora, mesmo com o token válido', async () => {
    const c = await montarCenario();
    const token = await c.tokenDe('paula@passe.com');
    const admin = await c.tokenDe('carlos@passe.com');

    const antes = await c.api.get('/users').set('Authorization', `Bearer ${token}`);
    expect(antes.status).toBe(200);

    await c.api.patch(`/users/${c.pessoas.portaria.id}`).set('Authorization', `Bearer ${admin}`).send({ ativo: false });

    const depois = await c.api.get('/users').set('Authorization', `Bearer ${token}`);
    expect(depois.status).toBe(401);
  });

  it('B4: o filtro ATIVA e o painel não contam agendadas nem sem usos', async () => {
    const c = await montarCenario();
    const admin = { Authorization: `Bearer ${await c.tokenDe('carlos@passe.com')}` };
    const base = { userId: c.pessoas.visitante.id, accessPointId: c.catraca.id, horaInicio: '08:00', horaFim: '18:00' };
    await c.api.post('/authorizations').set(admin).send({ ...base, dataInicio: '2026-12-01', dataFim: '2026-12-31', maxUsos: 1 });
    const esgotada = await c.api.post('/authorizations').set(admin).send({ ...base, dataInicio: '2026-10-01', dataFim: '2026-10-31', maxUsos: 1 });
    c.db.authorizations.find((a) => a.id === esgotada.body.id)!.usosRealizados = 1;

    const ativas = await c.api.get('/authorizations?situacao=ATIVA').set(admin);
    expect(ativas.body.map((a: { situacao: string }) => a.situacao)).toEqual(['ATIVA']);

    const painel = await c.api.get('/dashboard').set(admin);
    expect(painel.body.autorizacoesAtivas).toBe(1);
  });

  it('B6: a pessoa bloqueia a própria tag, mas não a de outra nem desbloqueia', async () => {
    const c = await montarCenario();
    const maria = { Authorization: `Bearer ${await c.tokenDe('maria@passe.com')}` };
    const ana = { Authorization: `Bearer ${await c.tokenDe('ana@passe.com')}` };

    const deOutra = await c.api.patch(`/me/tags/${c.tag.id}`).set(ana).send({ ativa: false });
    expect(deOutra.status).toBe(404);

    const desbloquear = await c.api.patch(`/me/tags/${c.tag.id}`).set(maria).send({ ativa: true });
    expect(desbloquear.status).toBe(400);

    const bloquear = await c.api.patch(`/me/tags/${c.tag.id}`).set(maria).send({ ativa: false });
    expect(bloquear.status).toBe(200);
    expect(bloquear.body.ativa).toBe(false);

    const nfc = await c.api.post('/terminal/nfc').set(c.terminalHeaders).send({ uid: '04A1B2C3' });
    expect(nfc.body.motivo).toBe('TAG_BLOQUEADA');
  });
});
```

## 8. Backend que ainda não tem código

Estas telas ficaram sem código porque dependem de uma decisão do grupo. Os contratos abaixo são **propostas**, para servir de ponto de partida. Nada disso foi implementado nem testado.

Se a decisão for tirar do menu, apague a `OpcaoMenu` no controller do menu e o teste correspondente.

### B8. Meus visitantes (decisão D4)

**Regra proposta:** o morador cria um visitante com autorização só para as catracas em que ele mesmo tem autorização vigente, com no máximo 7 dias e 1 uso por padrão.

| Rota | Corpo | Resposta |
|---|---|---|
| `GET /me/visitors` | | Lista de `{visitante, autorizacao}` |
| `POST /me/visitors` | `{nome, cpf, email, accessPointId, dataInicio, dataFim, horaInicio, horaFim}` | 201, ou 403 se a catraca não for dele |
| `DELETE /me/visitors/:id` | | 204: cancela a autorização |

Vai precisar de uma coluna nova na autorização, como `criadaPorId`, para saber de quem é cada visitante, e de definir como o visitante recebe a senha.

### B10. Comunicados (decisão D3)

| Rota | Perfil | Corpo |
|---|---|---|
| `GET /announcements` | Todos | |
| `POST /announcements` | Admin | `{titulo, texto}` |
| `PATCH /announcements/:id` | Admin | `{titulo?, texto?}` |
| `DELETE /announcements/:id` | Admin | |

Precisa do modelo `Announcement` (`id`, `titulo`, `texto`, `createdAt`) e de uma migration. Se a tela for feita, dá para partir da `VisitantesView`, que é a lista mais simples.

### B10. Configurações (decisão D3)

Hoje o horário e os usos ficam em cada autorização, e o raio fica em cada catraca. Não há nada global para configurar, então a recomendação é tirar a opção do menu.

### B5. Editar e apagar locais

Faltam `PATCH` e `DELETE` para `/locations/buildings/:id`, `/gates/:id` e `/doors/:id`, e `DELETE` para `/locations/access-points/:id` e `/terminals/:id`. **Cuidado:** o schema apaga em cascata (`onDelete: Cascade`), então apagar um edifício apaga catracas, autorizações e terminais. Decida se isso pode acontecer antes de oferecer na tela.

### T1–T3. Terminal no Flutter (decisão D5)

O backend está pronto: `GET /terminal/qr-token`, `POST /terminal/heartbeat`, `GET /terminal/decisions` e `POST /terminal/nfc`. Falta o pacote `qr_flutter` e uma tela para guardar o Id e a chave do terminal. A página `backend/public/simulador/app.js` já faz esse fluxo em JavaScript e serve de modelo.
