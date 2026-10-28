// Console web do Passe: as mesmas telas do app Flutter, para testar o backend
// sem precisar rodar o Flutter. Fala com a mesma API (JWT em Authorization).
// Sem build e sem scripts inline: a CSP do helmet só aceita arquivos próprios.
'use strict';

const PERFIS = {
  ADMIN: 'Admin',
  CONTROLADOR_ACESSO: 'Controlador de acesso',
  CONDOMINO: 'Condômino',
  VISITANTE: 'Visitante',
};
const EQUIPE = ['ADMIN', 'CONTROLADOR_ACESSO'];
// A portaria só gerencia quem usa o prédio (users.service.ts).
const PERFIS_DA_PORTARIA = ['CONDOMINO', 'VISITANTE'];

const MOTIVOS = {
  QR_INVALIDO: 'QR Code não reconhecido',
  QR_EXPIRADO: 'QR Code vencido',
  QR_JA_UTILIZADO: 'QR Code já usado',
  TERMINAL_DESCONHECIDO: 'Catraca não cadastrada',
  TAG_DESCONHECIDA: 'Tag não cadastrada',
  TAG_BLOQUEADA: 'Tag bloqueada',
  USUARIO_INATIVO: 'Cadastro desativado',
  SEM_AUTORIZACAO: 'Sem autorização para a catraca',
  AUTORIZACAO_CANCELADA: 'Autorização cancelada',
  AUTORIZACAO_EXPIRADA: 'Autorização expirada',
  AUTORIZACAO_NAO_INICIADA: 'Autorização ainda não começou',
  FORA_DO_HORARIO: 'Fora do horário',
  SEM_USOS: 'Sem usos restantes',
  LOCALIZACAO_AUSENTE: 'Sem localização do celular',
  LONGE_DO_TERMINAL: 'Mais de 100 m da catraca',
};

const CHAVE_SESSAO = 'passe.console';
let sessao = lerSessao();

const $ = (seletor) => document.querySelector(seletor);

// ---------------------------------------------------------------- utilidades

/** Cria um elemento. Texto entra como texto (nunca como HTML). */
function h(tag, props, ...filhos) {
  const el = document.createElement(tag);
  let valor;
  for (const [k, v] of Object.entries(props || {})) {
    if (v === undefined || v === null || v === false) continue;
    if (k === 'class') el.className = v;
    else if (k === 'value') valor = v;
    else if (k.startsWith('on')) el.addEventListener(k.slice(2), v);
    else if (k === 'checked' || k === 'disabled' || k === 'required') el[k] = v;
    else el.setAttribute(k, v === true ? '' : v);
  }
  for (const f of filhos.flat(Infinity)) {
    if (f === undefined || f === null || f === false) continue;
    el.append(f instanceof Node ? f : document.createTextNode(String(f)));
  }
  // O valor de um <select> só vale depois de as opções existirem.
  if (valor !== undefined) el.value = valor;
  return el;
}

function lerSessao() {
  try {
    return JSON.parse(sessionStorage.getItem(CHAVE_SESSAO));
  } catch {
    return null;
  }
}

function guardarSessao(nova) {
  sessao = nova;
  try {
    if (nova) sessionStorage.setItem(CHAVE_SESSAO, JSON.stringify(nova));
    else sessionStorage.removeItem(CHAVE_SESSAO);
  } catch {
    // Sem armazenamento: a sessão vale só até recarregar a página.
  }
}

async function api(metodo, caminho, { corpo, query, headers } = {}) {
  const url = new URL(caminho, location.origin);
  for (const [k, v] of Object.entries(query || {})) {
    if (v !== undefined && v !== null && v !== '') url.searchParams.set(k, v);
  }
  const resposta = await fetch(url, {
    method: metodo,
    headers: {
      Accept: 'application/json',
      ...(corpo ? { 'Content-Type': 'application/json' } : {}),
      ...(sessao ? { Authorization: `Bearer ${sessao.token}` } : {}),
      ...headers,
    },
    body: corpo ? JSON.stringify(corpo) : undefined,
  });
  const texto = await resposta.text();
  let json = null;
  try {
    json = texto ? JSON.parse(texto) : null;
  } catch {
    // Resposta que não é JSON: cai na mensagem genérica abaixo.
  }
  if (resposta.ok) return json;
  if (resposta.status === 401 && sessao && caminho !== '/auth/login') {
    sair();
    throw new Error('Sessão vencida. Entre de novo.');
  }
  const erro = json && json.erro;
  let mensagem = (erro && erro.mensagem) || `Erro ${resposta.status}`;
  if (erro && erro.detalhes && typeof erro.detalhes === 'object') {
    const extra = Object.entries(erro.detalhes)
      .map(([campo, msgs]) => `${campo}: ${[].concat(msgs).join(', ')}`)
      .join(' · ');
    if (extra) mensagem += ` (${extra})`;
  }
  throw new Error(mensagem);
}

let temporizadorAviso;
function aviso(texto, ruim = false) {
  const el = $('#aviso');
  el.textContent = texto;
  el.className = ruim ? 'aviso ruim' : 'aviso';
  el.hidden = false;
  clearTimeout(temporizadorAviso);
  temporizadorAviso = setTimeout(() => (el.hidden = true), ruim ? 9000 : 4000);
}

/** Roda uma ação e mostra o erro da API num aviso, em vez de quebrar a tela. */
async function tentar(acao) {
  try {
    return await acao();
  } catch (erro) {
    aviso(erro.message, true);
    return undefined;
  }
}

const souEquipe = () => sessao && EQUIPE.includes(sessao.usuario.perfil);
const souAdmin = () => sessao && sessao.usuario.perfil === 'ADMIN';

