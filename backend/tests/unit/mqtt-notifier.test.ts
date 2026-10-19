import { describe, expect, it, vi } from 'vitest';
import { loadEnv } from '../../src/config/env.js';
import { MqttTerminalNotifier, topicoDecisoes } from '../../src/modules/terminals/mqtt-notifier.js';
import type { DecisaoTerminal } from '../../src/modules/terminals/terminal-notifier.js';

const decisao: DecisaoTerminal = { acao: 'ABRIR', metodo: 'QR', mensagem: 'Acesso liberado', nome: 'Maria', em: '2026-10-14T12:00:00.000Z' };

function clienteFalso(connected: boolean) {
  return { connected, publish: vi.fn() };
}

describe('MqttTerminalNotifier', () => {
  it('publica a decisão em JSON no tópico do terminal, com QoS 1', () => {
    const client = clienteFalso(true);
    new MqttTerminalNotifier(client as never).enviar('t-1', decisao);

    expect(client.publish).toHaveBeenCalledWith('passe/terminais/t-1/decisoes', JSON.stringify(decisao), { qos: 1 }, expect.any(Function));
  });

  it('descarta a decisão com o broker fora do ar, para a catraca não abrir atrasada', () => {
    const client = clienteFalso(false);
    const aviso = vi.spyOn(console, 'warn').mockImplementation(() => {});
    new MqttTerminalNotifier(client as never).enviar('t-1', decisao);

    expect(client.publish).not.toHaveBeenCalled();
    expect(aviso).toHaveBeenCalled();
    aviso.mockRestore();
  });

  it('topicoDecisoes', () => {
    expect(topicoDecisoes('abc')).toBe('passe/terminais/abc/decisoes');
  });
});

describe('loadEnv (MQTT)', () => {
  const base = { DATABASE_URL: 'postgresql://x', JWT_SECRET: 'segredo-jwt-de-teste-123', QR_SECRET: 'segredo-qr-de-teste-1234' };

  it('MQTT é opcional e variável vazia conta como não informada', () => {
    const env = loadEnv({ ...base, MQTT_URL: '', MQTT_USERNAME: '  ' });
    expect(env.MQTT_URL).toBeUndefined();
    expect(env.MQTT_USERNAME).toBeUndefined();
  });

  it('lê o endereço do broker', () => {
    expect(loadEnv({ ...base, MQTT_URL: 'mqtt://localhost:1883' }).MQTT_URL).toBe('mqtt://localhost:1883');
  });
});
