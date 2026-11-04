import jwt from 'jsonwebtoken';
import { describe, expect, it } from 'vitest';
import { config, montarCenario } from '../support/test-app.js';

describe('O que as telas novas pedem ao backend', () => {
  it('B2: histórico e painel trazem o texto do motivo', async () => {
    const c = await montarCenario();
    await c.api.post('/terminal/nfc').set(c.terminalHeaders).send({ uid: 'FFFFFFFF' });
    const auth = { Authorization: `Bearer ${await c.tokenDe('paula@passe.com')}` };

    const historico = await c.api.get('/access-events').set(auth);
    expect(historico.body.itens[0]).toMatchObject({
      motivo: 'TAG_DESCONHECIDA',
      titulo: 'Tag não cadastrada',
      oQueFazer: 'Peça para a portaria vincular sua tag.',
    });
    const painel = await c.api.get('/dashboard').set(auth);
    expect(painel.body.negadosRecentes[0].titulo).toBe('Tag não cadastrada');
  });

  it('B2: o histórico da própria pessoa traz o texto, e o evento liberado vem com null', async () => {
    const c = await montarCenario();
    await c.api.post('/terminal/nfc').set(c.terminalHeaders).send({ uid: '04A1B2C3' });
    c.db.tags[0]!.ativa = false;
    await c.api.post('/terminal/nfc').set(c.terminalHeaders).send({ uid: '04A1B2C3' });
    const maria = { Authorization: `Bearer ${await c.tokenDe('maria@passe.com')}` };

    const { body } = await c.api.get('/me/access-events').set(maria);
    const texto = (resultado: string) => {
      const { titulo, oQueFazer } = body.itens.find((e: { resultado: string }) => e.resultado === resultado);
      return { titulo, oQueFazer };
    };
    expect(texto('NEGADO')).toEqual({ titulo: 'Sua tag está bloqueada', oQueFazer: 'Fale com a portaria.' });
    expect(texto('LIBERADO')).toEqual({ titulo: null, oQueFazer: null });
  });

  it('B3: quem foi desativado perde o acesso na hora, mesmo com o token válido', async () => {
    const c = await montarCenario();
    const token = await c.tokenDe('paula@passe.com');
    const admin = await c.tokenDe('carlos@passe.com');

    const antes = await c.api.get('/users').set('Authorization', `Bearer ${token}`);
    expect(antes.status).toBe(200);

    await c.api.patch(`/users/${c.pessoas.portaria.id}`).set('Authorization', `Bearer ${admin}`).send({ ativo: false });

    const depois = await c.api.get('/users').set('Authorization', `Bearer ${token}`);
    expect(depois.status).toBe(401);
    expect(depois.body.erro).toEqual({
      codigo: 'CADASTRO_DESATIVADO',
      mensagem: 'Seu cadastro está desativado. Fale com a portaria.',
    });

    await c.api.patch(`/users/${c.pessoas.portaria.id}`).set('Authorization', `Bearer ${admin}`).send({ ativo: true });
    const reativada = await c.api.get('/users').set('Authorization', `Bearer ${token}`);
    expect(reativada.status).toBe(200);
  });

  it('B3: o perfil vale pelo banco, não pelo que o token diz', async () => {
    const c = await montarCenario();
    const token = await c.tokenDe('paula@passe.com');
    const admin = await c.tokenDe('carlos@passe.com');

    await c.api.patch(`/users/${c.pessoas.portaria.id}`).set('Authorization', `Bearer ${admin}`).send({ perfil: 'VISITANTE' });

    const depois = await c.api.get('/users').set('Authorization', `Bearer ${token}`);
    expect(depois.status).toBe(403);
  });

  it('B3: token de quem não existe mais é sessão inválida, não cadastro desativado', async () => {
    const c = await montarCenario();
    const token = jwt.sign({ perfil: 'ADMIN' }, config.jwtSecret, { subject: '00000000-0000-4000-8000-00000000dead' });

    const res = await c.api.get('/auth/me').set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(401);
    expect(res.body.erro).toEqual({ codigo: 'NAO_AUTENTICADO', mensagem: 'Sessão inválida ou expirada. Entre de novo.' });
  });

  it('B4: o filtro ATIVA e o painel não contam agendadas nem sem usos', async () => {
    const c = await montarCenario();
    const admin = { Authorization: `Bearer ${await c.tokenDe('carlos@passe.com')}` };
    const base = { userId: c.pessoas.visitante.id, accessPointId: c.catraca.id, horaInicio: '08:00', horaFim: '18:00' };
    await c.api.post('/authorizations').set(admin).send({ ...base, dataInicio: '2026-12-01', dataFim: '2026-12-31', maxUsos: 1 });
    const esgotada = await c.api.post('/authorizations').set(admin).send({ ...base, dataInicio: '2026-10-01', dataFim: '2026-10-31', maxUsos: 1 });
    c.db.authorizations.find((a) => a.id === esgotada.body.id)!.usosRealizados = 1;

    const ativas = await c.api.get('/authorizations?situacao=ATIVA').set(admin);
    expect(ativas.body.map((a: { situacao: string }) => a.situacao)).toEqual(['ATIVA']);

    const painel = await c.api.get('/dashboard').set(admin);
    expect(painel.body.autorizacoesAtivas).toBe(1);
  });

  it('B4: as agendadas e as sem usos que saíram de ATIVA têm filtro próprio', async () => {
    const c = await montarCenario();
    const admin = { Authorization: `Bearer ${await c.tokenDe('carlos@passe.com')}` };
    const base = { userId: c.pessoas.visitante.id, accessPointId: c.catraca.id, horaInicio: '08:00', horaFim: '18:00' };
    const agendada = await c.api.post('/authorizations').set(admin).send({ ...base, dataInicio: '2026-12-01', dataFim: '2026-12-31', maxUsos: 1 });
    const esgotada = await c.api.post('/authorizations').set(admin).send({ ...base, dataInicio: '2026-10-01', dataFim: '2026-10-31', maxUsos: 1 });
    c.db.authorizations.find((a) => a.id === esgotada.body.id)!.usosRealizados = 1;

    const agendadas = await c.api.get('/authorizations?situacao=AGENDADA').set(admin);
    expect(agendadas.status).toBe(200);
    expect(agendadas.body.map((a: { id: string }) => a.id)).toEqual([agendada.body.id]);

    const esgotadas = await c.api.get('/authorizations?situacao=ESGOTADA').set(admin);
    expect(esgotadas.status).toBe(200);
    expect(esgotadas.body.map((a: { id: string }) => a.id)).toEqual([esgotada.body.id]);
  });

  it('B4: o filtro EXPIRADA continua trazendo a que venceu sem usos', async () => {
    const c = await montarCenario();
    const admin = { Authorization: `Bearer ${await c.tokenDe('carlos@passe.com')}` };
    const vencida = await c.api.post('/authorizations').set(admin).send({
      userId: c.pessoas.visitante.id,
      accessPointId: c.catraca.id,
      horaInicio: '08:00',
      horaFim: '18:00',
      dataInicio: '2026-09-01',
      dataFim: '2026-09-30',
      maxUsos: 1,
    });
    c.db.authorizations.find((a) => a.id === vencida.body.id)!.usosRealizados = 1;

    const expiradas = await c.api.get('/authorizations?situacao=EXPIRADA').set(admin);
    expect(expiradas.body.map((a: { id: string }) => a.id)).toEqual([vencida.body.id]);
  });

  it('B6: a pessoa bloqueia a própria tag, mas não a de outra nem desbloqueia', async () => {
    const c = await montarCenario();
    const maria = { Authorization: `Bearer ${await c.tokenDe('maria@passe.com')}` };
    const ana = { Authorization: `Bearer ${await c.tokenDe('ana@passe.com')}` };

    const deOutra = await c.api.patch(`/me/tags/${c.tag.id}`).set(ana).send({ ativa: false });
    expect(deOutra.status).toBe(404);

    const desbloquear = await c.api.patch(`/me/tags/${c.tag.id}`).set(maria).send({ ativa: true });
    expect(desbloquear.status).toBe(400);

    const bloquear = await c.api.patch(`/me/tags/${c.tag.id}`).set(maria).send({ ativa: false });
    expect(bloquear.status).toBe(200);
    expect(bloquear.body.ativa).toBe(false);

    const nfc = await c.api.post('/terminal/nfc').set(c.terminalHeaders).send({ uid: '04A1B2C3' });
    expect(nfc.body.motivo).toBe('TAG_BLOQUEADA');
  });
});
