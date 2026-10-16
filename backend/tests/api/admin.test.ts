import { beforeEach, describe, expect, it } from 'vitest';
import { montarCenario, PERTO } from '../support/test-app.js';

type Cenario = Awaited<ReturnType<typeof montarCenario>>;

describe('Login (RF07)', () => {
  let c: Cenario;
  beforeEach(async () => {
    c = await montarCenario();
  });

  it('entra com e-mail e devolve o perfil, sem a senha', async () => {
    const res = await c.api.post('/auth/login').send({ login: 'maria@passe.com', senha: 'passe123' });
    expect(res.status).toBe(200);
    expect(res.body.usuario).toMatchObject({ nome: 'Maria Souza', perfil: 'CONDOMINO' });
    expect(res.body.usuario.senhaHash).toBeUndefined();
  });

  it('entra com CPF com pontuação', async () => {
    const res = await c.api.post('/auth/login').send({ login: '333.333.333-33', senha: 'passe123' });
    expect(res.status).toBe(200);
  });

  it('recusa senha errada com a mensagem do design', async () => {
    const res = await c.api.post('/auth/login').send({ login: 'maria@passe.com', senha: 'errada' });
    expect(res.status).toBe(401);
    expect(res.body.erro.mensagem).toBe('E-mail, CPF ou senha não conferem.');
  });

  it('/auth/me devolve quem está logado', async () => {
    const token = await c.tokenDe('maria@passe.com');
    const res = await c.api.get('/auth/me').set('Authorization', `Bearer ${token}`);
    expect(res.body.tags[0].uid).toBe('04A1B2C3');
  });

  it('valida o corpo da requisição', async () => {
    const res = await c.api.post('/auth/login').send({ login: '' });
    expect(res.status).toBe(400);
    expect(res.body.erro.detalhes).toHaveProperty('senha');
  });
});

describe('Usuários (RF01) e permissões', () => {
  let c: Cenario;
  let admin: string;
  let portaria: string;
  let maria: string;

  beforeEach(async () => {
    c = await montarCenario();
    admin = await c.tokenDe('carlos@passe.com');
    portaria = await c.tokenDe('paula@passe.com');
    maria = await c.tokenDe('maria@passe.com');
  });

  const novo = (perfil: string) => ({ nome: 'João Pereira', email: 'joao@passe.com', cpf: '765.430.000-11', senha: 'senha123', perfil });

  it('admin cadastra qualquer perfil', async () => {
    const res = await c.api.post('/users').set('Authorization', `Bearer ${admin}`).send(novo('ADMIN'));
    expect(res.status).toBe(201);
    expect(res.body.cpf).toBe('76543000011');
  });

  it('portaria cadastra visitante, mas não admin', async () => {
    const ok = await c.api.post('/users').set('Authorization', `Bearer ${portaria}`).send(novo('VISITANTE'));
    expect(ok.status).toBe(201);
    const negado = await c.api
      .post('/users')
      .set('Authorization', `Bearer ${portaria}`)
      .send({ ...novo('ADMIN'), email: 'outro@passe.com', cpf: '99999999999' });
    expect(negado.status).toBe(403);
  });

  it('condômino não acessa a administração', async () => {
    const res = await c.api.get('/users').set('Authorization', `Bearer ${maria}`);
    expect(res.status).toBe(403);
  });

  it('não deixa repetir e-mail ou CPF', async () => {
    const res = await c.api
      .post('/users')
      .set('Authorization', `Bearer ${admin}`)
      .send({ ...novo('CONDOMINO'), email: 'maria@passe.com' });
    expect(res.status).toBe(409);
  });

  it('vincula tag e não deixa a mesma tag em duas pessoas', async () => {
    const ana = c.pessoas.visitante.id;
    const ok = await c.api.post(`/users/${ana}/tags`).set('Authorization', `Bearer ${portaria}`).send({ uid: '91:C3:00:11' });
    expect(ok.status).toBe(201);
    expect(ok.body.uid).toBe('91C30011');
    const repetida = await c.api.post(`/users/${ana}/tags`).set('Authorization', `Bearer ${portaria}`).send({ uid: '04A1B2C3' });
    expect(repetida.status).toBe(409);
  });

  it('busca por nome', async () => {
    const res = await c.api.get('/users?busca=maria').set('Authorization', `Bearer ${admin}`);
    expect(res.body).toHaveLength(1);
  });
});

describe('Locais (RF02)', () => {
  it('admin monta edifício › portaria › porta › catraca; portaria só consulta', async () => {
    const c = await montarCenario();
    const admin = await c.tokenDe('carlos@passe.com');
    const portaria = await c.tokenDe('paula@passe.com');
    const auth = { Authorization: `Bearer ${admin}` };

    const ed = await c.api.post('/locations/buildings').set(auth).send({ nome: 'Torre Sul', endereco: 'Rua X, 10' });
    const gate = await c.api.post('/locations/gates').set(auth).send({ nome: 'Garagem', buildingId: ed.body.id });
    const porta = await c.api.post('/locations/doors').set(auth).send({ nome: 'Rampa', gateId: gate.body.id });
    const catraca = await c.api
      .post('/locations/access-points')
      .set(auth)
      .send({ nome: 'Catraca G1', doorId: porta.body.id, ...PERTO });
    expect(catraca.status).toBe(201);
    expect(catraca.body.raioMetros).toBe(100);

    const arvore = await c.api.get('/locations').set('Authorization', `Bearer ${portaria}`);
    expect(arvore.body).toHaveLength(2);

    const negado = await c.api
      .post('/locations/buildings')
      .set('Authorization', `Bearer ${portaria}`)
      .send({ nome: 'X', endereco: 'Y' });
    expect(negado.status).toBe(403);
  });
});

