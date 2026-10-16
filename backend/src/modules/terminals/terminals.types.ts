export interface Terminal {
  id: string;
  nome: string;
  accessPointId: string;
  chaveHash: string;
  ultimoSinal: Date | null;
  latitude: number | null;
  longitude: number | null;
}

export interface TerminalsRepository {
  create(data: { nome: string; accessPointId: string; chaveHash: string }): Promise<Terminal>;
  findById(id: string): Promise<Terminal | null>;
  findByAccessPoint(accessPointId: string): Promise<Terminal | null>;
  list(): Promise<Terminal[]>;
  update(id: string, data: Partial<Omit<Terminal, 'id' | 'accessPointId'>>): Promise<Terminal>;
}
