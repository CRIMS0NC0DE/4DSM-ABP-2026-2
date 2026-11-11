import { describe, expect, it, vi } from 'vitest';
import { createPrismaRepositories } from '../../src/database/repositories.prisma.js';
import { AppError } from '../../src/shared/errors.js';

const comNfcTag = (nfcTag: object) => createPrismaRepositories({ nfcTag } as never).users;

describe('Tag removida por outra chamada ao mesmo tempo', () => {
  it('atualizar responde 404 em vez de estourar o erro do Prisma', async () => {
    const users = comNfcTag({ update: vi.fn().mockRejectedValue({ code: 'P2025' }) });
    await expect(users.updateTag('t1', { ativa: false })).rejects.toMatchObject({ status: 404, code: 'NAO_ENCONTRADO' });
    await expect(users.updateTag('t1', { ativa: false })).rejects.toBeInstanceOf(AppError);
  });

  it('outros erros do banco continuam como estão', async () => {
    const falha = new Error('banco fora do ar');
    const users = comNfcTag({ update: vi.fn().mockRejectedValue(falha) });
    await expect(users.updateTag('t1', { ativa: false })).rejects.toBe(falha);
  });

  it('remover não falha quando a tag já saiu', async () => {
    const deleteMany = vi.fn().mockResolvedValue({ count: 0 });
    await expect(comNfcTag({ deleteMany }).removeTag('t1')).resolves.toBeUndefined();
    expect(deleteMany).toHaveBeenCalledWith({ where: { id: 't1' } });
  });
});
