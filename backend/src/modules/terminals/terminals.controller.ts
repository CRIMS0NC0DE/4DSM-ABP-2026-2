import { Router, type RequestHandler } from 'express';
import { z } from 'zod';
import { terminalDe } from '../../shared/http/auth.js';
import { id, idParam, latitude, longitude } from '../../shared/http/schemas.js';
import { parse } from '../../shared/http/validate.js';
import type { AccessService } from '../access/access.service.js';
import type { InMemoryTerminalNotifier } from './terminal-notifier.js';
import type { TerminalsService } from './terminals.service.js';

const cadastroSchema = z.object({ nome: z.string().trim().min(1), accessPointId: id });

/** Gestão dos terminais pela equipe. */
export function terminalsRouter(terminals: TerminalsService, somenteAdmin: RequestHandler) {
  const router = Router();

  router.get('/', async (_req, res) => {
    res.json(await terminals.listar());
  });

  router.post('/', somenteAdmin, async (req, res) => {
    res.status(201).json(await terminals.cadastrar(parse(cadastroSchema, req.body)));
  });

  router.post('/:id/rotate-key', somenteAdmin, async (req, res) => {
    res.json(await terminals.trocarChave(parse(idParam, req.params).id));
  });

  return router;
}

const sinalSchema = z.object({ latitude: latitude.optional(), longitude: longitude.optional() });
const nfcSchema = z.object({ uid: z.string().trim().min(4).max(40) });
const decisoesSchema = z.object({ apos: z.coerce.number().int().min(0).default(0) });

/**
 * API usada pelo próprio dispositivo (ESP32 ou simulador).
 * Montado atrás de autenticarTerminal (cabeçalhos X-Terminal-Id e X-Terminal-Key).
 */
export function deviceRouter(terminals: TerminalsService, access: AccessService, decisoes: InMemoryTerminalNotifier) {
  const router = Router();

  // RF12: o terminal pede um QR novo a cada 10 s.
  router.get('/qr-token', (req, res) => {
    res.json(terminals.qrToken(terminalDe(req)));
  });

  router.post('/heartbeat', async (req, res) => {
    res.json(await terminals.sinal(terminalDe(req), parse(sinalSchema, req.body ?? {})));
  });

  // RF14: leu uma tag; a resposta já diz se abre ou não.
  router.post('/nfc', async (req, res) => {
    res.json(await access.validarNfc(terminalDe(req), parse(nfcSchema, req.body).uid));
  });

  // Decisões dos acessos por QR, para terminais sem MQTT (consulta periódica).
  router.get('/decisions', (req, res) => {
    const { apos } = parse(decisoesSchema, req.query);
    res.json(decisoes.desde(terminalDe(req).id, apos));
  });

  return router;
}
