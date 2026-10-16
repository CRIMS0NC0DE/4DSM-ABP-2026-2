import { toLocal, type Clock } from '../../shared/clock.js';
import { distanciaEmMetros, type Coordenadas } from '../../shared/geo.js';
import type { AuthorizationsRepository } from '../authorizations/authorizations.types.js';
import type { EventsRepository, MetodoAcesso, QrTokenStore } from '../events/events.types.js';
import type { AccessPointDetalhe, LocationsRepository } from '../locations/locations.types.js';
import type { QrTokenService } from '../terminals/qr-token.js';
import type { TerminalNotifier } from '../terminals/terminal-notifier.js';
import type { Terminal, TerminalsRepository } from '../terminals/terminals.types.js';
import type { User, UsersRepository } from '../users/users.types.js';
import { escolherAutorizacao, MOTIVOS, type MotivoNegacao } from './access.rules.js';

export interface DecisaoAcesso {
  liberado: boolean;
  motivo?: MotivoNegacao;
  titulo: string;
  oQueFazer?: string;
  catraca?: { id: string; nome: string; caminho: string };
  usosRestantes?: number;
  distanciaMetros?: number;
  eventoId: string;
  em: string;
}

export interface AccessServiceDeps {
  users: UsersRepository;
  authorizations: AuthorizationsRepository;
  terminals: TerminalsRepository;
  locations: LocationsRepository;
  events: EventsRepository;
  qrTokens: QrTokenStore;
  qr: QrTokenService;
  notifier: TerminalNotifier;
  clock: Clock;
  timezone: string;
}

interface Tentativa {
  metodo: MetodoAcesso;
  user?: User | null;
  terminal?: Terminal | null;
  catraca?: AccessPointDetalhe | null;
  credencial?: string;
  posicao?: Partial<Coordenadas>;
  distanciaMetros?: number;
}

/**
 * O validador de acesso: a única parte do sistema que decide liberar ou negar.
 * QR (RF13) e NFC (RF14) passam pelas mesmas regras; toda tentativa vira um evento (RF17).
 */
export class AccessService {
  constructor(private readonly deps: AccessServiceDeps) {}

  async validarQr(userId: string, entrada: { token: string; latitude?: number; longitude?: number }): Promise<DecisaoAcesso> {
    const { deps } = this;
    const posicao = { latitude: entrada.latitude, longitude: entrada.longitude };
    const user = await deps.users.findById(userId);
    const base: Tentativa = { metodo: 'QR', user, posicao };

    const qr = deps.qr.verificar(entrada.token);
    if (!qr.ok) return this.negar(base, qr.motivo);

    const terminal = await deps.terminals.findById(qr.terminalId);
    const catraca = terminal ? await deps.locations.findAccessPoint(terminal.accessPointId) : null;
    const tentativa: Tentativa = { ...base, terminal, catraca, credencial: qr.jti };
    if (!terminal || !catraca) return this.negar(tentativa, 'TERMINAL_DESCONHECIDO');
    if (!user || !user.ativo) return this.negar(tentativa, 'USUARIO_INATIVO');

    const escolha = await this.escolher(user.id, catraca.id);
    if (escolha.motivo) return this.negar(tentativa, escolha.motivo);

    // RF13: o celular precisa estar a até N metros (100 por padrão) do terminal.
    if (entrada.latitude === undefined || entrada.longitude === undefined) {
      return this.negar(tentativa, 'LOCALIZACAO_AUSENTE');
    }
    const referencia = terminal.latitude !== null && terminal.longitude !== null
      ? { latitude: terminal.latitude, longitude: terminal.longitude }
      : catraca;
    const distancia = distanciaEmMetros({ latitude: entrada.latitude, longitude: entrada.longitude }, referencia);
    tentativa.distanciaMetros = Math.round(distancia);
    if (distancia > catraca.raioMetros) return this.negar(tentativa, 'LONGE_DO_TERMINAL');

    if (!(await deps.qrTokens.marcarUsado(qr.jti))) return this.negar(tentativa, 'QR_JA_UTILIZADO');
    return this.liberar(tentativa, escolha.autorizacao);
  }

