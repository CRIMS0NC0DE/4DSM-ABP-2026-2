import { generateKeyPairSync, sign, webcrypto } from 'node:crypto';
import { describe, expect, it } from 'vitest';
import { conferirAssinatura, desafioDoQr, lerChavePublica, PREFIXO_ASSINATURA } from '../../src/modules/phones/phone-signature.js';

const QR = 'P1.AAAAAAAAAAAAAAAAAAAAAAAAAA.T5X3K0.ABCDEFGHIJKLMNOP.ABCDEFGHIJKLMNOPQRSTUVWX';

describe('Assinatura do celular como chave', () => {
  it('aceita o que o WebCrypto produz (simulador): SPKI e r||s', async () => {
    const { subtle } = webcrypto;
    const par = await subtle.generateKey({ name: 'ECDSA', namedCurve: 'P-256' }, true, ['sign', 'verify']);
    const publica = Buffer.from(await subtle.exportKey('spki', par.publicKey)).toString('base64');
    const mensagem = Buffer.concat([PREFIXO_ASSINATURA, desafioDoQr(QR)]);
    const assinatura = Buffer.from(await subtle.sign({ name: 'ECDSA', hash: 'SHA-256' }, par.privateKey, mensagem));

    expect(assinatura).toHaveLength(64);
    expect(conferirAssinatura(publica, QR, assinatura.toString('base64'))).toBe(true);
  });

  it('recusa a assinatura em DER, que é o formato cru do Keystore (o app converte para r||s)', () => {
    const { publicKey, privateKey } = generateKeyPairSync('ec', { namedCurve: 'prime256v1' });
    const der = sign('sha256', Buffer.concat([PREFIXO_ASSINATURA, desafioDoQr(QR)]), privateKey);
    const publica = publicKey.export({ format: 'der', type: 'spki' }).toString('base64');
    expect(conferirAssinatura(publica, QR, der.toString('base64'))).toBe(false);
  });

  it('a assinatura vale só para aquele QR', () => {
    const { publicKey, privateKey } = generateKeyPairSync('ec', { namedCurve: 'prime256v1' });
    const publica = publicKey.export({ format: 'der', type: 'spki' }).toString('base64');
    const assinar = (qr: string) =>
      sign('sha256', Buffer.concat([PREFIXO_ASSINATURA, desafioDoQr(qr)]), { key: privateKey, dsaEncoding: 'ieee-p1363' }).toString('base64');
    expect(conferirAssinatura(publica, QR, assinar(QR))).toBe(true);
    expect(conferirAssinatura(publica, QR, assinar(`${QR}X`))).toBe(false);
  });

  it('só aceita chave EC P-256', () => {
    const p384 = generateKeyPairSync('ec', { namedCurve: 'secp384r1' }).publicKey.export({ format: 'der', type: 'spki' });
    expect(lerChavePublica(p384.toString('base64'))).toBeNull();
    expect(lerChavePublica('isto não é base64')).toBeNull();
    expect(lerChavePublica(Buffer.from('lixo').toString('base64'))).toBeNull();
  });

  it('o desafio é o SHA-256 do texto do QR, como o firmware calcula', () => {
    expect(desafioDoQr('abc').toString('hex')).toBe('ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
  });
});
