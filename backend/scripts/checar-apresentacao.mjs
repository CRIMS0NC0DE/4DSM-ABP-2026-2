// Checagem antes da apresentação: confere, com o backend no ar, tudo o que a demo usa e
// diz o que fazer quando algo não bate. Não muda nada no banco nem no broker.
//
//   node backend/scripts/checar-apresentacao.mjs
//
// Variáveis: API_URL (padrão http://localhost:3000), MQTT_URL (padrão mqtt://localhost:1883).
import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import { get } from 'node:https';
import { networkInterfaces } from 'node:os';
import mqtt from 'mqtt';

const API = process.env.API_URL ?? 'http://localhost:3000';
const MQTT_URL = process.env.MQTT_URL ?? 'mqtt://localhost:1883';
const RAIZ = new URL('../../', import.meta.url);
const CREDENCIAIS = new URL('arduino/include/credenciais.h', RAIZ);
const SENHA = 'passe123';
const TAGS_DO_KIT = { '6EACD706': 'Maria (morador@passe.com)', '5C521206': 'Thiago (thiago@passe.com)' };

let problemas = 0;
let avisos = 0;
const ok = (texto) => console.info(`  ✅ ${texto}`);
const aviso = (texto, fazer) => {
  avisos++;
  console.info(`  ⚠️  ${texto}${fazer ? `\n      → ${fazer}` : ''}`);
};
const falha = (texto, fazer) => {
  problemas++;
  console.info(`  ❌ ${texto}${fazer ? `\n      → ${fazer}` : ''}`);
};
const secao = (titulo) => console.info(`\n${titulo}`);

async function chamar(caminho, { token, headers = {}, metodo = 'GET' } = {}) {
  const res = await fetch(`${API}${caminho}`, {
    method: metodo,
    headers: { ...headers, ...(token && { authorization: `Bearer ${token}` }) },
    signal: AbortSignal.timeout(5000),
  });
  const corpo = await res.json().catch(() => null);
  return { status: res.status, corpo };
}

function lerCredenciais() {
  if (!existsSync(CREDENCIAIS)) return null;
  const texto = readFileSync(CREDENCIAIS, 'utf8');
  const valor = (nome) => texto.match(new RegExp(`^#define ${nome} "([^"]*)"`, 'm'))?.[1];
  return {
    ssid: valor('WIFI_SSID'),
    apiUrl: valor('API_URL'),
    mqttHost: valor('MQTT_HOST'),
    terminalId: valor('TERMINAL_ID'),
    terminalKey: valor('TERMINAL_KEY'),
  };
}

function ipsDoPc() {
  return Object.values(networkInterfaces())
    .flat()
    .filter((i) => i && i.family === 'IPv4' && !i.internal && !/^172\.(1[6-9]|2\d|3[01])\./.test(i.address))
    .map((i) => i.address);
}

function wifiAtual() {
  try {
    const saida = execFileSync('nmcli', ['-t', '-f', 'active,ssid', 'dev', 'wifi', 'list', '--rescan', 'no'], {
      encoding: 'utf8',
      timeout: 5000,
    });
    return saida
      .split('\n')
      .find((l) => /^(sim|yes):/.test(l))
      ?.replace(/^(sim|yes):/, '');
  } catch {
    return undefined;
  }
}

function brokerAceita(usuario, senha) {
  return new Promise((resolve) => {
    const client = mqtt.connect(MQTT_URL, { username: usuario, password: senha, reconnectPeriod: 0, connectTimeout: 4000 });
    client.once('connect', () => {
      client.end(true);
      resolve(true);
    });
    client.once('error', () => {
      client.end(true);
      resolve(false);
    });
  });
}

/** O certificado do app HTTPS é do próprio PC: aqui só importa se responde. */
function httpsResponde(url) {
  return new Promise((resolve) => {
    const req = get(url, { rejectUnauthorized: false, timeout: 3000 }, (res) => {
      res.resume();
      resolve(res.statusCode === 200);
    });
    req.on('timeout', () => req.destroy());
    req.on('error', () => resolve(false));
  });
}

