import { Router } from 'express';
import { z } from 'zod';
import { authDe } from '../../shared/http/auth.js';
import { cpf, dataIso, hora, id, idParam } from '../../shared/http/schemas.js';
import { parse } from '../../shared/http/validate.js';
import type { VisitorsService } from './visitors.service.js';

const conviteSchema = z.object({
  nome: z.string().trim().min(3, 'Informe o nome completo'),
  email: z.email('E-mail inválido'),
  cpf,
  accessPointId: id,
  dataInicio: dataIso,
  dataFim: dataIso,
  horaInicio: hora,
  horaFim: hora,
});

/** "Meus visitantes". Montado atrás de autenticar + exigirPerfil('CONDOMINO'). */
export function visitorsRouter(visitors: VisitorsService) {
  const router = Router();

  router.get('/', async (req, res) => {
    res.json(await visitors.listar(authDe(req).userId));
  });

  router.get('/catracas', async (req, res) => {
    res.json(await visitors.catracas(authDe(req).userId));
  });

  router.post('/', async (req, res) => {
    res.status(201).json(await visitors.convidar(authDe(req).userId, parse(conviteSchema, req.body)));
  });

  router.post('/:id/cancel', async (req, res) => {
    res.json(await visitors.cancelar(authDe(req).userId, parse(idParam, req.params).id));
  });

  return router;
}
