import { conflict, notFound } from '../../shared/errors.js';
import type { TerminalsRepository } from '../terminals/terminals.types.js';
import type { AccessPoint, Building, Door, Gate, LocationsRepository } from './locations.types.js';

/** RF02: edifício › portaria › porta › catraca. */
export class LocationsService {
  constructor(
    private readonly locations: LocationsRepository,
    private readonly terminals: Pick<TerminalsRepository, 'findByAccessPoint'>,
  ) {}

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

  async atualizarEdificio(id: string, dados: Partial<Omit<Building, 'id'>>) {
    if (!(await this.locations.findBuilding(id))) throw notFound('Edifício');
    return this.locations.updateBuilding(id, dados);
  }

  async atualizarPortaria(id: string, dados: { nome?: string }) {
    if (!(await this.locations.findGate(id))) throw notFound('Portaria');
    return this.locations.updateGate(id, dados);
  }

  async atualizarPorta(id: string, dados: { nome?: string }) {
    if (!(await this.locations.findDoor(id))) throw notFound('Porta');
    return this.locations.updateDoor(id, dados);
  }

  // Apagar só vale de baixo para cima: o banco apagaria os filhos em cascata, e com eles as autorizações.
  async apagarEdificio(id: string) {
    if (!(await this.locations.findBuilding(id))) throw notFound('Edifício');
    if (!(await this.locations.removeBuilding(id))) throw conflict('Este edifício ainda tem portarias. Apague-as antes.');
  }

  async apagarPortaria(id: string) {
    if (!(await this.locations.findGate(id))) throw notFound('Portaria');
    if (!(await this.locations.removeGate(id))) throw conflict('Esta portaria ainda tem portas. Apague-as antes.');
  }

  async apagarPorta(id: string) {
    if (!(await this.locations.findDoor(id))) throw notFound('Porta');
    if (!(await this.locations.removeDoor(id))) throw conflict('Esta porta ainda tem catracas. Apague-as antes.');
  }

  async apagarCatraca(id: string) {
    await this.buscarCatraca(id);
    if (await this.terminals.findByAccessPoint(id)) throw conflict('Esta catraca tem um terminal. Remova o terminal antes.');
    if (!(await this.locations.removeAccessPoint(id))) {
      throw conflict('Esta catraca tem autorizações. Ela não pode ser apagada, para não perder o histórico.');
    }
  }
}
