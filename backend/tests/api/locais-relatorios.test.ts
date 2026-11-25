import { beforeEach, describe, expect, it } from 'vitest';
import type { NewAccessEvent } from '../../src/modules/events/events.types.js';
import { fimDoDiaLocal, inicioDoDiaLocal } from '../../src/shared/clock.js';
import { montarCenario, PERTO } from '../support/test-app.js';

type Cenario = Awaited<ReturnType<typeof montarCenario>>;

const NINGUEM = '00000000-0000-4000-8000-00000000dead';

/** Grava um evento no instante dado, sem passar pela validação (o relatório só agrupa). */
async function evento(c: Cenario, quando: string, dados: Pick<NewAccessEvent, 'resultado'> & Partial<NewAccessEvent>) {
  c.clock.irPara(quando);
  return c.repos.events.create({
    metodo: 'NFC',
    motivo: null,
    userId: null,
    accessPointId: c.catraca.id,
    terminalId: null,
    authorizationId: null,
    credencial: null,
    latitude: null,
    longitude: null,
    distanciaMetros: null,
    ...dados,
  });
}

describe('Locais: editar e apagar (só o admin)', () => {
  let c: Cenario;
  let admin: { Authorization: string };
  let portaria: { Authorization: string };

  beforeEach(async () => {
    c = await montarCenario();
    admin = { Authorization: `Bearer ${await c.tokenDe('carlos@passe.com')}` };
    portaria = { Authorization: `Bearer ${await c.tokenDe('paula@passe.com')}` };
  });

  const caminho = () => {
    const porta = c.db.doors.find((d) => d.id === c.catraca.doorId)!;
    const gate = c.db.gates.find((g) => g.id === porta.gateId)!;
    return { porta, gate, edificio: c.db.buildings.find((b) => b.id === gate.buildingId)! };
  };

  /** Edifício › portaria › porta › catraca novos, sem terminal nem autorização. */
  async function ramoVazio() {
    const edificio = await c.repos.locations.createBuilding({ nome: 'Torre Sul', endereco: 'Rua X, 10' });
    const gate = await c.repos.locations.createGate({ nome: 'Garagem', buildingId: edificio.id });
    const porta = await c.repos.locations.createDoor({ nome: 'Rampa', gateId: gate.id });
    const catraca = await c.repos.locations.createAccessPoint({ nome: 'Catraca G1', doorId: porta.id, raioMetros: 100, ...PERTO });
    return { edificio, gate, porta, catraca };
  }

  it('edita o edifício, a portaria e a porta', async () => {
    const { edificio, gate, porta } = caminho();

    const ed = await c.api.patch(`/locations/buildings/${edificio.id}`).set(admin).send({ endereco: 'Av. Paulista, 2000' });
    expect(ed.status).toBe(200);
    expect(ed.body).toEqual({ id: edificio.id, nome: 'Edifício Atlântico', endereco: 'Av. Paulista, 2000' });

    // Portaria e porta só trocam de nome: o id do pai que vier no corpo é ignorado.
    const g = await c.api.patch(`/locations/gates/${gate.id}`).set(admin).send({ nome: 'Portaria Social', buildingId: NINGUEM });
    expect(g.status).toBe(200);
    expect(g.body).toEqual({ id: gate.id, nome: 'Portaria Social', buildingId: edificio.id });

    const p = await c.api.patch(`/locations/doors/${porta.id}`).set(admin).send({ nome: 'Porta B' });
    expect(p.status).toBe(200);
    expect(p.body).toEqual({ id: porta.id, nome: 'Porta B', gateId: gate.id });

    const arvore = await c.api.get('/locations').set(portaria);
    expect(arvore.body[0]).toMatchObject({ endereco: 'Av. Paulista, 2000', portarias: [{ nome: 'Portaria Social', portas: [{ nome: 'Porta B' }] }] });
  });

  it('não aceita nome vazio e responde 404 para id que não existe', async () => {
    const vazio = await c.api.patch(`/locations/doors/${caminho().porta.id}`).set(admin).send({ nome: '  ' });
    expect(vazio.status).toBe(400);
    expect(vazio.body.erro.detalhes.nome).toEqual(['Informe o nome']);

    const editar = await c.api.patch(`/locations/gates/${NINGUEM}`).set(admin).send({ nome: 'X' });
    expect(editar.status).toBe(404);
    expect(editar.body.erro.mensagem).toBe('Portaria não encontrado(a).');

    for (const tipo of ['buildings', 'gates', 'doors', 'access-points']) {
      const apagar = await c.api.delete(`/locations/${tipo}/${NINGUEM}`).set(admin);
      expect(apagar.status).toBe(404);
      expect(apagar.body.erro.codigo).toBe('NAO_ENCONTRADO');
    }
  });

  it('apaga de baixo para cima o que está vazio', async () => {
    const { edificio, gate, porta, catraca } = await ramoVazio();

    expect((await c.api.delete(`/locations/access-points/${catraca.id}`).set(admin)).status).toBe(204);
    expect((await c.api.delete(`/locations/doors/${porta.id}`).set(admin)).status).toBe(204);
    expect((await c.api.delete(`/locations/gates/${gate.id}`).set(admin)).status).toBe(204);
    const res = await c.api.delete(`/locations/buildings/${edificio.id}`).set(admin);
    expect(res.status).toBe(204);
    expect(res.text).toBe('');

    const arvore = await c.api.get('/locations').set(admin);
    expect(arvore.body.map((b: { nome: string }) => b.nome)).toEqual(['Edifício Atlântico']);
  });

  it('não apaga edifício, portaria nem porta que ainda têm filhos', async () => {
    const { edificio, gate, porta } = caminho();

    const ed = await c.api.delete(`/locations/buildings/${edificio.id}`).set(admin);
    expect(ed.status).toBe(409);
    expect(ed.body.erro).toMatchObject({ codigo: 'CONFLITO', mensagem: 'Este edifício ainda tem portarias. Apague-as antes.' });

    const g = await c.api.delete(`/locations/gates/${gate.id}`).set(admin);
    expect(g.status).toBe(409);
    expect(g.body.erro.mensagem).toBe('Esta portaria ainda tem portas. Apague-as antes.');

    const p = await c.api.delete(`/locations/doors/${porta.id}`).set(admin);
    expect(p.status).toBe(409);
    expect(p.body.erro.mensagem).toBe('Esta porta ainda tem catracas. Apague-as antes.');

    expect(c.db.buildings).toHaveLength(1);
    expect(c.db.accessPoints).toHaveLength(1);
  });

  it('não apaga catraca com terminal nem com autorizações', async () => {
    const comTerminal = await c.api.delete(`/locations/access-points/${c.catraca.id}`).set(admin);
    expect(comTerminal.status).toBe(409);
    expect(comTerminal.body.erro.mensagem).toBe('Esta catraca tem um terminal. Remova o terminal antes.');

    // Mesmo cancelada, a autorização é histórico.
    const { catraca } = await ramoVazio();
    const autorizacao = await c.repos.authorizations.create({
      userId: c.pessoas.visitante.id,
      accessPointId: catraca.id,
      dataInicio: '2026-10-01',
      dataFim: '2026-10-02',
      horaInicio: '08:00',
      horaFim: '18:00',
      maxUsos: 1,
    });
    await c.repos.authorizations.update(autorizacao.id, { status: 'CANCELADA', canceladaEm: c.clock.now() });

    const comAutorizacao = await c.api.delete(`/locations/access-points/${catraca.id}`).set(admin);
    expect(comAutorizacao.status).toBe(409);
    expect(comAutorizacao.body.erro.mensagem).toBe('Esta catraca tem autorizações. Ela não pode ser apagada, para não perder o histórico.');
    expect(c.db.accessPoints.some((x) => x.id === catraca.id)).toBe(true);
  });

  it('apagar a catraca não apaga os eventos de acesso', async () => {
    const { catraca } = await ramoVazio();
    const tentativa = await evento(c, '2026-10-14T13:00:00.000Z', { resultado: 'NEGADO', motivo: 'TAG_DESCONHECIDA', accessPointId: catraca.id });

    expect((await c.api.delete(`/locations/access-points/${catraca.id}`).set(admin)).status).toBe(204);

    const historico = await c.api.get('/access-events').set(portaria);
    expect(historico.body.itens.find((e: { id: string }) => e.id === tentativa.id)).toMatchObject({
      accessPointId: null,
      catraca: null,
      motivo: 'TAG_DESCONHECIDA',
    });
  });

  it('a portaria consulta, mas não edita nem apaga (403)', async () => {
    const { edificio, gate, porta } = caminho();
    const tentativas = [
      () => c.api.patch(`/locations/buildings/${edificio.id}`).send({ nome: 'X' }),
      () => c.api.patch(`/locations/gates/${gate.id}`).send({ nome: 'X' }),
      () => c.api.patch(`/locations/doors/${porta.id}`).send({ nome: 'X' }),
      () => c.api.delete(`/locations/buildings/${edificio.id}`),
      () => c.api.delete(`/locations/gates/${gate.id}`),
      () => c.api.delete(`/locations/doors/${porta.id}`),
      () => c.api.delete(`/locations/access-points/${c.catraca.id}`),
    ];
    for (const tentativa of tentativas) {
      const res = await tentativa().set(portaria);
      expect(res.status).toBe(403);
      expect(res.body.erro.codigo).toBe('SEM_PERMISSAO');
    }
    expect(caminho().edificio.nome).toBe('Edifício Atlântico');
  });
});

