import 'package:flutter_test/flutter_test.dart';
import 'package:public/models/autorizacao.dart';
import 'package:public/views/user/autorizacao_textos.dart';

import '../../support/api_falsa.dart';

Autorizacao _autorizacao({
  String situacao = 'ATIVA',
  String dataInicio = '2026-10-01',
  String dataFim = '2026-10-31',
  String horaInicio = '08:00',
  String horaFim = '18:00',
  int maxUsos = 10,
  int usosRestantes = 3,
  String? canceladaEm,
}) => Autorizacao.fromJson(
  autorizacaoJson(
    situacao: situacao,
    dataInicio: dataInicio,
    dataFim: dataFim,
    horaInicio: horaInicio,
    horaFim: horaFim,
    maxUsos: maxUsos,
    usosRestantes: usosRestantes,
    canceladaEm: canceladaEm,
  ),
);

/// 14/10/2026, às 9:41, como no design.
final _hoje = DateTime(2026, 10, 14, 9, 41);

void main() {
  test('Horário e período como no design', () {
    final autorizacao = _autorizacao();

    expect(autorizacao.horario, 'Das 08:00 às 18:00');
    expect(autorizacao.periodo, '01/10/2026 a 31/10/2026');
    expect(autorizacao.periodoCurto(_hoje), '01/10 a 31/10/2026');
  });

  test('Período curto mostra os dois anos quando passa da virada', () {
    final autorizacao = _autorizacao(
      dataInicio: '2026-12-20',
      dataFim: '2027-01-10',
    );

    expect(autorizacao.periodoCurto(_hoje), '20/12/2026 a 10/01/2027');
  });

  test('Um dia só: "Somente hoje" ou a data', () {
    final hoje = _autorizacao(dataInicio: '2026-10-14', dataFim: '2026-10-14');
    final outroDia = _autorizacao(
      dataInicio: '2026-10-20',
      dataFim: '2026-10-20',
    );

    expect(hoje.periodoCurto(_hoje), 'Somente hoje, 14/10');
    expect(outroDia.periodoCurto(_hoje), 'Somente em 20/10/2026');
  });

  test('Usos no plural e no singular', () {
    expect(_autorizacao().usos, '3 de 10 usos restantes');
    expect(_autorizacao().restantes, '3 de 10 restantes');
    expect(
      _autorizacao(maxUsos: 1, usosRestantes: 1).usos,
      '1 de 1 uso restante',
    );
    expect(
      _autorizacao(maxUsos: 1, usosRestantes: 0).restantes,
      '0 de 1 restante',
    );
  });

  group('Quando pode entrar (U8)', () {
    final ativa = _autorizacao();

    test('Dentro do horário, até quando', () {
      expect(ativa.quandoEntrar(_hoje), 'Você pode entrar hoje até 18:00.');
    });

    test('Antes do horário, a partir de quando', () {
      expect(
        ativa.quandoEntrar(DateTime(2026, 10, 14, 7)),
        'Hoje você pode entrar a partir das 08:00.',
      );
    });

    test('Depois do horário, amanhã', () {
      expect(
        ativa.quandoEntrar(DateTime(2026, 10, 14, 19, 42)),
        'Amanhã você pode entrar a partir das 08:00.',
      );
    });

    test('Depois do horário no último dia, acabou', () {
      expect(
        ativa.quandoEntrar(DateTime(2026, 10, 31, 19)),
        'O horário de hoje já acabou.',
      );
    });

    test('Janela que passa da meia-noite', () {
      final noite = _autorizacao(horaInicio: '22:00', horaFim: '06:00');

      expect(
        noite.quandoEntrar(DateTime(2026, 10, 14, 23)),
        'Você pode entrar até 06:00 de amanhã.',
      );
      expect(
        noite.quandoEntrar(DateTime(2026, 10, 14, 2)),
        'Você pode entrar hoje até 06:00.',
      );
      expect(
        noite.quandoEntrar(DateTime(2026, 10, 14, 12)),
        'Hoje você pode entrar a partir das 22:00.',
      );
    });

    test('Agendada, esgotada, expirada e cancelada', () {
      expect(
        _autorizacao(
          situacao: 'AGENDADA',
          dataInicio: '2026-11-01',
        ).quandoEntrar(_hoje),
        'Você poderá entrar a partir de 01/11/2026.',
      );
      expect(
        _autorizacao(
          situacao: 'ESGOTADA',
          usosRestantes: 0,
        ).quandoEntrar(_hoje),
        'Você já usou todos os usos. Peça mais à portaria.',
      );
      expect(
        _autorizacao(
          situacao: 'EXPIRADA',
          dataFim: '2026-10-10',
        ).quandoEntrar(_hoje),
        'Terminou em 10/10/2026.',
      );
      expect(
        _autorizacao(situacao: 'CANCELADA').quandoEntrar(_hoje),
        'A portaria cancelou esta autorização.',
      );
      expect(
        _autorizacao(
          situacao: 'CANCELADA',
          canceladaEm: '2026-10-12T15:00:00.000Z',
        ).quandoEntrar(_hoje),
        'A portaria cancelou esta autorização em 12/10/2026.',
      );
    });
  });
}
