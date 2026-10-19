export class AppError extends Error {
  constructor(
    public readonly status: number,
    public readonly code: string,
    message: string,
    public readonly details?: unknown,
  ) {
    super(message);
    this.name = 'AppError';
  }
}

export const badRequest = (message: string, details?: unknown) =>
  new AppError(400, 'DADOS_INVALIDOS', message, details);

export const unauthorized = (message = 'Faça login para continuar.') =>
  new AppError(401, 'NAO_AUTENTICADO', message);

export const forbidden = (message = 'Você não tem permissão para esta ação.') =>
  new AppError(403, 'SEM_PERMISSAO', message);

export const notFound = (what: string) => new AppError(404, 'NAO_ENCONTRADO', `${what} não encontrado(a).`);

export const conflict = (message: string) => new AppError(409, 'CONFLITO', message);
