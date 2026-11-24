/** Celular Android cadastrado como chave NFC (o aparelho emula um cartão, HCE). */
export interface NfcPhone {
  id: string;
  userId: string;
  /** Nome do aparelho, para a pessoa reconhecer na lista (ex.: "Galaxy A54"). */
  nome: string;
  /** Chave pública EC P-256 (SPKI DER em base64). A privada nunca sai do Keystore do celular. */
  chavePublica: string;
  ativo: boolean;
  createdAt: Date;
}

/** O celular como as rotas devolvem: sem a chave, que só o validador usa. */
export type NfcPhoneView = Omit<NfcPhone, 'chavePublica'>;

export interface PhonesRepository {
  findById(id: string): Promise<NfcPhone | null>;
  findByChave(chavePublica: string): Promise<NfcPhone | null>;
  listByUser(userId: string): Promise<NfcPhone[]>;
  create(data: { userId: string; nome: string; chavePublica: string }): Promise<NfcPhone>;
  update(id: string, data: { ativo: boolean }): Promise<NfcPhone>;
  remove(id: string): Promise<void>;
}