describe('Relatório de acessos (GET /reports/access)', () => {
  let c: Cenario;
  let portaria: { Authorization: string };

  beforeEach(async () => {
    c = await montarCenario();
    portaria = { Authorization: `Bearer ${await c.tokenDe('paula@passe.com')}` };
  });

  it('sem filtro traz os últimos 7 dias, contando hoje, mesmo zerados', async () => {
    const res = await c.api.get('/reports/access').set(portaria);
    expect(res.status).toBe(200);
    expect(res.body).toEqual({
      de: '2026-10-08',
      ate: '2026-10-14',
      total: 0,
      liberados: 0,
      negados: 0,
      porDia: ['08', '09', '10', '11', '12', '13', '14'].map((d) => ({ dia: `2026-10-${d}`, liberados: 0, negados: 0 })),
      porMetodo: [
        { metodo: 'QR', liberados: 0, negados: 0 },
        { metodo: 'NFC', liberados: 0, negados: 0 },
        { metodo: 'CELULAR', liberados: 0, negados: 0 },
      ],
      porCatraca: [],
      porMotivo: [],
    });
  });

  it('conta cada evento no dia do prédio: 23:30 de Brasília não vira o dia seguinte', async () => {
    const catraca3 = await c.repos.locations.createAccessPoint({ nome: 'Catraca 3', doorId: c.catraca.doorId, raioMetros: 100, ...PERTO });
    // 12/10 23:30 em Brasília: fora do período.
    await evento(c, '2026-10-13T02:30:00.000Z', { resultado: 'NEGADO', motivo: 'TAG_DESCONHECIDA' });
    // 13/10 23:30 em Brasília (já é 14/10 em UTC).
    await evento(c, '2026-10-14T02:30:00.000Z', { resultado: 'NEGADO', motivo: 'TAG_DESCONHECIDA' });
    // 14/10
    await evento(c, '2026-10-14T12:00:00.000Z', { resultado: 'LIBERADO' });
    await evento(c, '2026-10-14T13:00:00.000Z', { resultado: 'NEGADO', motivo: 'TAG_DESCONHECIDA' });
    await evento(c, '2026-10-14T14:00:00.000Z', { resultado: 'LIBERADO', metodo: 'QR', accessPointId: catraca3.id });
    await evento(c, '2026-10-14T15:00:00.000Z', { resultado: 'NEGADO', metodo: 'QR', motivo: 'QR_INVALIDO', accessPointId: null });
    // 14/10 23:30 em Brasília (15/10 em UTC): ainda conta no dia 14.
    await evento(c, '2026-10-15T02:30:00.000Z', { resultado: 'NEGADO', motivo: 'FORA_DO_HORARIO' });
    // 15/10 00:30 em Brasília: fora do período.
    await evento(c, '2026-10-15T03:30:00.000Z', { resultado: 'LIBERADO' });

    const res = await c.api.get('/reports/access?de=2026-10-13&ate=2026-10-14').set(portaria);
    expect(res.status).toBe(200);
    expect(res.body).toEqual({
      de: '2026-10-13',
      ate: '2026-10-14',
      total: 6,
      liberados: 2,
      negados: 4,
      porDia: [
        { dia: '2026-10-13', liberados: 0, negados: 1 },
        { dia: '2026-10-14', liberados: 2, negados: 3 },
      ],
      porMetodo: [
        { metodo: 'QR', liberados: 1, negados: 1 },
        { metodo: 'NFC', liberados: 1, negados: 3 },
        { metodo: 'CELULAR', liberados: 0, negados: 0 },
      ],
      porCatraca: [
        { catraca: { id: c.catraca.id, nome: 'Catraca 2' }, liberados: 1, negados: 3 },
        { catraca: { id: catraca3.id, nome: 'Catraca 3' }, liberados: 1, negados: 0 },
        { catraca: null, liberados: 0, negados: 1 },
      ],
      porMotivo: [
        { motivo: 'TAG_DESCONHECIDA', titulo: 'Tag não cadastrada', total: 2 },
        { motivo: 'FORA_DO_HORARIO', titulo: 'Fora do horário permitido', total: 1 },
        { motivo: 'QR_INVALIDO', titulo: 'QR Code não reconhecido', total: 1 },
      ],
    });

    const soCatraca3 = await c.api.get(`/reports/access?de=2026-10-13&ate=2026-10-14&accessPointId=${catraca3.id}`).set(portaria);
    expect(soCatraca3.body).toMatchObject({ total: 1, liberados: 1, porCatraca: [{ catraca: { nome: 'Catraca 3' } }], porMotivo: [] });
  });

  it('conta as tentativas reais feitas no terminal', async () => {
    await c.api.post('/terminal/nfc').set(c.terminalHeaders).send({ uid: '04A1B2C3' });
    await c.api.post('/terminal/nfc').set(c.terminalHeaders).send({ uid: 'FFFFFFFF' });

    const res = await c.api.get('/reports/access?de=2026-10-14&ate=2026-10-14').set(portaria);
    expect(res.body).toMatchObject({
      total: 2,
      porDia: [{ dia: '2026-10-14', liberados: 1, negados: 1 }],
      porMotivo: [{ motivo: 'TAG_DESCONHECIDA', total: 1 }],
    });
  });

  it('aceita até 366 dias e recusa período maior ou invertido', async () => {
    const ano = await c.api.get('/reports/access?de=2025-10-14&ate=2026-10-14').set(portaria);
    expect(ano.status).toBe(200);
    expect(ano.body.porDia).toHaveLength(366);

    const longo = await c.api.get('/reports/access?de=2025-10-13&ate=2026-10-14').set(portaria);
    expect(longo.status).toBe(400);
    expect(longo.body.erro).toEqual({
      codigo: 'DADOS_INVALIDOS',
      mensagem: 'Escolha um período de até 366 dias.',
      detalhes: { ate: ['Escolha um período de até 366 dias.'] },
    });

    const invertido = await c.api.get('/reports/access?de=2026-10-14&ate=2026-10-13').set(portaria);
    expect(invertido.status).toBe(400);
    expect(invertido.body.erro.mensagem).toBe('A data inicial precisa ser antes da data final.');

    const formato = await c.api.get('/reports/access?de=14/10/2026').set(portaria);
    expect(formato.status).toBe(400);
    expect(formato.body.erro.detalhes.de).toContain('Use o formato AAAA-MM-DD');
  });

  it('é da equipe: o admin vê, o condômino não', async () => {
    const admin = { Authorization: `Bearer ${await c.tokenDe('carlos@passe.com')}` };
    expect((await c.api.get('/reports/access').set(admin)).status).toBe(200);

    const maria = { Authorization: `Bearer ${await c.tokenDe('maria@passe.com')}` };
    expect((await c.api.get('/reports/access').set(maria)).status).toBe(403);
    expect((await c.api.get('/reports/access')).status).toBe(401);
  });
});