describe('Autorizações (RF03, RF04, RF05, RF08)', () => {
  let c: Cenario;
  let admin: string;

  beforeEach(async () => {
    c = await montarCenario();
    admin = await c.tokenDe('carlos@passe.com');
  });

  const criar = (dados: object = {}) =>
    c.api
      .post('/authorizations')
      .set('Authorization', `Bearer ${admin}`)
      .send({
        userId: c.pessoas.visitante.id,
        accessPointId: c.catraca.id,
        dataInicio: '2026-10-14',
        dataFim: '2026-10-14',
        horaInicio: '14:00',
        horaFim: '16:00',
        maxUsos: 1,
        ...dados,
      });

  it('cria com todos os campos do RF03 e calcula a situação', async () => {
    const res = await criar();
    expect(res.status).toBe(201);
    expect(res.body).toMatchObject({ situacao: 'ATIVA', usosRestantes: 1, user: { nome: 'Ana Lima' }, catraca: { nome: 'Catraca 2' } });
  });

  it('recusa término antes do início', async () => {
    const res = await criar({ dataInicio: '2026-10-20', dataFim: '2026-10-10' });
    expect(res.status).toBe(400);
  });

  it('recusa data ou hora em formato errado', async () => {
    const res = await criar({ dataInicio: '14/10/2026', horaFim: '25:00' });
    expect(res.status).toBe(400);
    expect(Object.keys(res.body.erro.detalhes)).toEqual(expect.arrayContaining(['dataInicio', 'horaFim']));
  });

  it('filtra por situação e por pessoa', async () => {
    await criar();
    await criar({ dataInicio: '2026-09-01', dataFim: '2026-09-30' });
    const auth = { Authorization: `Bearer ${admin}` };

    const ativas = await c.api.get('/authorizations?situacao=ATIVA').set(auth);
    expect(ativas.body).toHaveLength(2);
    const expiradas = await c.api.get('/authorizations?situacao=EXPIRADA').set(auth);
    expect(expiradas.body).toHaveLength(1);
    const daAna = await c.api.get(`/authorizations?userId=${c.pessoas.visitante.id}`).set(auth);
    expect(daAna.body).toHaveLength(2);
  });

  it('cancela e não deixa editar depois', async () => {
    const { body } = await criar();
    const auth = { Authorization: `Bearer ${admin}` };
    const cancelada = await c.api.post(`/authorizations/${body.id}/cancel`).set(auth);
    expect(cancelada.body.situacao).toBe('CANCELADA');
    const edicao = await c.api.patch(`/authorizations/${body.id}`).set(auth).send({ maxUsos: 5 });
    expect(edicao.status).toBe(409);
  });

  it('o usuário vê só as próprias autorizações', async () => {
    await criar();
    const token = await c.tokenDe('maria@passe.com');
    const res = await c.api.get('/me/authorizations').set('Authorization', `Bearer ${token}`);
    expect(res.body).toHaveLength(1);
    expect(res.body[0]).toMatchObject({ situacao: 'ATIVA', usosRestantes: 7 });
  });
});

describe('Histórico e painel (RF06)', () => {
  it('lista tentativas com contagem de liberados e negados', async () => {
    const c = await montarCenario();
    await c.api.post('/terminal/nfc').set(c.terminalHeaders).send({ uid: '04A1B2C3' });
    await c.api.post('/terminal/nfc').set(c.terminalHeaders).send({ uid: 'FFFFFFFF' });
    const auth = { Authorization: `Bearer ${await c.tokenDe('paula@passe.com')}` };

    const historico = await c.api.get('/access-events').set(auth);
    expect(historico.body).toMatchObject({ total: 2, liberados: 1, negados: 1 });
    expect(historico.body.itens[0].catraca.nome).toBe('Catraca 2');

    const negados = await c.api.get('/access-events?resultado=NEGADO').set(auth);
    expect(negados.body.itens).toHaveLength(1);

    const painel = await c.api.get('/dashboard').set(auth);
    expect(painel.body).toMatchObject({ acessosHoje: 1, negadosHoje: 1, autorizacoesAtivas: 1 });
  });

  it('cadastra terminal e mostra a chave uma única vez', async () => {
    const c = await montarCenario();
    const auth = { Authorization: `Bearer ${await c.tokenDe('carlos@passe.com')}` };
    const repetido = await c.api.post('/terminals').set(auth).send({ nome: 'Outro', accessPointId: c.catraca.id });
    expect(repetido.status).toBe(409);

    const lista = await c.api.get('/terminals').set(auth);
    expect(lista.body[0]).not.toHaveProperty('chaveHash');
    expect(lista.body[0].online).toBe(false);
  });

  it('responde 404 em rota inexistente e /health', async () => {
    const c = await montarCenario();
    expect((await c.api.get('/nao-existe')).status).toBe(404);
    expect((await c.api.get('/health')).body.status).toBe('ok');
  });
});
