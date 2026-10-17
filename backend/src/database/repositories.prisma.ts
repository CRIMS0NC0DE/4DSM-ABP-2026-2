import type { Repositories } from '../container.js';
import { dateOnlyToDate, dateToDateOnly } from '../shared/clock.js';
import type { Authorization, AuthorizationWithRefs } from '../modules/authorizations/authorizations.types.js';
import type { Prisma } from './prisma.js';

// Converte as colunas DATE do Postgres para "YYYY-MM-DD", que é como o domínio trabalha.
function autorizacao<T extends { dataInicio: Date; dataFim: Date }>(row: T) {
  return { ...row, dataInicio: dateToDateOnly(row.dataInicio), dataFim: dateToDateOnly(row.dataFim) };
}

const comRefs = {
  user: { select: { id: true, nome: true, perfil: true } },
  catraca: { select: { id: true, nome: true } },
} as const;

export function createPrismaRepositories(db: Prisma): Repositories {
  return {
    users: {
      findById: (id) => db.user.findUnique({ where: { id }, include: { tags: true } }),
      findByEmail: (email) => db.user.findUnique({ where: { email } }),
      findByCpf: (cpf) => db.user.findUnique({ where: { cpf } }),
      list: ({ busca, perfil }) =>
        db.user.findMany({
          where: {
            perfil,
            ...(busca && {
              OR: [
                { nome: { contains: busca, mode: 'insensitive' } },
                { email: { contains: busca, mode: 'insensitive' } },
                { cpf: { contains: busca.replace(/\D/g, '') || busca } },
              ],
            }),
          },
          include: { tags: true },
          orderBy: { nome: 'asc' },
        }),
      create: (data) => db.user.create({ data }),
      update: (id, data) => db.user.update({ where: { id }, data }),
      findTagByUid: (uid) => db.nfcTag.findUnique({ where: { uid } }),
      findTagById: (id) => db.nfcTag.findUnique({ where: { id } }),
      addTag: (userId, uid) => db.nfcTag.create({ data: { userId, uid } }),
      updateTag: (id, data) => db.nfcTag.update({ where: { id }, data }),
      removeTag: async (id) => {
        await db.nfcTag.delete({ where: { id } });
      },
    },

    locations: {
      tree: () =>
        db.building.findMany({
          orderBy: { nome: 'asc' },
          include: {
            portarias: {
              orderBy: { nome: 'asc' },
              include: { portas: { orderBy: { nome: 'asc' }, include: { catracas: { orderBy: { nome: 'asc' } } } } },
            },
          },
        }),
      createBuilding: (data) => db.building.create({ data }),
      createGate: (data) => db.gate.create({ data }),
      createDoor: (data) => db.door.create({ data }),
      createAccessPoint: (data) => db.accessPoint.create({ data }),
      updateAccessPoint: (id, data) => db.accessPoint.update({ where: { id }, data }),
      findBuilding: (id) => db.building.findUnique({ where: { id } }),
      findGate: (id) => db.gate.findUnique({ where: { id } }),
      findDoor: (id) => db.door.findUnique({ where: { id } }),
      findAccessPoint: async (id) => {
        const row = await db.accessPoint.findUnique({
          where: { id },
          include: { porta: { include: { portaria: { include: { edificio: true } } } } },
        });
        if (!row) return null;
        const { porta, ...catraca } = row;
        return { ...catraca, porta: porta.nome, portaria: porta.portaria.nome, edificio: porta.portaria.edificio.nome };
      },
    },

    terminals: {
      create: (data) => db.terminal.create({ data }),
      findById: (id) => db.terminal.findUnique({ where: { id } }),
      findByAccessPoint: (accessPointId) => db.terminal.findUnique({ where: { accessPointId } }),
      list: () => db.terminal.findMany({ orderBy: { nome: 'asc' } }),
      update: (id, data) => db.terminal.update({ where: { id }, data }),
    },

    authorizations: {
      create: async (data) =>
        autorizacao(
          await db.authorization.create({
            data: { ...data, dataInicio: dateOnlyToDate(data.dataInicio), dataFim: dateOnlyToDate(data.dataFim) },
            include: comRefs,
          }),
        ) as AuthorizationWithRefs,
      findById: async (id) => {
        const row = await db.authorization.findUnique({ where: { id }, include: comRefs });
        return row ? (autorizacao(row) as AuthorizationWithRefs) : null;
      },
      list: async (f) => {
        const hoje = dateOnlyToDate(f.hoje);
        const rows = await db.authorization.findMany({
          where: {
            userId: f.userId,
            accessPointId: f.accessPointId,
            AND: [
              f.situacao === 'CANCELADA' ? { status: 'CANCELADA' } : {},
              f.situacao === 'ATIVA' ? { status: 'ATIVA', dataFim: { gte: hoje } } : {},
              f.situacao === 'EXPIRADA' ? { status: 'ATIVA', dataFim: { lt: hoje } } : {},
              f.de ? { dataFim: { gte: dateOnlyToDate(f.de) } } : {},
              f.ate ? { dataInicio: { lte: dateOnlyToDate(f.ate) } } : {},
            ],
          },
          include: comRefs,
          orderBy: [{ dataInicio: 'desc' }, { createdAt: 'desc' }],
        });
        return rows.map((r) => autorizacao(r) as AuthorizationWithRefs);
      },
      listForAccess: async (userId, accessPointId) => {
        const rows = await db.authorization.findMany({ where: { userId, accessPointId } });
        return rows.map((r) => autorizacao(r) as Authorization);
      },
      update: async (id, data) =>
        autorizacao(
          await db.authorization.update({
            where: { id },
            data: {
              ...data,
              dataInicio: data.dataInicio ? dateOnlyToDate(data.dataInicio) : undefined,
              dataFim: data.dataFim ? dateOnlyToDate(data.dataFim) : undefined,
            },
            include: comRefs,
          }),
        ) as AuthorizationWithRefs,
      consumirUso: async (id) => {
        // UPDATE ... WHERE usos < max: o banco garante que dois acessos simultâneos não estourem o limite.
        const n = await db.$executeRaw`
          UPDATE "authorizations" SET "usosRealizados" = "usosRealizados" + 1, "updatedAt" = now()
          WHERE "id" = ${id} AND "status" = 'ATIVA' AND "usosRealizados" < "maxUsos"`;
        return n === 1;
      },
    },

    events: {
      create: (data) => db.accessEvent.create({ data }),
      list: async (f) => {
        const where = {
          resultado: f.resultado,
          metodo: f.metodo,
          userId: f.userId,
          accessPointId: f.accessPointId,
          createdAt: { gte: f.de, lte: f.ate },
        };
        const [itens, porResultado] = await Promise.all([
          db.accessEvent.findMany({
            where,
            include: { user: { select: { id: true, nome: true } }, catraca: { select: { id: true, nome: true } } },
            orderBy: { createdAt: 'desc' },
            take: f.limite,
            skip: f.pular,
          }),
          db.accessEvent.groupBy({ by: ['resultado'], where, _count: { _all: true } }),
        ]);
        const contar = (r: string) => porResultado.find((g) => g.resultado === r)?._count._all ?? 0;
        const liberados = contar('LIBERADO');
        const negados = contar('NEGADO');
        return { itens, total: liberados + negados, liberados, negados };
      },
    },

    qrTokens: {
      marcarUsado: async (jti) => {
        const r = await db.usedQrToken.createMany({ data: [{ jti }], skipDuplicates: true });
        return r.count === 1;
      },
    },
  };
}
