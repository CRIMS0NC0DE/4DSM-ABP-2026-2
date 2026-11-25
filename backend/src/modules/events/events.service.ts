import { fimDoDiaLocal, inicioDoDiaLocal } from '../../shared/clock.js';
import { MOTIVOS, type MotivoNegacao } from '../access/access.rules.js';
import type {
  AccessEventComTexto,
  AccessEventView,
  EventPageComTexto,
  EventsRepository,
  FiltroEventos,
} from './events.types.js';

function comTexto(evento: AccessEventView): AccessEventComTexto {
  const texto = evento.motivo ? MOTIVOS[evento.motivo as MotivoNegacao] : undefined;
  return { ...evento, titulo: texto?.titulo ?? null, oQueFazer: texto?.oQueFazer ?? null };
}

/** RF06: histórico das tentativas de acesso. */
export class EventsService {
  constructor(
    private readonly events: EventsRepository,
    private readonly timezone: string,
  ) {}

  async listar(filtro: FiltroEventos): Promise<EventPageComTexto> {
    // "ate=2026-10-14" vale até 23:59:59.999 no fuso do prédio, e não só até a meia-noite UTC que abre o dia.
    const { de, ate } = filtro;
    const pagina = await this.events.list({
      ...filtro,
      de: typeof de === 'string' ? inicioDoDiaLocal(de, this.timezone) : de,
      ate: typeof ate === 'string' ? fimDoDiaLocal(ate, this.timezone) : ate,
    });
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
