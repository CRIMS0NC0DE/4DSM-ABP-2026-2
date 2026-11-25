import { createHash, createPublicKey, verify, type KeyObject } from 'node:crypto';

/*
 * Celular como chave NFC, protocolo versão 1 (detalhes em docs/documentacao-tecnica/celular-nfc.md).
 *
 *   terminal (RC522)                              celular Android (HCE)
 *   SELECT  00 A4 04 00 07 F0 50 41 53 53 45 01 00   ──▶
 *                                                 ◀──   01 90 00              versão do protocolo
 *   ASSINAR 80 10 00 00 20 <desafio, 32 bytes> 00   ──▶
 *                                                 ◀──   <id, 16 bytes> <assinatura, 64 bytes> 90 00
 *
 *   desafio    SHA-256 do QR que está na tela do terminal agora (o texto P1.…)
 *   assinatura ECDSA P-256 + SHA-256 de PREFIXO_ASSINATURA || desafio, no formato r||s
 *   id         id do celular no Passe (o UUID em 16 bytes)
 *
 * O terminal manda { desafio: <o QR inteiro>, celularId, assinatura em base64 } para
 * POST /terminal/phone. A API confere o QR como no acesso por QR (HMAC, validade e
 * terminal) e a assinatura com a chave pública cadastrada. Assim o celular prova que
 * estava encostado neste terminal agora, sem GPS e sem internet no celular.
 */
export const PREFIXO_ASSINATURA = Buffer.from('PASSE-CEL1', 'ascii');

const BYTES_ASSINATURA = 64;

/** Aceita só chave pública EC P-256 em SPKI DER (base64), que é o que o Keystore do Android exporta. */
export function lerChavePublica(base64: string): KeyObject | null {
  if (!/^[A-Za-z0-9+/]+={0,2}$/.test(base64)) return null;
  try {
    const chave = createPublicKey({ key: Buffer.from(base64, 'base64'), format: 'der', type: 'spki' });
    return chave.asymmetricKeyType === 'ec' && chave.asymmetricKeyDetails?.namedCurve === 'prime256v1' ? chave : null;
  } catch {
    return null;
  }
}

/** O que o terminal entrega ao celular: o SHA-256 do QR (32 bytes cabem num quadro só do RC522). */
export const desafioDoQr = (qr: string) => createHash('sha256').update(qr, 'ascii').digest();

export function conferirAssinatura(chavePublica: string, qr: string, assinaturaBase64: string): boolean {
  const chave = lerChavePublica(chavePublica);
  const assinatura = Buffer.from(assinaturaBase64, 'base64');
  if (!chave || assinatura.length !== BYTES_ASSINATURA) return false;
  const mensagem = Buffer.concat([PREFIXO_ASSINATURA, desafioDoQr(qr)]);
  try {
    return verify('sha256', mensagem, { key: chave, dsaEncoding: 'ieee-p1363' }, assinatura);
  } catch {
    return false;
  }
}
