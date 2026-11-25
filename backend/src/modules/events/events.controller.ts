import { Router } from 'express';
import { z } from 'zod';
import { dataIso, id, paginacao } from '../../shared/http/schemas.js';
import { parse } from '../../shared/http/validate.js';
import type { EventsService } from './events.service.js';

const SO_DATA = /^\d{4}-\d{2}-\d{2}$/;

// Só a data (AAAA-MM-DD) segue como texto: o service lê como o dia inteiro no fuso do prédio.
// Com hora, continua como antes: o instante que o JavaScript entender (de preferência ISO 8601).
const dataOuInstante = z
  .string()
  .refine(
    (v) => (SO_DATA.test(v) ? dataIso.safeParse(v).success : !Number.isNaN(Date.parse(v))),
    'Data inválida. Use AAAA-MM-DD ou data e hora ISO 8601.',
  )
  .transform((v) => (SO_DATA.test(v) ? v : new Date(v)));

export const filtroEventosSchema = z.object({
  de: dataOuInstante.optional(),
  ate: dataOuInstante.optional(),
  resultado: z.enum(['LIBERADO', 'NEGADO']).optional(),
  metodo: z.enum(['QR', 'NFC', 'CELULAR']).optional(),
  userId: id.optional(),
  accessPointId: id.optional(),
  ...paginacao,
});

/** RF06. Montado atrás de autenticar + exigirPerfil(equipe). */
export function eventsRouter(events: EventsService) {
  const router = Router();

  router.get('/', async (req, res) => {
    res.json(await events.listar(parse(filtroEventosSchema, req.query)));
  });

  return router;
}
