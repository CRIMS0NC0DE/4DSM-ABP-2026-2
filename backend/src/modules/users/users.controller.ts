import { Router } from 'express';
import { z } from 'zod';
import { authDe } from '../../shared/http/auth.js';
import { cpf, id, idParam } from '../../shared/http/schemas.js';
import { parse } from '../../shared/http/validate.js';
import type { UsersService } from './users.service.js';
import { PERFIS } from './users.types.js';

const criarSchema = z.object({
  nome: z.string().trim().min(3, 'Informe o nome completo'),
  email: z.email('E-mail inválido'),
  cpf,
  senha: z.string().min(6, 'A senha precisa de pelo menos 6 caracteres'),
  perfil: z.enum(PERFIS),
});

const atualizarSchema = criarSchema.partial().extend({ ativo: z.boolean().optional() });

const filtroSchema = z.object({
  busca: z.string().trim().min(1).optional(),
  perfil: z.enum(PERFIS).optional(),
});

const tagSchema = z.object({ uid: z.string().trim().regex(/^[0-9a-fA-F:\s-]{4,40}$/, 'UID da tag inválido') });
const tagParams = z.object({ id, tagId: id });

/** RF01. Montado atrás de autenticar + exigirPerfil(ADMIN, CONTROLADOR_ACESSO). */
export function usersRouter(users: UsersService) {
  const router = Router();

  router.get('/', async (req, res) => {
    res.json(await users.listar(parse(filtroSchema, req.query)));
  });

  router.post('/', async (req, res) => {
    res.status(201).json(await users.criar(authDe(req), parse(criarSchema, req.body)));
  });

  router.get('/:id', async (req, res) => {
    res.json(await users.buscar(parse(idParam, req.params).id));
  });

  router.patch('/:id', async (req, res) => {
    const { id: userId } = parse(idParam, req.params);
    res.json(await users.atualizar(authDe(req), userId, parse(atualizarSchema, req.body)));
  });

  router.post('/:id/tags', async (req, res) => {
    const { id: userId } = parse(idParam, req.params);
    res.status(201).json(await users.vincularTag(authDe(req), userId, parse(tagSchema, req.body).uid));
  });

  router.patch('/:id/tags/:tagId', async (req, res) => {
    const p = parse(tagParams, req.params);
    const { ativa } = parse(z.object({ ativa: z.boolean() }), req.body);
    res.json(await users.alterarTag(authDe(req), p.id, p.tagId, ativa));
  });

  router.delete('/:id/tags/:tagId', async (req, res) => {
    const p = parse(tagParams, req.params);
    await users.removerTag(authDe(req), p.id, p.tagId);
    res.status(204).end();
  });

  return router;
}
