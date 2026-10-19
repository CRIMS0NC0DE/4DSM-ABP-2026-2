export const PERFIS = ['ADMIN', 'CONTROLADOR_ACESSO', 'CONDOMINO', 'VISITANTE'] as const;
export type Perfil = (typeof PERFIS)[number];

/** Quem administra o prédio: admin e portaria. */
export const PERFIS_EQUIPE: readonly Perfil[] = ['ADMIN', 'CONTROLADOR_ACESSO'];

export interface User {
  id: string;
  nome: string;
  email: string;
  cpf: string;
  senhaHash: string;
  perfil: Perfil;
  ativo: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface NfcTag {
  id: string;
  uid: string;
  userId: string;
  ativa: boolean;
  createdAt: Date;
}

export type UserWithTags = User & { tags: NfcTag[] };

export interface NewUser {
  nome: string;
  email: string;
  cpf: string;
  senhaHash: string;
  perfil: Perfil;
}

export interface UserFilter {
  /** nome, e-mail ou CPF */
  busca?: string;
  perfil?: Perfil;
}

export interface UsersRepository {
  findById(id: string): Promise<UserWithTags | null>;
  findByEmail(email: string): Promise<User | null>;
  findByCpf(cpf: string): Promise<User | null>;
  list(filter: UserFilter): Promise<UserWithTags[]>;
  create(data: NewUser): Promise<User>;
  update(id: string, data: Partial<Omit<NewUser, 'senhaHash'>> & { senhaHash?: string; ativo?: boolean }): Promise<User>;
  findTagByUid(uid: string): Promise<NfcTag | null>;
  findTagById(id: string): Promise<NfcTag | null>;
  addTag(userId: string, uid: string): Promise<NfcTag>;
  updateTag(id: string, data: { ativa: boolean }): Promise<NfcTag>;
  removeTag(id: string): Promise<void>;
}
