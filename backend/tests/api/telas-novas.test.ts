import { describe, expect, it } from 'vitest';
import { montarCenario } from '../support/test-app.js';

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

  it('B3: quem foi desativado perde o acesso na hora, mesmo com o token válido', async () => {
    const c = await montarCenario();
    const token = await c.tokenDe('paula@passe.com');
    const admin = await c.tokenDe('carlos@passe.com');

    const antes = await c.api.get('/users').set('Authorization', `Bearer ${token}`);
    expect(antes.status).toBe(200);

    await c.api.patch(`/users/${c.pessoas.portaria.id}`).set('Authorization', `Bearer ${admin}`).send({ ativo: false });

    const depois = await c.api.get('/users').set('Authorization', `Bearer ${token}`);
    expect(depois.status).toBe(401);
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
