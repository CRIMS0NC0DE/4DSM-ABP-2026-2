import { timeToMinutes, type LocalDateTime } from '../../shared/clock.js';
import type { Authorization, SituacaoAutorizacao } from '../authorizations/authorizations.types.js';

export type MotivoNegacao =
  | 'QR_INVALIDO'
  | 'QR_EXPIRADO'
  | 'QR_JA_UTILIZADO'
  | 'TERMINAL_DESCONHECIDO'
  | 'TAG_DESCONHECIDA'
  | 'TAG_BLOQUEADA'
  | 'USUARIO_INATIVO'
  | 'SEM_AUTORIZACAO'
  | 'AUTORIZACAO_CANCELADA'
  | 'AUTORIZACAO_EXPIRADA'
  | 'AUTORIZACAO_NAO_INICIADA'
  | 'FORA_DO_HORARIO'
  | 'SEM_USOS'
  | 'LOCALIZACAO_AUSENTE'
  | 'LONGE_DO_TERMINAL';

/** Textos das telas de "Acesso negado" do design (N1 a N4, U6). */
export const MOTIVOS: Record<MotivoNegacao, { titulo: string; oQueFazer: string }> = {
  QR_INVALIDO: { titulo: 'QR Code não reconhecido', oQueFazer: 'Escaneie o QR que aparece na tela da catraca.' },
  QR_EXPIRADO: { titulo: 'O QR Code já mudou', oQueFazer: 'Escaneie o código novo que está na tela.' },
  QR_JA_UTILIZADO: { titulo: 'Este QR Code já foi usado', oQueFazer: 'Espere o código novo aparecer e escaneie de novo.' },
  TERMINAL_DESCONHECIDO: { titulo: 'Catraca não cadastrada', oQueFazer: 'Fale com a portaria.' },
  TAG_DESCONHECIDA: { titulo: 'Tag não cadastrada', oQueFazer: 'Peça para a portaria vincular sua tag.' },
  TAG_BLOQUEADA: { titulo: 'Sua tag está bloqueada', oQueFazer: 'Fale com a portaria.' },
  USUARIO_INATIVO: { titulo: 'Seu cadastro está desativado', oQueFazer: 'Fale com a portaria.' },
  SEM_AUTORIZACAO: { titulo: 'Você não tem autorização para esta catraca', oQueFazer: 'Peça uma autorização à portaria.' },
  AUTORIZACAO_CANCELADA: { titulo: 'Sua autorização foi cancelada', oQueFazer: 'Fale com a portaria para saber mais.' },
  AUTORIZACAO_EXPIRADA: { titulo: 'Sua autorização expirou', oQueFazer: 'Peça uma nova autorização à portaria.' },
  AUTORIZACAO_NAO_INICIADA: { titulo: 'Sua autorização ainda não começou', oQueFazer: 'Volte na data de início.' },
  FORA_DO_HORARIO: { titulo: 'Fora do horário permitido', oQueFazer: 'Volte dentro do horário ou fale com a portaria.' },
  SEM_USOS: { titulo: 'Você não tem mais usos', oQueFazer: 'Peça mais usos à portaria.' },
  LOCALIZACAO_AUSENTE: { titulo: 'Não conseguimos sua localização', oQueFazer: 'Permita a localização no celular e tente de novo.' },
  LONGE_DO_TERMINAL: { titulo: 'Você está longe da catraca', oQueFazer: 'Chegue mais perto da catraca e tente de novo.' },
};

/** Dentro do horário? Aceita janelas que passam da meia-noite (ex.: 22:00 às 06:00). */
export function dentroDoHorario(horaInicio: string, horaFim: string, minutosAgora: number): boolean {
  const inicio = timeToMinutes(horaInicio);
  const fim = timeToMinutes(horaFim);
  if (inicio <= fim) return minutosAgora >= inicio && minutosAgora < fim;
  return minutosAgora >= inicio || minutosAgora < fim;
}

/** Devolve o motivo de a autorização não valer agora, ou null se vale. */
export function avaliarAutorizacao(a: Authorization, agora: LocalDateTime): MotivoNegacao | null {
  if (a.status === 'CANCELADA') return 'AUTORIZACAO_CANCELADA';
  if (agora.date > a.dataFim) return 'AUTORIZACAO_EXPIRADA';
  if (agora.date < a.dataInicio) return 'AUTORIZACAO_NAO_INICIADA';
  if (!dentroDoHorario(a.horaInicio, a.horaFim, agora.minutes)) return 'FORA_DO_HORARIO';
  if (a.usosRealizados >= a.maxUsos) return 'SEM_USOS';
  return null;
}

// Quando nenhuma autorização vale, mostra o motivo da que "chegou mais perto".
const PROXIMIDADE: Partial<Record<MotivoNegacao, number>> = {
  AUTORIZACAO_CANCELADA: 1,
  AUTORIZACAO_EXPIRADA: 2,
  AUTORIZACAO_NAO_INICIADA: 3,
  FORA_DO_HORARIO: 4,
  SEM_USOS: 5,
};

export type Escolha = { autorizacao: Authorization; motivo?: never } | { autorizacao?: never; motivo: MotivoNegacao };

export function escolherAutorizacao(candidatas: Authorization[], agora: LocalDateTime): Escolha {
  let melhorMotivo: MotivoNegacao = 'SEM_AUTORIZACAO';
  for (const a of candidatas) {
    const motivo = avaliarAutorizacao(a, agora);
    if (motivo === null) return { autorizacao: a };
    if ((PROXIMIDADE[motivo] ?? 0) > (PROXIMIDADE[melhorMotivo] ?? 0)) melhorMotivo = motivo;
  }
  return { motivo: melhorMotivo };
}

export function situacaoDe(a: Authorization, hoje: string): SituacaoAutorizacao {
  if (a.status === 'CANCELADA') return 'CANCELADA';
  if (hoje > a.dataFim) return 'EXPIRADA';
  if (a.usosRealizados >= a.maxUsos) return 'ESGOTADA';
  if (hoje < a.dataInicio) return 'AGENDADA';
  return 'ATIVA';
}
