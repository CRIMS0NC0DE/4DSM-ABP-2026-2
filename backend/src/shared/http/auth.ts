import type { Request, RequestHandler } from 'express';
import jwt from 'jsonwebtoken';
import { z } from 'zod';
import { forbidden, unauthorized } from '../errors.js';
import { PERFIS, type Perfil, type UsersRepository } from '../../modules/users/users.types.js';
import type { TerminalsRepository, Terminal } from '../../modules/terminals/terminals.types.js';
import { conferirChave } from '../security.js';

export interface AuthContext {
  userId: string;
  perfil: Perfil;
}

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      auth?: AuthContext;
      terminal?: Terminal;
    }
  }
}

const jwtPayloadSchema = z.object({ sub: z.string(), perfil: z.enum(PERFIS) });

export function assinarJwt(ctx: AuthContext, secret: string, expiresIn: string): string {
  return jwt.sign({ perfil: ctx.perfil }, secret, { subject: ctx.userId, expiresIn: expiresIn as jwt.SignOptions['expiresIn'] });
}

/** Exige "Authorization: Bearer <jwt>" de um usuário. */
/** Exige "Authorization: Bearer <jwt>" de um usuário que continua com o cadastro ativo. */
export function autenticar(secret: string, users: Pick<UsersRepository, 'findById'>): RequestHandler {
  return async (req, _res, next) => {
    const [tipo, token] = (req.headers.authorization ?? '').split(' ');
    if (tipo !== 'Bearer' || !token) throw unauthorized();
    let payload: z.infer<typeof jwtPayloadSchema>;
    try {
      payload = jwtPayloadSchema.parse(jwt.verify(token, secret));
    } catch {
      throw unauthorized('Sessão inválida ou expirada. Entre de novo.');
    }
    // O token vale 8 h: sem isto, quem foi desativado continuaria usando a API até ele vencer.
    const user = await users.findById(payload.sub);
    if (!user?.ativo) throw unauthorized('Seu cadastro está desativado. Fale com a portaria.');
    req.auth = { userId: payload.sub, perfil: user.perfil };
    next();
  };
}


export function exigirPerfil(...perfis: readonly Perfil[]): RequestHandler {
  return (req, _res, next) => {
    if (!req.auth) throw unauthorized();
    if (!perfis.includes(req.auth.perfil)) throw forbidden();
    next();
  };
}

export function authDe(req: Request): AuthContext {
  if (!req.auth) throw unauthorized();
  return req.auth;
}

/** Exige os cabeçalhos X-Terminal-Id e X-Terminal-Key de um terminal cadastrado. */
export function autenticarTerminal(terminals: TerminalsRepository): RequestHandler {
  return async (req, _res, next) => {
    const id = req.header('x-terminal-id');
    const chave = req.header('x-terminal-key');
    if (!id || !chave) throw unauthorized('Terminal não identificado.');
    const terminal = await terminals.findById(id);
    if (!terminal || !conferirChave(chave, terminal.chaveHash)) throw unauthorized('Terminal não identificado.');
    req.terminal = terminal;
    next();
  };
}

export function terminalDe(req: Request): Terminal {
  if (!req.terminal) throw unauthorized('Terminal não identificado.');
  return req.terminal;
}