const dois = (n) => String(n).padStart(2, '0');
const dataBr = (iso) => (iso ? iso.split('-').reverse().join('/') : '');
const dataHora = (iso) => {
  const d = new Date(iso);
  return `${dois(d.getDate())}/${dois(d.getMonth() + 1)}/${d.getFullYear()} ${dois(d.getHours())}:${dois(d.getMinutes())}`;
};
const dataIso = (d) => `${d.getFullYear()}-${dois(d.getMonth() + 1)}-${dois(d.getDate())}`;
const cpfMascarado = (cpf) => (cpf.length === 11 ? `•••.${cpf.slice(3, 6)}.${cpf.slice(6, 9)}-••` : cpf);
const motivo = (codigo) => (codigo ? MOTIVOS[codigo] || codigo : '');

function selo(texto, tom) {
  return h('span', { class: `selo ${tom || ''}` }, texto);
}

const TOM_SITUACAO = { ATIVA: 'ok', AGENDADA: '', EXPIRADA: '', ESGOTADA: 'atencao', CANCELADA: 'ruim' };
const ROTULO_SITUACAO = { ATIVA: 'Ativa', AGENDADA: 'Agendada', EXPIRADA: 'Expirada', ESGOTADA: 'Sem usos', CANCELADA: 'Cancelada' };
const seloSituacao = (s) => selo(ROTULO_SITUACAO[s] || s, TOM_SITUACAO[s]);

function campo(rotulo, entrada) {
  return h('label', null, rotulo, entrada);
}

function opcoes(lista, vazio) {
  return [vazio ? h('option', { value: '' }, vazio) : null, ...lista.map(([valor, texto]) => h('option', { value: valor }, texto))];
}

function tabela(colunas, linhas, aoClicar) {
  if (!linhas.length) return h('p', { class: 'vazio' }, 'Nada encontrado.');
  return h(
    'div',
    { class: 'rolagem' },
    h(
      'table',
      null,
      h('thead', null, h('tr', null, colunas.map((c) => h('th', null, c)))),
      h(
        'tbody',
        null,
        linhas.map(({ celulas, dado }) =>
          h('tr', { class: aoClicar ? 'clicavel' : '', onclick: aoClicar ? () => aoClicar(dado) : undefined }, celulas.map((c) => h('td', null, c))),
        ),
      ),
    ),
  );
}

function carregando(destino) {
  destino.replaceChildren(h('p', { class: 'vazio' }, 'Carregando…'));
}

// --------------------------------------------------------------------- telas

const TELAS = {
  painel: { rotulo: 'Painel', equipe: true, render: telaPainel },
  usuarios: { rotulo: 'Usuários', equipe: true, render: telaUsuarios },
  locais: { rotulo: 'Locais', equipe: true, render: telaLocais },
  autorizacoes: { rotulo: 'Autorizações', equipe: true, render: telaAutorizacoes },
  historico: { rotulo: 'Histórico de acessos', equipe: true, render: telaHistorico },
  terminais: { rotulo: 'Terminais', equipe: true, render: telaTerminais },
  minhas: { rotulo: 'Minhas autorizações', render: telaMinhas },
  qr: { rotulo: 'Ler QR Code', render: telaQr },
  meuhistorico: { rotulo: 'Meu histórico', render: telaMeuHistorico },
  perfil: { rotulo: 'Perfil', render: telaPerfil },
};

let telaAtual = null;

function montarMenu() {
  const menu = $('#menu');
  const ids = Object.keys(TELAS).filter((id) => !TELAS[id].equipe || souEquipe());
  const partes = [];
  ids.forEach((id, i) => {
    if (i > 0 && !TELAS[id].equipe && TELAS[ids[i - 1]].equipe) partes.push(h('span', { class: 'separador' }));
    partes.push(h('button', { type: 'button', 'data-tela': id, class: id === telaAtual ? 'ativo' : '', onclick: () => abrir(id) }, TELAS[id].rotulo));
  });
  menu.replaceChildren(...partes);
}

async function abrir(id) {
  telaAtual = id;
  montarMenu();
  const conteudo = $('#conteudo');
  carregando(conteudo);
  try {
    await TELAS[id].render(conteudo);
  } catch (erro) {
    if (telaAtual !== id) return;
    conteudo.replaceChildren(h('p', { class: 'erro' }, erro.message), h('button', { type: 'button', onclick: () => abrir(id) }, 'Tentar novamente'));
  }
}

// ---- Painel (A1)

async function telaPainel(el) {
  const r = await api('GET', '/dashboard');
  const numero = (valor, rotulo, destino) =>
    h('div', { class: 'cartao' }, h('div', { class: 'numero' }, valor), h('div', null, rotulo), h('button', { type: 'button', class: 'sec pequeno', onclick: () => abrir(destino) }, 'Ver'));
  el.replaceChildren(
    h('h2', null, 'Painel'),
    h('p', { class: 'suave' }, `Hoje, ${dois(new Date().getDate())}/${dois(new Date().getMonth() + 1)}`),
    h('div', { class: 'grade' }, numero(r.acessosHoje, 'Acessos hoje', 'historico'), numero(r.negadosHoje, 'Negados hoje', 'historico'), numero(r.autorizacoesAtivas, 'Autorizações ativas', 'autorizacoes')),
    h(
      'div',
      { class: 'cartao' },
      h('h3', null, 'Negados recentes'),
      tabela(['Quando', 'Pessoa', 'Catraca', 'Motivo'], r.negadosRecentes.map((e) => ({ celulas: [dataHora(e.createdAt), e.user ? e.user.nome : '—', e.catraca ? e.catraca.nome : '—', motivo(e.motivo)] }))),
    ),
  );
}

