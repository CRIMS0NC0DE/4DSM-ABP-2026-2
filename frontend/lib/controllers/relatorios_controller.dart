import '../core/constants/formato.dart';
import '../models/local.dart';
import '../models/relatorio_acessos.dart';
import '../services/api_client.dart';

/// Período do relatório, contando hoje.
enum PeriodoRelatorio {
  hoje('Hoje', 1),
  seteDias('7 dias', 7),
  trintaDias('30 dias', 30);

  const PeriodoRelatorio(this.rotulo, this.dias);

  final String rotulo;
  final int dias;
}

/// Relatórios da equipe (admin e portaria): GET /reports/access soma todos os
/// acessos do período na API, com o filtro de catraca opcional.
class RelatoriosController {
  RelatoriosController({ApiClient? api, DateTime Function()? relogio})
    : _api = api ?? ApiClient.instancia,
      _relogio = relogio ?? DateTime.now;

  final ApiClient _api;
  final DateTime Function() _relogio;

  DateTime agora() => _relogio();

  /// [catracaId] null = todas as catracas (não manda o accessPointId).
  /// As datas vão sem hora: a API conta o dia inteiro no fuso do prédio.
  Future<RelatorioAcessos> carregar({
    required PeriodoRelatorio periodo,
    String? catracaId,
  }) async {
    final hoje = agora();
    final inicio = DateTime(hoje.year, hoje.month, hoje.day - periodo.dias + 1);
    final resposta = await _api.get(
      '/reports/access',
      query: {
        'de': Formato.dataApi(inicio),
        'ate': Formato.dataApi(hoje),
        'accessPointId': ?catracaId,
      },
    );
    // Com status, para a tela não confundir com falta de internet.
    if (resposta is! Map<String, dynamic>) {
      throw const ApiException(
        'O servidor respondeu o relatório num formato inesperado. '
        'Tente de novo.',
        status: 500,
      );
    }
    return RelatorioAcessos.fromJson(resposta);
  }

  /// Catracas para o filtro, de GET /locations.
  Future<List<CatracaNoLocal>> catracas() async {
    final lista = await _api.get('/locations') as List<dynamic>;
    return catracasDe([
      for (final json in lista) Edificio.fromJson(json as Map<String, dynamic>),
    ]);
  }
}
