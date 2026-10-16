export type StatusAutorizacao = 'ATIVA' | 'CANCELADA';

/** Situação calculada a partir do status, das datas e dos usos. */
export type SituacaoAutorizacao = 'ATIVA' | 'AGENDADA' | 'EXPIRADA' | 'ESGOTADA' | 'CANCELADA';

export interface Authorization {
  id: string;
  userId: string;
  accessPointId: string;
  /** YYYY-MM-DD */
  dataInicio: string;
  /** YYYY-MM-DD */
  dataFim: string;
  /** HH:MM */
  horaInicio: string;
  /** HH:MM */
  horaFim: string;
  maxUsos: number;
  usosRealizados: number;
  status: StatusAutorizacao;
  canceladaEm: Date | null;
  createdAt: Date;
}

export type AuthorizationWithRefs = Authorization & {
  user: { id: string; nome: string; perfil: string };
  catraca: { id: string; nome: string };
};

export type NewAuthorization = Pick<
  Authorization,
  'userId' | 'accessPointId' | 'dataInicio' | 'dataFim' | 'horaInicio' | 'horaFim' | 'maxUsos'
>;

export interface AuthorizationFilter {
  userId?: string;
  accessPointId?: string;
  /** "ATIVA" = não cancelada e ainda dentro da data; "EXPIRADA" = não cancelada e já passou. */
  situacao?: 'ATIVA' | 'EXPIRADA' | 'CANCELADA';
  /** Data de hoje (YYYY-MM-DD) no fuso do prédio, usada pelo filtro de situação. */
  hoje: string;
  /** Autorizações que valem em algum dia do intervalo. */
  de?: string;
  ate?: string;
}

export interface AuthorizationsRepository {
  create(data: NewAuthorization): Promise<AuthorizationWithRefs>;
  findById(id: string): Promise<AuthorizationWithRefs | null>;
  list(filter: AuthorizationFilter): Promise<AuthorizationWithRefs[]>;
  listForAccess(userId: string, accessPointId: string): Promise<Authorization[]>;
  update(id: string, data: Partial<NewAuthorization> & { status?: StatusAutorizacao; canceladaEm?: Date | null }): Promise<AuthorizationWithRefs>;
  /** Soma um uso só se ainda houver usos disponíveis. Atômico: devolve false se esgotou. */
  consumirUso(id: string): Promise<boolean>;
}
