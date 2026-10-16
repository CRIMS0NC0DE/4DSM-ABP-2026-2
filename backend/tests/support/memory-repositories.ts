import { randomUUID } from 'node:crypto';
import type { Repositories } from '../../src/container.js';
import type { Authorization, AuthorizationWithRefs } from '../../src/modules/authorizations/authorizations.types.js';
import type { AccessEvent } from '../../src/modules/events/events.types.js';
import type { AccessPoint, Building, Door, Gate } from '../../src/modules/locations/locations.types.js';
import type { Terminal } from '../../src/modules/terminals/terminals.types.js';
import type { NfcTag, User } from '../../src/modules/users/users.types.js';

/** Repositórios em memória: mesmo contrato do Prisma, sem precisar de banco nos testes. */
export function createMemoryRepositories() {
  const db = {
    users: [] as User[],
    tags: [] as NfcTag[],
    buildings: [] as Building[],
    gates: [] as Gate[],
    doors: [] as Door[],
    accessPoints: [] as AccessPoint[],
    terminals: [] as Terminal[],
    authorizations: [] as Authorization[],
    events: [] as AccessEvent[],
    qrUsados: new Set<string>(),
  };

  const comTags = (u: User) => ({ ...u, tags: db.tags.filter((t) => t.userId === u.id) });
  const comRefs = (a: Authorization): AuthorizationWithRefs => {
    const u = db.users.find((x) => x.id === a.userId)!;
    const c = db.accessPoints.find((x) => x.id === a.accessPointId)!;
    return { ...a, user: { id: u.id, nome: u.nome, perfil: u.perfil }, catraca: { id: c.id, nome: c.nome } };
  };
  const atualizar = <T extends { id: string }>(lista: T[], id: string, dados: object): T => {
    const item = lista.find((x) => x.id === id);
    if (!item) throw new Error(`${id} não existe`);
    for (const [k, v] of Object.entries(dados)) if (v !== undefined) (item as Record<string, unknown>)[k] = v;
    return item;
  };

  const repos: Repositories = {
    users: {
      findById: async (id) => {
        const u = db.users.find((x) => x.id === id);
        return u ? comTags(u) : null;
      },
      findByEmail: async (email) => db.users.find((x) => x.email === email) ?? null,
      findByCpf: async (cpf) => db.users.find((x) => x.cpf === cpf) ?? null,
      list: async ({ busca, perfil }) =>
        db.users
          .filter((u) => !perfil || u.perfil === perfil)
          .filter((u) => !busca || u.nome.toLowerCase().includes(busca.toLowerCase()) || u.cpf.includes(busca))
          .map(comTags),
      create: async (data) => {
        const agora = new Date();
        const u: User = { id: randomUUID(), ativo: true, createdAt: agora, updatedAt: agora, ...data };
        db.users.push(u);
        return u;
      },
      update: async (id, data) => atualizar(db.users, id, data),
      findTagByUid: async (uid) => db.tags.find((t) => t.uid === uid) ?? null,
      findTagById: async (id) => db.tags.find((t) => t.id === id) ?? null,
      addTag: async (userId, uid) => {
        const t: NfcTag = { id: randomUUID(), userId, uid, ativa: true, createdAt: new Date() };
        db.tags.push(t);
        return t;
      },
      updateTag: async (id, data) => atualizar(db.tags, id, data),
      removeTag: async (id) => {
        db.tags = db.tags.filter((t) => t.id !== id);
      },
    },

    locations: {
      tree: async () =>
        db.buildings.map((b) => ({
          ...b,
          portarias: db.gates
            .filter((g) => g.buildingId === b.id)
            .map((g) => ({
              ...g,
              portas: db.doors
                .filter((d) => d.gateId === g.id)
                .map((d) => ({ ...d, catracas: db.accessPoints.filter((c) => c.doorId === d.id) })),
            })),
        })),
      createBuilding: async (data) => push(db.buildings, { id: randomUUID(), ...data }),
      createGate: async (data) => push(db.gates, { id: randomUUID(), ...data }),
      createDoor: async (data) => push(db.doors, { id: randomUUID(), ...data }),
      createAccessPoint: async (data) => push(db.accessPoints, { id: randomUUID(), ...data }),
      updateAccessPoint: async (id, data) => atualizar(db.accessPoints, id, data),
      findBuilding: async (id) => db.buildings.find((x) => x.id === id) ?? null,
      findGate: async (id) => db.gates.find((x) => x.id === id) ?? null,
      findDoor: async (id) => db.doors.find((x) => x.id === id) ?? null,
      findAccessPoint: async (id) => {
        const c = db.accessPoints.find((x) => x.id === id);
        if (!c) return null;
        const porta = db.doors.find((d) => d.id === c.doorId)!;
        const portaria = db.gates.find((g) => g.id === porta.gateId)!;
        const edificio = db.buildings.find((b) => b.id === portaria.buildingId)!;
        return { ...c, porta: porta.nome, portaria: portaria.nome, edificio: edificio.nome };
      },
    },

    terminals: {
      create: async (data) =>
        push(db.terminals, { id: randomUUID(), ultimoSinal: null, latitude: null, longitude: null, ...data }),
      findById: async (id) => db.terminals.find((x) => x.id === id) ?? null,
      findByAccessPoint: async (accessPointId) => db.terminals.find((x) => x.accessPointId === accessPointId) ?? null,
      list: async () => db.terminals,
      update: async (id, data) => atualizar(db.terminals, id, data),
    },

    authorizations: {
      create: async (data) =>
        comRefs(
          push(db.authorizations, {
            id: randomUUID(),
            usosRealizados: 0,
            status: 'ATIVA',
            canceladaEm: null,
            createdAt: new Date(),
            ...data,
          }),
        ),
      findById: async (id) => {
        const a = db.authorizations.find((x) => x.id === id);
        return a ? comRefs(a) : null;
      },
      list: async (f) =>
        db.authorizations
          .filter((a) => !f.userId || a.userId === f.userId)
          .filter((a) => !f.accessPointId || a.accessPointId === f.accessPointId)
          .filter((a) => {
            if (f.situacao === 'CANCELADA') return a.status === 'CANCELADA';
            if (f.situacao === 'ATIVA') return a.status === 'ATIVA' && a.dataFim >= f.hoje;
            if (f.situacao === 'EXPIRADA') return a.status === 'ATIVA' && a.dataFim < f.hoje;
            return true;
          })
          .filter((a) => (!f.de || a.dataFim >= f.de) && (!f.ate || a.dataInicio <= f.ate))
          .map(comRefs),
      listForAccess: async (userId, accessPointId) =>
        db.authorizations.filter((a) => a.userId === userId && a.accessPointId === accessPointId),
      update: async (id, data) => comRefs(atualizar(db.authorizations, id, data)),
      consumirUso: async (id) => {
        const a = db.authorizations.find((x) => x.id === id);
        if (!a || a.status !== 'ATIVA' || a.usosRealizados >= a.maxUsos) return false;
        a.usosRealizados += 1;
        return true;
      },
    },

    events: {
      create: async (data) => push(db.events, { id: randomUUID(), createdAt: new Date(), ...data }),
      list: async (f) => {
        const filtrados = db.events
          .filter((e) => (!f.resultado || e.resultado === f.resultado) && (!f.metodo || e.metodo === f.metodo))
          .filter((e) => (!f.userId || e.userId === f.userId) && (!f.accessPointId || e.accessPointId === f.accessPointId))
          .filter((e) => (!f.de || e.createdAt >= f.de) && (!f.ate || e.createdAt <= f.ate))
          .reverse();
        const itens = filtrados.slice(f.pular, f.pular + f.limite).map((e) => {
          const u = db.users.find((x) => x.id === e.userId);
          const c = db.accessPoints.find((x) => x.id === e.accessPointId);
          return { ...e, user: u ? { id: u.id, nome: u.nome } : null, catraca: c ? { id: c.id, nome: c.nome } : null };
        });
        const liberados = filtrados.filter((e) => e.resultado === 'LIBERADO').length;
        return { itens, total: filtrados.length, liberados, negados: filtrados.length - liberados };
      },
    },

    qrTokens: {
      marcarUsado: async (jti) => {
        if (db.qrUsados.has(jti)) return false;
        db.qrUsados.add(jti);
        return true;
      },
    },
  };

  return { repos, db };
}

function push<T>(lista: T[], item: T): T {
  lista.push(item);
  return item;
}
