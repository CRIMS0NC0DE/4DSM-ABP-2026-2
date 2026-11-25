import { beforeEach, describe, expect, it } from 'vitest';
import { montarCenario, PERTO } from '../support/test-app.js';

type Cenario = Awaited<ReturnType<typeof montarCenario>>;

// O relógio do cenário está em 14/10/2026, 09:00 de Brasília. A Maria tem autorização na
// Catraca 2 de 01/10 a 31/10, das 08:00 às 18:00.

describe('Cadastro pelo app (POST /auth/register)', () => {
  let c: Cenario;
  beforeEach(async () => {
    c = await montarCenario();
  });

  const pedido = { nome: 'João Pereira', email: 'Joao@Exemplo.com', cpf: '555.555.555-55', senha: 'segredo1' };

  it('cria um morador inativo, que só entra depois que a portaria libera', async () => {
    const res = await c.api.post('/auth/register').send(pedido);
    expect(res.status).toBe(201);
    expect(res.body.mensagem).toBe('Pedido enviado. A portaria vai liberar seu acesso.');
    expect(res.body.usuario).toMatchObject({ email: 'joao@exemplo.com', cpf: '55555555555', perfil: 'CONDOMINO', ativo: false });
    expect(res.body.usuario.senhaHash).toBeUndefined();

    const antes = await c.api.post('/auth/login').send({ login: 'joao@exemplo.com', senha: 'segredo1' });
    expect(antes.status).toBe(401);
    expect(antes.body.erro.codigo).toBe('CADASTRO_DESATIVADO');

    const portaria = await c.tokenDe('paula@passe.com');
    const liberar = await c.api
      .patch(`/users/${res.body.usuario.id}`)
      .set('Authorization', `Bearer ${portaria}`)
      .send({ ativo: true });
    expect(liberar.status).toBe(200);

    const depois = await c.api.post('/auth/login').send({ login: '555.555.555-55', senha: 'segredo1' });
    expect(depois.status).toBe(200);
    expect(depois.body.usuario.perfil).toBe('CONDOMINO');
  });

  it('não aceita e-mail ou CPF que já existem', async () => {
    const email = await c.api.post('/auth/register').send({ ...pedido, email: 'maria@passe.com' });
    expect(email.status).toBe(409);
    const cpf = await c.api.post('/auth/register').send({ ...pedido, cpf: '33333333333' });
    expect(cpf.status).toBe(409);
  });

  it('valida os campos com mensagens em português', async () => {
    const res = await c.api.post('/auth/register').send({ nome: 'Jo', email: 'x', cpf: '123', senha: '1' });
    expect(res.status).toBe(400);
    expect(res.body.erro.detalhes).toMatchObject({
      nome: ['Informe o nome completo'],
      email: ['E-mail inválido'],
      cpf: ['O CPF precisa ter 11 números'],
      senha: ['A senha precisa de pelo menos 6 caracteres'],
    });
  });
});

describe('Comunicados', () => {
  let c: Cenario;
  beforeEach(async () => {
    c = await montarCenario();
  });

  it('o admin publica e apaga; todos leem, do mais novo para o mais antigo', async () => {
    const admin = await c.tokenDe('carlos@passe.com');
    const primeiro = await c.api
      .post('/announcements')
      .set('Authorization', `Bearer ${admin}`)
      .send({ titulo: 'Manutenção', mensagem: 'A catraca 2 para às 14h.' });
    expect(primeiro.status).toBe(201);
    expect(primeiro.body).toMatchObject({ titulo: 'Manutenção', autor: { nome: 'Carlos Lima' } });
    c.clock.avancar(60);
    await c.api.post('/announcements').set('Authorization', `Bearer ${admin}`).send({ titulo: 'Festa', mensagem: 'Sábado.' });

    const morador = await c.tokenDe('maria@passe.com');
    const lista = await c.api.get('/announcements').set('Authorization', `Bearer ${morador}`);
    expect(lista.status).toBe(200);
    expect(lista.body.map((x: { titulo: string }) => x.titulo)).toEqual(['Festa', 'Manutenção']);

    const apagar = await c.api.delete(`/announcements/${primeiro.body.id}`).set('Authorization', `Bearer ${admin}`);
    expect(apagar.status).toBe(204);
    const deNovo = await c.api.delete(`/announcements/${primeiro.body.id}`).set('Authorization', `Bearer ${admin}`);
    expect(deNovo.status).toBe(404);
  });

  it('a portaria e o morador não publicam', async () => {
    for (const email of ['paula@passe.com', 'maria@passe.com']) {
      const token = await c.tokenDe(email);
      const res = await c.api.post('/announcements').set('Authorization', `Bearer ${token}`).send({ titulo: 'Oi', mensagem: 'Teste' });
      expect(res.status).toBe(403);
    }
  });

  it('exige login para ler', async () => {
    expect((await c.api.get('/announcements')).status).toBe(401);
  });
});

