import { Router } from 'express';
import { z } from 'zod';
import { authDe, type autenticar } from '../../shared/http/auth.js';
import { parse } from '../../shared/http/validate.js';
import type { UsersService } from '../users/users.service.js';
import type { AuthService } from './auth.service.js';

const loginSchema = z.object({
  login: z.string().trim().min(1, 'Informe seu e-mail ou CPF'),
  senha: z.string().min(1, 'Informe sua senha'),
});

export function authRouter(auth: AuthService, users: UsersService, autenticado: ReturnType<typeof autenticar>) {
  const router = Router();

  router.post('/login', async (req, res) => {
    const { login, senha } = parse(loginSchema, req.body);
    res.json(await auth.entrar(login, senha));
  });

  router.get('/me', autenticado, async (req, res) => {
    res.json(await users.buscar(authDe(req).userId));
  });

  return router;
}
