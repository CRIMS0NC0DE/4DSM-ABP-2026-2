import { MOTIVOS, type MotivoNegacao } from '../access/access.rules.js';
import type {
  AccessEventComTexto,
  AccessEventView,
  EventFilter,
  EventPageComTexto,
  EventsRepository,
} from './events.types.js';

function comTexto(evento: AccessEventView): AccessEventComTexto {
  const texto = evento.motivo ? MOTIVOS[evento.motivo as MotivoNegacao] : undefined;
  return { ...evento, titulo: texto?.titulo ?? null, oQueFazer: texto?.oQueFazer ?? null };
}

/** RF06: histórico das tentativas de acesso. */
export class EventsService {
  constructor(private readonly events: EventsRepository) {}

  async listar(filtro: EventFilter): Promise<EventPageComTexto> {
    const pagina = await this.events.list(filtro);
    return { ...pagina, itens: pagina.itens.map(comTexto) };
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
