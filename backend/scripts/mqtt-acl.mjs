// Teste do broker MQTT (issue #10): roda contra um Mosquitto com a configuração
// de docker/mosquitto. Confere que
//   1. cliente anônimo e senha errada são recusados;
//   2. o terminal recebe as decisões que a API publica no tópico dele;
//   3. um terminal não lê o tópico de outro;
//   4. um terminal não consegue publicar um ABRIR falso.
//
//   MQTT_URL=mqtt://localhost:1883 node scripts/mqtt-acl.mjs
import { readFileSync } from 'node:fs';
import mqtt from 'mqtt';

const URL = process.env.MQTT_URL ?? 'mqtt://localhost:1883';
const API = { username: process.env.MQTT_USERNAME ?? 'passe-api', password: process.env.MQTT_PASSWORD ?? 'passe-api-dev' };
const TERMINAL = {
  username: process.env.TERMINAL_ID ?? '00000000-0000-4000-8000-000000000005',
  password: process.env.TERMINAL_KEY ?? 'chave-demo-terminal-catraca-1',
};
// Com TLS: MQTT_URL=mqtts://localhost:8883 MQTT_CA_FILE=../docker/mosquitto/certs/ca.crt
const CA = process.env.MQTT_CA_FILE ? readFileSync(process.env.MQTT_CA_FILE) : undefined;
const OUTRO_TERMINAL = '11111111-1111-4111-8111-111111111111';
const topico = (id) => `passe/terminais/${id}/decisoes`;

let falhas = 0;
function conferir(condicao, descricao) {
  console.info(`${condicao ? 'ok  ' : 'FALHOU'} ${descricao}`);
  if (!condicao) falhas++;
}

/** Conecta e devolve o cliente, ou o erro de conexão. */
function conectar(opcoes) {
  return new Promise((resolve) => {
    const client = mqtt.connect(URL, { protocolVersion: 5, reconnectPeriod: 0, connectTimeout: 5000, ca: CA, ...opcoes });
    client.once('connect', () => resolve({ client }));
    client.once('error', (erro) => {
      client.end(true);
      resolve({ erro });
    });
  });
}

const esperar = (ms) => new Promise((r) => setTimeout(r, ms));

const anonimo = await conectar({});
conferir(!!anonimo.erro, `cliente anônimo é recusado (${anonimo.erro?.message ?? 'conectou!'})`);

const senhaErrada = await conectar({ username: TERMINAL.username, password: 'errada' });
conferir(!!senhaErrada.erro, 'terminal com senha errada é recusado');

const { client: api, erro: erroApi } = await conectar(API);
const { client: terminal, erro: erroTerminal } = await conectar(TERMINAL);
if (erroApi || erroTerminal) {
  console.error(`Não conectou: ${(erroApi ?? erroTerminal).message}`);
  process.exit(1);
}

const recebidas = [];
terminal.on('message', (t, payload) => recebidas.push({ topico: t, decisao: JSON.parse(payload.toString()) }));

const [proprio] = await terminal.subscribeAsync(topico(TERMINAL.username), { qos: 1 });
conferir(proprio.qos === 1, 'terminal assina o próprio tópico');

// O Mosquitto pode aceitar a assinatura, mas a ACL de leitura barra a entrega (conferido abaixo).
await terminal.subscribeAsync(topico(OUTRO_TERMINAL), { qos: 1 });

await api.publishAsync(topico(TERMINAL.username), JSON.stringify({ acao: 'ABRIR', metodo: 'QR', mensagem: 'teste da API' }), { qos: 1 });
await api.publishAsync(topico(OUTRO_TERMINAL), JSON.stringify({ acao: 'ABRIR', metodo: 'QR', mensagem: 'para outro' }), { qos: 1 });

// Um terminal (ou alguém com a chave dele) tentando se mandar um ABRIR.
const falso = await terminal.publishAsync(topico(TERMINAL.username), JSON.stringify({ acao: 'ABRIR', metodo: 'QR', mensagem: 'falso' }), { qos: 1 }).catch((e) => e);

await esperar(1000);
conferir(recebidas.some((m) => m.decisao.mensagem === 'teste da API'), 'terminal recebe a decisão publicada pela API');
conferir(!recebidas.some((m) => m.decisao.mensagem === 'para outro'), 'terminal não recebe decisão de outro terminal');
conferir(!recebidas.some((m) => m.decisao.mensagem === 'falso'), `terminal não publica ABRIR falso (${falso?.reasonCode ?? falso?.message ?? 'sem retorno'})`);

await Promise.all([api.endAsync(), terminal.endAsync()]);
console.info(falhas ? `\n${falhas} verificação(ões) falharam.` : '\nBroker protegido: tudo certo.');
process.exit(falhas ? 1 : 0);
