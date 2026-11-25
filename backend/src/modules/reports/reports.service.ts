import { dateOnlyToDate, fimDoDiaLocal, inicioDoDiaLocal, somarDias, toLocal, type Clock } from '../../shared/clock.js';
import { badRequest } from '../../shared/errors.js';
import { MOTIVOS, type MotivoNegacao } from '../access/access.rules.js';
import type { EventsRepository, MetodoAcesso } from '../events/events.types.js';
import type { Contagem, FiltroRelatorio, RelatorioAcessos } from './reports.types.js';

/** Um ano, contando o bissexto: o relatório traz todos os eventos do período e agrupa aqui. */
export const MAX_DIAS_RELATORIO = 366;

const METODOS: MetodoAcesso[] = ['QR', 'NFC', 'CELULAR'];

const invalido = (campo: string, mensagem: string) => badRequest(mensagem, { [campo]: [mensagem] });

/** Posição do último começo de dia que não passa do instante (busca binária). */
function indiceDoDia(inicios: number[], instante: number): number {
  let baixo = 0;
  let alto = inicios.length - 1;
  while (baixo < alto) {
    const meio = Math.ceil((baixo + alto) / 2);
    if (inicios[meio]! <= instante) baixo = meio;
    else alto = meio - 1;
  }
  return baixo;
}

const total = (c: Contagem) => c.liberados + c.negados;

/** Relatório agregado dos acessos, com os dias contados no fuso do prédio. */
export class ReportsService {
  constructor(
    private readonly events: Pick<EventsRepository, 'listForReport'>,
    private readonly clock: Clock,
    private readonly timezone: string,
  ) {}

  async acessos(filtro: FiltroRelatorio): Promise<RelatorioAcessos> {
    const ate = filtro.ate ?? toLocal(this.clock.now(), this.timezone).date;
    const de = filtro.de ?? somarDias(ate, -6);
    if (de > ate) throw invalido('de', 'A data inicial precisa ser antes da data final.');
    const quantidade = (dateOnlyToDate(ate).getTime() - dateOnlyToDate(de).getTime()) / 86_400_000 + 1;
    if (quantidade > MAX_DIAS_RELATORIO) throw invalido('ate', `Escolha um período de até ${MAX_DIAS_RELATORIO} dias.`);

    const dias = Array.from({ length: quantidade }, (_, i) => somarDias(de, i));
    // O mesmo começo de dia filtra a consulta e separa os eventos: um evento às 23:30 fica no seu dia.
    const inicios = dias.map((dia) => inicioDoDiaLocal(dia, this.timezone).getTime());
    const linhas = await this.events.listForReport({
      de: new Date(inicios[0]!),
      ate: fimDoDiaLocal(ate, this.timezone),
      accessPointId: filtro.accessPointId,
    });

    const porDia = dias.map((dia) => ({ dia, liberados: 0, negados: 0 }));
    const porMetodo = METODOS.map((metodo) => ({ metodo, liberados: 0, negados: 0 }));
    const porCatraca = new Map<string | null, Contagem & { catraca: { id: string; nome: string } | null }>();
    const porMotivo = new Map<string, number>();

    for (const linha of linhas) {
      const campo = linha.resultado === 'LIBERADO' ? 'liberados' : 'negados';
      porDia[indiceDoDia(inicios, linha.createdAt.getTime())]![campo] += 1;
      const metodo = porMetodo.find((m) => m.metodo === linha.metodo);
      if (metodo) metodo[campo] += 1;

      const catraca = linha.accessPointId && linha.catraca ? { id: linha.accessPointId, nome: linha.catraca.nome } : null;
      const daCatraca = porCatraca.get(catraca?.id ?? null) ?? { catraca, liberados: 0, negados: 0 };
      daCatraca[campo] += 1;
      porCatraca.set(catraca?.id ?? null, daCatraca);

      if (linha.resultado === 'NEGADO' && linha.motivo) porMotivo.set(linha.motivo, (porMotivo.get(linha.motivo) ?? 0) + 1);
    }

    const liberados = porDia.reduce((soma, d) => soma + d.liberados, 0);
    const negados = porDia.reduce((soma, d) => soma + d.negados, 0);
    return {
      de,
      ate,
      total: liberados + negados,
      liberados,
      negados,
      porDia,
      porMetodo,
      // No empate, por nome; "sem catraca" por último.
      porCatraca: [...porCatraca.values()].sort(
        (a, b) =>
          total(b) - total(a) ||
          Number(!a.catraca) - Number(!b.catraca) ||
          (a.catraca?.nome ?? '').localeCompare(b.catraca?.nome ?? '', 'pt-BR'),
      ),
      porMotivo: [...porMotivo]
        .map(([motivo, vezes]) => ({ motivo, titulo: MOTIVOS[motivo as MotivoNegacao]?.titulo ?? motivo, total: vezes }))
        .sort((a, b) => b.total - a.total || a.titulo.localeCompare(b.titulo, 'pt-BR')),
    };
  }
}
