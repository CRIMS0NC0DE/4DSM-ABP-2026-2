import type { Clock } from './shared/clock.js';
import { AccessService } from './modules/access/access.service.js';
import { AuthService } from './modules/auth/auth.service.js';
import type { AuthorizationsRepository } from './modules/authorizations/authorizations.types.js';
import { AuthorizationsService } from './modules/authorizations/authorizations.service.js';
import type { EventsRepository, QrTokenStore } from './modules/events/events.types.js';
import { EventsService } from './modules/events/events.service.js';
import type { LocationsRepository } from './modules/locations/locations.types.js';
import { LocationsService } from './modules/locations/locations.service.js';
import type { SimuladorConfig } from './modules/simulador/simulador.router.js';
import { QrTokenService } from './modules/terminals/qr-token.js';
import { CompositeTerminalNotifier, InMemoryTerminalNotifier, type TerminalNotifier } from './modules/terminals/terminal-notifier.js';
import type { TerminalsRepository } from './modules/terminals/terminals.types.js';
import { TerminalsService } from './modules/terminals/terminals.service.js';
import type { UsersRepository } from './modules/users/users.types.js';
import { UsersService } from './modules/users/users.service.js';

export interface Repositories {
  users: UsersRepository;
  locations: LocationsRepository;
  terminals: TerminalsRepository;
  authorizations: AuthorizationsRepository;
  events: EventsRepository;
  qrTokens: QrTokenStore;
}

export interface AppConfig {
  jwtSecret: string;
  jwtExpiresIn: string;
  qrSecret: string;
  qrTtlSeconds: number;
  qrRotationSeconds: number;
  timezone: string;
  corsOrigin: string;
  simulador?: SimuladorConfig;
}

export interface Container {
  config: AppConfig;
  clock: Clock;
  repos: Repositories;
  decisoes: InMemoryTerminalNotifier;
  services: {
    auth: AuthService;
    users: UsersService;
    locations: LocationsService;
    terminals: TerminalsService;
    authorizations: AuthorizationsService;
    access: AccessService;
    events: EventsService;
  };
}

/** Liga repositórios e serviços. A produção usa Prisma; os testes, repositórios em memória. */
export function createContainer(
  repos: Repositories,
  config: AppConfig,
  clock: Clock,
  notificadoresExtras: TerminalNotifier[] = [],
): Container {
  const qr = new QrTokenService(
    { secret: config.qrSecret, ttlSeconds: config.qrTtlSeconds, rotationSeconds: config.qrRotationSeconds },
    clock,
  );
  const decisoes = new InMemoryTerminalNotifier();
  const notifier = new CompositeTerminalNotifier([decisoes, ...notificadoresExtras]);

  return {
    config,
    clock,
    repos,
    decisoes,
    services: {
      auth: new AuthService(repos.users, { secret: config.jwtSecret, expiresIn: config.jwtExpiresIn }),
      users: new UsersService(repos.users),
      locations: new LocationsService(repos.locations),
      terminals: new TerminalsService(repos.terminals, repos.locations, qr, clock),
      authorizations: new AuthorizationsService(repos.authorizations, repos.users, repos.locations, clock, config.timezone),
      access: new AccessService({ ...repos, qr, notifier, clock, timezone: config.timezone }),
      events: new EventsService(repos.events),
    },
  };
}
