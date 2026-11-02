import type { ErrorRequestHandler, RequestHandler } from 'express';
import { AppError } from '../errors.js';

export const notFoundHandler: RequestHandler = (req, res) => {
  res.status(404).json({ erro: { codigo: 'ROTA_NAO_ENCONTRADA', mensagem: `${req.method} ${req.path} não existe.` } });
};

function erroDoCliente(status: number) {
  if (status === 413) return { codigo: 'CORPO_GRANDE_DEMAIS', mensagem: 'O corpo da requisição é grande demais.' };
  if (status === 415) return { codigo: 'CORPO_NAO_SUPORTADO', mensagem: 'O formato do corpo da requisição não é aceito.' };
  return { codigo: 'REQUISICAO_INVALIDA', mensagem: 'A requisição é inválida.' };
}

export const errorHandler: ErrorRequestHandler = (err, _req, res, _next) => {
  if (err instanceof AppError) {
    res.status(err.status).json({ erro: { codigo: err.code, mensagem: err.message, detalhes: err.details } });
    return;
  }
  if ((err as { type?: string }).type === 'entity.parse.failed') {
    res.status(400).json({ erro: { codigo: 'JSON_INVALIDO', mensagem: 'O corpo da requisição não é um JSON válido.' } });
    return;
  }
  // Corpo grande demais, charset desconhecido, URL malformada...: erro de quem chamou, não do servidor.
  const status = (err as { status?: unknown }).status;
  if (typeof status === 'number' && status >= 400 && status < 500) {
    res.status(status).json({ erro: erroDoCliente(status) });
    return;
  }
  console.error(err);
  res.status(500).json({ erro: { codigo: 'ERRO_INTERNO', mensagem: 'Erro interno. Tente novamente.' } });
};