const agoraEm = (fuso) =>
  new Intl.DateTimeFormat('en-CA', { timeZone: fuso, hour: '2-digit', minute: '2-digit', hourCycle: 'h23' }).format(new Date());

function dentroDoHorario(agora, inicio, fim) {
  return inicio <= fim ? agora >= inicio && agora < fim : agora >= inicio || agora < fim;
}

// ---------------------------------------------------------------------------

console.info(`Checagem da apresentação · ${new Date().toLocaleString('pt-BR')} · API ${API}`);

secao('1. Backend');
try {
  const { status } = await chamar('/health');
  if (status !== 200) throw new Error(`HTTP ${status}`);
  ok('API no ar (/health)');
} catch (erro) {
  falha(`A API não respondeu em ${API} (${erro.message})`, 'docker compose -f docker-compose.dev.yml up -d database mqtt backend');
  console.info(`\nSem a API não dá para conferir o resto. ${problemas} problema(s).`);
  process.exit(1);
}

const tokens = {};
for (const email of ['admin@passe.com', 'portaria@passe.com', 'morador@passe.com', 'visitante@passe.com']) {
  const res = await fetch(`${API}/auth/login`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ login: email, senha: SENHA }),
  });
  const corpo = await res.json().catch(() => null);
  if (res.ok) tokens[email] = corpo.token;
  else falha(`Login de ${email}: ${corpo?.erro?.mensagem ?? res.status}`, 'Confira se o seed rodou (npm run db:seed)');
}
if (Object.keys(tokens).length === 4) ok('As 4 contas de demonstração entram (senha passe123)');
const admin = tokens['admin@passe.com'];

const { corpo: config } = admin ? await chamar('/settings', { token: admin }) : { corpo: null };
const fuso = config?.sistema?.fuso ?? 'America/Sao_Paulo';
if (config) ok(`Configurações: "${config.nomeCondominio}", contato "${config.contatoPortaria}"`);
else aviso('GET /settings não respondeu', 'A migration 20261125000000_apresentacao rodou? Reinicie o backend.');

secao('2. Terminal (ESP32) e chaves');
const cred = lerCredenciais();
if (!cred) {
  falha('arduino/include/credenciais.h não existe', 'cp arduino/include/credenciais.exemplo.h arduino/include/credenciais.h e preencha');
} else {
  const terminal = { 'X-Terminal-Id': cred.terminalId, 'X-Terminal-Key': cred.terminalKey };
  const qr = await chamar('/terminal/qr-token', { headers: terminal });
  if (qr.status === 200) {
    ok('A API aceita a chave do credenciais.h');
    const tamanho = qr.corpo.token.length;
    if (tamanho <= 77) ok(`QR com ${tamanho} caracteres: no OLED fica com 2 pontos por módulo (versão 3)`);
    else aviso(`QR com ${tamanho} caracteres: no OLED fica com 1 ponto por módulo`, 'O backend está com a versão nova do qr-token.ts?');
  } else {
    falha(
      `A API recusou a chave do credenciais.h (HTTP ${qr.status}): o ESP32 vai mostrar "Sem servidor"`,
      'A chave do banco vem do TERMINAL_DEMO_KEY do .env da raiz. Ele precisa ser igual ao TERMINAL_KEY do credenciais.h; depois: docker compose -f docker-compose.dev.yml up -d backend',
    );
  }
  if (await brokerAceita(cred.terminalId, cred.terminalKey)) ok('O broker MQTT aceita a chave do credenciais.h');
  else falha('O broker MQTT recusou a chave do credenciais.h', 'Rode o provisionar-terminal.mjs --trocar-chave e reinicie o broker (restart mqtt)');

  const ips = ipsDoPc();
  const hostApi = cred.apiUrl?.match(/\/\/([^:/]+)/)?.[1];
  if (hostApi && ips.includes(hostApi) && cred.mqttHost === hostApi) ok(`API_URL e MQTT_HOST apontam para este PC (${hostApi})`);
  else
    aviso(
      `O credenciais.h aponta para ${hostApi} / ${cred.mqttHost}, e este PC está em ${ips.join(', ') || '?'}`,
      'Troque API_URL e MQTT_HOST no credenciais.h pelo IP certo e grave: cd arduino && pio run -e oled -t upload',
    );
  const ssid = wifiAtual();
  if (!ssid) aviso('Não consegui ler o Wi-Fi atual (nmcli)');
  else if (ssid === cred.ssid) ok(`O PC está no mesmo Wi-Fi gravado no ESP32 ("${ssid}")`);
  else
    aviso(
      `O PC está no Wi-Fi "${ssid}", e o ESP32 foi gravado para "${cred.ssid}"`,
      'Ligue os dois na mesma rede, ou troque WIFI_SSID/WIFI_SENHA e grave de novo',
    );
}

