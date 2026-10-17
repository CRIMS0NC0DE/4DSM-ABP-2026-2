import type { Clock } from '../../shared/clock.js';
import { conflict, notFound } from '../../shared/errors.js';
import { gerarChave, hashChave } from '../../shared/security.js';
import type { LocationsRepository } from '../locations/locations.types.js';
import type { QrTokenService } from './qr-token.js';
import type { Terminal, TerminalsRepository } from './terminals.types.js';

// Sem sinal há mais que isso, o terminal aparece como fora do ar.
const LIMITE_ONLINE_MS = 90_000;

export class TerminalsService {
  constructor(
    private readonly terminals: TerminalsRepository,
    private readonly locations: LocationsRepository,
    private readonly qr: QrTokenService,
    private readonly clock: Clock,
  ) {}

  private apresentar(t: Terminal) {
    const { chaveHash: _chaveHash, ...resto } = t;
    const online = t.ultimoSinal !== null && this.clock.now().getTime() - t.ultimoSinal.getTime() < LIMITE_ONLINE_MS;
    return { ...resto, online };
  }

  async listar() {
    return (await this.terminals.list()).map((t) => this.apresentar(t));
  }

  /** Cadastra o terminal de uma catraca. A chave aparece só nesta resposta: grave no firmware. */
  async cadastrar(dados: { nome: string; accessPointId: string }) {
    if (!(await this.locations.findAccessPoint(dados.accessPointId))) throw notFound('Catraca');
    if (await this.terminals.findByAccessPoint(dados.accessPointId)) throw conflict('Esta catraca já tem um terminal.');
    const chave = gerarChave();
    const terminal = await this.terminals.create({ ...dados, chaveHash: hashChave(chave) });
    return { ...this.apresentar(terminal), chave };
  }

  /** Gera uma chave nova (ex.: terminal trocado ou chave vazada). */
  async trocarChave(id: string) {
    if (!(await this.terminals.findById(id))) throw notFound('Terminal');
    const chave = gerarChave();
    const terminal = await this.terminals.update(id, { chaveHash: hashChave(chave) });
    return { ...this.apresentar(terminal), chave };
  }

  /** RF12: conteúdo do QR que o terminal desenha na tela. */
  qrToken(terminal: Terminal) {
    return this.qr.gerar(terminal.id);
  }

  /** O terminal avisa que está vivo e, se tiver GPS, onde está. */
  async sinal(terminal: Terminal, posicao: { latitude?: number; longitude?: number }) {
    const atualizado = await this.terminals.update(terminal.id, {
      ultimoSinal: this.clock.now(),
      ...(posicao.latitude !== undefined && posicao.longitude !== undefined ? posicao : {}),
    });
    return this.apresentar(atualizado);
  }
}
