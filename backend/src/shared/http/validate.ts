import { z } from 'zod';
import { badRequest } from '../errors.js';

/** O Postgres não guarda o caractere NUL: sem isto, o texto vira erro 500 no banco. */
function temNul(valor: unknown): boolean {
  if (typeof valor === 'string') return valor.includes('\0');
  if (typeof valor === 'object' && valor !== null) return Object.values(valor).some(temNul);
  return false;
}

/** Valida body, query ou params; responde 400 com os campos inválidos. */
export function parse<T extends z.ZodType>(schema: T, data: unknown): z.infer<T> {
  if (temNul(data)) throw badRequest('Dados inválidos.');
  const result = schema.safeParse(data);
  if (!result.success) {
    throw badRequest('Dados inválidos.', z.flattenError(result.error).fieldErrors);
  }
  return result.data;
}
