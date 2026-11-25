export interface Comunicado {
  id: string;
  titulo: string;
  mensagem: string;
  autorId: string | null;
  createdAt: Date;
}

export type NovoComunicado = Pick<Comunicado, 'titulo' | 'mensagem' | 'autorId'>;

/** Como as rotas devolvem: com o nome de quem escreveu (null se a conta foi apagada). */
export type ComunicadoView = Comunicado & { autor: { id: string; nome: string } | null };

export interface AnnouncementsRepository {
  /** Mais recentes primeiro. */
  list(limite: number): Promise<ComunicadoView[]>;
  create(data: NovoComunicado): Promise<ComunicadoView>;
  findById(id: string): Promise<Comunicado | null>;
  remove(id: string): Promise<void>;
}
