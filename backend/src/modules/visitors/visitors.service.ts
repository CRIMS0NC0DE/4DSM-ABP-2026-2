import { toLocal, type Clock } from '../../shared/clock.js';
import { badRequest, conflict, forbidden, notFound } from '../../shared/errors.js';
import { gerarSenhaProvisoria, hashSenha, somenteNumeros } from '../../shared/security.js';
import type { AuthorizationsService } from '../authorizations/authorizations.service.js';
import type { AuthorizationsRepository } from '../authorizations/authorizations.types.js';
import type { SettingsService } from '../settings/settings.service.js';
import type { UsersRepository } from '../users/users.types.js';

export interface Convite {
  nome: string;
  email: string;
  cpf: string;
  accessPointId: string;
  /** YYYY-MM-DD */
  dataInicio: string;
  /** YYYY-MM-DD */
  dataFim: string;
  /** HH:MM */
  horaInicio: string;
  /** HH:MM */
  horaFim: string;
}

const FORA_DA_AUTORIZACAO = 'Você só pode convidar para as catracas que você usa, dentro do período da sua autorização.';

/** Dias entre duas datas YYYY-MM-DD, contando as duas. */
function diasEntre(inicio: string, fim: string) {
  return Math.round((Date.parse(`${fim}T00:00:00Z`) - Date.parse(`${inicio}T00:00:00Z`)) / 86_400_000) + 1;
}

/**
 * "Meus visitantes": o morador cadastra quem vai chegar, só para as catracas que ele mesmo usa
 * e dentro do período da autorização dele. A autorização do visitante guarda quem a criou.
 */
export class VisitorsService {
  constructor(
    private readonly deps: {
      users: UsersRepository;
      authorizationsRepo: AuthorizationsRepository;
      authorizations: AuthorizationsService;
      settings: SettingsService;
      clock: Clock;
      timezone: string;
    },
  ) {}

  private hoje() {
    return toLocal(this.deps.clock.now(), this.deps.timezone).date;
  }

  /** As autorizações do morador que ainda valem (ativas ou agendadas, mesmo sem usos). */
  private async minhasVigentes(moradorId: string) {
    const hoje = this.hoje();
    return (await this.deps.authorizations.listar({ userId: moradorId })).filter(
      (a) => a.status === 'ATIVA' && a.dataFim >= hoje,
    );
  }

  /** Catracas para onde o morador pode convidar, com o último dia em que pode. */
  async catracas(moradorId: string) {
    const porCatraca = new Map<string, { id: string; nome: string; edificio: string; portaria: string; porta: string; ate: string }>();
    for (const a of await this.minhasVigentes(moradorId)) {
      const atual = porCatraca.get(a.accessPointId);
      if (!atual || a.dataFim > atual.ate) porCatraca.set(a.accessPointId, { ...a.catraca, ate: a.dataFim });
    }
    return [...porCatraca.values()].sort((x, y) => x.nome.localeCompare(y.nome));
  }

  listar(moradorId: string) {
    return this.deps.authorizations.listar({ criadaPorId: moradorId });
  }

  async convidar(moradorId: string, convite: Convite) {
    const regras = await this.deps.settings.regras();
    if (!regras.moradorPodeConvidar) {
      throw forbidden('O condomínio não permite que moradores cadastrem visitantes. Fale com a portaria.');
    }

    if (convite.dataInicio < this.hoje()) throw badRequest('A visita precisa começar hoje ou depois.');
    if (convite.dataFim < convite.dataInicio) throw badRequest('A data de término precisa ser depois da data de início.');
    if (convite.horaInicio === convite.horaFim) throw badRequest('O horário inicial e o final não podem ser iguais.');
    if (diasEntre(convite.dataInicio, convite.dataFim) > regras.visitanteDiasMax) {
      throw badRequest(`Uma visita pode durar até ${regras.visitanteDiasMax} dia(s).`);
    }

    // Uma autorização do morador precisa cobrir todo o período da visita, na mesma catraca.
    const cobre = (await this.minhasVigentes(moradorId)).some(
      (a) => a.accessPointId === convite.accessPointId && a.dataInicio <= convite.dataInicio && a.dataFim >= convite.dataFim,
    );
    if (!cobre) throw forbidden(FORA_DA_AUTORIZACAO);

    const { visitante, senhaProvisoria } = await this.visitante(convite);
    const autorizacao = await this.deps.authorizations.criar({
      userId: visitante.id,
      accessPointId: convite.accessPointId,
      dataInicio: convite.dataInicio,
      dataFim: convite.dataFim,
      horaInicio: convite.horaInicio,
      horaFim: convite.horaFim,
      maxUsos: regras.visitanteMaxUsos,
      criadaPorId: moradorId,
    });
    return { autorizacao, visitante: { id: visitante.id, nome: visitante.nome, email: visitante.email }, senhaProvisoria };
  }

  async cancelar(moradorId: string, autorizacaoId: string) {
    const a = await this.deps.authorizationsRepo.findById(autorizacaoId);
    if (!a || a.criadaPorId !== moradorId) throw notFound('Autorização');
    return this.deps.authorizations.cancelar(autorizacaoId);
  }

  /**
   * Reaproveita o visitante que já tem cadastro (mesmo e-mail e mesmo CPF) ou cria um novo
   * com senha provisória, que só aparece nesta resposta.
   */
  private async visitante(convite: Convite) {
    const email = convite.email.trim().toLowerCase();
    const cpf = somenteNumeros(convite.cpf);
    const [porEmail, porCpf] = await Promise.all([this.deps.users.findByEmail(email), this.deps.users.findByCpf(cpf)]);

    if (porEmail || porCpf) {
      const mesmaPessoa = porEmail && porCpf && porEmail.id === porCpf.id;
      if (!mesmaPessoa) throw conflict(porEmail ? 'Já existe alguém com este e-mail.' : 'Já existe alguém com este CPF.');
      if (porEmail.perfil !== 'VISITANTE') throw conflict('Este e-mail é de um morador ou da equipe, não de um visitante.');
      if (!porEmail.ativo) throw conflict('O cadastro deste visitante está desativado. Fale com a portaria.');
      return { visitante: porEmail, senhaProvisoria: null };
    }

    const senhaProvisoria = gerarSenhaProvisoria();
    const visitante = await this.deps.users.create({
      nome: convite.nome.trim(),
      email,
      cpf,
      perfil: 'VISITANTE',
      senhaHash: await hashSenha(senhaProvisoria),
    });
    return { visitante, senhaProvisoria };
  }
}
