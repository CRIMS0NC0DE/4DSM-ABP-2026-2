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