  async validarNfc(terminal: Terminal, uid: string): Promise<DecisaoAcesso> {
    const { deps } = this;
    const catraca = await deps.locations.findAccessPoint(terminal.accessPointId);
    const tag = await deps.users.findTagByUid(normalizarUid(uid));
    const user = tag ? await deps.users.findById(tag.userId) : null;
    const tentativa: Tentativa = { metodo: 'NFC', user, terminal, catraca, credencial: normalizarUid(uid) };

    if (!catraca) return this.negar(tentativa, 'TERMINAL_DESCONHECIDO');
    if (!tag || !user) return this.negar(tentativa, 'TAG_DESCONHECIDA');
    if (!tag.ativa) return this.negar(tentativa, 'TAG_BLOQUEADA');
    if (!user.ativo) return this.negar(tentativa, 'USUARIO_INATIVO');

    const escolha = await this.escolher(user.id, catraca.id);
    if (escolha.motivo) return this.negar(tentativa, escolha.motivo);
    return this.liberar(tentativa, escolha.autorizacao);
  }

  private async escolher(userId: string, accessPointId: string) {
    const candidatas = await this.deps.authorizations.listForAccess(userId, accessPointId);
    return escolherAutorizacao(candidatas, toLocal(this.deps.clock.now(), this.deps.timezone));
  }

  private async liberar(t: Tentativa, autorizacao: { id: string; maxUsos: number; usosRealizados: number }) {
    const usosRestantes = autorizacao.maxUsos - autorizacao.usosRealizados - 1;
    // Dois acessos ao mesmo tempo não podem passar do limite de usos.
    if (!(await this.deps.authorizations.consumirUso(autorizacao.id))) return this.negar(t, 'SEM_USOS');
    return this.registrar(t, { liberado: true, authorizationId: autorizacao.id, usosRestantes });
  }

  private negar(t: Tentativa, motivo: MotivoNegacao) {
    return this.registrar(t, { liberado: false, motivo });
  }

  private async registrar(
    t: Tentativa,
    r: { liberado: boolean; motivo?: MotivoNegacao; authorizationId?: string; usosRestantes?: number },
  ): Promise<DecisaoAcesso> {
    const { deps } = this;
    const evento = await deps.events.create({
      metodo: t.metodo,
      resultado: r.liberado ? 'LIBERADO' : 'NEGADO',
      motivo: r.motivo ?? null,
      userId: t.user?.id ?? null,
      accessPointId: t.catraca?.id ?? null,
      terminalId: t.terminal?.id ?? null,
      authorizationId: r.authorizationId ?? null,
      credencial: t.credencial ?? null,
      latitude: t.posicao?.latitude ?? null,
      longitude: t.posicao?.longitude ?? null,
      distanciaMetros: t.distanciaMetros ?? null,
    });

    const textos = r.motivo ? MOTIVOS[r.motivo] : { titulo: 'Acesso liberado', oQueFazer: undefined };
    const decisao: DecisaoAcesso = {
      liberado: r.liberado,
      motivo: r.motivo,
      titulo: textos.titulo,
      oQueFazer: textos.oQueFazer,
      catraca: t.catraca
        ? { id: t.catraca.id, nome: t.catraca.nome, caminho: `${t.catraca.edificio} › ${t.catraca.portaria} › ${t.catraca.porta}` }
        : undefined,
      usosRestantes: r.usosRestantes,
      distanciaMetros: t.distanciaMetros,
      eventoId: evento.id,
      em: evento.createdAt.toISOString(),
    };

    if (t.terminal) {
      await deps.notifier.enviar(t.terminal.id, {
        acao: r.liberado ? 'ABRIR' : 'NEGAR',
        metodo: t.metodo,
        mensagem: textos.titulo,
        motivo: r.motivo,
        nome: t.user?.nome.split(' ')[0],
        em: decisao.em,
      });
    }
    return decisao;
  }
}

export const normalizarUid = (uid: string) => uid.replace(/[^0-9a-f]/gi, '').toUpperCase();
