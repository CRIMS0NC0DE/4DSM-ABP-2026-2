import { Router } from 'express';
import { z } from 'zod';
import { authDe } from '../../shared/http/auth.js';
import { id } from '../../shared/http/schemas.js';
import { parse } from '../../shared/http/validate.js';
import type { PhonesService } from './phones.service.js';

const ativarSchema = z.object({
  nome: z.string().trim().min(1, 'Informe o nome do aparelho').max(60),
  // SPKI DER de uma chave P-256 tem 91 bytes (~124 caracteres em base64).
  chavePublica: z.string().trim().min(40).max(400),
});

/** "Celular como chave": montado em /me/phones, atrás de autenticar. */
export function meusCelularesRouter(phones: PhonesService) {
  const router = Router();

  router.get('/', async (req, res) => {
    res.json(await phones.meus(authDe(req).userId));
  });

  router.post('/', async (req, res) => {
    res.status(201).json(await phones.ativarMeu(authDe(req).userId, parse(ativarSchema, req.body)));
  });

  router.delete('/:celularId', async (req, res) => {
    const { celularId } = parse(z.object({ celularId: id }), req.params);
    await phones.removerMeu(authDe(req).userId, celularId);
    res.status(204).end();
  });

  return router;
}

const params = z.object({ id });
const celularParams = z.object({ id, celularId: id });

/** Celulares de uma pessoa, para a equipe: montado em /users/:id/phones, atrás de autenticar + equipe. */
export function celularesDaEquipeRouter(phones: PhonesService) {
  const router = Router({ mergeParams: true });

  router.get('/', async (req, res) => {
    res.json(await phones.doUsuario(authDe(req), parse(params, req.params).id));
  });

  router.patch('/:celularId', async (req, res) => {
    const p = parse(celularParams, req.params);
    const { ativo } = parse(z.object({ ativo: z.boolean() }), req.body);
    res.json(await phones.alterar(authDe(req), p.id, p.celularId, ativo));
  });

  router.delete('/:celularId', async (req, res) => {
    const p = parse(celularParams, req.params);
    await phones.remover(authDe(req), p.id, p.celularId);
    res.status(204).end();
  });

  return router;
}