describe('Configurações', () => {
  let c: Cenario;
  beforeEach(async () => {
    c = await montarCenario();
  });

  it('todos leem as regras e os valores do sistema', async () => {
    const ana = await c.tokenDe('ana@passe.com');
    const res = await c.api.get('/settings').set('Authorization', `Bearer ${ana}`);
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({
      moradorPodeConvidar: true,
      visitanteMaxUsos: 2,
      visitanteDiasMax: 7,
      sistema: { fuso: 'America/Sao_Paulo', qrTrocaSegundos: 10, qrValidadeSegundos: 20, raioPadraoMetros: 100 },
    });
    expect(res.body.atualizadoEm).toBeDefined();
  });

  it('só o admin altera, com os limites da tela', async () => {
    const admin = await c.tokenDe('carlos@passe.com');
    const ok = await c.api
      .patch('/settings')
      .set('Authorization', `Bearer ${admin}`)
      .send({ contatoPortaria: 'Ramal 100', visitanteMaxUsos: 4 });
    expect(ok.status).toBe(200);
    expect(ok.body).toMatchObject({ contatoPortaria: 'Ramal 100', visitanteMaxUsos: 4, visitanteDiasMax: 7 });

    const fora = await c.api.patch('/settings').set('Authorization', `Bearer ${admin}`).send({ visitanteDiasMax: 90 });
    expect(fora.status).toBe(400);
    expect(fora.body.erro.detalhes.visitanteDiasMax).toEqual(['Use até 30 dias']);

    const paula = await c.tokenDe('paula@passe.com');
    const portaria = await c.api.patch('/settings').set('Authorization', `Bearer ${paula}`).send({ visitanteMaxUsos: 1 });
    expect(portaria.status).toBe(403);
  });
});

describe('Meus visitantes (morador)', () => {
  let c: Cenario;
  let maria: string;
  beforeEach(async () => {
    c = await montarCenario();
    maria = await c.tokenDe('maria@passe.com');
  });

  const convite = (extra: object = {}) => ({
    nome: 'Bruno Alves',
    email: 'bruno@exemplo.com',
    cpf: '666.666.666-66',
    accessPointId: c.catraca.id,
    dataInicio: '2026-10-14',
    dataFim: '2026-10-15',
    horaInicio: '08:00',
    horaFim: '12:00',
    ...extra,
  });
  const convidar = (extra: object = {}, token = maria) =>
    c.api.post('/me/visitors').set('Authorization', `Bearer ${token}`).send(convite(extra));

  it('lista as catracas que a Maria usa, até o fim da autorização dela', async () => {
    const res = await c.api.get('/me/visitors/catracas').set('Authorization', `Bearer ${maria}`);
    expect(res.status).toBe(200);
    expect(res.body).toEqual([
      { id: c.catraca.id, nome: 'Catraca 2', edificio: 'Edifício Atlântico', portaria: 'Portaria Principal', porta: 'Porta A', ate: '2026-10-31' },
    ]);
  });

  it('cria o visitante com senha provisória, e ele entra pelo QR', async () => {
    const res = await convidar();
    expect(res.status).toBe(201);
    expect(res.body.senhaProvisoria).toMatch(/^[A-HJKMNP-Z2-9]{8}$/);
    expect(res.body.visitante).toMatchObject({ nome: 'Bruno Alves', email: 'bruno@exemplo.com' });
    expect(res.body.autorizacao).toMatchObject({
      maxUsos: 2,
      situacao: 'ATIVA',
      criadaPorId: c.pessoas.maria.id,
      user: { nome: 'Bruno Alves', perfil: 'VISITANTE' },
    });

    const lista = await c.api.get('/me/visitors').set('Authorization', `Bearer ${maria}`);
    expect(lista.body).toHaveLength(1);
    expect(lista.body[0].id).toBe(res.body.autorizacao.id);

    const login = await c.api.post('/auth/login').send({ login: 'bruno@exemplo.com', senha: res.body.senhaProvisoria });
    expect(login.status).toBe(200);
    const qr = (await c.api.get('/terminal/qr-token').set(c.terminalHeaders)).body.token;
    const acesso = await c.api
      .post('/access/qr')
      .set('Authorization', `Bearer ${login.body.token}`)
      .send({ token: qr, ...PERTO });
    expect(acesso.body).toMatchObject({ liberado: true, usosRestantes: 1 });
  });

  it('reaproveita o visitante que já tem cadastro, sem senha nova', async () => {
    const res = await convidar({ nome: 'Ana Lima', email: 'ana@passe.com', cpf: '44444444444' });
    expect(res.status).toBe(201);
    expect(res.body.senhaProvisoria).toBeNull();
    expect(res.body.visitante.id).toBe(c.pessoas.visitante.id);
  });

  it('não usa o e-mail ou o CPF de outra pessoa', async () => {
    expect((await convidar({ email: 'paula@passe.com' })).status).toBe(409);
    expect((await convidar({ cpf: '33333333333' })).status).toBe(409);
    // E-mail da Ana com outro CPF: não é a mesma pessoa.
    expect((await convidar({ email: 'ana@passe.com' })).status).toBe(409);
  });

  it('só dentro do período da autorização da Maria e das regras do condomínio', async () => {
    const depois = await convidar({ dataInicio: '2026-10-30', dataFim: '2026-11-02' });
    expect(depois.status).toBe(403);
    expect(depois.body.erro.mensagem).toBe(
      'Você só pode convidar para as catracas que você usa, dentro do período da sua autorização.',
    );
    expect((await convidar({ dataInicio: '2026-10-13' })).status).toBe(400);
    const longa = await convidar({ dataInicio: '2026-10-14', dataFim: '2026-10-25' });
    expect(longa.status).toBe(400);
    expect(longa.body.erro.mensagem).toBe('Uma visita pode durar até 7 dia(s).');
    expect((await convidar({ horaFim: '08:00' })).status).toBe(400);
  });

  it('respeita quando o admin desliga os convites', async () => {
    const admin = await c.tokenDe('carlos@passe.com');
    await c.api.patch('/settings').set('Authorization', `Bearer ${admin}`).send({ moradorPodeConvidar: false });
    const res = await convidar();
    expect(res.status).toBe(403);
    expect(res.body.erro.mensagem).toContain('não permite que moradores cadastrem visitantes');
  });

  it('o visitante e a equipe não usam "Meus visitantes"', async () => {
    for (const email of ['ana@passe.com', 'paula@passe.com']) {
      const token = await c.tokenDe(email);
      const res = await c.api.get('/me/visitors').set('Authorization', `Bearer ${token}`);
      expect(res.status).toBe(403);
    }
  });

  it('a Maria cancela o próprio convite, e só o dela', async () => {
    const criado = (await convidar()).body.autorizacao;
    const cancelar = await c.api.post(`/me/visitors/${criado.id}/cancel`).set('Authorization', `Bearer ${maria}`);
    expect(cancelar.status).toBe(200);
    expect(cancelar.body.situacao).toBe('CANCELADA');

    // A autorização da própria Maria foi criada pela equipe: não é um convite dela.
    const outra = await c.api.post(`/me/visitors/${c.autorizacaoMaria.id}/cancel`).set('Authorization', `Bearer ${maria}`);
    expect(outra.status).toBe(404);
  });
});

