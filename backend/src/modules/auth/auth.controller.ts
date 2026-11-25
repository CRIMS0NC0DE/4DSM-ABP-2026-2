import { Router } from 'express';
import { z } from 'zod';
import { authDe, type autenticar } from '../../shared/http/auth.js';
import { cpf } from '../../shared/http/schemas.js';
import { parse } from '../../shared/http/validate.js';
import type { UsersService } from '../users/users.service.js';
import type { AuthService } from './auth.service.js';

const loginSchema = z.object({
  login: z.string().trim().min(1, 'Informe seu e-mail ou CPF'),
  senha: z.string().min(1, 'Informe sua senha'),
});

// As mesmas regras do cadastro feito pela equipe (POST /users).
const cadastroSchema = z.object({
  nome: z.string().trim().min(3, 'Informe o nome completo'),
  email: z.email('E-mail inválido'),
  cpf,
  senha: z.string().min(6, 'A senha precisa de pelo menos 6 caracteres'),
});

export function authRouter(auth: AuthService, users: UsersService, autenticado: ReturnType<typeof autenticar>) {
  const router = Router();

  router.post('/login', async (req, res) => {
    const { login, senha } = parse(loginSchema, req.body);
    res.json(await auth.entrar(login, senha));
  });

  // Pública. A conta nasce inativa (morador): só entra depois que a portaria libera.
  router.post('/register', async (req, res) => {
    const usuario = await users.solicitarCadastro(parse(cadastroSchema, req.body));
    res.status(201).json({ mensagem: 'Pedido enviado. A portaria vai liberar seu acesso.', usuario });
  });

  router.get('/me', autenticado, async (req, res) => {
    res.json(await users.buscar(authDe(req).userId));
  });

  return router;
}
