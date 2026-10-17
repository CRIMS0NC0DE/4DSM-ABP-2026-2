import { describe, expect, it } from 'vitest';
import {
  avaliarAutorizacao,
  dentroDoHorario,
  escolherAutorizacao,
  situacaoDe,
} from '../../src/modules/access/access.rules.js';
import type { Authorization } from '../../src/modules/authorizations/authorizations.types.js';
import type { LocalDateTime } from '../../src/shared/clock.js';

const base: Authorization = {
  id: 'a1',
  userId: 'u1',
  accessPointId: 'c1',
  dataInicio: '2026-10-01',
  dataFim: '2026-10-31',
  horaInicio: '08:00',
  horaFim: '18:00',
  maxUsos: 10,
  usosRealizados: 3,
  status: 'ATIVA',
  canceladaEm: null,
  createdAt: new Date(),
};

const em = (date: string, time: string): LocalDateTime => {
  const [h, m] = time.split(':').map(Number);
  return { date, time, minutes: h! * 60 + m! };
};

describe('avaliarAutorizacao', () => {
  it('libera dentro do período, do horário e com usos restantes', () => {
    expect(avaliarAutorizacao(base, em('2026-10-14', '09:12'))).toBeNull();
  });

  it.each([
    ['cancelada', { status: 'CANCELADA' as const }, em('2026-10-14', '09:00'), 'AUTORIZACAO_CANCELADA'],
    ['expirada', {}, em('2026-11-01', '09:00'), 'AUTORIZACAO_EXPIRADA'],
    ['ainda não começou', {}, em('2026-09-30', '09:00'), 'AUTORIZACAO_NAO_INICIADA'],
    ['antes do horário', {}, em('2026-10-14', '07:59'), 'FORA_DO_HORARIO'],
    ['depois do horário', {}, em('2026-10-14', '19:42'), 'FORA_DO_HORARIO'],
    ['sem usos', { usosRealizados: 10 }, em('2026-10-14', '09:00'), 'SEM_USOS'],
  ])('nega quando está %s', (_caso, mudanca, agora, motivo) => {
    expect(avaliarAutorizacao({ ...base, ...mudanca }, agora)).toBe(motivo);
  });

  it('vale no primeiro e no último dia do período', () => {
    expect(avaliarAutorizacao(base, em('2026-10-01', '08:00'))).toBeNull();
    expect(avaliarAutorizacao(base, em('2026-10-31', '17:59'))).toBeNull();
  });
});

describe('dentroDoHorario', () => {
  it('trata o horário final como exclusivo', () => {
    expect(dentroDoHorario('08:00', '18:00', 18 * 60)).toBe(false);
  });

  it('aceita janelas que passam da meia-noite', () => {
    expect(dentroDoHorario('22:00', '06:00', 23 * 60)).toBe(true);
    expect(dentroDoHorario('22:00', '06:00', 5 * 60)).toBe(true);
    expect(dentroDoHorario('22:00', '06:00', 12 * 60)).toBe(false);
  });
});

describe('escolherAutorizacao', () => {
  it('sem nenhuma autorização para a catraca, o motivo é SEM_AUTORIZACAO', () => {
    expect(escolherAutorizacao([], em('2026-10-14', '09:00'))).toEqual({ motivo: 'SEM_AUTORIZACAO' });
  });

  it('usa a autorização válida mesmo havendo outras inválidas', () => {
    const cancelada = { ...base, id: 'a0', status: 'CANCELADA' as const };
    expect(escolherAutorizacao([cancelada, base], em('2026-10-14', '09:00')).autorizacao?.id).toBe('a1');
  });

  it('quando nenhuma vale, mostra o motivo da que chegou mais perto', () => {
    const cancelada = { ...base, status: 'CANCELADA' as const };
    const foraDoHorario = { ...base, horaInicio: '14:00', horaFim: '16:00' };
    expect(escolherAutorizacao([cancelada, foraDoHorario], em('2026-10-14', '09:00')).motivo).toBe('FORA_DO_HORARIO');
  });
});

describe('situacaoDe', () => {
  it.each([
    [base, 'ATIVA'],
    [{ ...base, status: 'CANCELADA' as const }, 'CANCELADA'],
    [{ ...base, dataFim: '2026-10-13' }, 'EXPIRADA'],
    [{ ...base, usosRealizados: 10 }, 'ESGOTADA'],
    [{ ...base, dataInicio: '2026-10-20' }, 'AGENDADA'],
  ])('%#: %s', (a, situacao) => {
    expect(situacaoDe(a, '2026-10-14')).toBe(situacao);
  });
});
