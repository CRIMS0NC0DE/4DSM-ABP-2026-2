export interface Building {
  id: string;
  nome: string;
  endereco: string;
}

export interface Gate {
  id: string;
  nome: string;
  buildingId: string;
}

export interface Door {
  id: string;
  nome: string;
  gateId: string;
}

/** Catraca */
export interface AccessPoint {
  id: string;
  nome: string;
  doorId: string;
  latitude: number;
  longitude: number;
  raioMetros: number;
}

export type LocationTree = (Building & {
  portarias: (Gate & { portas: (Door & { catracas: AccessPoint[] })[] })[];
})[];

/** Catraca com o caminho completo, ex.: "Edifício Atlântico › Portaria Principal › Porta A". */
export type AccessPointDetalhe = AccessPoint & { edificio: string; portaria: string; porta: string };

export interface LocationsRepository {
  tree(): Promise<LocationTree>;
  createBuilding(data: Omit<Building, 'id'>): Promise<Building>;
  createGate(data: Omit<Gate, 'id'>): Promise<Gate>;
  createDoor(data: Omit<Door, 'id'>): Promise<Door>;
  createAccessPoint(data: Omit<AccessPoint, 'id'>): Promise<AccessPoint>;
  updateAccessPoint(id: string, data: Partial<Omit<AccessPoint, 'id'>>): Promise<AccessPoint>;
  updateBuilding(id: string, data: Partial<Omit<Building, 'id'>>): Promise<Building>;
  updateGate(id: string, data: { nome?: string }): Promise<Gate>;
  updateDoor(id: string, data: { nome?: string }): Promise<Door>;
  /**
   * Apagam só o que não tem filhos (a catraca: nem terminal, nem autorizações) e devolvem false
   * quando não apagaram. Os eventos de acesso ficam, sem a catraca (accessPointId = null).
   */
  removeBuilding(id: string): Promise<boolean>;
  removeGate(id: string): Promise<boolean>;
  removeDoor(id: string): Promise<boolean>;
  removeAccessPoint(id: string): Promise<boolean>;
  findBuilding(id: string): Promise<Building | null>;
  findGate(id: string): Promise<Gate | null>;
  findDoor(id: string): Promise<Door | null>;
  findAccessPoint(id: string): Promise<AccessPointDetalhe | null>;
}
