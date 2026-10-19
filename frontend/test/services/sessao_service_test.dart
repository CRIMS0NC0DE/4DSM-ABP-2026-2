import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:public/models/usuario.dart';
import 'package:public/services/sessao_service.dart';

import '../support/api_falsa.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('Ao abrir o app de novo, volta a sessão guardada', () async {
    await SessaoService().iniciar(tokenFalso(), contasDemo[2]);

    final usuario = await SessaoService().restaurar();

    expect(usuario?.email, 'morador@passe.com');
    expect(usuario?.perfil, Perfil.morador);
  });

  test('Token vencido pede login de novo e apaga a sessão', () async {
    final vence = DateTime(2026, 10, 17, 12);
    await SessaoService().iniciar(tokenFalso(vence: vence), contasDemo.first);

    final depois = SessaoService(
      agora: () => vence.add(const Duration(minutes: 1)),
    );
    expect(await depois.restaurar(), isNull);
    expect(depois.token, isNull);

    // Já foi apagada: nem antes do vencimento ela volta.
    expect(await SessaoService(agora: () => vence).restaurar(), isNull);
  });

  test('Sem nada guardado, não tem sessão', () async {
    expect(await SessaoService().restaurar(), isNull);
  });

  test('Token que não é JWT é descartado', () async {
    await SessaoService().iniciar('nao-e-jwt', contasDemo.first);
    expect(await SessaoService().restaurar(), isNull);
  });

  test('Encerrar apaga do armazenamento', () async {
    final sessao = SessaoService();
    await sessao.iniciar(tokenFalso(), contasDemo.first);

    await sessao.encerrar();

    expect(sessao.token, isNull);
    expect(await SessaoService().restaurar(), isNull);
  });
}
