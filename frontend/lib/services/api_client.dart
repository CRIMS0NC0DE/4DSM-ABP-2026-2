import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';
import 'sessao_service.dart';

/// Erro de uma chamada à API, com a mensagem pronta para mostrar na tela.
/// A API responde os erros como {"erro": {"codigo", "mensagem", "detalhes"}}.
class ApiException implements Exception {
  const ApiException(
    this.mensagem, {
    this.status,
    this.codigo,
    this.campos = const {},
  });

  /// Erro de rede: a requisição não chegou na API.
  const ApiException.semConexao()
    : this(
        'Não foi possível falar com o servidor. '
        'Confira a internet e tente de novo.',
      );

  final String mensagem;

  /// Status HTTP. Null quando a requisição nem chegou na API.
  final int? status;

  /// Ex.: NAO_AUTENTICADO, SEM_PERMISSAO, DADOS_INVALIDOS, CONFLITO.
  final String? codigo;

  /// Nos erros 400, as mensagens de cada campo inválido.
  final Map<String, List<String>> campos;

  bool get semConexao => status == null;

  /// Senha errada no login, ou sessão vencida nas outras rotas.
  bool get naoAutenticado => status == 401;

  @override
  String toString() => 'ApiException($status, $codigo): $mensagem';
}

/// Faz as chamadas HTTP para a API Express.
/// Manda o token da sessão em "Authorization: Bearer" e transforma os erros
/// em [ApiException].
class ApiClient {
  ApiClient({
    http.Client? cliente,
    SessaoService? sessao,
    this.baseUrl = ApiConstants.baseUrl,
    this.timeout = ApiConstants.timeout,
  }) : _cliente = cliente ?? http.Client(),
       _sessao = sessao ?? SessaoService.instancia;

  /// O mesmo para o app inteiro.
  static final instancia = ApiClient();

  final http.Client _cliente;
  final SessaoService _sessao;
  final String baseUrl;
  final Duration timeout;

  Future<dynamic> get(String caminho, {Map<String, String>? query}) =>
      _enviar('GET', caminho, query: query);

  Future<dynamic> post(String caminho, [Object? corpo]) =>
      _enviar('POST', caminho, corpo: corpo);

  Future<dynamic> patch(String caminho, [Object? corpo]) =>
      _enviar('PATCH', caminho, corpo: corpo);

  Future<dynamic> delete(String caminho) => _enviar('DELETE', caminho);

  Future<dynamic> _enviar(
    String metodo,
    String caminho, {
    Map<String, String>? query,
    Object? corpo,
  }) async {
    final request = http.Request(
      metodo,
      Uri.parse('$baseUrl$caminho').replace(queryParameters: query),
    );
    request.headers['Accept'] = 'application/json';
    final token = _sessao.token;
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (corpo != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(corpo);
    }

    final http.Response resposta;
    try {
      resposta = await http.Response.fromStream(
        await _cliente.send(request).timeout(timeout),
      ).timeout(timeout);
    } on TimeoutException {
      throw const ApiException.semConexao();
    } on http.ClientException {
      throw const ApiException.semConexao();
    }

    final json = _decodificar(resposta);
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) return json;
    throw _erro(resposta.statusCode, json);
  }

  static dynamic _decodificar(http.Response resposta) {
    if (resposta.body.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(resposta.bodyBytes));
    } on FormatException {
      return null;
    }
  }

  static ApiException _erro(int status, dynamic json) {
    final erro = json is Map ? json['erro'] : null;
    if (erro is! Map) {
      return ApiException(
        'O servidor respondeu com erro ($status). Tente de novo.',
        status: status,
      );
    }
    final detalhes = erro['detalhes'];
    return ApiException(
      erro['mensagem'] as String? ?? 'Erro inesperado. Tente de novo.',
      status: status,
      codigo: erro['codigo'] as String?,
      campos: {
        if (detalhes is Map)
          for (final MapEntry(:key, :value) in detalhes.entries)
            if (value is List) '$key': [for (final m in value) '$m'],
      },
    );
  }
}
