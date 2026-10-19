import bcrypt from 'bcryptjs';
import { createHash, randomBytes, timingSafeEqual } from 'node:crypto';

const BCRYPT_ROUNDS = 10;

export const hashSenha = (senha: string) => bcrypt.hash(senha, BCRYPT_ROUNDS);
export const hashSenhaSync = (senha: string) => bcrypt.hashSync(senha, BCRYPT_ROUNDS);
export const conferirSenha = (senha: string, hash: string) => bcrypt.compare(senha, hash);

/** Chave do terminal: mostrada uma vez no cadastro, guardada só como hash. */
export const gerarChave = () => randomBytes(32).toString('hex');
export const hashChave = (chave: string) => createHash('sha256').update(chave).digest('hex');

export function conferirChave(chave: string, hash: string): boolean {
  const a = Buffer.from(hashChave(chave), 'hex');
  const b = Buffer.from(hash, 'hex');
  return a.length === b.length && timingSafeEqual(a, b);
}

export const somenteNumeros = (texto: string) => texto.replace(/\D/g, '');
