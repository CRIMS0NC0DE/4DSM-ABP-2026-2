import { toLocal, type Clock } from '../../shared/clock.js';
import { badRequest, conflict, notFound } from '../../shared/errors.js';
import { situacaoDe } from '../access/access.rules.js';
import type { LocationsRepository } from '../locations/locations.types.js';
import type { UsersRepository } from '../users/users.types.js';
import type {
  AuthorizationFilter,
  AuthorizationsRepository,
  AuthorizationWithRefs,
  NewAuthorization,
} from './authorizations.types.js';

export class AuthorizationsService {
  constructor(
    private readonly authorizations: AuthorizationsRepository,
    private readonly users: UsersRepository,
    private readonly locations: LocationsRepository,
    private readonly clock: Clock,
    private readonly timezone: string,
  ) {}

  private hoje() {
    return toLocal(this.clock.now(), this.timezone).date;
  }

  /** Acrescenta a situação calculada e os usos restantes, que é o que as telas mostram. */
  private apresentar(a: AuthorizationWithRefs) {
    return {
      ...a,
      situacao: situacaoDe(a, this.hoje()),
      usosRestantes: Math.max(0, a.maxUsos - a.usosRealizados),
    };
  }

  /** RF04 */
  async listar(filtro: Omit<AuthorizationFilter, 'hoje'>) {
    const lista = await this.authorizations.list({ ...filtro, hoje: this.hoje() });
    return lista.map((a) => this.apresentar(a));
  }

  /** RF08: as autorizações de quem está logado. */
  async minhas(userId: string) {
    return this.listar({ userId });
  }

  async buscar(id: string) {
    const a = await this.authorizations.findById(id);
    if (!a) throw notFound('Autorização');
    return this.apresentar(a);
  }

  /** RF03 */
  async criar(dados: NewAuthorization) {
    validarPeriodo(dados);
    if (!(await this.users.findById(dados.userId))) throw notFound('Usuário');
    if (!(await this.locations.findAccessPoint(dados.accessPointId))) throw notFound('Catraca');
    return this.apresentar(await this.authorizations.create(dados));
  }

  async atualizar(id: string, dados: Partial<Omit<NewAuthorization, 'userId'>>) {
    const atual = await this.authorizations.findById(id);
    if (!atual) throw notFound('Autorização');
    if (atual.status === 'CANCELADA') throw conflict('Autorização cancelada não pode ser editada. Crie outra.');
    validarPeriodo({ ...atual, ...dados });
    if (dados.maxUsos !== undefined && dados.maxUsos < atual.usosRealizados) {
      throw badRequest(`Esta autorização já foi usada ${atual.usosRealizados} vez(es).`);
    }
    if (dados.accessPointId && !(await this.locations.findAccessPoint(dados.accessPointId))) throw notFound('Catraca');
    return this.apresentar(await this.authorizations.update(id, dados));
  }

  /** RF05 */
  async cancelar(id: string) {
    const atual = await this.authorizations.findById(id);
    if (!atual) throw notFound('Autorização');
    if (atual.status === 'CANCELADA') return this.apresentar(atual);
    return this.apresentar(await this.authorizations.update(id, { status: 'CANCELADA', canceladaEm: this.clock.now() }));
  }
}

function validarPeriodo(d: Pick<NewAuthorization, 'dataInicio' | 'dataFim' | 'horaInicio' | 'horaFim'>) {
  if (d.dataFim < d.dataInicio) throw badRequest('A data de término precisa ser depois da data de início.');
  if (d.horaInicio === d.horaFim) throw badRequest('O horário inicial e o final não podem ser iguais.');
}