// ---- Usuários (A3, A4)

async function telaUsuarios(el) {
  const busca = h('input', { placeholder: 'Nome, e-mail ou CPF' });
  const perfil = h('select', null, opcoes(Object.entries(PERFIS), 'Todos os perfis'));
  const lista = h('div');
  const formulario = h('div');

  async function carregar() {
    carregando(lista);
    const usuarios = await tentar(() => api('GET', '/users', { query: { busca: busca.value.trim(), perfil: perfil.value } }));
    if (!usuarios) return lista.replaceChildren(h('p', { class: 'vazio' }, 'Não foi possível carregar.'));
    lista.replaceChildren(
      h('p', { class: 'suave' }, `${usuarios.length} ${usuarios.length === 1 ? 'usuário encontrado' : 'usuários encontrados'}`),
      tabela(
        ['Nome', 'CPF', 'Perfil', 'Tag', 'Situação'],
        usuarios.map((u) => {
          const tag = (u.tags || []).find((t) => t.ativa);
          return { dado: u, celulas: [u.nome, cpfMascarado(u.cpf), PERFIS[u.perfil], tag ? `Tag ${tag.uid.slice(-4)}` : 'Sem tag', u.ativo ? selo('Ativo', 'ok') : selo('Desativado', 'ruim')] };
        }),
        (u) => formUsuario(formulario, u, carregar),
      ),
    );
  }

  el.replaceChildren(
    h('h2', null, 'Usuários'),
    h(
      'form',
      { class: 'barra', onsubmit: (e) => (e.preventDefault(), carregar()) },
      campo('Buscar usuário', busca),
      campo('Perfil', perfil),
      h('button', { type: 'submit' }, 'Buscar'),
      h('button', { type: 'button', class: 'sec', onclick: () => formUsuario(formulario, null, carregar) }, 'Novo usuário'),
    ),
    lista,
    formulario,
  );
  await carregar();
}

async function formUsuario(destino, usuario, aoSalvar) {
  const novo = !usuario;
  const permitidos = souAdmin() ? Object.keys(PERFIS) : PERFIS_DA_PORTARIA;
  if (usuario && !permitidos.includes(usuario.perfil)) {
    destino.replaceChildren(h('div', { class: 'cartao' }, h('p', { class: 'erro' }, 'A portaria só gerencia condôminos e visitantes.')));
    return;
  }
  // Tags frescas direto da API.
  const atual = novo ? null : await tentar(() => api('GET', `/users/${usuario.id}`));
  if (!novo && !atual) return;

  const nome = h('input', { value: atual ? atual.nome : '', required: true });
  const email = h('input', { type: 'email', value: atual ? atual.email : '', required: true });
  const cpf = h('input', { value: atual ? atual.cpf : '', required: true, placeholder: 'Só números' });
  const senha = h('input', { type: 'password', autocomplete: 'new-password', placeholder: novo ? 'Mínimo 6 caracteres' : 'Deixe em branco para manter', required: novo });
  const perfil = h('select', null, opcoes(permitidos.map((p) => [p, `${PERFIS[p]}`])));
  perfil.value = atual ? atual.perfil : permitidos.includes('CONDOMINO') ? 'CONDOMINO' : permitidos[0];
  const ativo = h('input', { type: 'checkbox', checked: atual ? atual.ativo : true });

  const form = h(
    'form',
    {
      onsubmit: async (e) => {
        e.preventDefault();
        const dados = { nome: nome.value.trim(), email: email.value.trim(), cpf: cpf.value, perfil: perfil.value };
        if (senha.value) dados.senha = senha.value;
        const ok = await tentar(() => (novo ? api('POST', '/users', { corpo: dados }) : api('PATCH', `/users/${usuario.id}`, { corpo: { ...dados, ativo: ativo.checked } })));
        if (!ok) return;
        aviso(novo ? 'Usuário cadastrado.' : 'Alterações salvas.');
        destino.replaceChildren();
        aoSalvar();
      },
    },
    h('h3', null, novo ? 'Novo usuário' : 'Editar usuário'),
    campo('Nome completo', nome),
    campo('E-mail', email),
    campo('Documento (CPF)', cpf),
    campo(novo ? 'Senha' : 'Nova senha', senha),
    campo('Perfil', perfil),
    novo ? null : h('label', { class: 'linha' }, ativo, 'Cadastro ativo (desativado não passa em nenhuma catraca)'),
    h('div', { class: 'acoes' }, h('button', { type: 'submit' }, novo ? 'Cadastrar usuário' : 'Salvar alterações'), h('button', { type: 'button', class: 'sec', onclick: () => destino.replaceChildren() }, 'Fechar')),
  );

  const cartao = h('div', { class: 'cartao' }, form);
  if (!novo) cartao.append(secaoTags(atual));
  destino.replaceChildren(cartao);
  destino.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
}

