import { z } from 'zod';

export const id = z.uuid({ message: 'id inválido' });
export const idParam = z.object({ id });

export const dataIso = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, 'Use o formato AAAA-MM-DD')
  .refine((v) => !Number.isNaN(Date.parse(`${v}T00:00:00Z`)), 'Data inválida');

export const hora = z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/, 'Use o formato HH:MM');

export const latitude = z.number().min(-90).max(90);
export const longitude = z.number().min(-180).max(180);

export const cpf = z
  .string()
  .transform((v) => v.replace(/\D/g, ''))
  .refine((v) => v.length === 11, 'O CPF precisa ter 11 números');

export const paginacao = {
  limite: z.coerce.number().int().min(1).max(200).default(50),
  pular: z.coerce.number().int().min(0).default(0),
};
