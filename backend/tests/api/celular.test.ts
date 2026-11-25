import { generateKeyPairSync, sign, type KeyObject } from 'node:crypto';
import { beforeEach, describe, expect, it } from 'vitest';
import { desafioDoQr, PREFIXO_ASSINATURA } from '../../src/modules/phones/phone-signature.js';
import { gerarChave, hashChave } from '../../src/shared/security.js';
import { montarCenario } from '../support/test-app.js';

type Cenario = Awaited<ReturnType<typeof montarCenario>>;

/** Faz o papel do Keystore do Android: par EC P-256, a pública em SPKI base64. */
function novoCelular() {
  const { publicKey, privateKey } = generateKeyPairSync('ec', { namedCurve: 'prime256v1' });
  return { privada: privateKey, publica: publicKey.export({ format: 'der', type: 'spki' }).toString('base64') };
}

/** O que o serviço HCE do app faz ao receber o desafio do terminal. */
const assinar = (privada: KeyObject, qr: string) =>
  sign('sha256', Buffer.concat([PREFIXO_ASSINATURA, desafioDoQr(qr)]), { key: privada, dsaEncoding: 'ieee-p1363' }).toString('base64');

describe('Celular como chave NFC (HCE)', () => {
  let c: Cenario;
  let jwtMaria: string;
  let celular: ReturnType<typeof novoCelular>;
  let celularId: string;

  beforeEach(async () => {
    c = await montarCenario();
    jwtMaria = await c.tokenDe('maria@passe.com');
    celular = novoCelular();
    const res = await c.api
      .post('/me/phones')
      .set('Authorization', `Bearer ${jwtMaria}`)
      .send({ nome: 'Galaxy A54', chavePublica: celular.publica });
    celularId = res.body.id;
  });

  const qrDoTerminal = async () => (await c.api.get('/terminal/qr-token').set(c.terminalHeaders)).body.token as string;
  const encostar = (corpo: object, headers: Record<string, string> = c.terminalHeaders) =>
    c.api.post('/terminal/phone').set(headers).send(corpo);
  const encostarAssinando = async (privada = celular.privada, id = celularId) => {
    const desafio = await qrDoTerminal();
    return encostar({ desafio, celularId: id, assinatura: assinar(privada, desafio) });
  };

  describe('ativação no app', () => {
    it('guarda o celular sem devolver a chave', async () => {
      const lista = await c.api.get('/me/phones').set('Authorization', `Bearer ${jwtMaria}`);
      expect(lista.status).toBe(200);
      expect(lista.body).toHaveLength(1);
      expect(lista.body[0]).toMatchObject({ id: celularId, nome: 'Galaxy A54', ativo: true, userId: c.pessoas.maria.id });
      expect(lista.body[0].chavePublica).toBeUndefined();
    });

    it('recusa chave que não é EC P-256', async () => {
      const rsa = generateKeyPairSync('rsa', { modulusLength: 1024 }).publicKey.export({ format: 'der', type: 'spki' });
      const res = await c.api
        .post('/me/phones')
        .set('Authorization', `Bearer ${jwtMaria}`)
        .send({ nome: 'Outro', chavePublica: rsa.toString('base64') });
      expect(res.status).toBe(400);
      expect(res.body.erro.detalhes.chavePublica).toBeDefined();
    });

    it('a mesma chave não entra duas vezes', async () => {
      const res = await c.api
        .post('/me/phones')
        .set('Authorization', `Bearer ${jwtMaria}`)
        .send({ nome: 'De novo', chavePublica: celular.publica });
      expect(res.status).toBe(409);
    });

    it('exige login', async () => {
      const res = await c.api.post('/me/phones').send({ nome: 'X', chavePublica: novoCelular().publica });
      expect(res.status).toBe(401);
    });
  });

  describe('acesso no terminal', () => {
    it('libera a Maria sem GPS, desconta um uso e registra o evento', async () => {
      const res = await encostarAssinando();

      expect(res.status).toBe(200);
      expect(res.body).toMatchObject({ liberado: true, titulo: 'Acesso liberado', usosRestantes: 6 });
      expect(c.db.authorizations[0]!.usosRealizados).toBe(4);
      expect(c.db.events.at(-1)).toMatchObject({
        metodo: 'CELULAR',
        resultado: 'LIBERADO',
        userId: c.pessoas.maria.id,
        credencial: celularId,
        latitude: null,
      });
      const decisoes = await c.api.get('/terminal/decisions').set(c.terminalHeaders);
      expect(decisoes.body.at(-1).decisao).toMatchObject({ acao: 'ABRIR', metodo: 'CELULAR', nome: 'Maria' });
    });

    it('nega assinatura feita por outra chave, sem atribuir a tentativa à Maria', async () => {
      const res = await encostarAssinando(novoCelular().privada);
      expect(res.body).toMatchObject({ liberado: false, motivo: 'CELULAR_NAO_CONFIRMADO' });
      expect(c.db.events.at(-1)).toMatchObject({ metodo: 'CELULAR', resultado: 'NEGADO', userId: null });
      expect(c.db.authorizations[0]!.usosRealizados).toBe(3);
    });

    it('nega celular que não está cadastrado', async () => {
      const res = await encostarAssinando(celular.privada, '9b2f3c1e-0000-4000-8000-000000000000');
      expect(res.body).toMatchObject({ liberado: false, motivo: 'CELULAR_DESCONHECIDO', titulo: 'Celular não cadastrado' });
    });

    it('id que não é UUID de versão conhecida ainda vira negação registrada, não erro 400', async () => {
      const res = await encostarAssinando(celular.privada, 'ffffffff-ffff-ffff-ffff-ffffffffffff');
      expect(res.status).toBe(200);
      expect(res.body).toMatchObject({ liberado: false, motivo: 'CELULAR_DESCONHECIDO' });
    });

    it('nega desafio vencido (assinatura guardada e reenviada depois)', async () => {
      const desafio = await qrDoTerminal();
      const assinatura = assinar(celular.privada, desafio);
      c.clock.avancar(25);
      const res = await encostar({ desafio, celularId, assinatura });
      expect(res.body).toMatchObject({ liberado: false, motivo: 'DESAFIO_INVALIDO' });
    });

    it('nega o QR de outro terminal', async () => {
      const outraCatraca = await c.repos.locations.createAccessPoint({
        nome: 'Catraca 3',
        doorId: c.catraca.doorId,
        raioMetros: 100,
        latitude: c.catraca.latitude,
        longitude: c.catraca.longitude,
      });
      const chave = gerarChave();
      const outro = await c.repos.terminals.create({ nome: 'Terminal 3', accessPointId: outraCatraca.id, chaveHash: hashChave(chave) });
      const desafio = (await c.api.get('/terminal/qr-token').set({ 'X-Terminal-Id': outro.id, 'X-Terminal-Key': chave })).body.token;

      const res = await encostar({ desafio, celularId, assinatura: assinar(celular.privada, desafio) });
      expect(res.body).toMatchObject({ liberado: false, motivo: 'DESAFIO_INVALIDO' });
    });

    it('a mesma assinatura não abre duas vezes', async () => {
      const desafio = await qrDoTerminal();
      const corpo = { desafio, celularId, assinatura: assinar(celular.privada, desafio) };
      expect((await encostar(corpo)).body.liberado).toBe(true);
      const segunda = await encostar(corpo);
      expect(segunda.body).toMatchObject({ liberado: false, motivo: 'DESAFIO_INVALIDO' });
      expect(c.db.authorizations[0]!.usosRealizados).toBe(4);
    });

    it('usa as mesmas regras de autorização (fora do horário)', async () => {
      c.clock.irPara('2026-10-14T22:42:00Z'); // 19:42 em Brasília
      const res = await encostarAssinando();
      expect(res.body).toMatchObject({ liberado: false, motivo: 'FORA_DO_HORARIO' });
    });

    it('nega quem foi desativado', async () => {
      c.db.users.find((u) => u.id === c.pessoas.maria.id)!.ativo = false;
      const res = await encostarAssinando();
      expect(res.body).toMatchObject({ liberado: false, motivo: 'USUARIO_INATIVO' });
    });

    it('exige a chave do terminal', async () => {
      const res = await encostar({ desafio: 'x'.repeat(20), celularId, assinatura: 'x' }, {
        'X-Terminal-Id': c.terminal.id,
        'X-Terminal-Key': 'errada',
      });
      expect(res.status).toBe(401);
    });
  });

  describe('gestão', () => {
    it('a portaria bloqueia o celular e ele para de abrir', async () => {
      const portaria = await c.tokenDe('paula@passe.com');
      const bloqueio = await c.api
        .patch(`/users/${c.pessoas.maria.id}/phones/${celularId}`)
        .set('Authorization', `Bearer ${portaria}`)
        .send({ ativo: false });
      expect(bloqueio.status).toBe(200);
      expect(bloqueio.body).toMatchObject({ ativo: false });

      const res = await encostarAssinando();
      expect(res.body).toMatchObject({ liberado: false, motivo: 'CELULAR_BLOQUEADO' });
    });

    it('a portaria lista os celulares de um condômino, mas não mexe nos do admin', async () => {
      const portaria = await c.tokenDe('paula@passe.com');
      const lista = await c.api.get(`/users/${c.pessoas.maria.id}/phones`).set('Authorization', `Bearer ${portaria}`);
      expect(lista.body).toHaveLength(1);

      const doAdmin = await c.api.get(`/users/${c.pessoas.admin.id}/phones`).set('Authorization', `Bearer ${portaria}`);
      expect(doAdmin.status).toBe(403);
    });

    it('morador não usa as rotas da equipe', async () => {
      const res = await c.api.get(`/users/${c.pessoas.maria.id}/phones`).set('Authorization', `Bearer ${jwtMaria}`);
      expect(res.status).toBe(403);
    });

    it('a Maria remove o próprio celular; outra pessoa não consegue', async () => {
      const ana = await c.tokenDe('ana@passe.com');
      const alheio = await c.api.delete(`/me/phones/${celularId}`).set('Authorization', `Bearer ${ana}`);
      expect(alheio.status).toBe(404);

      const res = await c.api.delete(`/me/phones/${celularId}`).set('Authorization', `Bearer ${jwtMaria}`);
      expect(res.status).toBe(204);
      expect((await encostarAssinando()).body).toMatchObject({ liberado: false, motivo: 'CELULAR_DESCONHECIDO' });
    });

    it('o histórico da equipe filtra pelo método CELULAR', async () => {
      await encostarAssinando();
      await c.api.post('/terminal/nfc').set(c.terminalHeaders).send({ uid: '04A1B2C3' });
      const admin = await c.tokenDe('carlos@passe.com');
      const res = await c.api.get('/access-events').query({ metodo: 'CELULAR' }).set('Authorization', `Bearer ${admin}`);
      expect(res.body.total).toBe(1);
      expect(res.body.itens[0]).toMatchObject({ metodo: 'CELULAR', user: { nome: 'Maria Souza' } });
    });
  });
});
