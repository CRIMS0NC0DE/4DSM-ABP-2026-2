import { Router, type RequestHandler } from 'express';
import { z } from 'zod';
import { id, idParam, latitude, longitude } from '../../shared/http/schemas.js';
import { parse } from '../../shared/http/validate.js';
import type { LocationsService } from './locations.service.js';

const nome = z.string().trim().min(1, 'Informe o nome');

const edificioSchema = z.object({ nome, endereco: z.string().trim().min(1, 'Informe o endereço') });
const portariaSchema = z.object({ nome, buildingId: id });
const portaSchema = z.object({ nome, gateId: id });
// Editar portaria e porta muda só o nome: para mudar de lugar, apague e crie de novo.
const renomearSchema = z.object({ nome: nome.optional() });
const catracaSchema = z.object({
  nome,
  doorId: id,
  latitude,
  longitude,
  raioMetros: z.number().int().min(10).max(1000).default(100),
});

/** RF02. Leitura para a equipe; criar, editar e apagar só o admin (somenteAdmin). */
export function locationsRouter(locations: LocationsService, somenteAdmin: RequestHandler) {
  const router = Router();

  router.get('/', async (_req, res) => {
    res.json(await locations.arvore());
  });

  router.post('/buildings', somenteAdmin, async (req, res) => {
    res.status(201).json(await locations.criarEdificio(parse(edificioSchema, req.body)));
  });

  router.post('/gates', somenteAdmin, async (req, res) => {
    res.status(201).json(await locations.criarPortaria(parse(portariaSchema, req.body)));
  });

  router.post('/doors', somenteAdmin, async (req, res) => {
    res.status(201).json(await locations.criarPorta(parse(portaSchema, req.body)));
  });

  router.post('/access-points', somenteAdmin, async (req, res) => {
    res.status(201).json(await locations.criarCatraca(parse(catracaSchema, req.body)));
  });

  router.get('/access-points/:id', async (req, res) => {
    res.json(await locations.buscarCatraca(parse(idParam, req.params).id));
  });

  router.patch('/access-points/:id', somenteAdmin, async (req, res) => {
    const { id: catracaId } = parse(idParam, req.params);
    res.json(await locations.atualizarCatraca(catracaId, parse(catracaSchema.partial(), req.body)));
  });

  router.patch('/buildings/:id', somenteAdmin, async (req, res) => {
    const { id: edificioId } = parse(idParam, req.params);
    res.json(await locations.atualizarEdificio(edificioId, parse(edificioSchema.partial(), req.body)));
  });

  router.patch('/gates/:id', somenteAdmin, async (req, res) => {
    const { id: portariaId } = parse(idParam, req.params);
    res.json(await locations.atualizarPortaria(portariaId, parse(renomearSchema, req.body)));
  });

  router.patch('/doors/:id', somenteAdmin, async (req, res) => {
    const { id: portaId } = parse(idParam, req.params);
    res.json(await locations.atualizarPorta(portaId, parse(renomearSchema, req.body)));
  });

  // Só apaga o que está vazio (409 se não); o histórico de acessos nunca é apagado.
  router.delete('/buildings/:id', somenteAdmin, async (req, res) => {
    await locations.apagarEdificio(parse(idParam, req.params).id);
    res.status(204).end();
  });

  router.delete('/gates/:id', somenteAdmin, async (req, res) => {
    await locations.apagarPortaria(parse(idParam, req.params).id);
    res.status(204).end();
  });

  router.delete('/doors/:id', somenteAdmin, async (req, res) => {
    await locations.apagarPorta(parse(idParam, req.params).id);
    res.status(204).end();
  });

  router.delete('/access-points/:id', somenteAdmin, async (req, res) => {
    await locations.apagarCatraca(parse(idParam, req.params).id);
    res.status(204).end();
  });

  return router;
}
