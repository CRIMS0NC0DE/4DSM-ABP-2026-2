import request from 'supertest';
import { createApp } from '../../src/app.js';
import { createContainer, type AppConfig } from '../../src/container.js';
import type { Clock } from '../../src/shared/clock.js';
import { gerarChave, hashChave, hashSenha } from '../../src/shared/security.js';
import type { Perfil } from '../../src/modules/users/users.types.js';
import { createMemoryRepositories } from './memory-repositories.js';

export const SENHA = 'passe123';

// Catraca 2 da Torre Norte (Av. Paulista, 1000)
export const CATRACA_POS = { latitude: -23.5649, longitude: -46.6519 };
// ~50 m ao norte da catraca
export const PERTO = { latitude: -23.56445, longitude: -46.6519 };
// ~1 km de distância
export const LONGE = { latitude: -23.5559, longitude: -46.6519 };

export const config: AppConfig = {
  jwtSecret: 'segredo-jwt-de-teste-123',
  jwtExpiresIn: '1h',
  qrSecret: 'segredo-qr-de-teste-1234',
  qrTtlSeconds: 20,
  qrRotationSeconds: 10,
  timezone: 'America/Sao_Paulo',
  corsOrigin: '*',
};

/** Relógio controlável. Começa numa quarta, 14/10/2026 às 09:00 de Brasília. */
export class FakeClock implements Clock {
  constructor(private atual = new Date('2026-10-14T12:00:00.000Z')) {}
  now() {
    return new Date(this.atual);
  }
  avancar(segundos: number) {
    this.atual = new Date(this.atual.getTime() + segundos * 1000);
  }
  irPara(iso: string) {
    this.atual = new Date(iso);
  }
}

/** Monta o app com dados de exemplo: prédio, catraca, terminal e uma pessoa de cada perfil. */
export async function montarCenario() {
  const clock = new FakeClock();
  const { repos, db } = createMemoryRepositories();
  const container = createContainer(repos, config, clock);
  const app = createApp(container);

  const senhaHash = await hashSenha(SENHA);
  const criarPessoa = (nome: string, perfil: Perfil, cpf: string) =>
    repos.users.create({ nome, perfil, cpf, senhaHash, email: `${nome.split(' ')[0]!.toLowerCase()}@passe.com` });

  const admin = await criarPessoa('Carlos Lima', 'ADMIN', '11111111111');
  const portaria = await criarPessoa('Paula Rocha', 'CONTROLADOR_ACESSO', '22222222222');
  const maria = await criarPessoa('Maria Souza', 'CONDOMINO', '33333333333');
  const visitante = await criarPessoa('Ana Lima', 'VISITANTE', '44444444444');

  const edificio = await repos.locations.createBuilding({ nome: 'Edifício Atlântico', endereco: 'Av. Paulista, 1000' });
  const gate = await repos.locations.createGate({ nome: 'Portaria Principal', buildingId: edificio.id });
  const porta = await repos.locations.createDoor({ nome: 'Porta A', gateId: gate.id });
  const catraca = await repos.locations.createAccessPoint({ nome: 'Catraca 2', doorId: porta.id, raioMetros: 100, ...CATRACA_POS });

  const chave = gerarChave();
  const terminal = await repos.terminals.create({ nome: 'Terminal Catraca 2', accessPointId: catraca.id, chaveHash: hashChave(chave) });
  const tag = await repos.users.addTag(maria.id, '04A1B2C3');

  const autorizacaoMaria = await repos.authorizations.create({
    userId: maria.id,
    accessPointId: catraca.id,
    dataInicio: '2026-10-01',
    dataFim: '2026-10-31',
    horaInicio: '08:00',
    horaFim: '18:00',
    maxUsos: 10,
  });
  // Como no design: "3 de 10 usos" já feitos.
  db.authorizations.find((a) => a.id === autorizacaoMaria.id)!.usosRealizados = 3;

  const api = request(app);

  async function tokenDe(email: string) {
    const res = await api.post('/auth/login').send({ login: email, senha: SENHA });
    return res.body.token as string;
  }

  const terminalHeaders = { 'X-Terminal-Id': terminal.id, 'X-Terminal-Key': chave };

  return {
    api,
    app,
    clock,
    repos,
    db,
    container,
    pessoas: { admin, portaria, maria, visitante },
    catraca,
    terminal,
    chave,
    tag,
    autorizacaoMaria,
    terminalHeaders,
    tokenDe,
  };
}
