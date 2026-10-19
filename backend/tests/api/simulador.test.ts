import request from 'supertest';
import { describe, expect, it, vi } from 'vitest';
import { createApp } from '../../src/app.js';
import { createContainer } from '../../src/container.js';
import { MqttTerminalNotifier } from '../../src/modules/terminals/mqtt-notifier.js';
import { createMemoryRepositories } from '../support/memory-repositories.js';
import { config, FakeClock, montarCenario } from '../support/test-app.js';

describe('Simulador do terminal (/simulador)', () => {
  it('serve a página e as bibliotecas do navegador', async () => {
    const { api } = await montarCenario();

    const pagina = await api.get('/simulador/');
    expect(pagina.status).toBe(200);
    expect(pagina.text).toContain('simulador do terminal');

    for (const arquivo of ['app.js', 'style.css', 'vendor/mqtt.min.js', 'vendor/qrcode.js']) {
      expect((await api.get(`/simulador/${arquivo}`)).status, arquivo).toBe(200);
    }
    expect((await api.get('/simulador/vendor/outro.js')).status).toBe(404);
  });

  it('libera WebSocket na política de conteúdo só da página do simulador', async () => {
    const { api } = await montarCenario();
    expect((await api.get('/simulador/')).headers['content-security-policy']).toContain("connect-src 'self' ws: wss:");
    expect((await api.get('/health')).headers['content-security-policy']).not.toContain('ws:');
  });

  it('config.json traz o broker e os dados da demo, quando houver', async () => {
    const { api } = await montarCenario();
    expect((await api.get('/simulador/config.json')).body).toEqual({ mqttWsUrl: null, demo: null });

    const { repos } = createMemoryRepositories();
    const demo = {
      terminalId: 't-1',
      terminalKey: 'chave',
      login: 'morador@passe.com',
      senha: 'passe123',
      tagUid: '04A1B2C3',
      catraca: { latitude: -23.3, longitude: -45.9 },
    };
    const app = createApp(createContainer(repos, { ...config, simulador: { mqttWsUrl: 'ws://localhost:9001', demo } }, new FakeClock()));
    expect((await request(app).get('/simulador/config.json')).body).toEqual({ mqttWsUrl: 'ws://localhost:9001', demo });
  });
});

describe('Decisões pelo MQTT', () => {
  it('a leitura de uma tag publica ABRIR no tópico do terminal', async () => {
    const c = await montarCenario();
    const client = { connected: true, publish: vi.fn() };
    const app = createApp(createContainer(c.repos, config, c.clock, [new MqttTerminalNotifier(client as never)]));

    const res = await request(app).post('/terminal/nfc').set(c.terminalHeaders).send({ uid: '04A1B2C3' });

    expect(res.body.liberado).toBe(true);
    const [topico, payload] = client.publish.mock.calls[0]!;
    expect(topico).toBe(`passe/terminais/${c.terminal.id}/decisoes`);
    expect(JSON.parse(payload)).toMatchObject({ acao: 'ABRIR', metodo: 'NFC', nome: 'Maria' });
  });
});