if (admin) {
  const { corpo: terminais } = await chamar('/terminals', { token: admin });
  const t = terminais?.find((x) => x.id === cred?.terminalId);
  if (!t) aviso('O terminal do credenciais.h não está na lista de terminais');
  else if (t.online) ok(`"${t.nome}" está online (último sinal ${new Date(t.ultimoSinal).toLocaleTimeString('pt-BR')})`);
  else aviso(`"${t.nome}" está offline`, 'Ligue o ESP32 no USB; ele aparece online em até 30 s');
}

secao('3. Tags do kit e autorizações');
if (admin) {
  const { corpo: usuarios } = await chamar('/users', { token: admin });
  for (const [uid, quem] of Object.entries(TAGS_DO_KIT)) {
    const dono = usuarios?.find((u) => u.tags?.some((t) => t.uid === uid));
    const tag = dono?.tags.find((t) => t.uid === uid);
    if (!dono) aviso(`Tag ${uid} (${quem}) não está cadastrada`, 'Tela Tags NFC (admin): vincule o UID à pessoa');
    else if (!tag.ativa) aviso(`Tag ${uid} de ${dono.nome} está bloqueada`, 'Desbloqueie na tela Tags NFC antes de começar');
    else ok(`Tag ${uid} ativa, de ${dono.nome}`);
  }

  const agora = agoraEm(fuso);
  const { corpo: autorizacoes } = await chamar('/authorizations?situacao=ATIVA', { token: admin });
  const daMaria = autorizacoes?.filter((a) => a.user?.nome === 'Maria Souza') ?? [];
  if (!daMaria.length) falha('A Maria não tem autorização ATIVA hoje', 'Crie uma na tela Autorizações (admin)');
  for (const a of daMaria) {
    const texto = `Maria em "${a.catraca.nome}": ${a.horaInicio}–${a.horaFim}, ${a.usosRestantes} uso(s) restante(s)`;
    if (!dentroDoHorario(agora, a.horaInicio, a.horaFim)) aviso(`${texto}; agora são ${agora}: vai negar por FORA_DO_HORARIO`, 'Amplie o horário na tela Autorizações');
    else if (a.usosRestantes < 5) aviso(texto, 'Aumente o máximo de usos na tela Autorizações');
    else ok(texto);
  }

  const { corpo: arvore } = await chamar('/locations', { token: admin });
  const catracas = arvore?.flatMap((e) => e.portarias.flatMap((p) => p.portas.flatMap((porta) => porta.catracas))) ?? [];
  for (const c of catracas) {
    console.info(`  ℹ️  ${c.nome}: ${c.latitude}, ${c.longitude}, raio ${c.raioMetros} m (o celular precisa estar dentro do raio)`);
  }
}

secao('4. App no celular (HTTPS)');
const ip = ipsDoPc()[0];
if (ip) {
  if (await httpsResponde(`https://${ip}:8443/api/health`)) ok(`App no ar em https://${ip}:8443`);
  else aviso(`O app HTTPS não está no ar em https://${ip}:8443`, 'bash scripts/app-no-celular.sh');
}
console.info(`  ℹ️  Plano B: simulador em ${API}/simulador/ e console em ${API}/console/`);

console.info(`\n${problemas ? `❌ ${problemas} problema(s)` : '✅ Nenhum problema'}${avisos ? ` e ⚠️  ${avisos} aviso(s)` : ''}.`);
process.exit(problemas ? 1 : 0);
