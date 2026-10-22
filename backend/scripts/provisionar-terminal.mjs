// Provisiona o terminal (ESP32) de uma catraca (issue #8).
//
//   node scripts/provisionar-terminal.mjs
//       lista as catracas e os terminais (online/último sinal)
//   node scripts/provisionar-terminal.mjs --catraca <id> --nome "Terminal Catraca 2" [--lat -23.3 --lng -45.9 --raio 100]
//       cadastra o terminal; se passar --lat/--lng/--raio, corrige antes a posição da catraca
//   node scripts/provisionar-terminal.mjs --trocar-chave <terminalId>
//       gera uma chave nova (a antiga para de funcionar na hora)
//
// A chave só aparece uma vez. O script já a grava onde ela é usada:
//   - firmware/include/credenciais.h  (TERMINAL_ID e TERMINAL_KEY, fora do git)
//   - docker/mosquitto/passwd          (login do terminal no broker)
// Depois: reinicie o broker e grave o firmware.
//
// Variáveis: API_URL (padrão http://localhost:3000), ADMIN_LOGIN, ADMIN_SENHA.
import { copyFileSync, existsSync, readFileSync, writeFileSync } from 'node:fs';
import { parseArgs } from 'node:util';
import { gravarSenha } from './mqtt-senha.mjs';

const API = process.env.API_URL ?? 'http://localhost:3000';
const RAIZ = new URL('../../', import.meta.url);
const CREDENCIAIS = new URL('firmware/include/credenciais.h', RAIZ);
const EXEMPLO = new URL('firmware/include/credenciais.exemplo.h', RAIZ);
const PASSWD = new URL('docker/mosquitto/passwd', RAIZ);

const { values: args } = parseArgs({
  options: {
    catraca: { type: 'string' },
    nome: { type: 'string' },
    lat: { type: 'string' },
    lng: { type: 'string' },
    raio: { type: 'string' },
    'trocar-chave': { type: 'string' },
  },
});

async function chamar(metodo, caminho, { token, body } = {}) {
  const res = await fetch(`${API}${caminho}`, {
    method: metodo,
    headers: { 'content-type': 'application/json', ...(token && { authorization: `Bearer ${token}` }) },
    body: body && JSON.stringify(body),
  });
  const dados = await res.json().catch(() => null);
  if (!res.ok) throw new Error(`${metodo} ${caminho}: ${dados?.erro?.mensagem ?? `HTTP ${res.status}`}`);
  return dados;
}

function catracasDe(arvore) {
  return arvore.flatMap((e) =>
    e.portarias.flatMap((p) => p.portas.flatMap((porta) => porta.catracas.map((c) => ({ ...c, caminho: `${e.nome} › ${p.nome} › ${porta.nome}` })))),
  );
}

function gravarCredenciais(terminal) {
  if (!existsSync(CREDENCIAIS)) copyFileSync(EXEMPLO, CREDENCIAIS);
  const texto = readFileSync(CREDENCIAIS, 'utf8')
    .replace(/#define TERMINAL_ID .*/, `#define TERMINAL_ID "${terminal.id}"`)
    .replace(/#define TERMINAL_KEY .*/, `#define TERMINAL_KEY "${terminal.chave}"`);
  writeFileSync(CREDENCIAIS, texto);
  gravarSenha(PASSWD, terminal.id, terminal.chave);
  console.info(`
Terminal "${terminal.nome}" pronto.
  TERMINAL_ID  = ${terminal.id}
  TERMINAL_KEY = ${terminal.chave}
Gravado em firmware/include/credenciais.h e docker/mosquitto/passwd.

Próximos passos:
  1. docker compose -f docker-compose.dev.yml restart mqtt
  2. Ajuste Wi-Fi e endereços em firmware/include/credenciais.h e grave o ESP32 (pio run -t upload)
  3. O terminal aparece como online depois do primeiro heartbeat (rode este script sem argumentos)`);
}

const { token } = await chamar('POST', '/auth/login', {
  body: { login: process.env.ADMIN_LOGIN ?? 'admin@passe.com', senha: process.env.ADMIN_SENHA ?? 'passe123' },
});

if (args['trocar-chave']) {
  gravarCredenciais(await chamar('POST', `/terminals/${args['trocar-chave']}/rotate-key`, { token }));
} else if (args.catraca) {
  if (!args.nome) throw new Error('Informe --nome.');
  const posicao = {
    ...(args.lat && { latitude: Number(args.lat) }),
    ...(args.lng && { longitude: Number(args.lng) }),
    ...(args.raio && { raioMetros: Number(args.raio) }),
  };
  if (Object.keys(posicao).length) {
    const c = await chamar('PATCH', `/locations/access-points/${args.catraca}`, { token, body: posicao });
    console.info(`Catraca "${c.nome}": ${c.latitude}, ${c.longitude}, raio ${c.raioMetros} m`);
  }
  gravarCredenciais(await chamar('POST', '/terminals', { token, body: { nome: args.nome, accessPointId: args.catraca } }));
} else {
  const [arvore, terminais] = await Promise.all([chamar('GET', '/locations', { token }), chamar('GET', '/terminals', { token })]);
  console.info('Catracas:');
  for (const c of catracasDe(arvore)) {
    const t = terminais.find((x) => x.accessPointId === c.id);
    const situacao = t ? `terminal ${t.id} · ${t.online ? 'online' : 'offline'} · último sinal ${t.ultimoSinal ?? 'nunca'}` : 'sem terminal';
    console.info(`  ${c.id}  ${c.caminho} › ${c.nome}  (${c.latitude}, ${c.longitude}, raio ${c.raioMetros} m)\n      ${situacao}`);
  }
}
