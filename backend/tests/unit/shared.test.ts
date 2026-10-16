import { describe, expect, it } from 'vitest';
import { QrTokenService } from '../../src/modules/terminals/qr-token.js';
import { timeToMinutes, toLocal } from '../../src/shared/clock.js';
import { distanciaEmMetros } from '../../src/shared/geo.js';
import { conferirChave, gerarChave, hashChave } from '../../src/shared/security.js';
import { FakeClock } from '../support/test-app.js';

describe('toLocal', () => {
  it('converte para o horário de Brasília', () => {
    expect(toLocal(new Date('2026-10-14T12:30:00Z'), 'America/Sao_Paulo')).toEqual({
      date: '2026-10-14',
      time: '09:30',
      minutes: 9 * 60 + 30,
    });
  });

  it('vira o dia corretamente perto da meia-noite', () => {
    expect(toLocal(new Date('2026-10-15T02:00:00Z'), 'America/Sao_Paulo').date).toBe('2026-10-14');
  });

  it('timeToMinutes', () => {
    expect(timeToMinutes('18:00')).toBe(1080);
  });
});

describe('distanciaEmMetros', () => {
  it('é zero para o mesmo ponto', () => {
    expect(distanciaEmMetros({ latitude: -23.5, longitude: -46.6 }, { latitude: -23.5, longitude: -46.6 })).toBe(0);
  });

  it('mede ~111 km por grau de latitude', () => {
    const d = distanciaEmMetros({ latitude: 0, longitude: 0 }, { latitude: 1, longitude: 0 });
    expect(d).toBeGreaterThan(111_000);
    expect(d).toBeLessThan(111_400);
  });

  it('mede ~50 m para 0,00045 grau', () => {
    const d = distanciaEmMetros({ latitude: -23.5649, longitude: -46.6519 }, { latitude: -23.56445, longitude: -46.6519 });
    expect(Math.round(d)).toBe(50);
  });
});

describe('chave do terminal', () => {
  it('confere só a chave certa', () => {
    const chave = gerarChave();
    const hash = hashChave(chave);
    expect(conferirChave(chave, hash)).toBe(true);
    expect(conferirChave(gerarChave(), hash)).toBe(false);
  });
});

describe('QrTokenService', () => {
  const criar = () => {
    const clock = new FakeClock();
    return { clock, qr: new QrTokenService({ secret: 'segredo-qr-de-teste-1234', ttlSeconds: 20, rotationSeconds: 10 }, clock) };
  };

  it('gera um token que identifica o terminal', () => {
    const { qr } = criar();
    const { token, trocarEmSegundos } = qr.gerar('terminal-1');
    expect(trocarEmSegundos).toBe(10);
    expect(qr.verificar(token)).toMatchObject({ ok: true, terminalId: 'terminal-1' });
  });

  it('cada token tem um id único', () => {
    const { qr } = criar();
    const a = qr.verificar(qr.gerar('t').token);
    const b = qr.verificar(qr.gerar('t').token);
    expect(a.ok && b.ok && a.jti !== b.jti).toBe(true);
  });

  it('expira depois do TTL', () => {
    const { qr, clock } = criar();
    const { token } = qr.gerar('terminal-1');
    clock.avancar(21);
    expect(qr.verificar(token)).toEqual({ ok: false, motivo: 'QR_EXPIRADO' });
  });

  it('recusa token adulterado ou de outro segredo', () => {
    const { qr, clock } = criar();
    const outro = new QrTokenService({ secret: 'outro-segredo-qualquer-123', ttlSeconds: 20, rotationSeconds: 10 }, clock);
    expect(qr.verificar(outro.gerar('t').token)).toEqual({ ok: false, motivo: 'QR_INVALIDO' });
    expect(qr.verificar('nao-e-um-token')).toEqual({ ok: false, motivo: 'QR_INVALIDO' });
  });
});
