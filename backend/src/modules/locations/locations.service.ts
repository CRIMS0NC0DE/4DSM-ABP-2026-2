import { notFound } from '../../shared/errors.js';
import type { AccessPoint, Building, Door, Gate, LocationsRepository } from './locations.types.js';

/** RF02: edifício › portaria › porta › catraca. */
export class LocationsService {
  constructor(private readonly locations: LocationsRepository) {}

  arvore() {
    return this.locations.tree();
  }

  criarEdificio(dados: Omit<Building, 'id'>) {
    return this.locations.createBuilding(dados);
  }

  async criarPortaria(dados: Omit<Gate, 'id'>) {
    if (!(await this.locations.findBuilding(dados.buildingId))) throw notFound('Edifício');
    return this.locations.createGate(dados);
  }

  async criarPorta(dados: Omit<Door, 'id'>) {
    if (!(await this.locations.findGate(dados.gateId))) throw notFound('Portaria');
    return this.locations.createDoor(dados);
  }

  async criarCatraca(dados: Omit<AccessPoint, 'id'>) {
    if (!(await this.locations.findDoor(dados.doorId))) throw notFound('Porta');
    return this.locations.createAccessPoint(dados);
  }

  async buscarCatraca(id: string) {
    const catraca = await this.locations.findAccessPoint(id);
    if (!catraca) throw notFound('Catraca');
    return catraca;
  }

  async atualizarCatraca(id: string, dados: Partial<Omit<AccessPoint, 'id'>>) {
    await this.buscarCatraca(id);
    if (dados.doorId && !(await this.locations.findDoor(dados.doorId))) throw notFound('Porta');
    return this.locations.updateAccessPoint(id, dados);
  }
}
