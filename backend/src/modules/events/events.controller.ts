import { Router } from 'express';
import { z } from 'zod';
import { id, paginacao } from '../../shared/http/schemas.js';
import { parse } from '../../shared/http/validate.js';
import type { EventsService } from './events.service.js';

export const filtroEventosSchema = z.object({
  de: z.coerce.date().optional(),
  ate: z.coerce.date().optional(),
  resultado: z.enum(['LIBERADO', 'NEGADO']).optional(),
  metodo: z.enum(['QR', 'NFC']).optional(),
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
