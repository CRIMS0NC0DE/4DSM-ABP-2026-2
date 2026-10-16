import type { EventFilter, EventsRepository } from './events.types.js';

/** RF06: histórico das tentativas de acesso. */
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
      negadosRecentes: pagina.itens,
    };
  }
}
