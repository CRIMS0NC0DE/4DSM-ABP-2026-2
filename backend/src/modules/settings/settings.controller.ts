import { Router, type RequestHandler } from 'express';
import { z } from 'zod';
import { parse } from '../../shared/http/validate.js';
import type { SettingsService } from './settings.service.js';

const alterarSchema = z
  .object({
    nomeCondominio: z.string().trim().min(1, 'Informe o nome do condomínio').max(80, 'Use até 80 caracteres'),
    contatoPortaria: z.string().trim().min(1, 'Informe o contato da portaria').max(200, 'Use até 200 caracteres'),
    moradorPodeConvidar: z.boolean(),
    visitanteMaxUsos: z.number().int().min(1, 'Permita pelo menos 1 uso').max(20, 'Use até 20 usos'),
    visitanteDiasMax: z.number().int().min(1, 'Permita pelo menos 1 dia').max(30, 'Use até 30 dias'),
  })
  .partial();

/** Montado atrás de autenticar: todos leem; só o admin altera. */
export function settingsRouter(settings: SettingsService, somenteAdmin: RequestHandler) {
  const router = Router();

  router.get('/', async (_req, res) => {
    res.json(await settings.ler());
  });

  router.patch('/', somenteAdmin, async (req, res) => {
    res.json(await settings.alterar(parse(alterarSchema, req.body ?? {})));
  });

  return router;
}
