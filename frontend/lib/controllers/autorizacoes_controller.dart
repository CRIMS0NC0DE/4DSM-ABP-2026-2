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
    return [
      for (final json in lista)
        AutorizacaoEquipe.fromJson(json as Map<String, dynamic>),
    ];
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
