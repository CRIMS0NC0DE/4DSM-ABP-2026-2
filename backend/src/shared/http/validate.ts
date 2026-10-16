import { z } from 'zod';
import { badRequest } from '../errors.js';

/** Valida body, query ou params; responde 400 com os campos inválidos. */
export function parse<T extends z.ZodType>(schema: T, data: unknown): z.infer<T> {
  const result = schema.safeParse(data);
  if (!result.success) {
    throw badRequest('Dados inválidos.', z.flattenError(result.error).fieldErrors);
  }
  return result.data;
}
