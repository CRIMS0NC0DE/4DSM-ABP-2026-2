import { Router } from 'express';
import { z } from 'zod';
import { authDe } from '../../shared/http/auth.js';
import { latitude, longitude } from '../../shared/http/schemas.js';
import { parse } from '../../shared/http/validate.js';
import type { AccessService } from './access.service.js';

const qrSchema = z.object({
  token: z.string().min(10, 'QR Code inválido').max(2000),
  latitude: latitude.optional(),
  longitude: longitude.optional(),
});

/** RF13: o app leu o QR do terminal e pergunta se pode passar. */
export function accessRouter(access: AccessService) {
  const router = Router();

  router.post('/qr', async (req, res) => {
    res.json(await access.validarQr(authDe(req).userId, parse(qrSchema, req.body)));
  });

  return router;
}