describe('Histórico: filtro só com a data vale pelo dia inteiro no fuso do prédio', () => {
  let c: Cenario;

  beforeEach(async () => {
    c = await montarCenario();
  });

  async function eventosDoDia14() {
    const maria = c.pessoas.maria.id;
    return {
      // 13/10 22:00 em Brasília (14/10 01:00 UTC)
      vespera: await evento(c, '2026-10-14T01:00:00.000Z', { resultado: 'NEGADO', motivo: 'FORA_DO_HORARIO', userId: maria }),
      manha: await evento(c, '2026-10-14T12:00:00.000Z', { resultado: 'LIBERADO', userId: maria }),
      // 14/10 23:30 em Brasília (15/10 02:30 UTC)
      noite: await evento(c, '2026-10-15T02:30:00.000Z', { resultado: 'NEGADO', motivo: 'FORA_DO_HORARIO', userId: maria }),
    };
  }

  const ids = (body: { itens: { id: string }[] }) => body.itens.map((e) => e.id);

  it('GET /access-events?de=…&ate=… pega o dia 14 de 00:00 a 23:59:59.999', async () => {
    const { manha, noite } = await eventosDoDia14();
    const auth = { Authorization: `Bearer ${await c.tokenDe('paula@passe.com')}` };

    const res = await c.api.get('/access-events?de=2026-10-14&ate=2026-10-14').set(auth);
    expect(res.status).toBe(200);
    expect(ids(res.body)).toEqual([noite.id, manha.id]);
    expect(res.body).toMatchObject({ total: 2, liberados: 1, negados: 1 });
  });

  it('GET /me/access-events?ate=… inclui a noite do último dia', async () => {
    const { vespera, manha, noite } = await eventosDoDia14();
    const maria = { Authorization: `Bearer ${await c.tokenDe('maria@passe.com')}` };

    const ate14 = await c.api.get('/me/access-events?ate=2026-10-14').set(maria);
    expect(ids(ate14.body)).toEqual([noite.id, manha.id, vespera.id]);
    const ate13 = await c.api.get('/me/access-events?ate=2026-10-13').set(maria);
    expect(ids(ate13.body)).toEqual([vespera.id]);
  });

  it('data com hora continua valendo como o instante exato', async () => {
    const { vespera, manha } = await eventosDoDia14();
    const auth = { Authorization: `Bearer ${await c.tokenDe('paula@passe.com')}` };

    const res = await c.api.get('/access-events').query({ de: '2026-10-14T00:00:00.000Z', ate: '2026-10-14T12:00:00.000Z' }).set(auth);
    expect(ids(res.body)).toEqual([manha.id, vespera.id]);
  });

  it('data impossível responde 400', async () => {
    const auth = { Authorization: `Bearer ${await c.tokenDe('paula@passe.com')}` };
    for (const de of ['2026-02-31', 'ontem']) {
      const res = await c.api.get('/access-events').query({ de }).set(auth);
      expect(res.status).toBe(400);
      expect(res.body.erro.detalhes.de).toEqual(['Data inválida. Use AAAA-MM-DD ou data e hora ISO 8601.']);
    }
  });
});

