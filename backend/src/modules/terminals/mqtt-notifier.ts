import { randomUUID } from 'node:crypto';
import mqtt, { type MqttClient } from 'mqtt';
import type { DecisaoTerminal, TerminalNotifier } from './terminal-notifier.js';

/** Tópico em que cada terminal escuta as decisões da sua catraca. */
export const topicoDecisoes = (terminalId: string) => `passe/terminais/${terminalId}/decisoes`;

type ClienteMqtt = Pick<MqttClient, 'connected' | 'publish'>;

/**
 * Publica a decisão no tópico do terminal (QoS 1). Não espera o broker: a
 * resposta ao celular não pode travar por causa dele. Com o broker fora do ar a
 * decisão é descartada, para a catraca não abrir atrasada quando ele voltar; o
 * terminal continua recebendo pela consulta HTTP (GET /terminal/decisions).
 */
export class MqttTerminalNotifier implements TerminalNotifier {
  constructor(private readonly client: ClienteMqtt) {}

  enviar(terminalId: string, decisao: DecisaoTerminal): void {
    if (!this.client.connected) {
      console.warn(`MQTT desconectado; decisão para o terminal ${terminalId} só pela consulta HTTP.`);
      return;
    }
    this.client.publish(topicoDecisoes(terminalId), JSON.stringify(decisao), { qos: 1 }, (err) => {
      if (err) console.warn(`Falha ao publicar no MQTT: ${err.message}`);
    });
  }
}

export function conectarMqtt(url: string, credenciais: { username?: string; password?: string } = {}): MqttClient {
  const client = mqtt.connect(url, {
    ...credenciais,
    clientId: `passe-api-${randomUUID().slice(0, 8)}`,
    reconnectPeriod: 5000,
  });
  client.on('connect', () => console.info(`MQTT conectado em ${url}`));
  client.on('error', (err) => console.warn(`MQTT: ${err.message}`));
  return client;
}
