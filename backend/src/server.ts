import { createApp } from './app.js';
import { loadEnv } from './config/env.js';
import { createContainer } from './container.js';
import { createPrisma } from './database/prisma.js';
import { createPrismaRepositories } from './database/repositories.prisma.js';
import { systemClock } from './shared/clock.js';

const env = loadEnv();
const db = createPrisma(env.DATABASE_URL);

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
  },
  systemClock,
);

const server = createApp(container).listen(env.PORT, () => {
  console.info(`Passe API ouvindo na porta ${env.PORT}`);
});

async function encerrar(sinal: string) {
  console.info(`${sinal} recebido, encerrando...`);
  server.close();
  await db.$disconnect();
  process.exit(0);
}

process.on('SIGINT', () => void encerrar('SIGINT'));
process.on('SIGTERM', () => void encerrar('SIGTERM'));
