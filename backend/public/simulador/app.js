// Simulador do terminal da catraca. Faz o mesmo que o firmware do ESP32:
// pede o QR à API, desenha, troca antes de vencer e recebe ABRIR/NEGAR pelo MQTT.
// Quando o broker não responde, consulta GET /terminal/decisions a cada 2 s.
'use strict';

const $ = (seletor) => document.querySelector(seletor);

const estado = {
  config: { mqttWsUrl: null, demo: null },
  terminal: null, // { id, chave }
  qrAtual: null,
  ultimoQrLido: null,
  jwt: null,
  mqtt: null,
  ultimoSeq: 0,
  timers: [],
  timerDecisao: null,
};

// ---------- utilidades ----------

async function api(caminho, { method = 'GET', body, headers = {} } = {}) {
  const res = await fetch(caminho, {
    method,
    headers: { 'Content-Type': 'application/json', ...headers },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const dados = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(dados.erro?.mensagem ?? `HTTP ${res.status}`);
  return dados;
}

const cabecalhosTerminal = () => ({ 'X-Terminal-Id': estado.terminal.id, 'X-Terminal-Key': estado.terminal.chave });

function registrar(texto, erro = false) {
  const item = document.createElement('li');
  item.textContent = `${new Date().toLocaleTimeString('pt-BR')}  ${texto}`;
  if (erro) item.className = 'erro';
  $('#log').prepend(item);
  while ($('#log').children.length > 60) $('#log').lastChild.remove();
}

function chip(seletor, texto, tipo) {
  const el = $(seletor);
  el.textContent = texto;
  el.className = `chip ${tipo ?? ''}`;
}

function lembrar(chave, valor) {
  try {
    localStorage.setItem(`passe-sim-${chave}`, valor);
  } catch {
    // navegador sem armazenamento: só não lembra
  }
}

function lembrado(chave) {
  try {
    return localStorage.getItem(`passe-sim-${chave}`);
  } catch {
    return null;
  }
}

// ---------- terminal ----------

function pararTerminal() {
  estado.timers.forEach(clearTimeout);
  estado.timers.forEach(clearInterval);
  estado.timers = [];
  if (estado.mqtt) estado.mqtt.end(true);
  estado.mqtt = null;
}

async function ligarTerminal(evento) {
  evento.preventDefault();
  pararTerminal();
  estado.terminal = { id: $('#terminal-id').value.trim(), chave: $('#terminal-chave').value.trim() };
  lembrar('terminal-id', estado.terminal.id);

  try {
    const info = await api('/terminal/heartbeat', { method: 'POST', body: {}, headers: cabecalhosTerminal() });
    $('#tela-nome').textContent = info.nome;
    chip('#chip-api', 'API: conectada', 'ok');
    registrar(`Terminal "${info.nome}" ligado.`);
  } catch (err) {
    chip('#chip-api', 'API: erro', 'erro');
    registrar(`Não ligou: ${err.message}`, true);
    return;
  }

  // Ponto de partida: ignora decisões antigas que estão na fila.
  const fila = await api('/terminal/decisions', { headers: cabecalhosTerminal() }).catch(() => []);
  estado.ultimoSeq = fila.at(-1)?.seq ?? 0;

  await buscarQr();
  estado.timers.push(setInterval(enviarSinal, 30_000));
  estado.timers.push(setInterval(consultarDecisoes, 2_000));
  conectarMqtt();
}

async function buscarQr() {
  try {
    const qr = await api('/terminal/qr-token', { headers: cabecalhosTerminal() });
    estado.qrAtual = qr.token;
    desenharQr(qr.token);
    animarBarra(qr.trocarEmSegundos);
    chip('#chip-api', 'API: conectada', 'ok');
    estado.timers.push(setTimeout(buscarQr, qr.trocarEmSegundos * 1000));
  } catch (err) {
    chip('#chip-api', 'API: erro', 'erro');
    registrar(`QR: ${err.message}. Tentando de novo em 3 s.`, true);
    estado.qrAtual = null;
    $('#qr').replaceChildren();
    $('#qr').classList.add('vazio');
    estado.timers.push(setTimeout(buscarQr, 3000));
  }
}

function desenharQr(texto) {
  const qr = window.qrcode(0, 'M');
  qr.addData(texto);
  qr.make();
  $('#qr').classList.remove('vazio');
  $('#qr').innerHTML = qr.createSvgTag({ cellSize: 4, margin: 2, scalable: true });
}

function animarBarra(segundos) {
  const barra = $('#barra-tempo');
  barra.style.transition = 'none';
  barra.style.width = '100%';
  void barra.offsetWidth; // aplica o 100% antes de animar
  barra.style.transition = `width ${segundos}s linear`;
  barra.style.width = '0%';
}

async function enviarSinal() {
  try {
    await api('/terminal/heartbeat', { method: 'POST', body: {}, headers: cabecalhosTerminal() });
  } catch (err) {
    registrar(`Sinal de vida falhou: ${err.message}`, true);
  }
}

function conectarMqtt() {
  const url = estado.config.mqttWsUrl;
  if (!url || !window.mqtt) {
    chip('#chip-mqtt', 'MQTT: sem broker (usando HTTP)', 'aviso');
    return;
  }
  const topico = `passe/terminais/${estado.terminal.id}/decisoes`;
  const client = window.mqtt.connect(url, {
    clientId: `simulador-${Math.random().toString(16).slice(2, 10)}`,
    reconnectPeriod: 3000,
    connectTimeout: 5000,
  });
  estado.mqtt = client;

  client.on('connect', () => {
    client.subscribe(topico, { qos: 1 });
    chip('#chip-mqtt', 'MQTT: conectado', 'ok');
    registrar(`MQTT conectado em ${url}, ouvindo ${topico}`);
  });
  client.on('offline', () => chip('#chip-mqtt', 'MQTT: fora do ar (usando HTTP)', 'aviso'));
  client.on('error', (err) => registrar(`MQTT: ${err.message}`, true));
  client.on('message', (_topico, payload) => {
    try {
      mostrarDecisao(JSON.parse(payload.toString()), 'MQTT');
    } catch {
      registrar('MQTT: mensagem ilegível', true);
    }
  });
}

// Com o MQTT conectado, só acompanha a fila para não repetir decisões depois.
async function consultarDecisoes() {
  try {
    const novas = await api(`/terminal/decisions?apos=${estado.ultimoSeq}`, { headers: cabecalhosTerminal() });
    const viaMqtt = estado.mqtt?.connected;
    for (const item of novas) {
      estado.ultimoSeq = Math.max(estado.ultimoSeq, item.seq);
      if (!viaMqtt) mostrarDecisao(item.decisao, 'HTTP');
    }
  } catch {
    // o erro já aparece na troca do QR
  }
}

function mostrarDecisao(decisao, via) {
  const abrir = decisao.acao === 'ABRIR';
  const painel = $('#decisao');
  painel.className = `decisao ${abrir ? 'abrir' : 'negar'}`;
  $('#decisao-icone').textContent = abrir ? '✓' : '✕';
  $('#decisao-titulo').textContent = abrir ? 'Pode passar' : 'Acesso negado';
  $('#decisao-texto').textContent = abrir && decisao.nome ? `Bem-vindo(a), ${decisao.nome}` : decisao.mensagem;
  $('#decisao-via').textContent = `${decisao.metodo} · recebido via ${via}`;
  painel.hidden = false;

  clearTimeout(estado.timerDecisao);
  estado.timerDecisao = setTimeout(() => (painel.hidden = true), 4000);
  registrar(`${decisao.acao} (${decisao.metodo}) via ${via}: ${decisao.mensagem}${decisao.motivo ? ` [${decisao.motivo}]` : ''}`);
}

async function aproximarTag(evento) {
  evento.preventDefault();
  if (!estado.terminal) return registrar('Ligue o terminal primeiro.', true);
  const uid = $('#nfc-uid').value.trim();
  try {
    // A decisão chega na tela pelo mesmo caminho do QR (MQTT ou consulta).
    const r = await api('/terminal/nfc', { method: 'POST', body: { uid }, headers: cabecalhosTerminal() });
    registrar(`Tag ${uid}: ${r.titulo}`);
  } catch (err) {
    registrar(`Tag ${uid}: ${err.message}`, true);
  }
}

// ---------- celular de teste ----------

async function entrar(evento) {
  evento.preventDefault();
  try {
    const r = await api('/auth/login', { method: 'POST', body: { login: $('#login').value, senha: $('#senha').value } });
    estado.jwt = r.token;
    $('#logado').textContent = `Logado como ${r.usuario.nome} (${r.usuario.perfil})`;
    registrar(`Celular: entrou como ${r.usuario.nome}`);
  } catch (err) {
    estado.jwt = null;
    $('#logado').textContent = err.message;
  }
}

function definirPosicao(lat, lng) {
  $('#lat').value = lat ?? '';
  $('#lng').value = lng ?? '';
}

function posicaoInformada() {
  const lat = parseFloat($('#lat').value);
  const lng = parseFloat($('#lng').value);
  return Number.isFinite(lat) && Number.isFinite(lng) ? { latitude: lat, longitude: lng } : {};
}

async function escanear(token) {
  if (!estado.jwt) return mostrarResultado({ erro: 'Entre com uma conta primeiro.' });
  if (!token) return mostrarResultado({ erro: 'Nenhum QR na tela. Ligue o terminal.' });
  estado.ultimoQrLido = token;
  try {
    const r = await api('/access/qr', {
      method: 'POST',
      body: { token, ...posicaoInformada() },
      headers: { Authorization: `Bearer ${estado.jwt}` },
    });
    mostrarResultado(r);
  } catch (err) {
    mostrarResultado({ erro: err.message });
  }
}

function mostrarResultado(r) {
  const caixa = $('#resultado');
  caixa.hidden = false;
  caixa.replaceChildren();
  const titulo = document.createElement('h3');
  const texto = document.createElement('p');

  if (r.erro) {
    caixa.className = 'resultado negado';
    titulo.textContent = 'Erro';
    texto.textContent = r.erro;
  } else {
    caixa.className = `resultado ${r.liberado ? 'ok' : 'negado'}`;
    titulo.textContent = r.titulo;
    const detalhes = [
      r.oQueFazer,
      r.motivo && `Motivo: ${r.motivo}`,
      r.usosRestantes !== undefined && `Usos restantes: ${r.usosRestantes}`,
      r.distanciaMetros !== undefined && `Distância: ${Math.round(r.distanciaMetros)} m`,
      r.catraca?.caminho,
    ].filter(Boolean);
    texto.textContent = detalhes.join(' · ');
  }
  caixa.append(titulo, texto);
}

// ---------- início ----------

async function iniciar() {
  estado.config = await fetch('config.json')
    .then((r) => r.json())
    .catch(() => estado.config);
  const demo = estado.config.demo;

  $('#terminal-id').value = lembrado('terminal-id') ?? demo?.terminalId ?? '';
  $('#terminal-chave').value = demo?.terminalKey ?? '';
  $('#nfc-uid').value = demo?.tagUid ?? '';
  $('#login').value = demo?.login ?? '';
  $('#senha').value = demo?.senha ?? '';
  if (demo) definirPosicao(demo.catraca.latitude, demo.catraca.longitude);

  $('#form-terminal').addEventListener('submit', ligarTerminal);
  $('#form-nfc').addEventListener('submit', aproximarTag);
  $('#form-login').addEventListener('submit', entrar);
  $('#btn-escanear').addEventListener('click', () => escanear(estado.qrAtual));
  $('#btn-reusar').addEventListener('click', () => escanear(estado.ultimoQrLido));
  $('#pos-perto').addEventListener('click', () => {
    const c = demo?.catraca;
    if (c) definirPosicao(c.latitude, c.longitude);
  });
  // ~1 km ao norte da posição atual (ou da catraca)
  $('#pos-longe').addEventListener('click', () => {
    const base = posicaoInformada().latitude !== undefined ? posicaoInformada() : demo?.catraca;
    if (base) definirPosicao((base.latitude + 0.009).toFixed(6), base.longitude);
  });
  $('#pos-sem').addEventListener('click', () => definirPosicao());

  $('#qr').classList.add('vazio');
  if (demo) registrar('Modo de desenvolvimento: campos preenchidos com os dados do seed.');
}

iniciar();
