import { badRequest, conflict, notFound } from '../../shared/errors.js';
import type { AuthContext } from '../../shared/http/auth.js';
import { conferirPermissao } from '../users/users.service.js';
import type { UsersRepository } from '../users/users.types.js';
import { lerChavePublica } from './phone-signature.js';
import type { NfcPhone, NfcPhoneView, PhonesRepository } from './phones.types.js';

export function semChave(celular: NfcPhone): NfcPhoneView {
  const { chavePublica: _chavePublica, ...resto } = celular;
  return resto;
}

/**
 * Celulares que abrem a catraca por NFC (o aparelho emula uma tag).
 * A própria pessoa ativa e remove o celular dela pelo app; a equipe vê, bloqueia e remove.
 */
export class PhonesService {
  constructor(
    private readonly phones: PhonesRepository,
    private readonly users: Pick<UsersRepository, 'findById'>,
  ) {}

  async meus(userId: string) {
    return (await this.phones.listByUser(userId)).map(semChave);
  }

  /** O app gerou o par de chaves no Keystore e manda só a pública. */
  async ativarMeu(userId: string, dados: { nome: string; chavePublica: string }) {
    if (!lerChavePublica(dados.chavePublica)) {
      throw badRequest('Chave do celular inválida.', { chavePublica: ['Use uma chave pública EC P-256 (SPKI em base64).'] });
    }
    if (await this.phones.findByChave(dados.chavePublica)) throw conflict('Este celular já está cadastrado.');
    return semChave(await this.phones.create({ userId, nome: dados.nome.trim(), chavePublica: dados.chavePublica }));
  }

  /** Trocou de aparelho ou desinstalou o app: a pessoa tira o celular da lista. */
  async removerMeu(userId: string, celularId: string) {
    const celular = await this.phones.findById(celularId);
    if (!celular || celular.userId !== userId) throw notFound('Celular');
    await this.phones.remove(celularId);
  }

  async doUsuario(quem: AuthContext, userId: string) {
    await this.conferirUsuario(quem, userId);
    return (await this.phones.listByUser(userId)).map(semChave);
  }

  async alterar(quem: AuthContext, userId: string, celularId: string, ativo: boolean) {
    await this.celularDoUsuario(quem, userId, celularId);
    return semChave(await this.phones.update(celularId, { ativo }));
  }

  async remover(quem: AuthContext, userId: string, celularId: string) {
    await this.celularDoUsuario(quem, userId, celularId);
    await this.phones.remove(celularId);
  }

  private async conferirUsuario(quem: AuthContext, userId: string) {
    const user = await this.users.findById(userId);
    if (!user) throw notFound('Usuário');
    conferirPermissao(quem, user.perfil);
  }

  private async celularDoUsuario(quem: AuthContext, userId: string, celularId: string) {
    await this.conferirUsuario(quem, userId);
    const celular = await this.phones.findById(celularId);
    if (!celular || celular.userId !== userId) throw notFound('Celular');
  }
}
