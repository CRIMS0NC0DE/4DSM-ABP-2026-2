import { createHmac, randomBytes, timingSafeEqual } from 'node:crypto';
import type { Clock } from '../../shared/clock.js';

export interface QrTokenConfig {
  secret: string;
  ttlSeconds: number;
  rotationSeconds: number;
}

export type QrVerificado = { ok: true; terminalId: string; jti: string } | { ok: false; motivo: 'QR_INVALIDO' | 'QR_EXPIRADO' };

/*
 * Formato do QR: P1.<terminal>.<vence>.<nonce>.<assinatura>
 *   terminal   UUID do terminal em base32 (26 caracteres)
 *   vence      instante em segundos (unix), base36
 *   nonce      10 bytes aleatórios em base32; é o id de uso único (jti)
 *   assinatura HMAC-SHA256 dos campos anteriores, 14 bytes (112 bits) em base32
 *
 * São 77 caracteres só com A-Z, 0-9 e ponto, o modo alfanumérico do QR. 77 é o
 * máximo da versão 3 (29×29 módulos) com correção L: no OLED de 64 pontos de
 * altura, cada módulo fica com 2 pontos (uns 10 mm de QR) em vez de 1 (uns 6 mm)
 * da versão 4, que era o que os 78 caracteres da assinatura de 15 bytes pediam.
 * O JWT de antes pedia a versão 10 (57×57). O conteúdo continua sendo gerado e
 * conferido só pelo backend; o terminal apenas desenha o texto.
 * O "vence" tem 6 caracteres em base36 até 2038; depois vira 7 e o QR volta à versão 4.
 */
const VERSAO = 'P1';
const BYTES_NONCE = 10;
const BYTES_ASSINATURA = 14;
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const FORMATO = /^P1\.([A-Z2-7]{26})\.([0-9A-Z]{1,8})\.([A-Z2-7]{16})\.([A-Z2-7]{23})$/;

/** Gera e confere o conteúdo do QR Code mostrado no terminal (RF12). */
export class QrTokenService {
  constructor(
    private readonly config: QrTokenConfig,
    private readonly clock: Clock,
  ) {}

  gerar(terminalId: string) {
    if (!UUID.test(terminalId)) throw new Error('O id do terminal precisa ser um UUID.');
    const agora = Math.floor(this.clock.now().getTime() / 1000);
    const vence = agora + this.config.ttlSeconds;
    const corpo = [VERSAO, base32(Buffer.from(terminalId.replace(/-/g, ''), 'hex')), vence.toString(36).toUpperCase(), base32(randomBytes(BYTES_NONCE))].join('.');
    return {
      token: `${corpo}.${this.assinar(corpo)}`,
      expiraEm: new Date(vence * 1000).toISOString(),
      trocarEmSegundos: this.config.rotationSeconds,
    };
  }

  verificar(token: string): QrVerificado {
    const partes = FORMATO.exec(token.trim());
    if (!partes) return { ok: false, motivo: 'QR_INVALIDO' };
    const [, terminal, vence, nonce, assinatura] = partes as unknown as [string, string, string, string, string];

    const esperada = Buffer.from(this.assinar(`${VERSAO}.${terminal}.${vence}.${nonce}`));
    const recebida = Buffer.from(assinatura);
    if (esperada.length !== recebida.length || !timingSafeEqual(esperada, recebida)) return { ok: false, motivo: 'QR_INVALIDO' };

    const agora = Math.floor(this.clock.now().getTime() / 1000);
    if (agora > parseInt(vence, 36)) return { ok: false, motivo: 'QR_EXPIRADO' };

    return { ok: true, terminalId: uuidDe(deBase32(terminal)), jti: nonce };
  }

  private assinar(corpo: string) {
    return base32(createHmac('sha256', this.config.secret).update(corpo).digest().subarray(0, BYTES_ASSINATURA));
  }
}

// Base32 da RFC 4648, sem "=": só letras maiúsculas e 2-7, o que o modo alfanumérico aceita.
const ALFABETO = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

function base32(dados: Buffer): string {
  let bits = 0;
  let valor = 0;
  let saida = '';
  for (const byte of dados) {
    valor = (valor << 8) | byte;
    bits += 8;
    while (bits >= 5) {
      saida += ALFABETO[(valor >>> (bits - 5)) & 31];
      bits -= 5;
    }
  }
  if (bits > 0) saida += ALFABETO[(valor << (5 - bits)) & 31];
  return saida;
}

function deBase32(texto: string): Buffer {
  let bits = 0;
  let valor = 0;
  const bytes: number[] = [];
  for (const c of texto) {
    valor = (valor << 5) | ALFABETO.indexOf(c);
    bits += 5;
    if (bits >= 8) {
      bytes.push((valor >>> (bits - 8)) & 255);
      bits -= 8;
    }
  }
  return Buffer.from(bytes);
}

function uuidDe(bytes: Buffer): string {
  const h = bytes.toString('hex');
  return `${h.slice(0, 8)}-${h.slice(8, 12)}-${h.slice(12, 16)}-${h.slice(16, 20)}-${h.slice(20)}`;
}
