import { conflict, forbidden, notFound } from '../../shared/errors.js';
import { hashSenha, somenteNumeros } from '../../shared/security.js';
import type { AuthContext } from '../../shared/http/auth.js';
import { normalizarUid } from '../access/access.service.js';
import type { NfcTag, Perfil, User, UserFilter, UsersRepository, UserWithTags } from './users.types.js';

export type PublicUser = Omit<User, 'senhaHash'> & { tags?: NfcTag[] };

export function semSenha(user: User | UserWithTags): PublicUser {
  const { senhaHash: _senhaHash, ...resto } = user;
  return resto;
}

// A portaria só cadastra quem usa o prédio; admin e portaria são criados pelo admin.
const PERFIS_QUE_A_PORTARIA_GERENCIA: readonly Perfil[] = ['CONDOMINO', 'VISITANTE'];

export interface CriarUsuario {
  nome: string;
  email: string;
  cpf: string;
  senha: string;
  perfil: Perfil;
}

export class UsersService {
  constructor(private readonly users: UsersRepository) {}

  async listar(filtro: UserFilter) {
    return (await this.users.list(filtro)).map(semSenha);
  }

  async buscar(id: string) {
    const user = await this.users.findById(id);
    if (!user) throw notFound('Usuário');
    return semSenha(user);
  }

  async criar(quem: AuthContext, dados: CriarUsuario) {
    this.conferirPermissao(quem, dados.perfil);
    const email = dados.email.trim().toLowerCase();
    const cpf = somenteNumeros(dados.cpf);
    await this.garantirUnico(email, cpf);
    const user = await this.users.create({
      nome: dados.nome.trim(),
      email,
      cpf,
      perfil: dados.perfil,
      senhaHash: await hashSenha(dados.senha),
    });
    return semSenha(user);
  }

  async atualizar(quem: AuthContext, id: string, dados: Partial<CriarUsuario> & { ativo?: boolean }) {
    const atual = await this.users.findById(id);
    if (!atual) throw notFound('Usuário');
    this.conferirPermissao(quem, atual.perfil);
    if (dados.perfil) this.conferirPermissao(quem, dados.perfil);

    const email = dados.email?.trim().toLowerCase();
    const cpf = dados.cpf ? somenteNumeros(dados.cpf) : undefined;
    await this.garantirUnico(email, cpf, id);

    const user = await this.users.update(id, {
      nome: dados.nome?.trim(),
      email,
      cpf,
      perfil: dados.perfil,
      ativo: dados.ativo,
      senhaHash: dados.senha ? await hashSenha(dados.senha) : undefined,
    });
    return semSenha(user);
  }

  async vincularTag(quem: AuthContext, userId: string, uid: string) {
    const user = await this.users.findById(userId);
    if (!user) throw notFound('Usuário');
    this.conferirPermissao(quem, user.perfil);
    const normalizado = normalizarUid(uid);
    if (await this.users.findTagByUid(normalizado)) throw conflict('Esta tag já está vinculada a alguém.');
    return this.users.addTag(userId, normalizado);
  }

  async alterarTag(quem: AuthContext, userId: string, tagId: string, ativa: boolean) {
    await this.tagDoUsuario(quem, userId, tagId);
    return this.users.updateTag(tagId, { ativa });
  }

  async removerTag(quem: AuthContext, userId: string, tagId: string) {
    await this.tagDoUsuario(quem, userId, tagId);
    await this.users.removeTag(tagId);
  }

  private async tagDoUsuario(quem: AuthContext, userId: string, tagId: string) {
    const user = await this.users.findById(userId);
    const tag = await this.users.findTagById(tagId);
    if (!user || !tag || tag.userId !== userId) throw notFound('Tag');
    this.conferirPermissao(quem, user.perfil);
  }

  private conferirPermissao(quem: AuthContext, perfilAlvo: Perfil) {
    if (quem.perfil === 'ADMIN') return;
    if (quem.perfil === 'CONTROLADOR_ACESSO' && PERFIS_QUE_A_PORTARIA_GERENCIA.includes(perfilAlvo)) return;
    throw forbidden();
  }

  private async garantirUnico(email?: string, cpf?: string, ignorarId?: string) {
    if (email) {
      const outro = await this.users.findByEmail(email);
      if (outro && outro.id !== ignorarId) throw conflict('Já existe alguém com este e-mail.');
    }
    if (cpf) {
      const outro = await this.users.findByCpf(cpf);
      if (outro && outro.id !== ignorarId) throw conflict('Já existe alguém com este CPF.');
    }
  }
}
