import { createApp } from './app.js';
import { loadEnv } from './config/env.js';
import { createContainer } from './container.js';
import { DEMO_CATRACA_POS, DEMO_IDS, DEMO_SENHA, DEMO_TAG_UID, demoChaveTerminal } from './database/demo.js';
import { createPrisma } from './database/prisma.js';
import { createPrismaRepositories } from './database/repositories.prisma.js';
import { conectarMqtt, MqttTerminalNotifier } from './modules/terminals/mqtt-notifier.js';
import { systemClock } from './shared/clock.js';

const env = loadEnv();
const db = createPrisma(env.DATABASE_URL);
const mqtt = env.MQTT_URL ? conectarMqtt(env.MQTT_URL, { username: env.MQTT_USERNAME, password: env.MQTT_PASSWORD }) : null;

const container = createContainer(
  createPrismaRepositories(db),
  {
    jwtSecret: env.JWT_SECRET,
    jwtExpiresIn: env.JWT_EXPIRES_IN,
    qrSecret: env.QR_SECRET,
    qrTtlSeconds: env.QR_TOKEN_TTL_SECONDS,
    qrRotationSeconds: env.QR_ROTATION_SECONDS,
    timezone: env.APP_TIMEZONE,
    corsOrigin: env.CORS_ORIGIN,
    simulador: {
      mqttWsUrl: env.MQTT_WS_URL,
      // Contas e chave do seed já preenchidas, para a demo local.
      demo:
        env.NODE_ENV === 'development'
          ? {
              terminalId: DEMO_IDS.terminal,
              terminalKey: demoChaveTerminal(),
              login: 'morador@passe.com',
              senha: DEMO_SENHA,
              tagUid: DEMO_TAG_UID,
              catraca: DEMO_CATRACA_POS,
            }
          : undefined,
    },
  },
  systemClock,
  mqtt ? [new MqttTerminalNotifier(mqtt)] : [],
);

const server = createApp(container).listen(env.PORT, () => {
  console.info(`Passe API ouvindo na porta ${env.PORT}`);
});

async function encerrar(sinal: string) {
  console.info(`${sinal} recebido, encerrando...`);
  server.close();
  await mqtt?.endAsync();
  await db.$disconnect();
  process.exit(0);
}

process.on('SIGINT', () => void encerrar('SIGINT'));
process.on('SIGTERM', () => void encerrar('SIGTERM'));
