/** Regras do condomínio que o admin muda pela tela Configurações. */
export interface Configuracao {
  nomeCondominio: string;
  /** Telefone, ramal ou horário da portaria, mostrado na Ajuda. */
  contatoPortaria: string;
  /** O morador pode cadastrar visitantes ("Meus visitantes"). */
  moradorPodeConvidar: boolean;
  /** Usos de cada autorização criada pelo morador para um visitante. */
  visitanteMaxUsos: number;
  /** Quantos dias uma visita pode durar, contando o primeiro e o último. */
  visitanteDiasMax: number;
  updatedAt: Date;
}

export type AlterarConfiguracao = Partial<Omit<Configuracao, 'updatedAt'>>;

export const CONFIGURACAO_PADRAO: Omit<Configuracao, 'updatedAt'> = {
  nomeCondominio: 'Condomínio',
  contatoPortaria: 'Fale com a portaria pelo interfone.',
  moradorPodeConvidar: true,
  visitanteMaxUsos: 2,
  visitanteDiasMax: 7,
};

export interface SettingsRepository {
  /** A linha única (id = 1). Se não existir, cria com os valores padrão. */
  get(): Promise<Configuracao>;
  update(data: AlterarConfiguracao): Promise<Configuracao>;
}
