import type { AlterarConfiguracao, Configuracao, SettingsRepository } from './settings.types.js';

/** Valores que vêm das variáveis de ambiente: a tela mostra, mas não muda. */
export interface ConfiguracaoDoSistema {
  fuso: string;
  qrTrocaSegundos: number;
  qrValidadeSegundos: number;
  raioPadraoMetros: number;
}

/** Tela Configurações (admin). A Ajuda e "Meus visitantes" leem daqui. */
export class SettingsService {
  constructor(
    private readonly settings: SettingsRepository,
    private readonly sistema: ConfiguracaoDoSistema,
  ) {}

  private apresentar({ updatedAt, ...c }: Configuracao) {
    return { ...c, atualizadoEm: updatedAt, sistema: this.sistema };
  }

  /** Só as regras, para os outros services. */
  regras() {
    return this.settings.get();
  }

  async ler() {
    return this.apresentar(await this.settings.get());
  }

  async alterar(dados: AlterarConfiguracao) {
    return this.apresentar(await this.settings.update(dados));
  }
}
