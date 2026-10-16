import { Router } from 'express';
import { z } from 'zod';
import { dataIso, hora, id, idParam } from '../../shared/http/schemas.js';
import { parse } from '../../shared/http/validate.js';
import type { AuthorizationsService } from './authorizations.service.js';

const criarSchema = z.object({
  userId: id,
  accessPointId: id,
  dataInicio: dataIso,
  dataFim: dataIso,
  horaInicio: hora,
  horaFim: hora,
  maxUsos: z.number().int().min(1, 'Permita pelo menos 1 uso').max(10_000),
});

const atualizarSchema = criarSchema.omit({ userId: true }).partial();

const filtroSchema = z.object({
  userId: id.optional(),
  accessPointId: id.optional(),
  situacao: z.enum(['ATIVA', 'EXPIRADA', 'CANCELADA']).optional(),
  de: dataIso.optional(),
  ate: dataIso.optional(),
});

/** RF03, RF04, RF05. Montado atrás de autenticar + exigirPerfil(equipe). */
export function authorizationsRouter(authorizations: AuthorizationsService) {
  const router = Router();

  router.get('/', async (req, res) => {
    res.json(await authorizations.listar(parse(filtroSchema, req.query)));
  });

  router.post('/', async (req, res) => {
    res.status(201).json(await authorizations.criar(parse(criarSchema, req.body)));
  });

  router.get('/:id', async (req, res) => {
    res.json(await authorizations.buscar(parse(idParam, req.params).id));
  });

  router.patch('/:id', async (req, res) => {
    const { id: autorizacaoId } = parse(idParam, req.params);
    res.json(await authorizations.atualizar(autorizacaoId, parse(atualizarSchema, req.body)));
  });

  router.post('/:id/cancel', async (req, res) => {
    res.json(await authorizations.cancelar(parse(idParam, req.params).id));
  });

  return router;
}
