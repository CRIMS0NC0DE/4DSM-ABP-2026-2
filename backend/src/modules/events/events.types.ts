export type MetodoAcesso = 'QR' | 'NFC';
export type ResultadoAcesso = 'LIBERADO' | 'NEGADO';

export interface AccessEvent {
  id: string;
  metodo: MetodoAcesso;
  resultado: ResultadoAcesso;
  motivo: string | null;
  userId: string | null;
  accessPointId: string | null;
  terminalId: string | null;
  authorizationId: string | null;
  credencial: string | null;
  latitude: number | null;
  longitude: number | null;
  distanciaMetros: number | null;
  createdAt: Date;
}

export type NewAccessEvent = Omit<AccessEvent, 'id' | 'createdAt'>;

export type AccessEventView = AccessEvent & {
  user: { id: string; nome: string } | null;
  catraca: { id: string; nome: string } | null;
};

export interface EventFilter {
  de?: Date;
  ate?: Date;
  resultado?: ResultadoAcesso;
  metodo?: MetodoAcesso;
  userId?: string;
  accessPointId?: string;
  limite: number;
  pular: number;
}

export interface EventPage {
  itens: AccessEventView[];
  total: number;
  liberados: number;
  negados: number;
}

export interface EventsRepository {
  create(data: NewAccessEvent): Promise<AccessEvent>;
  list(filter: EventFilter): Promise<EventPage>;
}

/** Guarda os QR já usados para que não sirvam de novo. */
export interface QrTokenStore {
  /** Devolve false se o token já tinha sido usado. */
  marcarUsado(jti: string): Promise<boolean>;
}
