import { beforeEach, describe, expect, it } from 'vitest';
import { LONGE, montarCenario, PERTO } from '../support/test-app.js';

type Cenario = Awaited<ReturnType<typeof montarCenario>>;

describe('Acesso por QR Code (RF12, RF13, RF15-RF17)', () => {
  let c: Cenario;
  let tokenMaria: string;

  beforeEach(async () => {
    c = await montarCenario();
    tokenMaria = await c.tokenDe('maria@passe.com');
  });

  const qrDoTerminal = async () => (await c.api.get('/terminal/qr-token').set(c.terminalHeaders)).body.token as string;
  const escanear = (token: string, posicao: object = PERTO, jwt = tokenMaria) =>
    c.api.post('/access/qr').set('Authorization', `Bearer ${jwt}`).send({ token, ...posicao });

  it('o terminal recebe um QR novo, que troca a cada 10 s', async () => {
    const res = await c.api.get('/terminal/qr-token').set(c.terminalHeaders);
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({ trocarEmSegundos: 10 });
    expect(typeof res.body.token).toBe('string');
  });

  it('o terminal precisa se identificar com a chave certa', async () => {
    const res = await c.api.get('/terminal/qr-token').set({ 'X-Terminal-Id': c.terminal.id, 'X-Terminal-Key': 'errada' });
    expect(res.status).toBe(401);
  });

  it('libera a Maria, desconta um uso, registra o evento e manda ABRIR para o terminal', async () => {
    const res = await escanear(await qrDoTerminal());

    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({ liberado: true, titulo: 'Acesso liberado', usosRestantes: 6 });
    expect(res.body.catraca.caminho).toBe('Edifício Atlântico › Portaria Principal › Porta A');
    expect(c.db.authorizations[0]!.usosRealizados).toBe(4);
    expect(c.db.events).toHaveLength(1);
    expect(c.db.events[0]).toMatchObject({ resultado: 'LIBERADO', metodo: 'QR', userId: c.pessoas.maria.id });

    const decisoes = await c.api.get('/terminal/decisions').set(c.terminalHeaders);
    expect(decisoes.body.at(-1).decisao).toMatchObject({ acao: 'ABRIR', nome: 'Maria' });
  });

  it('nega quem está a mais de 100 m da catraca', async () => {
    const res = await escanear(await qrDoTerminal(), LONGE);
    expect(res.body).toMatchObject({ liberado: false, motivo: 'LONGE_DO_TERMINAL' });
    expect(res.body.distanciaMetros).toBeGreaterThan(900);
    expect(c.db.authorizations[0]!.usosRealizados).toBe(3);
  });

  it('nega sem a localização do celular', async () => {
    const res = await escanear(await qrDoTerminal(), {});
    expect(res.body).toMatchObject({ liberado: false, motivo: 'LOCALIZACAO_AUSENTE' });
  });

  it('usa o GPS do terminal quando ele informa a posição', async () => {
    await c.api.post('/terminal/heartbeat').set(c.terminalHeaders).send(LONGE);
    const res = await escanear(await qrDoTerminal(), LONGE);
    expect(res.body.liberado).toBe(true);
  });

  it('nega QR vencido (foto ou print antigo)', async () => {
    const token = await qrDoTerminal();
    c.clock.avancar(25);
    const res = await escanear(token);
    expect(res.body).toMatchObject({ liberado: false, motivo: 'QR_EXPIRADO' });
  });

  it('o mesmo QR não serve duas vezes', async () => {
    const token = await qrDoTerminal();
    await escanear(token);
    const res = await escanear(token);
    expect(res.body).toMatchObject({ liberado: false, motivo: 'QR_JA_UTILIZADO' });
  });

  it('nega fora do horário e explica o motivo', async () => {
    c.clock.irPara('2026-10-14T22:42:00Z'); // 19:42 em Brasília
    const res = await escanear(await qrDoTerminal());
    expect(res.body).toMatchObject({
      liberado: false,
      motivo: 'FORA_DO_HORARIO',
      titulo: 'Fora do horário permitido',
      oQueFazer: 'Volte dentro do horário ou fale com a portaria.',
    });
    expect(c.db.events[0]).toMatchObject({ resultado: 'NEGADO', motivo: 'FORA_DO_HORARIO' });
  });

  it('nega quem não tem autorização para a catraca', async () => {
    const res = await escanear(await qrDoTerminal(), PERTO, await c.tokenDe('ana@passe.com'));
    expect(res.body).toMatchObject({ liberado: false, motivo: 'SEM_AUTORIZACAO' });
  });

  it('nega quando os usos acabam', async () => {
    c.db.authorizations[0]!.usosRealizados = 10;
    const res = await escanear(await qrDoTerminal());
    expect(res.body).toMatchObject({ liberado: false, motivo: 'SEM_USOS' });
  });

  it('nega autorização cancelada', async () => {
    const admin = await c.tokenDe('carlos@passe.com');
    await c.api.post(`/authorizations/${c.autorizacaoMaria.id}/cancel`).set('Authorization', `Bearer ${admin}`);
    const res = await escanear(await qrDoTerminal());
    expect(res.body).toMatchObject({ liberado: false, motivo: 'AUTORIZACAO_CANCELADA' });
  });

  it('nega QR forjado', async () => {
    const res = await escanear('eyJhbGciOiJIUzI1NiJ9.eyJ0aWQiOiJ4In0.assinatura-falsa');
    expect(res.body).toMatchObject({ liberado: false, motivo: 'QR_INVALIDO' });
  });

  it('exige login no app', async () => {
    const res = await c.api.post('/access/qr').send({ token: 'qualquer-coisa', ...PERTO });
    expect(res.status).toBe(401);
  });
});

describe('Acesso por tag NFC (RF10, RF14)', () => {
  let c: Cenario;

  beforeEach(async () => {
    c = await montarCenario();
  });

  const encostar = (uid: string) => c.api.post('/terminal/nfc').set(c.terminalHeaders).send({ uid });

  it('libera a tag da Maria (aceita o UID com separadores)', async () => {
    const res = await encostar('04:a1:b2:c3');
    expect(res.body).toMatchObject({ liberado: true, usosRestantes: 6 });
    expect(c.db.events[0]).toMatchObject({ metodo: 'NFC', resultado: 'LIBERADO', credencial: '04A1B2C3' });
  });

  it('nega tag desconhecida e registra a tentativa', async () => {
    const res = await encostar('DEADBEEF');
    expect(res.body).toMatchObject({ liberado: false, motivo: 'TAG_DESCONHECIDA' });
    expect(c.db.events[0]).toMatchObject({ resultado: 'NEGADO', userId: null });
  });

  it('nega tag bloqueada (perdida)', async () => {
    c.db.tags[0]!.ativa = false;
    const res = await encostar('04A1B2C3');
    expect(res.body).toMatchObject({ liberado: false, motivo: 'TAG_BLOQUEADA' });
  });

  it('nega usuário desativado', async () => {
    c.db.users.find((u) => u.id === c.pessoas.maria.id)!.ativo = false;
    const res = await encostar('04A1B2C3');
    expect(res.body).toMatchObject({ liberado: false, motivo: 'USUARIO_INATIVO' });
  });

  it('só terminal cadastrado pode enviar leitura', async () => {
    const res = await c.api.post('/terminal/nfc').send({ uid: '04A1B2C3' });
    expect(res.status).toBe(401);
  });
});
