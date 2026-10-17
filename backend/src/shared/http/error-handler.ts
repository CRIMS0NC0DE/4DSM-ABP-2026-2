import type { ErrorRequestHandler, RequestHandler } from 'express';
import { AppError } from '../errors.js';

export const notFoundHandler: RequestHandler = (req, res) => {
  res.status(404).json({ erro: { codigo: 'ROTA_NAO_ENCONTRADA', mensagem: `${req.method} ${req.path} não existe.` } });
};

export const errorHandler: ErrorRequestHandler = (err, _req, res, _next) => {
  if (err instanceof AppError) {
    res.status(err.status).json({ erro: { codigo: err.code, mensagem: err.message, detalhes: err.details } });
    return;
  }
  if ((err as { type?: string }).type === 'entity.parse.failed') {
    res.status(400).json({ erro: { codigo: 'JSON_INVALIDO', mensagem: 'O corpo da requisição não é um JSON válido.' } });
    return;
  }
  console.error(err);
  res.status(500).json({ erro: { codigo: 'ERRO_INTERNO', mensagem: 'Erro interno. Tente novamente.' } });
};