describe('Ajustes da apresentação', () => {
  let c: Cenario;
  beforeEach(async () => {
    c = await montarCenario();
  });

  it('a autorização criada pela equipe guarda quem criou', async () => {
    const admin = await c.tokenDe('carlos@passe.com');
    const res = await c.api.post('/authorizations').set('Authorization', `Bearer ${admin}`).send({
      userId: c.pessoas.visitante.id,
      accessPointId: c.catraca.id,
      dataInicio: '2026-10-14',
      dataFim: '2026-10-14',
      horaInicio: '08:00',
      horaFim: '12:00',
      maxUsos: 1,
    });
    expect(res.status).toBe(201);
    expect(res.body.criadaPorId).toBe(c.pessoas.admin.id);
  });

  it('o admin remove o terminal: a chave para na hora e o histórico fica', async () => {
    const nfc = await c.api.post('/terminal/nfc').set(c.terminalHeaders).send({ uid: '04A1B2C3' });
    expect(nfc.body.liberado).toBe(true);
    const admin = await c.tokenDe('carlos@passe.com');
    const paula = await c.tokenDe('paula@passe.com');

    expect((await c.api.delete(`/terminals/${c.terminal.id}`).set('Authorization', `Bearer ${paula}`)).status).toBe(403);
    expect((await c.api.delete(`/terminals/${c.terminal.id}`).set('Authorization', `Bearer ${admin}`)).status).toBe(204);
    expect((await c.api.delete(`/terminals/${c.terminal.id}`).set('Authorization', `Bearer ${admin}`)).status).toBe(404);

    expect((await c.api.get('/terminal/qr-token').set(c.terminalHeaders)).status).toBe(401);
    const historico = await c.api.get('/access-events').set('Authorization', `Bearer ${admin}`);
    expect(historico.body.total).toBe(1);
    expect(historico.body.itens[0].terminalId).toBeNull();
  });

  it('latitude fora da faixa responde em português', async () => {
    const admin = await c.tokenDe('carlos@passe.com');
    const res = await c.api
      .patch(`/locations/access-points/${c.catraca.id}`)
      .set('Authorization', `Bearer ${admin}`)
      .send({ latitude: 200 });
    expect(res.status).toBe(400);
    expect(res.body.erro.detalhes.latitude).toEqual(['A latitude vai de -90 a 90']);
  });
});