function secaoTags(usuario) {
  const caixa = h('div');
  async function recarregar() {
    const u = await tentar(() => api('GET', `/users/${usuario.id}`));
    if (u) desenhar(u.tags || []);
  }
  function desenhar(tags) {
    const uid = h('input', { placeholder: '04A1B2C3' });
    caixa.replaceChildren(
      h('h3', null, 'Tags NFC'),
      tags.length
        ? tabela(
            ['UID', 'Situação', ''],
            tags.map((t) => ({
              celulas: [
                t.uid,
                t.ativa ? selo('Ativa', 'ok') : selo('Bloqueada', 'ruim'),
                h(
                  'span',
                  { class: 'acoes' },
                  h('button', { type: 'button', class: 'sec pequeno', onclick: async () => (await tentar(() => api('PATCH', `/users/${usuario.id}/tags/${t.id}`, { corpo: { ativa: !t.ativa } }))) && recarregar() }, t.ativa ? 'Bloquear' : 'Ativar'),
                  h('button', { type: 'button', class: 'perigo pequeno', onclick: async () => confirm(`Remover a tag ${t.uid}?`) && (await tentar(() => api('DELETE', `/users/${usuario.id}/tags/${t.id}`))) !== undefined && recarregar() }, 'Remover'),
                ),
              ],
            })),
          )
        : h('p', { class: 'suave' }, 'Nenhuma tag vinculada.'),
      h(
        'form',
        { class: 'barra', onsubmit: async (e) => (e.preventDefault(), (await tentar(() => api('POST', `/users/${usuario.id}/tags`, { corpo: { uid: uid.value.trim() } }))) && (aviso('Tag vinculada.'), recarregar())) },
        campo('UID da nova tag', uid),
        h('button', { type: 'submit' }, 'Vincular tag'),
      ),
    );
  }
  desenhar(usuario.tags || []);
  return caixa;
}

// ---- Locais (A5, A6)

