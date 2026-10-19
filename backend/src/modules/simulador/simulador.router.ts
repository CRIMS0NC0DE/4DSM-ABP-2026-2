import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import express, { Router } from 'express';
import helmet from 'helmet';

/** Valores pré-preenchidos na tela, só em desenvolvimento. */
export interface DemoSimulador {
  terminalId: string;
  terminalKey: string;
  login: string;
  senha: string;
  tagUid: string;
  catraca: { latitude: number; longitude: number };
}

export interface SimuladorConfig {
  mqttWsUrl?: string;
  demo?: DemoSimulador;
}

const require = createRequire(import.meta.url);
const pastaPacote = (nome: string) => path.dirname(require.resolve(`${nome}/package.json`));

// Mesmo caminho a partir de src/ (tsx) e de dist/ (build).
const PASTA_PAGINA = fileURLToPath(new URL('../../../public/simulador/', import.meta.url));

const BIBLIOTECAS: Record<string, string> = {
  'mqtt.min.js': path.join(pastaPacote('mqtt'), 'dist', 'mqtt.min.js'),
  'qrcode.js': path.join(pastaPacote('qrcode-generator'), 'qrcode.js'),
};

/**
 * Simulador web do terminal da catraca (RP08: o hardware pode ser simulado).
 * Usa a mesma API do ESP32 e recebe as decisões pelo MQTT via WebSocket.
 */
export function simuladorRouter(config: SimuladorConfig) {
  const router = Router();

  // A página fala com o broker por WebSocket e desenha o QR como SVG.
  router.use(
    helmet.contentSecurityPolicy({
      directives: { connectSrc: ["'self'", 'ws:', 'wss:'], imgSrc: ["'self'", 'data:'] },
    }),
  );

  router.get('/config.json', (_req, res) => {
    res.json({ mqttWsUrl: config.mqttWsUrl ?? null, demo: config.demo ?? null });
  });

  router.get('/vendor/:arquivo', (req, res, next) => {
    const arquivo = BIBLIOTECAS[req.params.arquivo];
    if (!arquivo) return next();
    res.sendFile(arquivo);
  });

  router.use(express.static(PASTA_PAGINA));
  return router;
}
