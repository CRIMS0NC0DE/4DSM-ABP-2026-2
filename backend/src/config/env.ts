import 'dotenv/config';
import { z } from 'zod';

// Variável vazia no .env (MQTT_URL=) conta como não informada.
const opcional = z
  .string()
  .trim()
  .optional()
  .transform((v) => v || undefined);

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(3000),
  DATABASE_URL: z.string().min(1),
  JWT_SECRET: z.string().min(16, 'JWT_SECRET precisa de pelo menos 16 caracteres'),
  JWT_EXPIRES_IN: z.string().default('8h'),
  QR_SECRET: z.string().min(16, 'QR_SECRET precisa de pelo menos 16 caracteres'),
  QR_ROTATION_SECONDS: z.coerce.number().int().positive().default(10),
  QR_TOKEN_TTL_SECONDS: z.coerce.number().int().positive().default(30),
  APP_TIMEZONE: z.string().default('America/Sao_Paulo'),
  CORS_ORIGIN: z.string().default('*'),
  // Broker MQTT que leva as decisões aos terminais. Sem ele, os terminais consultam por HTTP.
  MQTT_URL: opcional,
  MQTT_USERNAME: opcional,
  MQTT_PASSWORD: opcional,
  // CA própria do broker, para mqtts:// com certificado gerado por docker/mosquitto/gerar-certificados.sh.
  MQTT_CA_FILE: opcional,
  // Endereço WebSocket do broker visto pelo navegador, usado pelo simulador do terminal.
  MQTT_WS_URL: opcional,
});

export type Env = z.infer<typeof envSchema>;

export function loadEnv(source: NodeJS.ProcessEnv = process.env): Env {
  const result = envSchema.safeParse(source);
  if (!result.success) {
    throw new Error(`Variáveis de ambiente inválidas:\n${z.prettifyError(result.error)}`);
  }
  return result.data;
}
