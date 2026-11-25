import { Router, type RequestHandler } from 'express';
import { z } from 'zod';
import { authDe } from '../../shared/http/auth.js';
import { idParam } from '../../shared/http/schemas.js';
import { parse } from '../../shared/http/validate.js';
import type { AnnouncementsService } from './announcements.service.js';

const comunicadoSchema = z.object({
  titulo: z.string().trim().min(1, 'Informe o título').max(120, 'Use até 120 caracteres'),
  mensagem: z.string().trim().min(1, 'Escreva a mensagem').max(2000, 'Use até 2000 caracteres'),
});

/** Montado atrás de autenticar: todos leem; só o admin publica e apaga. */
export function announcementsRouter(announcements: AnnouncementsService, somenteAdmin: RequestHandler) {
  const router = Router();

  router.get('/', async (_req, res) => {
    res.json(await announcements.listar());
  });

  router.post('/', somenteAdmin, async (req, res) => {
    const dados = parse(comunicadoSchema, req.body);
    res.status(201).json(await announcements.publicar({ ...dados, autorId: authDe(req).userId }));
  });

  router.delete('/:id', somenteAdmin, async (req, res) => {
    await announcements.apagar(parse(idParam, req.params).id);
    res.status(204).end();
  });

  return router;
}
