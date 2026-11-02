import { MOTIVOS, type MotivoNegacao } from '../access/access.rules.js';
import type { AccessEventView, EventFilter, EventsRepository } from './events.types.js';

/** RF06: histórico das tentativas de acesso. */
function comTexto(evento: AccessEventView) {
  const texto = evento.motivo ? MOTIVOS[evento.motivo as MotivoNegacao] : undefined;
  return { ...evento, titulo: texto?.titulo ?? null, oQueFazer: texto?.oQueFazer ?? null };
}

export class EventsService {
  constructor(private readonly events: EventsRepository) {}

  listar(filtro: EventFilter) {
    return this.events.list(filtro);
  }

  /** Números do painel (A1): acessos e negados desde um instante (ex.: meia-noite de hoje). */
  async resumo(desde: Date) {
    const pagina = await this.events.list({ de: desde, limite: 5, pular: 0, resultado: 'NEGADO' });
    const todos = await this.events.list({ de: desde, limite: 0, pular: 0 });
    return {
      acessosHoje: todos.liberados,
      negadosHoje: todos.negados,
      negadosRecentes: pagina.itens.map(comTexto),
    };
  }
}
