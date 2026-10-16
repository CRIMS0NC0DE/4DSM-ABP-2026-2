import { randomUUID } from 'node:crypto';
import jwt from 'jsonwebtoken';
import { z } from 'zod';
import type { Clock } from '../../shared/clock.js';

export interface QrTokenConfig {
  secret: string;
  ttlSeconds: number;
  rotationSeconds: number;
}

export type QrVerificado = { ok: true; terminalId: string; jti: string } | { ok: false; motivo: 'QR_INVALIDO' | 'QR_EXPIRADO' };

const payloadSchema = z.object({ typ: z.literal('qr'), tid: z.string(), jti: z.string() });

/** Gera e confere o conteúdo do QR Code mostrado no terminal (RF12). */
export class QrTokenService {
  constructor(
    private readonly config: QrTokenConfig,
    private readonly clock: Clock,
  ) {}

  gerar(terminalId: string) {
    const agora = Math.floor(this.clock.now().getTime() / 1000);
    const token = jwt.sign({ typ: 'qr', tid: terminalId, iat: agora }, this.config.secret, {
      expiresIn: this.config.ttlSeconds,
      jwtid: randomUUID(),
    });
    return {
      token,
      expiraEm: new Date((agora + this.config.ttlSeconds) * 1000).toISOString(),
      trocarEmSegundos: this.config.rotationSeconds,
    };
  }

  verificar(token: string): QrVerificado {
    try {
      const payload = payloadSchema.parse(
        jwt.verify(token, this.config.secret, { clockTimestamp: Math.floor(this.clock.now().getTime() / 1000) }),
      );
      return { ok: true, terminalId: payload.tid, jti: payload.jti };
    } catch (err) {
      return { ok: false, motivo: err instanceof jwt.TokenExpiredError ? 'QR_EXPIRADO' : 'QR_INVALIDO' };
    }
  }
}
