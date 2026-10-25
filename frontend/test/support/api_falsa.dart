import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:public/models/usuario.dart';
import 'package:public/services/api_client.dart';
import 'package:public/services/auth_service.dart';

/// Mesmas contas do seed do backend (backend/prisma/seed.ts).
const senhaDemo = 'passe123';

const contasDemo = [
  Usuario(
    id: '00000000-0000-4000-8000-0000000000a1',
    nome: 'Carlos Lima',
    email: 'admin@passe.com',
    cpf: '11111111111',
    perfil: Perfil.admin,
  ),
  Usuario(
    id: '00000000-0000-4000-8000-0000000000a2',
    nome: 'Paula Rocha',
    email: 'portaria@passe.com',
    cpf: '22222222222',
    perfil: Perfil.controladorAcesso,
  ),
  Usuario(
    id: '00000000-0000-4000-8000-0000000000a3',
    nome: 'Maria Souza',
    email: 'morador@passe.com',
    cpf: '33333333333',
    perfil: Perfil.morador,
  ),
  Usuario(
    id: '00000000-0000-4000-8000-0000000000a4',
    nome: 'Ana Lima',
    email: 'visitante@passe.com',
    cpf: '44444444444',
    perfil: Perfil.visitante,
  ),
];

/// JWT com o mesmo formato do backend (o app só lê o "exp").
String tokenFalso({DateTime? vence}) {
  String parte(Map<String, Object> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  final exp = (vence ?? DateTime.now().add(const Duration(hours: 8)));
  return [
    parte({'alg': 'HS256', 'typ': 'JWT'}),
    parte({
      'perfil': 'ADMIN',
      'sub': contasDemo.first.id,
      'exp': exp.millisecondsSinceEpoch ~/ 1000,
    }),
    'assinatura',
  ].join('.');
}

http.Response respostaJson(Object? corpo, int status) => http.Response.bytes(
  utf8.encode(jsonEncode(corpo)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

http.Response erroDaApi(int status, String codigo, String mensagem) =>
    respostaJson({
      'erro': {'codigo': codigo, 'mensagem': mensagem},
    }, status);

/// Mesmos textos de MOTIVOS em backend/src/modules/access/access.rules.ts:
/// os 13 motivos que o POST /access/qr pode devolver, com (titulo, oQueFazer).
const motivosDoQr = {
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

/// Catraca do seed do backend.
const catracaDemo = {
  'id': '00000000-0000-4000-8000-000000000004',
  'nome': 'Catraca 1',
  'caminho': 'FATEC Jacareí › Portaria Principal › Porta A',
};

/// QR que a API falsa responde com 401, como se a sessão tivesse vencido.
const qrSessaoVencida = 'P1.SESSAO_VENCIDA';

/// Resposta do POST /access/qr. O token escolhe o resultado: "P1.LIBERADO"
/// libera, "P1.MOTIVO" (ex.: "P1.SEM_USOS") nega com esse motivo e qualquer
/// outro texto é QR_INVALIDO, como no backend.
http.Response respostaDoQr(String token) {
  if (token.length < 10) {
    return erroDaApi(400, 'DADOS_INVALIDOS', 'Dados inválidos.');
  }
  if (token == qrSessaoVencida) {
    return erroDaApi(
      401,
      'NAO_AUTENTICADO',
      'Sessão inválida ou expirada. Entre de novo.',
    );
  }
  const base = {'eventoId': 'evento-1', 'em': '2026-10-25T17:30:00.000Z'};
  final caso = token.substring(3);
  if (caso == 'LIBERADO') {
    return respostaJson({
      ...base,
      'liberado': true,
      'titulo': 'Acesso liberado',
      'catraca': catracaDemo,
      'usosRestantes': 999,
      'distanciaMetros': 12,
    }, 200);
  }
  final motivo = motivosDoQr.containsKey(caso) ? caso : 'QR_INVALIDO';
  final (titulo, oQueFazer) = motivosDoQr[motivo]!;
  // Sem QR válido ou sem terminal, a API não sabe qual é a catraca.
  const semCatraca = {'QR_INVALIDO', 'QR_EXPIRADO', 'TERMINAL_DESCONHECIDO'};
  return respostaJson({
    ...base,
    'liberado': false,
    'motivo': motivo,
    'titulo': titulo,
    'oQueFazer': oQueFazer,
    if (!semCatraca.contains(motivo)) 'catraca': catracaDemo,
    if (motivo == 'LONGE_DO_TERMINAL') 'distanciaMetros': 1043,
  }, 200);
}

/// Responde como o backend: POST /auth/login com e-mail ou CPF e
/// POST /access/qr (ver [respostaDoQr]).
/// Guarda em [chamadas] cada requisição feita.
MockClient apiFalsa({List<http.Request>? chamadas}) {
  return MockClient((request) async {
    chamadas?.add(request);
    if (request.method == 'POST' && request.url.path == '/auth/login') {
      final corpo = jsonDecode(request.body) as Map<String, dynamic>;
      final login = (corpo['login'] as String).trim().toLowerCase();
      final conta = contasDemo
          .where(
            (c) => login.contains('@')
                ? c.email == login
                : c.cpf == login.replaceAll(RegExp(r'\D'), ''),
          )
          .firstOrNull;
      if (conta == null || corpo['senha'] != senhaDemo) {
        return erroDaApi(
          401,
          'NAO_AUTENTICADO',
          'E-mail, CPF ou senha não conferem.',
        );
      }
      return respostaJson({
        'token': tokenFalso(),
        'usuario': {
          ...conta.toJson(),
          'ativo': true,
          'createdAt': '2026-10-16T12:00:00.000Z',
          'updatedAt': '2026-10-16T12:00:00.000Z',
        },
      }, 200);
    }
    if (request.method == 'POST' && request.url.path == '/access/qr') {
      final corpo = jsonDecode(request.body) as Map<String, dynamic>;
      return respostaDoQr(corpo['token'] as String);
    }
    return erroDaApi(
      404,
      'ROTA_NAO_ENCONTRADA',
      '${request.method} ${request.url.path} não existe.',
    );
  });
}

/// Cliente que nunca chega na API (sem internet).
MockClient semInternet() =>
    MockClient((request) async => throw http.ClientException('offline'));

/// AuthService ligado à [apiFalsa]. Usa a sessão do app
/// (SessaoService.instancia), como o login de verdade.
AuthService authFalso({http.Client? cliente}) =>
    AuthService(api: ApiClient(cliente: cliente ?? apiFalsa()));
