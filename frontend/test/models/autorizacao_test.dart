import 'package:flutter_test/flutter_test.dart';
import 'package:public/models/autorizacao.dart';

import '../support/api_falsa.dart';

void main() {
  test('Lê a autorização como a API devolve', () {
    final autorizacao = Autorizacao.fromJson(autorizacaoJson());

    expect(autorizacao.id, 'autorizacao-1');
    expect(autorizacao.catraca.nome, 'Catraca 1');
    expect(autorizacao.catraca.edificio, 'FATEC Jacareí');
    expect(autorizacao.catraca.portaria, 'Portaria Principal');
    expect(autorizacao.catraca.porta, 'Porta A');
    expect(autorizacao.dataInicio, DateTime(2026, 10, 1));
    expect(autorizacao.dataFim, DateTime(2026, 10, 31));
    expect(autorizacao.horaInicio, '08:00');
    expect(autorizacao.horaFim, '18:00');
    expect(autorizacao.maxUsos, 10);
    expect(autorizacao.usosRestantes, 3);
    expect(autorizacao.situacao, SituacaoAutorizacao.ativa);
    expect(autorizacao.canceladaEm, isNull);
  });

  test('Cancelada traz quando foi cancelada', () {
    final autorizacao = Autorizacao.fromJson(
      autorizacaoJson(
        situacao: 'CANCELADA',
        canceladaEm: '2026-10-20T13:00:00.000Z',
      ),
    );

    expect(autorizacao.situacao, SituacaoAutorizacao.cancelada);
    expect(autorizacao.canceladaEm, DateTime.utc(2026, 10, 20, 13));
  });

  test('Lê as 5 situações da API e recusa outra', () {
    expect(
      [for (final s in SituacaoAutorizacao.values) s.api],
      ['ATIVA', 'AGENDADA', 'ESGOTADA', 'EXPIRADA', 'CANCELADA'],
    );
    expect(
      () => SituacaoAutorizacao.daApi('PAUSADA'),
      throwsA(isA<FormatException>()),
    );
  });

  test('Só ativa e agendada ficam em "Ativas"', () {
    expect(
      [
        for (final s in SituacaoAutorizacao.values)
          if (s.vigente) s,
      ],
      [SituacaoAutorizacao.ativa, SituacaoAutorizacao.agendada],
    );
  });

  test('Último uso só quando vale hoje e sobra um', () {
    Autorizacao com(String situacao, int restantes) => Autorizacao.fromJson(
      autorizacaoJson(situacao: situacao, maxUsos: 1, usosRestantes: restantes),
    );

    expect(com('ATIVA', 1).ultimoUso, isTrue);
    expect(com('AGENDADA', 1).ultimoUso, isFalse);
    expect(com('ESGOTADA', 0).ultimoUso, isFalse);
  });

  test(
    'Confere o horário como o backend, inclusive passando da meia-noite',
    () {
      final dia = Autorizacao.fromJson(autorizacaoJson());
      expect(dia.dentroDoHorario(DateTime(2026, 10, 14, 7, 59)), isFalse);
      expect(dia.dentroDoHorario(DateTime(2026, 10, 14, 8)), isTrue);
      expect(dia.dentroDoHorario(DateTime(2026, 10, 14, 17, 59)), isTrue);
      expect(dia.dentroDoHorario(DateTime(2026, 10, 14, 18)), isFalse);

      final noite = Autorizacao.fromJson(
        autorizacaoJson(horaInicio: '22:00', horaFim: '06:00'),
      );
      expect(noite.dentroDoHorario(DateTime(2026, 10, 14, 23)), isTrue);
      expect(noite.dentroDoHorario(DateTime(2026, 10, 14, 5, 59)), isTrue);
      expect(noite.dentroDoHorario(DateTime(2026, 10, 14, 6)), isFalse);
      expect(noite.dentroDoHorario(DateTime(2026, 10, 14, 12)), isFalse);
    },
  );

  test('Onde fica a catraca: portaria › porta › catraca', () {
    final autorizacao = Autorizacao.fromJson(autorizacaoJson());

    expect(
      autorizacao.catraca.onde,
      'Portaria Principal › Porta A › Catraca 1',
    );
  });
}
