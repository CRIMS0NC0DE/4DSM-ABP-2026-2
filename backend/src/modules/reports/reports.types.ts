import type { MetodoAcesso } from '../events/events.types.js';

export interface FiltroRelatorio {
  /** YYYY-MM-DD; padrão: 6 dias antes de "ate" (uma semana contando hoje). */
  de?: string;
  /** YYYY-MM-DD; padrão: hoje no fuso do prédio. */
  ate?: string;
  accessPointId?: string;
}

export interface Contagem {
  liberados: number;
  negados: number;
}

export interface RelatorioAcessos extends Contagem {
  de: string;
  ate: string;
  total: number;
  /** Todos os dias do período, em ordem, inclusive os zerados. */
  porDia: (Contagem & { dia: string })[];
  /** Sempre os três métodos, nessa ordem: QR, NFC, CELULAR. */
  porMetodo: (Contagem & { metodo: MetodoAcesso })[];
  /** Maior total primeiro. catraca null = evento sem catraca (QR inválido, catraca apagada). */
  porCatraca: (Contagem & { catraca: { id: string; nome: string } | null })[];
  /** Só os negados, maior total primeiro. */
  porMotivo: { motivo: string; titulo: string; total: number }[];
}