async function telaLocais(el) {
  const arvore = await api('GET', '/locations');
  const admin = souAdmin();
  const portas = arvore.flatMap((e) => e.portarias.flatMap((p) => p.portas.map((porta) => [porta.id, `${e.nome} › ${p.nome} › ${porta.nome}`])));
  const portarias = arvore.flatMap((e) => e.portarias.map((p) => [p.id, `${e.nome} › ${p.nome}`]));
  const formularioCatraca = h('div');

  const noArvore = h(
    'div',
    { class: 'cartao' },
    h('h3', null, 'Edifício › Portaria › Porta › Catraca'),
    arvore.length ? null : h('p', { class: 'vazio' }, 'Nenhum local cadastrado.'),
    arvore.map((e) =>
      h(
        'div',
        null,
        h('p', null, h('strong', null, e.nome), ` · ${e.endereco}`),
        e.portarias.map((p) =>
          h(
            'div',
            { class: 'arvore' },
            h('p', null, h('strong', null, p.nome)),
            p.portas.map((porta) =>
              h(
                'div',
                { class: 'arvore' },
                h('p', null, porta.nome),
                porta.catracas.map((c) =>
                  h(
                    'p',
                    { class: 'arvore' },
                    `${c.nome} · raio ${c.raioMetros} m · (${c.latitude}, ${c.longitude}) `,
                    admin ? h('button', { type: 'button', class: 'sec pequeno', onclick: () => formCatraca(formularioCatraca, portas, c, () => abrir('locais')) }, 'Editar') : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  el.replaceChildren(h('h2', null, 'Locais'), noArvore);
  if (!admin) {
    el.append(h('p', { class: 'suave' }, 'Só o administrador cadastra e edita locais.'));
    return;
  }

  const simples = (titulo, extras, enviar) => {
    const nome = h('input', { required: true });
    const adicionais = extras.map(([rotulo, entrada]) => campo(rotulo, entrada));
    return h(
      'form',
      {
        class: 'cartao',
        onsubmit: async (e) => {
          e.preventDefault();
          if (await tentar(() => enviar(nome.value.trim()))) {
            aviso('Cadastrado.');
            abrir('locais');
          }
        },
      },
      h('h3', null, titulo),
      campo('Nome', nome),
      adicionais,
      h('button', { type: 'submit' }, 'Cadastrar'),
    );
  };

  const endereco = h('input', { required: true });
  const edificio = h('select', { required: true }, opcoes(arvore.map((e) => [e.id, e.nome])));
  const portaria = h('select', { required: true }, opcoes(portarias));

  el.append(
    h(
      'div',
      { class: 'colunas' },
      simples('Novo edifício', [['Endereço', endereco]], (nome) => api('POST', '/locations/buildings', { corpo: { nome, endereco: endereco.value.trim() } })),
      simples('Nova portaria', [['Edifício', edificio]], (nome) => api('POST', '/locations/gates', { corpo: { nome, buildingId: edificio.value } })),
      simples('Nova porta', [['Portaria', portaria]], (nome) => api('POST', '/locations/doors', { corpo: { nome, gateId: portaria.value } })),
      h('div', { class: 'cartao' }, h('h3', null, 'Nova catraca'), h('button', { type: 'button', onclick: () => formCatraca(formularioCatraca, portas, null, () => abrir('locais')) }, 'Abrir formulário')),
    ),
    formularioCatraca,
  );
}

function formCatraca(destino, portas, catraca, aoSalvar) {
  const nova = !catraca;
  const nome = h('input', { value: catraca ? catraca.nome : '', required: true });
  const porta = h('select', { required: true }, opcoes(portas));
  const latitude = h('input', { value: catraca ? catraca.latitude : '', required: true, inputmode: 'decimal' });
  const longitude = h('input', { value: catraca ? catraca.longitude : '', required: true, inputmode: 'decimal' });
  const raio = h('input', { type: 'number', min: 10, max: 1000, value: catraca ? catraca.raioMetros : 100, required: true });
  const numero = (campoTexto) => Number(campoTexto.value.trim().replace(',', '.'));

  destino.replaceChildren(
    h(
      'form',
      {
        class: 'cartao',
        onsubmit: async (e) => {
          e.preventDefault();
          const dados = { nome: nome.value.trim(), latitude: numero(latitude), longitude: numero(longitude), raioMetros: Number(raio.value) };
          const ok = await tentar(() => (nova ? api('POST', '/locations/access-points', { corpo: { ...dados, doorId: porta.value } }) : api('PATCH', `/locations/access-points/${catraca.id}`, { corpo: dados })));
          if (ok) {
            aviso('Catraca salva.');
            aoSalvar();
          }
        },
      },
      h('h3', null, nova ? 'Nova catraca' : `Editar ${catraca.nome}`),
      campo('Nome', nome),
      nova ? campo('Porta', porta) : null,
      campo('Latitude', latitude),
      campo('Longitude', longitude),
      h('div', { class: 'acoes' }, h('button', { type: 'button', class: 'sec', onclick: () => usarGps(latitude, longitude) }, 'Usar minha localização')),
      campo('Raio permitido (metros, de 10 a 1000)', raio),
      h('div', { class: 'acoes' }, h('button', { type: 'submit' }, nova ? 'Cadastrar catraca' : 'Salvar local'), h('button', { type: 'button', class: 'sec', onclick: () => destino.replaceChildren() }, 'Fechar')),
    ),
  );
  destino.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
}

function usarGps(latitude, longitude) {
  if (!navigator.geolocation) return aviso('Este navegador não tem geolocalização.', true);
  navigator.geolocation.getCurrentPosition(
    (p) => {
      latitude.value = p.coords.latitude.toFixed(6);
      longitude.value = p.coords.longitude.toFixed(6);
    },
    () => aviso('Não consegui sua localização. Permita o acesso ou digite as coordenadas.', true),
    { timeout: 8000 },
  );
}

// ---- Autorizações (A7 a A10)

async function telaAutorizacoes(el) {
  const [usuarios, arvore] = await Promise.all([api('GET', '/users'), api('GET', '/locations')]);
  const catracas = arvore.flatMap((e) => e.portarias.flatMap((p) => p.portas.flatMap((porta) => porta.catracas.map((c) => [c.id, `${c.nome} · ${e.nome} › ${p.nome} › ${porta.nome}`]))));
  const pessoas = usuarios.map((u) => [u.id, `${u.nome} · ${PERFIS[u.perfil]}`]);

  const situacao = h('select', null, opcoes([['ATIVA', 'Ativas'], ['EXPIRADA', 'Expiradas'], ['CANCELADA', 'Canceladas']], 'Todas'));
  situacao.value = 'ATIVA';
  const pessoa = h('select', null, opcoes(pessoas, 'Todas'));
  const local = h('select', null, opcoes(catracas, 'Todos'));
  const de = h('input', { type: 'date' });
  const ate = h('input', { type: 'date' });
  const lista = h('div');
  const formulario = h('div');

  async function carregar() {
    carregando(lista);
    const itens = await tentar(() => api('GET', '/authorizations', { query: { situacao: situacao.value, userId: pessoa.value, accessPointId: local.value, de: de.value, ate: ate.value } }));
    if (!itens) return lista.replaceChildren(h('p', { class: 'vazio' }, 'Não foi possível carregar.'));
    lista.replaceChildren(
      h('p', { class: 'suave' }, `${itens.length} ${itens.length === 1 ? 'autorização encontrada' : 'autorizações encontradas'}`),
      tabela(
        ['Pessoa', 'Catraca', 'Período', 'Horário', 'Usos', 'Situação'],
        itens.map((a) => ({
          dado: a,
          celulas: [
            a.user.nome,
            a.catraca.nome,
            a.dataInicio === a.dataFim ? `Somente ${dataBr(a.dataInicio)}` : `${dataBr(a.dataInicio)} a ${dataBr(a.dataFim)}`,
            `${a.horaInicio} às ${a.horaFim}`,
            [`${a.usosRestantes} de ${a.maxUsos} restantes`, a.situacao === 'ATIVA' && a.usosRestantes === 1 ? h('div', null, selo('Último uso', 'atencao')) : null],
            seloSituacao(a.situacao),
          ],
        })),
        (a) => formAutorizacao(formulario, a, pessoas, catracas, carregar),
      ),
    );
  }

  el.replaceChildren(
    h('h2', null, 'Autorizações'),
    h(
      'form',
      { class: 'barra', onsubmit: (e) => (e.preventDefault(), carregar()) },
      campo('Situação', situacao),
      campo('Pessoa', pessoa),
      campo('Local', local),
      campo('De', de),
      campo('Até', ate),
      h('button', { type: 'submit' }, 'Filtrar'),
      h('button', { type: 'button', class: 'sec', onclick: () => formAutorizacao(formulario, null, pessoas, catracas, carregar) }, 'Nova autorização'),
    ),
    lista,
    formulario,
  );
  await carregar();
}

function formAutorizacao(destino, a, pessoas, catracas, aoSalvar) {
  const nova = !a;
  const somenteLeitura = a && a.status === 'CANCELADA';
  const pessoa = h('select', { disabled: !nova }, opcoes(pessoas, nova ? 'Escolha a pessoa' : null));
  pessoa.value = a ? a.userId : '';
  const local = h('select', null, opcoes(catracas, 'Escolha a catraca'));
  local.value = a ? a.accessPointId : '';
  const inicio = h('input', { type: 'date', value: a ? a.dataInicio : dataIso(new Date()), required: true });
  const fim = h('input', { type: 'date', value: a ? a.dataFim : dataIso(new Date()), required: true });
  const horaInicio = h('input', { type: 'time', value: a ? a.horaInicio : '08:00', required: true });
  const horaFim = h('input', { type: 'time', value: a ? a.horaFim : '18:00', required: true });
  const usos = h('input', { type: 'number', min: 1, max: 10000, value: a ? a.maxUsos : 1, required: true });
  if (somenteLeitura) for (const c of [pessoa, local, inicio, fim, horaInicio, horaFim, usos]) c.disabled = true;

  async function salvar(e) {
    e.preventDefault();
    if (!pessoa.value || !local.value) return aviso('Escolha a pessoa e o local.', true);
    if (fim.value < inicio.value) return aviso('O fim precisa ser depois do início.', true);
    const dados = { accessPointId: local.value, dataInicio: inicio.value, dataFim: fim.value, horaInicio: horaInicio.value, horaFim: horaFim.value, maxUsos: Number(usos.value) };
    const ok = await tentar(() => (nova ? api('POST', '/authorizations', { corpo: { ...dados, userId: pessoa.value } }) : api('PATCH', `/authorizations/${a.id}`, { corpo: dados })));
    if (!ok) return;
    aviso(nova ? 'Autorização criada.' : 'Alterações salvas.');
    destino.replaceChildren();
    aoSalvar();
  }

  async function cancelar() {
    if (!confirm(`Cancelar esta autorização? ${a.user.nome} não vai mais conseguir passar pela ${a.catraca.nome}. Para liberar de novo, será preciso criar outra.`)) return;
    if (await tentar(() => api('POST', `/authorizations/${a.id}/cancel`))) {
      aviso('Autorização cancelada.');
      destino.replaceChildren();
      aoSalvar();
    }
  }

  destino.replaceChildren(
    h(
      'form',
      { class: 'cartao', onsubmit: salvar },
      h('h3', null, nova ? 'Nova autorização' : somenteLeitura ? 'Autorização (cancelada)' : 'Editar autorização'),
      somenteLeitura ? h('p', { class: 'erro' }, 'Esta autorização foi cancelada e não pode ser editada. Crie outra se precisar liberar o acesso.') : null,
      campo('Pessoa', pessoa),
      campo('Local', local),
      h('div', { class: 'barra' }, campo('Início', inicio), campo('Fim', fim)),
      h('div', { class: 'barra' }, campo('Das', horaInicio), campo('Até', horaFim)),
      campo(nova ? 'Quantidade de usos' : `Quantidade de usos (já usada ${a.usosRealizados} vez(es))`, usos),
      h(
        'div',
        { class: 'acoes' },
        somenteLeitura ? null : h('button', { type: 'submit' }, nova ? 'Criar autorização' : 'Salvar alterações'),
        !nova && !somenteLeitura ? h('button', { type: 'button', class: 'perigo', onclick: cancelar }, 'Cancelar esta autorização') : null,
        h('button', { type: 'button', class: 'sec', onclick: () => destino.replaceChildren() }, 'Fechar'),
      ),
    ),
  );
  destino.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
}

// ---- Histórico (A11, A12)

async function telaHistorico(el) {
  const arvore = await api('GET', '/locations');
  const catracas = arvore.flatMap((e) => e.portarias.flatMap((p) => p.portas.flatMap((porta) => porta.catracas.map((c) => [c.id, c.nome]))));
  const periodo = h('select', null, opcoes([['hoje', 'Hoje'], ['7', 'Últimos 7 dias'], ['30', 'Últimos 30 dias'], ['tudo', 'Tudo']]));
  const resultado = h('select', null, opcoes([['LIBERADO', 'Liberados'], ['NEGADO', 'Negados']], 'Todos'));
  const metodo = h('select', null, opcoes([['QR', 'QR Code'], ['NFC', 'Tag NFC']], 'Todos'));
  const local = h('select', null, opcoes(catracas, 'Todas'));
  const resumo = h('p', { class: 'suave' });
  const lista = h('div');
  const mais = h('div');
  let itens = [];
  let total = 0;

  const desde = () => {
    if (periodo.value === 'tudo') return undefined;
    const d = new Date();
    d.setHours(0, 0, 0, 0);
    if (periodo.value !== 'hoje') d.setDate(d.getDate() - (Number(periodo.value) - 1));
    return d.toISOString();
  };

  async function carregar(somar) {
    const pular = somar ? itens.length : 0;
    const pagina = await tentar(() => api('GET', '/access-events', { query: { de: desde(), resultado: resultado.value, metodo: metodo.value, accessPointId: local.value, limite: 50, pular } }));
    if (!pagina) return;
    itens = somar ? itens.concat(pagina.itens) : pagina.itens;
    total = pagina.total;
    resumo.textContent = `${pagina.total} registros · ${pagina.liberados} liberados, ${pagina.negados} negados`;
    lista.replaceChildren(
      itens.length
        ? tabela(
            ['Quando', 'Pessoa', 'Catraca', 'Forma', 'Resultado', 'Motivo'],
            itens.map((e) => ({ celulas: [dataHora(e.createdAt), e.user ? e.user.nome : 'Não identificada', e.catraca ? e.catraca.nome : '—', e.metodo === 'NFC' ? 'Tag NFC' : 'QR Code', e.resultado === 'LIBERADO' ? selo('Liberado', 'ok') : selo('Negado', 'ruim'), motivo(e.motivo)] })),
          )
        : h('div', { class: 'vazio' }, h('p', null, h('strong', null, 'Nenhum acesso encontrado')), h('p', null, 'Mude os filtros ou escolha outro período.')),
    );
    mais.replaceChildren(itens.length < total ? h('button', { type: 'button', class: 'sec', onclick: () => carregar(true) }, `Ver mais (${total - itens.length} restantes)`) : '');
  }

  el.replaceChildren(
    h('h2', null, 'Histórico de acessos'),
    h('form', { class: 'barra', onsubmit: (e) => (e.preventDefault(), carregar(false)) }, campo('Período', periodo), campo('Resultado', resultado), campo('Forma de entrada', metodo), campo('Catraca', local), h('button', { type: 'submit' }, 'Filtrar')),
    resumo,
    lista,
    mais,
  );
  await carregar(false);
}

// ---- Terminais

async function telaTerminais(el) {
  const [terminais, arvore] = await Promise.all([api('GET', '/terminals'), api('GET', '/locations')]);
  const catracas = arvore.flatMap((e) => e.portarias.flatMap((p) => p.portas.flatMap((porta) => porta.catracas.map((c) => [c.id, `${c.nome} · ${e.nome} › ${p.nome} › ${porta.nome}`]))));
  const nomes = Object.fromEntries(catracas);
  const livres = catracas.filter(([id]) => !terminais.some((t) => t.accessPointId === id));
  const admin = souAdmin();
  const chave = h('div');

  const mostrarChave = (t) =>
    chave.replaceChildren(
      h('div', { class: 'cartao' }, h('h3', null, `Chave de ${t.nome}`), h('p', { class: 'suave' }, 'Grave esta chave no firmware agora. Ela não aparece de novo.'), h('pre', null, t.chave)),
    );

  const nome = h('input', { required: true });
  const catraca = h('select', { required: true }, opcoes(livres));

  el.replaceChildren(
    h('h2', null, 'Terminais'),
    h('p', { class: 'suave' }, 'Sem sinal há mais de 90 s, o terminal aparece offline.'),
    h(
      'div',
      { class: 'cartao' },
      tabela(
        ['Terminal', 'Catraca', 'Situação', 'Último sinal', ''],
        terminais.map((t) => ({
          celulas: [
            t.nome,
            nomes[t.accessPointId] || 'Catraca removida',
            t.online ? selo('Online', 'ok') : selo('Offline', 'ruim'),
            t.ultimoSinal ? dataHora(t.ultimoSinal) : 'Nunca enviou sinal',
            admin
              ? h(
                  'button',
                  {
                    type: 'button',
                    class: 'perigo pequeno',
                    onclick: async () => {
                      if (!confirm(`Trocar a chave de ${t.nome}? A chave atual para de valer na hora.`)) return;
                      const novo = await tentar(() => api('POST', `/terminals/${t.id}/rotate-key`));
                      if (novo) mostrarChave(novo);
                    },
                  },
                  'Trocar chave',
                )
              : '',
          ],
        })),
      ),
    ),
    chave,
    admin
      ? h(
          'form',
          {
            class: 'cartao',
            onsubmit: async (e) => {
              e.preventDefault();
              if (!catraca.value) return aviso('Todas as catracas já têm terminal.', true);
              const novo = await tentar(() => api('POST', '/terminals', { corpo: { nome: nome.value.trim(), accessPointId: catraca.value } }));
              if (novo) {
                mostrarChave(novo);
                aviso('Terminal cadastrado.');
              }
            },
          },
          h('h3', null, 'Novo terminal'),
          campo('Nome', nome),
          campo('Catraca (só as sem terminal)', catraca),
          h('button', { type: 'submit' }, 'Cadastrar'),
        )
      : h('p', { class: 'suave' }, 'Só o administrador cadastra terminais e troca chaves.'),
  );
}

// ---- Telas do app para todos os perfis (morador, visitante e equipe)

async function telaMinhas(el) {
  const lista = await api('GET', '/me/authorizations');
  el.replaceChildren(
    h('h2', null, `Olá, ${sessao.usuario.nome.split(' ')[0]}`),
    h('p', { class: 'suave' }, 'Onde e quando você pode entrar'),
    lista.length
      ? lista.map((a) =>
          h(
            'div',
            { class: 'cartao' },
            h('h3', null, a.catraca.nome, ' ', seloSituacao(a.situacao)),
            h('p', null, a.dataInicio === a.dataFim ? `Somente ${dataBr(a.dataInicio)}` : `${dataBr(a.dataInicio)} a ${dataBr(a.dataFim)}`),
            h('p', null, `Das ${a.horaInicio} às ${a.horaFim}`),
            h('p', null, `${a.usosRestantes} de ${a.maxUsos} usos restantes`, a.situacao === 'ATIVA' && a.usosRestantes === 1 ? [' ', selo('Último uso disponível', 'atencao')] : null),
          ),
        )
      : h('div', { class: 'vazio' }, h('p', null, h('strong', null, 'Você ainda não tem autorizações')), h('p', null, 'Quando a portaria liberar seu acesso, ele aparece aqui.')),
  );
}

async function telaMeuHistorico(el) {
  const pagina = await api('GET', '/me/access-events', { query: { limite: 50 } });
  el.replaceChildren(
    h('h2', null, 'Meu histórico'),
    h('p', { class: 'suave' }, `${pagina.total} registros`),
    h('div', { class: 'cartao' }, tabela(['Quando', 'Catraca', 'Forma', 'Resultado', 'Motivo'], pagina.itens.map((e) => ({ celulas: [dataHora(e.createdAt), e.catraca ? e.catraca.nome : '—', e.metodo === 'NFC' ? 'Tag NFC' : 'QR Code', e.resultado === 'LIBERADO' ? selo('Liberado', 'ok') : selo('Negado', 'ruim'), motivo(e.motivo)] })))),
  );
}

async function telaPerfil(el) {
  const u = await api('GET', '/auth/me');
  const linha = (rotulo, valor) => h('tr', null, h('th', null, rotulo), h('td', null, valor));
  const tag = (u.tags || []).find((t) => t.ativa);
  el.replaceChildren(
    h('h2', null, 'Perfil'),
    h('div', { class: 'cartao' }, h('table', null, h('tbody', null, linha('Nome', u.nome), linha('Perfil', PERFIS[u.perfil]), linha('E-mail', u.email), linha('CPF', cpfMascarado(u.cpf)), linha('Tag NFC', tag ? `Vinculada · final ${tag.uid.slice(-4)}` : 'Sem tag'))), h('div', { class: 'acoes' }, h('button', { type: 'button', class: 'perigo', onclick: sair }, 'Sair da conta'))),
  );
}

/** Ler QR Code (U3 a U6): cola o token da catraca e manda com a posição. */
async function telaQr(el) {
  const config = await fetch('/simulador/config.json').then((r) => (r.ok ? r.json() : null)).catch(() => null);
  const demo = config && config.demo;

  const token = h('input', { placeholder: 'Cole aqui o QR Code lido da catraca', required: true });
  const latitude = h('input', { inputmode: 'decimal', placeholder: 'Em branco = sem localização' });
  const longitude = h('input', { inputmode: 'decimal' });
  const resultado = h('div');

  async function gerarDoTerminal() {
    if (!demo) return aviso('Sem terminal de demonstração configurado (só em NODE_ENV=development). Abra o simulador, ligue o terminal e copie o QR.', true);
    const r = await tentar(() => api('GET', '/terminal/qr-token', { headers: { 'X-Terminal-Id': demo.terminalId, 'X-Terminal-Key': demo.terminalKey } }));
    if (r) {
      token.value = r.token;
      aviso('QR do terminal de demonstração gerado. Vale por 30 s e só funciona uma vez.');
    }
  }

  async function ler(e) {
    e.preventDefault();
    const corpo = { token: token.value.trim() };
    if (latitude.value.trim() && longitude.value.trim()) {
      corpo.latitude = Number(latitude.value.trim().replace(',', '.'));
      corpo.longitude = Number(longitude.value.trim().replace(',', '.'));
    }
    const r = await tentar(() => api('POST', '/access/qr', { corpo }));
    if (!r) return;
    resultado.replaceChildren(
      h(
        'div',
        { class: `resultado ${r.liberado ? 'ok' : 'ruim'}` },
        h('h3', null, r.liberado ? '✔ Acesso liberado' : '✖ Acesso negado'),
        r.liberado ? h('p', null, 'Pode passar pela catraca.') : [h('p', null, h('strong', null, 'Motivo: '), r.titulo), r.oQueFazer ? h('p', null, h('strong', null, 'O que fazer: '), r.oQueFazer) : null],
        r.catraca ? h('p', null, `${r.catraca.nome} · ${r.catraca.caminho}`) : null,
        r.usosRestantes !== undefined && r.usosRestantes !== null ? h('p', null, `Restam ${r.usosRestantes} usos`) : null,
        r.distanciaMetros !== undefined && r.distanciaMetros !== null ? h('p', null, `Distância da catraca: ${r.distanciaMetros} m`) : null,
        h('p', { class: 'suave' }, `Código do motivo: ${r.motivo || '—'} · evento ${r.eventoId}`),
      ),
    );
  }

  el.replaceChildren(
    h('h2', null, 'Ler QR Code'),
    h('p', { class: 'suave' }, 'Faz o papel do celular: manda o QR da catraca e a posição para a API decidir (POST /access/qr). O terminal recebe a decisão pelo simulador.'),
    h(
      'form',
      { class: 'cartao', onsubmit: ler },
      campo('QR Code', token),
      h('div', { class: 'acoes' }, h('button', { type: 'button', class: 'sec', onclick: gerarDoTerminal }, 'Gerar QR do terminal de demonstração')),
      h('div', { class: 'barra' }, campo('Latitude do celular', latitude), campo('Longitude do celular', longitude)),
      h(
        'div',
        { class: 'acoes' },
        h('button', { type: 'button', class: 'sec', onclick: () => usarGps(latitude, longitude) }, 'Usar minha localização'),
        demo ? h('button', { type: 'button', class: 'sec', onclick: () => ((latitude.value = demo.catraca.latitude), (longitude.value = demo.catraca.longitude)) }, 'Estou na catraca (demo)') : null,
        demo ? h('button', { type: 'button', class: 'sec', onclick: () => ((latitude.value = (demo.catraca.latitude + 0.009).toFixed(6)), (longitude.value = demo.catraca.longitude)) }, 'Estou a 1 km (demo)') : null,
      ),
      h('button', { type: 'submit' }, 'Ler QR Code'),
    ),
    resultado,
  );
}

// -------------------------------------------------------------- entrada/saída

function mostrar(logado) {
  $('#tela-login').hidden = logado;
  $('#app').hidden = !logado;
  $('#sessao').hidden = !logado;
  if (logado) $('#sessao-nome').textContent = `${sessao.usuario.nome} · ${PERFIS[sessao.usuario.perfil]}`;
}

function sair() {
  guardarSessao(null);
  telaAtual = null;
  mostrar(false);
}

function entrarNoApp() {
  mostrar(true);
  abrir(souEquipe() ? 'painel' : 'minhas');
}

$('#form-login').addEventListener('submit', async (e) => {
  e.preventDefault();
  const erro = $('#erro-login');
  erro.hidden = true;
  const botao = e.submitter;
  botao.disabled = true;
  try {
    const r = await api('POST', '/auth/login', { corpo: { login: $('#login').value, senha: $('#senha').value } });
    guardarSessao({ token: r.token, usuario: r.usuario });
    $('#senha').value = '';
    entrarNoApp();
  } catch (falha) {
    erro.textContent = falha.message;
    erro.hidden = false;
  } finally {
    botao.disabled = false;
  }
});

for (const botao of document.querySelectorAll('.atalho')) {
  botao.addEventListener('click', () => {
    $('#login').value = botao.dataset.login;
    $('#senha').value = 'passe123';
  });
}

$('#btn-sair').addEventListener('click', sair);

if (sessao) entrarNoApp();
else mostrar(false);
