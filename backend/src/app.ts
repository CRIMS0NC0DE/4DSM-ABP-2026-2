import { fileURLToPath } from 'node:url';
import cors from 'cors';
import express, { Router } from 'express';
import helmet from 'helmet';
import type { Container } from './container.js';
import { accessRouter } from './modules/access/access.controller.js';
import { authRouter } from './modules/auth/auth.controller.js';
import { authorizationsRouter } from './modules/authorizations/authorizations.controller.js';
import { eventsRouter, filtroEventosSchema } from './modules/events/events.controller.js';
import { locationsRouter } from './modules/locations/locations.controller.js';
import { deviceRouter, terminalsRouter } from './modules/terminals/terminals.controller.js';
import { usersRouter } from './modules/users/users.controller.js';
import { simuladorRouter } from './modules/simulador/simulador.router.js';
import { PERFIS_EQUIPE } from './modules/users/users.types.js';
import { toLocal } from './shared/clock.js';
import { authDe, autenticar, autenticarTerminal, exigirPerfil } from './shared/http/auth.js';
import { errorHandler, notFoundHandler } from './shared/http/error-handler.js';
import { parse } from './shared/http/validate.js';

export function createApp(c: Container) {
  const { services } = c;
  const app = express();

  app.disable('x-powered-by');
  app.use(helmet());
  app.use(cors({ origin: c.config.corsOrigin === '*' ? true : c.config.corsOrigin.split(',') }));
  app.use(express.json({ limit: '100kb' }));

  const autenticado = autenticar(c.config.jwtSecret);
  const equipe = [autenticado, exigirPerfil(...PERFIS_EQUIPE)];
  const somenteAdmin = exigirPerfil('ADMIN');

  app.get('/health', (_req, res) => {
    res.json({ status: 'ok', em: c.clock.now().toISOString() });
  });

  // App: qualquer pessoa logada
  app.use('/auth', authRouter(services.auth, services.users, autenticado));
  app.use('/me', autenticado, meRouter(c));
  app.use('/access', autenticado, accessRouter(services.access));

  // App: administração (admin e portaria)
  app.use('/users', ...equipe, usersRouter(services.users));
  app.use('/locations', ...equipe, locationsRouter(services.locations, somenteAdmin));
  app.use('/authorizations', ...equipe, authorizationsRouter(services.authorizations));
  app.use('/access-events', ...equipe, eventsRouter(services.events));
  app.use('/terminals', ...equipe, terminalsRouter(services.terminals, somenteAdmin));
  app.get('/dashboard', ...equipe, async (_req, res) => {
    const meiaNoite = inicioDoDia(c);
    const [resumo, ativas] = await Promise.all([
      services.events.resumo(meiaNoite),
      services.authorizations.listar({ situacao: 'ATIVA' }),
    ]);
    res.json({ ...resumo, autorizacoesAtivas: ativas.length });
  });

  // Dispositivo IoT
  app.use('/terminal', autenticarTerminal(c.repos.terminals), deviceRouter(services.terminals, services.access, c.decisoes));
  app.use('/simulador', simuladorRouter(c.config.simulador ?? {}));
  // Console web de testes: as telas do app para quem não roda o Flutter. Só arquivos estáticos; a API é a mesma.
  app.use('/console', express.static(fileURLToPath(new URL('../public/console/', import.meta.url))));

  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
}

function meRouter(c: Container) {
  const router = Router();

  // RF08
  router.get('/authorizations', async (req, res) => {
    res.json(await c.services.authorizations.minhas(authDe(req).userId));
  });

  router.get('/access-events', async (req, res) => {
    const filtro = parse(filtroEventosSchema.omit({ userId: true }), req.query);
    res.json(await c.services.events.listar({ ...filtro, userId: authDe(req).userId }));
  });

  return router;
}

/** Meia-noite de hoje no fuso do prédio, como instante UTC. */
function inicioDoDia(c: Container): Date {
  const agora = c.clock.now();
  const local = toLocal(agora, c.config.timezone);
  return new Date(agora.getTime() - local.minutes * 60_000 - agora.getUTCSeconds() * 1000 - agora.getUTCMilliseconds());
}
