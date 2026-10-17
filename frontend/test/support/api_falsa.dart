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

/// Responde como o backend: POST /auth/login com e-mail ou CPF.
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
