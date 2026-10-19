// Teste de fumaça contra a API rodando com Postgres de verdade (usado no CI).
// Uso: API_URL=http://localhost:3000 node scripts/smoke.mjs
// Espera o banco com o seed aplicado (npm run db:seed).
const API = process.env.API_URL ?? 'http://localhost:3000';
const TERMINAL = {
  'X-Terminal-Id': '00000000-0000-4000-8000-000000000005',
  'X-Terminal-Key': process.env.TERMINAL_DEMO_KEY ?? 'chave-demo-terminal-catraca-1',
};
const CATRACA = { latitude: -23.3053, longitude: -45.9658 };

let falhas = 0;
function conferir(condicao, descricao, extra) {
  console.info(`${condicao ? 'ok  ' : 'FALHOU'} ${descricao}`);
  if (!condicao) {
    falhas += 1;
    if (extra !== undefined) console.error(JSON.stringify(extra, null, 2));
  }
}

async function chamar(metodo, caminho, { token, headers = {}, body } = {}) {
  const res = await fetch(`${API}${caminho}`, {
    method: metodo,
    headers: {
      'content-type': 'application/json',
      ...(token && { authorization: `Bearer ${token}` }),
      ...headers,
    },
    body: body && JSON.stringify(body),
  });
  const texto = await res.text();
  return { status: res.status, body: texto ? JSON.parse(texto) : null };
}

async function esperarApi() {
  for (let i = 0; i < 30; i++) {
    try {
      if ((await fetch(`${API}/health`)).ok) return;
    } catch {
      /* ainda subindo */
    }
    await new Promise((r) => setTimeout(r, 1000));
  }
  throw new Error('A API não respondeu em 30 s');
}

const hojeEmSP = new Intl.DateTimeFormat('en-CA', { timeZone: 'America/Sao_Paulo' }).format(new Date());

await esperarApi();

const login = await chamar('POST', '/auth/login', { body: { login: 'admin@passe.com', senha: 'passe123' } });
conferir(login.status === 200 && login.body.token, 'login do admin', login.body);
const admin = login.body.token;

const errado = await chamar('POST', '/auth/login', { body: { login: 'admin@passe.com', senha: 'x' } });
conferir(errado.status === 401, 'senha errada é recusada');

const usuarios = await chamar('GET', '/users?busca=Ana', { token: admin });
const ana = usuarios.body?.[0];
conferir(usuarios.status === 200 && ana?.perfil === 'VISITANTE', 'lista e busca usuários', usuarios.body);

const arvore = await chamar('GET', '/locations', { token: admin });
const catracaId = arvore.body?.[0]?.portarias?.[0]?.portas?.[0]?.catracas?.[0]?.id;
conferir(arvore.status === 200 && catracaId, 'árvore de locais', arvore.body);

const novaTag = await chamar('POST', `/users/${ana.id}/tags`, {
  token: admin,
  body: { uid: `AA:${Date.now().toString(16).slice(-6).toUpperCase()}` },
});
conferir(novaTag.status === 201, 'vincula tag NFC', novaTag.body);

// O seed dá à visitante uma autorização das 14h às 16h; sem cancelar, o teste do limite de usos depende da hora.
const doSeed = await chamar('GET', `/authorizations?situacao=ATIVA&userId=${ana.id}`, { token: admin });
for (const a of doSeed.body ?? []) await chamar('POST', `/authorizations/${a.id}/cancel`, { token: admin });

const autorizacao = await chamar('POST', '/authorizations', {
  token: admin,
  body: { userId: ana.id, accessPointId: catracaId, dataInicio: hojeEmSP, dataFim: hojeEmSP, horaInicio: '00:00', horaFim: '23:59', maxUsos: 1 },
});
conferir(autorizacao.status === 201 && autorizacao.body.situacao === 'ATIVA', 'cria autorização', autorizacao.body);

const filtradas = await chamar('GET', `/authorizations?situacao=ATIVA&userId=${ana.id}`, { token: admin });
conferir(filtradas.status === 200 && filtradas.body.length >= 1, 'filtra autorizações');

const qr = await chamar('GET', '/terminal/qr-token', { headers: TERMINAL });
conferir(qr.status === 200 && qr.body.token, 'terminal recebe QR', qr.body);

const sinal = await chamar('POST', '/terminal/heartbeat', { headers: TERMINAL, body: CATRACA });
conferir(sinal.status === 200 && sinal.body.online === true, 'heartbeat do terminal', sinal.body);

const nfc = await chamar('POST', '/terminal/nfc', { headers: TERMINAL, body: { uid: novaTag.body.uid } });
conferir(nfc.status === 200 && nfc.body.liberado === true, 'NFC libera a visitante', nfc.body);

const deNovo = await chamar('POST', '/terminal/nfc', { headers: TERMINAL, body: { uid: novaTag.body.uid } });
conferir(deNovo.body?.motivo === 'SEM_USOS', 'segundo uso é negado (limite de usos)', deNovo.body);

const loginAna = await chamar('POST', '/auth/login', { body: { login: '444.444.444-44', senha: 'passe123' } });
const viaQr = await chamar('POST', '/access/qr', { token: loginAna.body.token, body: { token: qr.body.token, ...CATRACA } });
conferir(viaQr.status === 200 && typeof viaQr.body.liberado === 'boolean' && viaQr.body.eventoId, 'validação por QR', viaQr.body);

const decisoes = await chamar('GET', '/terminal/decisions', { headers: TERMINAL });
conferir(decisoes.status === 200 && decisoes.body.length >= 3, 'terminal recebe as decisões', decisoes.body);

const historico = await chamar('GET', '/access-events?limite=10', { token: admin });
conferir(historico.status === 200 && historico.body.total >= 3 && historico.body.negados >= 1, 'histórico de acessos', historico.body);

const cancelada = await chamar('POST', `/authorizations/${autorizacao.body.id}/cancel`, { token: admin });
conferir(cancelada.body?.situacao === 'CANCELADA', 'cancela autorização', cancelada.body);

const painel = await chamar('GET', '/dashboard', { token: admin });
conferir(painel.status === 200 && typeof painel.body.acessosHoje === 'number', 'painel', painel.body);

if (falhas > 0) {
  console.error(`\n${falhas} verificação(ões) falharam.`);
  process.exit(1);
}
console.info('\nTeste de fumaça passou.');
