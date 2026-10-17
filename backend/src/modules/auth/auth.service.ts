import { unauthorized } from '../../shared/errors.js';
import { assinarJwt } from '../../shared/http/auth.js';
import { conferirSenha, hashSenhaSync, somenteNumeros } from '../../shared/security.js';
import { semSenha } from '../users/users.service.js';
import type { UsersRepository } from '../users/users.types.js';

// Compara a senha mesmo quando o login não existe, para o tempo de
// resposta não revelar quais e-mails estão cadastrados.
const HASH_FALSO = hashSenhaSync('senha-que-ninguem-tem');

export class AuthService {
  constructor(
    private readonly users: UsersRepository,
    private readonly jwt: { secret: string; expiresIn: string },
  ) {}

  /** RF07: entra com e-mail ou CPF (com ou sem pontuação) e senha. */
  async entrar(login: string, senha: string) {
    const texto = login.trim().toLowerCase();
    const user = texto.includes('@')
      ? await this.users.findByEmail(texto)
      : await this.users.findByCpf(somenteNumeros(texto));

    const senhaConfere = await conferirSenha(senha, user?.senhaHash ?? HASH_FALSO);
    if (!user || !senhaConfere) throw unauthorized('E-mail, CPF ou senha não conferem.');
    if (!user.ativo) throw unauthorized('Seu cadastro está desativado. Fale com a portaria.');

    const token = assinarJwt({ userId: user.id, perfil: user.perfil }, this.jwt.secret, this.jwt.expiresIn);
    return { token, usuario: semSenha(user) };
  }
}
