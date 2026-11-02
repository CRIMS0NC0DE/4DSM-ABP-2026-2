import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:public/models/usuario.dart';
import 'package:public/services/api_client.dart';
import 'package:public/services/auth_service.dart';
import 'package:public/services/sessao_service.dart';

import '../support/api_falsa.dart';

void main() {
  late List<http.Request> chamadas;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await SessaoService.instancia.encerrar();
    chamadas = [];
  });

  test('Entra pela API e guarda o token na sessão', () async {
    final auth = authFalso(cliente: apiFalsa(chamadas: chamadas));

    final usuario = await auth.entrar('admin@passe.com', senhaDemo);

    expect(usuario.perfil, Perfil.admin);
    expect(usuario.nome, 'Carlos Lima');
    expect(auth.usuario?.id, usuario.id);
    expect(SessaoService.instancia.token, isNotNull);

    final chamada = chamadas.single;
    expect(chamada.method, 'POST');
    expect(chamada.url.path, '/auth/login');
    expect(jsonDecode(chamada.body), {
      'login': 'admin@passe.com',
      'senha': senhaDemo,
    });
  });

  test('Também entra pelo CPF, com ou sem pontuação', () async {
    final auth = authFalso();
    expect(
      (await auth.entrar('222.222.222-22', senhaDemo)).perfil,
      Perfil.controladorAcesso,
    );
    expect(
      (await auth.entrar('33333333333', senhaDemo)).perfil,
      Perfil.morador,
    );
  });

  test('Lê os 4 perfis da API', () async {
    final auth = authFalso();
    for (final conta in contasDemo) {
      expect((await auth.entrar(conta.email, senhaDemo)).perfil, conta.perfil);
    }
  });

  test('Senha errada lança a mensagem da API e não abre sessão', () async {
    final auth = authFalso();

    await expectLater(
      auth.entrar('admin@passe.com', 'errada'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.status, 'status', 401)
            .having((e) => e.codigo, 'codigo', 'NAO_AUTENTICADO')
            .having(
              (e) => e.mensagem,
              'mensagem',
              'E-mail, CPF ou senha não conferem.',
            ),
      ),
    );
    expect(SessaoService.instancia.token, isNull);
  });

  test('Sem internet avisa para conferir a conexão', () async {
    final auth = authFalso(cliente: semInternet());

    await expectLater(
      auth.entrar('admin@passe.com', senhaDemo),
      throwsA(
        isA<ApiException>().having((e) => e.semConexao, 'semConexao', true),
      ),
    );
  });

  test('Sair esquece o token e o usuário', () async {
    final auth = authFalso();
    await auth.entrar('admin@passe.com', senhaDemo);

    await auth.sair();

    expect(SessaoService.instancia.token, isNull);
    expect(auth.usuario, isNull);
  });

  group('Ao abrir o app', () {
    final morador = contasDemo[2];
    AuthService authCom(Future<http.Response> Function() resposta) =>
        authFalso(
          cliente: MockClient((request) {
            chamadas.add(request);
            return resposta();
          }),
        );

    test('Sem sessão guardada, nem chama a API', () async {
      final sessao = await authCom(
        () async => respostaJson({}, 200),
      ).restaurar();

      expect(sessao.usuario, isNull);
      expect(sessao.aviso, isNull);
      expect(chamadas, isEmpty);
    });

    test('Atualiza e guarda o perfil que mudou na API', () async {
      await SessaoService.instancia.iniciar(tokenFalso(), morador);
      final auth = authCom(
        () async =>
            respostaJson({...morador.toJson(), 'perfil': 'VISITANTE'}, 200),
      );

      final sessao = await auth.restaurar();

      expect(chamadas.single.url.path, '/auth/me');
      expect(sessao.usuario?.perfil, Perfil.visitante);
      expect((await SessaoService().restaurar())?.perfil, Perfil.visitante);
    });

    test('Cadastro desativado encerra a sessão e explica o motivo', () async {
      await SessaoService.instancia.iniciar(tokenFalso(), morador);
      final auth = authCom(
        () async =>
            erroDaApi(401, 'CADASTRO_DESATIVADO', 'Seu cadastro está desativado.'),
      );

      final sessao = await auth.restaurar();

      expect(sessao.usuario, isNull);
      expect(sessao.aviso, 'Seu cadastro está desativado.');
      expect(SessaoService.instancia.token, isNull);
      expect(await SessaoService().restaurar(), isNull);
    });

    test('Sessão inválida volta ao login sem aviso', () async {
      await SessaoService.instancia.iniciar(tokenFalso(), morador);
      final auth = authCom(
        () async => erroDaApi(401, 'NAO_AUTENTICADO', 'Sessão inválida.'),
      );

      final sessao = await auth.restaurar();

      expect(sessao.usuario, isNull);
      expect(sessao.aviso, isNull);
      expect(SessaoService.instancia.token, isNull);
    });

    test('Sem internet, segue com a cópia local', () async {
      await SessaoService.instancia.iniciar(tokenFalso(), morador);

      final sessao = await authFalso(cliente: semInternet()).restaurar();

      expect(sessao.usuario?.perfil, Perfil.morador);
      expect(SessaoService.instancia.token, isNotNull);
    });

    test('Erro do servidor não derruba a sessão', () async {
      await SessaoService.instancia.iniciar(tokenFalso(), morador);
      final auth = authCom(
        () async => erroDaApi(500, 'ERRO_INTERNO', 'Erro interno.'),
      );

      expect((await auth.restaurar()).usuario?.perfil, Perfil.morador);
      expect(SessaoService.instancia.token, isNotNull);
    });

    test('API que demora não segura a abertura do app', () async {
      await SessaoService.instancia.iniciar(tokenFalso(), morador);
      final auth = authCom(() => Completer<http.Response>().future);

      final sessao = await auth.restaurar(
        espera: const Duration(milliseconds: 10),
      );

      expect(sessao.usuario?.perfil, Perfil.morador);
    });
  });

  test('Cadastro pelo app ainda não existe na API', () async {
    await expectLater(
      authFalso().registrar(
        nome: 'João Pereira',
        cpf: '765.430.123-00',
        email: 'joao@email.com',
        senha: 'segredo123',
      ),
      throwsA(
        isA<ApiException>().having(
          (e) => e.mensagem,
          'mensagem',
          contains('Peça seu cadastro na portaria'),
        ),
      ),
    );
  });
}
