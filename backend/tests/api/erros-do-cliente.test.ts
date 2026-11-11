import jwt from 'jsonwebtoken';
import { beforeEach, describe, expect, it } from 'vitest';
import { config, montarCenario } from '../support/test-app.js';

type Cenario = Awaited<ReturnType<typeof montarCenario>>;

describe('Erro de quem chama a API não vira 500', () => {
  let c: Cenario;
  let admin: { Authorization: string };

  beforeEach(async () => {
    c = await montarCenario();
    admin = { Authorization: `Bearer ${await c.tokenDe('carlos@passe.com')}` };
  });

  it('corpo grande demais responde 413', async () => {
    const res = await c.api.post('/auth/login').send({ login: 'x'.repeat(200_000), senha: 'y' });
    expect(res.status).toBe(413);
    expect(res.body.erro.codigo).toBe('CORPO_GRANDE_DEMAIS');
  });

  it('charset desconhecido responde 415', async () => {
    const res = await c.api
      .post('/auth/login')
      .set('Content-Type', 'application/json; charset=nao-existe')
      .send('{"login":"a","senha":"b"}');
    expect(res.status).toBe(415);
    expect(res.body.erro.codigo).toBe('CORPO_NAO_SUPORTADO');
  });

  it('URL malformada responde 400', async () => {
    const res = await c.api.get('/users/%E0%A4%A').set(admin);
    expect(res.status).toBe(400);
    expect(res.body.erro.codigo).toBe('REQUISICAO_INVALIDA');
  });

  it('caractere NUL no corpo ou na busca responde 400', async () => {
    const login = await c.api.post('/auth/login').send({ login: 'a\0@passe.com', senha: 'passe123' });
    expect(login.status).toBe(400);
    const busca = await c.api.get('/users?busca=ma%00ria').set(admin);
    expect(busca.status).toBe(400);
  });

  it('token assinado com NUL no sub é sessão inválida', async () => {
    const token = jwt.sign({ perfil: 'ADMIN' }, config.jwtSecret, { subject: 'a\0b' });
    const res = await c.api.get('/auth/me').set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(401);
    expect(res.body.erro.codigo).toBe('NAO_AUTENTICADO');
  });

  it.each(['2026-02-31', '2026-13-01', '0000-01-01'])('a data impossível %s responde 400', async (dataInicio) => {
    const res = await c.api.post('/authorizations').set(admin).send({
      userId: c.pessoas.visitante.id,
      accessPointId: c.catraca.id,
      dataInicio,
      dataFim: '2026-12-31',
      horaInicio: '08:00',
      horaFim: '18:00',
      maxUsos: 1,
    });
    expect(res.status).toBe(400);
    expect(res.body.erro.detalhes.dataInicio).toEqual(['Data inválida']);
  });

  it('29/02 em ano bissexto continua valendo', async () => {
    const res = await c.api.post('/authorizations').set(admin).send({
      userId: c.pessoas.visitante.id,
      accessPointId: c.catraca.id,
      dataInicio: '2028-02-29',
      dataFim: '2028-02-29',
      horaInicio: '08:00',
      horaFim: '18:00',
      maxUsos: 1,
    });
    expect(res.status).toBe(201);
  });
});
