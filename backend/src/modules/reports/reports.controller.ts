import { Router } from 'express';
import { z } from 'zod';
import { dataIso, id } from '../../shared/http/schemas.js';
import { parse } from '../../shared/http/validate.js';
import type { ReportsService } from './reports.service.js';

const filtroSchema = z.object({
  de: dataIso.optional(),
  ate: dataIso.optional(),
  accessPointId: id.optional(),
});

/** Relatório agregado dos acessos. Montado atrás de autenticar + exigirPerfil(equipe). */
export function reportsRouter(reports: ReportsService) {
  const router = Router();

  router.get('/access', async (req, res) => {
    res.json(await reports.acessos(parse(filtroSchema, req.query)));
  });

  return router;
}