describe('Começo e fim do dia no fuso', () => {
  it('Brasília: 00:00 é 03:00 UTC', () => {
    expect(inicioDoDiaLocal('2026-10-14', 'America/Sao_Paulo').toISOString()).toBe('2026-10-14T03:00:00.000Z');
    expect(fimDoDiaLocal('2026-10-14', 'America/Sao_Paulo').toISOString()).toBe('2026-10-15T02:59:59.999Z');
  });

  it('acerta os dias em que o horário de verão começa ou termina', () => {
    // Nova York: o relógio muda às 2 h.
    expect(inicioDoDiaLocal('2026-03-08', 'America/New_York').toISOString()).toBe('2026-03-08T05:00:00.000Z');
    expect(fimDoDiaLocal('2026-03-08', 'America/New_York').toISOString()).toBe('2026-03-09T03:59:59.999Z');
    expect(inicioDoDiaLocal('2026-11-01', 'America/New_York').toISOString()).toBe('2026-11-01T04:00:00.000Z');
    // Brasil em 2018: à meia-noite o relógio pulou para 01:00, então o dia começou às 01:00.
    expect(inicioDoDiaLocal('2018-11-04', 'America/Sao_Paulo').toISOString()).toBe('2018-11-04T03:00:00.000Z');
    expect(fimDoDiaLocal('2018-11-03', 'America/Sao_Paulo').toISOString()).toBe('2018-11-04T02:59:59.999Z');
    // Fuso de meia hora
    expect(inicioDoDiaLocal('2026-10-14', 'Asia/Kolkata').toISOString()).toBe('2026-10-13T18:30:00.000Z');
  });
});
