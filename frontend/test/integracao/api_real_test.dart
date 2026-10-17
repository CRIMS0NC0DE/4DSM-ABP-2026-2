// Testa a integração do app contra a API de verdade (backend com o seed).
//
//   cd backend && npm run db:seed && npm run dev
//   cd frontend && flutter test test/integracao --dart-define=API_REAL=http://localhost:3000
//
// Sem o --dart-define os testes são pulados; o CI roda só os da API falsa.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:public/models/usuario.dart';
import 'package:public/services/api_client.dart';
import 'package:public/services/auth_service.dart';
import 'package:public/services/sessao_service.dart';

const _apiReal = String.fromEnvironment('API_REAL');

const _senha = 'passe123';

void main() {
  late SessaoService sessao;
  late ApiClient api;
  late AuthService auth;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    sessao = SessaoService();
    api = ApiClient(sessao: sessao, baseUrl: _apiReal);
    auth = AuthService(api: api, sessao: sessao);
  });

  group(
    'API real',
    () {
      test('Cada conta do seed entra com o perfil certo', () async {
        const contas = {
          'admin@passe.com': Perfil.admin,
          'portaria@passe.com': Perfil.controladorAcesso,
          'morador@passe.com': Perfil.morador,
          'visitante@passe.com': Perfil.visitante,
        };
        for (final MapEntry(key: email, value: perfil) in contas.entries) {
          final usuario = await auth.entrar(email, _senha);
          expect(usuario.perfil, perfil, reason: email);
          expect(usuario.id, isNotEmpty);
        }
      });

      test('Entra pelo CPF com pontuação', () async {
        final usuario = await auth.entrar('333.333.333-33', _senha);
        expect(usuario.email, 'morador@passe.com');
      });

      test('Senha errada devolve 401 com a mensagem da API', () async {
        await expectLater(
          auth.entrar('admin@passe.com', 'senha-errada'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.status, 'status', 401)
                .having(
                  (e) => e.mensagem,
                  'mensagem',
                  'E-mail, CPF ou senha não conferem.',
                ),
          ),
        );
        expect(sessao.token, isNull);
      });

      test('O token do login abre as rotas da equipe', () async {
        await auth.entrar('admin@passe.com', _senha);

        final painel = await api.get('/dashboard') as Map<String, dynamic>;
        expect(painel, contains('acessosHoje'));
        expect(painel, contains('autorizacoesAtivas'));
      });

      test('Morador não entra nas rotas da equipe (403)', () async {
        await auth.entrar('morador@passe.com', _senha);

        await expectLater(
          api.get('/users'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.status, 'status', 403)
                .having((e) => e.codigo, 'codigo', 'SEM_PERMISSAO'),
          ),
        );
        // Mas vê as próprias autorizações (RF08).
        expect(await api.get('/me/authorizations'), isA<List<dynamic>>());
      });

      test('Erro de validação traz os campos inválidos', () async {
        await auth.entrar('admin@passe.com', _senha);

        await expectLater(
          api.post('/authorizations', {'horaInicio': '8h'}),
          throwsA(
            isA<ApiException>()
                .having((e) => e.status, 'status', 400)
                .having((e) => e.campos, 'campos', contains('horaInicio')),
          ),
        );
      });

      test('A sessão com o JWT de verdade volta ao abrir o app', () async {
        await auth.entrar('portaria@passe.com', _senha);

        final restaurado = await SessaoService().restaurar();
        expect(restaurado?.perfil, Perfil.controladorAcesso);
      });

      test('Sem token, a API pede login (401)', () async {
        await expectLater(
          api.get('/auth/me'),
          throwsA(
            isA<ApiException>().having((e) => e.naoAutenticado, '401', true),
          ),
        );
      });
    },
    skip: _apiReal.isEmpty
        ? 'Rode com --dart-define=API_REAL=http://localhost:3000'
        : false,
  );
}
