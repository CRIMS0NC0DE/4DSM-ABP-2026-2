import { notFound } from '../../shared/errors.js';
import type { AnnouncementsRepository, NovoComunicado } from './announcements.types.js';

const LIMITE = 50;

/** Avisos do admin para quem usa o prédio (tela Comunicados e cartão do Início). */
export class AnnouncementsService {
  constructor(private readonly announcements: AnnouncementsRepository) {}

  listar() {
    return this.announcements.list(LIMITE);
  }

  publicar(dados: NovoComunicado) {
    return this.announcements.create(dados);
  }

  async apagar(id: string) {
    if (!(await this.announcements.findById(id))) throw notFound('Comunicado');
    await this.announcements.remove(id);
  }
}
