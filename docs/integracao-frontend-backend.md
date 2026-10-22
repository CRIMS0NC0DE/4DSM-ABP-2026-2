# Integração frontend × backend — Passe

Revisão da branch `feat/frontcomback` (17/10/2026): o que já está ligado à API, o que dá para fazer tela a tela com o backend atual e o que ainda falta.

Referências: telas do `docs/Design.pdf` (U = usuário, N = negação, E = estados, A = administrador, T = terminal) e a arquitetura do `docs/Fluxo.pdf` (App Flutter → API REST/JWT → Postgres; terminal IoT por HTTPS/MQTT).

**Legenda**

| Símbolo | Significado |
|---|---|
| ✅ | Integrado: a tela existe e já fala com a API |
| 🟢 | Pronto para fazer: o backend já tem tudo, falta só a tela no app |
| 🟡 | Parcial: o backend cobre parte; falta algo no backend ou uma decisão |
| 🔴 | Falta backend: não existe rota; precisa criar antes da tela |
| ⚪ | Só no app: não depende da API |

---

## 1. Resumo

| | Situação |
|---|---|
| Backend | 7 módulos prontos (auth, users, locations, authorizations, access, events, terminals). 69 testes passando e o teste de fumaça com Postgres passa 16/16. |
| Frontend antes desta branch | Login, cadastro e os 3 menus funcionavam só com contas em memória (`AuthService` falso). Nenhuma chamada HTTP. |
| Frontend agora | Login, sessão (token JWT guardado), restaurar sessão ao abrir o app e sair da conta ligados à API. Camada `ApiClient` pronta para as próximas telas. 70 testes com API falsa e 8 testes contra a API real passando. |
| Telas do design | 2 de 35 integradas (U1 Login e E5 Senha errada; o E2 "sem internet" já funciona no login). As outras estão nas seções 4 e 5. |

---

## 2. Como rodar app + API

```bash
# 1a. Banco + API, tudo no Docker (na raiz do repositório)
docker compose -f docker-compose.dev.yml up --build database backend
#    Se você subiu antes de 17/10/2026 e o seed falhou com "spawn tsx ENOENT",
#    apague o cache de dependências uma vez (o banco não é afetado):
#    docker compose -f docker-compose.dev.yml rm -f backend && docker volume rm 4dsm-abp_backend_node_modules

# 1b. Ou só o banco no Docker e a API rodando direto no Node:
docker compose -f docker-compose.dev.yml up -d database   # Postgres em localhost:5432 (app/app)
cd backend && cp .env.example .env                        # o DATABASE_URL do exemplo já aponta para ele
npm ci && npx prisma migrate deploy && npm run db:seed && npm run dev
#    Sem o banco no ar, o migrate falha com "P1001: Can't reach database server at localhost:5432".

# 2. App
cd frontend
flutter run -d chrome   --dart-define=API_URL=http://localhost:3000
flutter run -d emulator --dart-define=API_URL=http://10.0.2.2:3000      # emulador Android
flutter run -d <celular> --dart-define=API_URL=http://<IP-do-PC>:3000  # celular na mesma rede
```

Sem `--dart-define`, o app usa `http://localhost:3000` (`lib/core/constants/api_constants.dart`).

**Contas do seed** (todas com a senha `passe123`):

| E-mail | CPF | Perfil na API | Menu no app |
|---|---|---|---|
| admin@passe.com | 111.111.111-11 | `ADMIN` | Administrador |
| portaria@passe.com | 222.222.222-22 | `CONTROLADOR_ACESSO` | Controlador de acesso |
| morador@passe.com | 333.333.333-33 | `CONDOMINO` | Morador |
| visitante@passe.com | 444.444.444-44 | `VISITANTE` | Visitante |

Terminal de demonstração: `X-Terminal-Id=00000000-0000-4000-8000-000000000005`, `X-Terminal-Key=chave-demo-terminal-catraca-1`.

**Testes**

```bash
cd frontend
flutter test                                                              # API falsa (o que o CI roda)
flutter test test/integracao --dart-define=API_REAL=http://localhost:3000 # contra a API de verdade
```

---

## 3. O que foi integrado nesta branch

### 3.1 Camada de integração (nova)

| Arquivo | O que faz |
|---|---|
| `lib/services/api_client.dart` | Faz as chamadas HTTP (`get`, `post`, `patch`, `delete`). Manda `Authorization: Bearer <token>` quando há sessão. Converte a resposta de erro da API (`{"erro": {"codigo", "mensagem", "detalhes"}}`) em `ApiException`, com `mensagem` pronta para a tela, `status`, `codigo` e `campos` (erros por campo dos 400). Rede fora do ar ou timeout de 10 s viram `ApiException.semConexao()`. |
| `lib/services/sessao_service.dart` | Guarda o token e o usuário no `flutter_secure_storage`. `restaurar()` lê o `exp` do JWT sem chamar a API: se o token venceu (8 h), apaga e pede login. `encerrar()` apaga tudo, porque a API não tem logout. |
| `lib/services/auth_service.dart` | Antes era uma lista de contas em memória. Agora `entrar()` chama `POST /auth/login` e abre a sessão; `sair()` encerra a sessão; `registrar()` avisa que o cadastro pelo app ainda não existe na API (ver P1.1). |
| `lib/core/routes/rotas.dart` | `menuDoPerfil(perfil)`: um só lugar decide o menu de cada perfil. Usado pelo login e pela abertura do app. |
| `lib/models/usuario.dart` | `Usuario` ganhou `id` (UUID da API), `fromJson` e `toJson`. `Perfil` ganhou `visitante` e o nome usado pela API (`Perfil.daApi('CONDOMINO')` → `Perfil.morador`). |

### 3.2 Telas e controllers ligados

| Tela / componente | Antes | Agora |
|---|---|---|
| **Login (U1, E5)** `login_view.dart` + `login_controller.dart` | Conferia contas em memória | `POST /auth/login` com e-mail ou CPF. Mostra a mensagem da API ("E-mail, CPF ou senha não conferem.", "Seu cadastro está desativado…") ou o aviso de falta de conexão (E2). O botão trava e mostra "Entrando…" enquanto espera, para não mandar duas vezes. |
| **Abrir o app já logado** `main.dart` | Sempre abria no login | Se há sessão guardada e o token ainda vale, abre direto no menu do perfil. |
| **Sair da conta** (3 menus) | Só voltava ao login | Apaga o token guardado e depois volta ao login. |
| **Cadastro** `register_view.dart` + `register_controller.dart` | Criava conta em memória | A tela continua igual, mas ao enviar mostra "O cadastro pelo app ainda não está disponível. Peça seu cadastro na portaria." A API não tem rota pública de cadastro (P1.1). |
| **Menu do visitante** `visitor_menu_view.dart` + `visitor_menu_controller.dart` | Não existia no app | O login de `VISITANTE` abre o menu próprio: o do morador sem "Meus visitantes", com selo "Visitante". Sair apaga a sessão. As opções usam só rotas `/me` e `/auth/me`, liberadas para o visitante. |

### 3.3 Configuração de plataforma

| Arquivo | Mudança | Por quê |
|---|---|---|
| `android/app/src/main/AndroidManifest.xml` | `INTERNET` | Sem ela, o APK de release não consegue chamar a API. Antes só o manifesto de debug tinha. |
| `android/app/src/debug/AndroidManifest.xml` | `usesCleartextTraffic="true"` | O Android 9+ bloqueia `http://`. Isso libera a API local (ex.: `http://10.0.2.2:3000`) **só no debug**; a release continua exigindo HTTPS. |
| `backend/Dockerfile` + `docker-compose.dev.yml` | Novo estágio `dev` (com devDependencies), usado pelo compose no lugar de `build` | O estágio `build` termina com `npm prune --omit=dev`, que apagava o `tsx`. Com isso o seed falhava (`spawn tsx ENOENT`) e o `npm run dev` não subia no container. A imagem de produção (`runtime`) não mudou. |

### 3.4 Testes

| Arquivo | Cobre |
|---|---|
| `test/support/api_falsa.dart` | API falsa com o mesmo contrato do backend (contas do seed, formato de erro) usando `http/testing.dart` |
| `test/services/api_client_test.dart` | Token no cabeçalho, filtros na URL, erro 400 com campos, 204 sem corpo, erro fora do formato, timeout |
| `test/services/sessao_service_test.dart` | Restaurar sessão, token vencido, token inválido, encerrar |
| `test/services/auth_service_test.dart` | Login por e-mail e CPF, os 4 perfis, senha errada, sem internet, sair, cadastro indisponível |
| `test/views/user/login_view_test.dart` | Cada conta abre o menu certo, mensagem da API, sem internet, botão travado durante o envio, sair apaga a sessão |
| `test/widget_test.dart` | App abre no login; com sessão abre no menu; visitante abre o menu do visitante |
| `test/views/visitor/visitor_menu_view_test.dart` | Opções do visitante (sem gestão e sem "Meus visitantes"; o morador tem todas as dele), cabe com fonte 2×, sair apaga a sessão aberta pela API |
| `test/integracao/api_real_test.dart` | **Contra a API real:** login dos 4 perfis, CPF com pontuação, 401, token liberando `/dashboard`, 403 do morador em `/users`, `/me/authorizations`, erro 400 com campos, restaurar sessão com JWT real |

---

## 4. Revisão tela a tela

As colunas "Rotas" e "Validações" vêm do código do backend (`backend/src/modules/*`). Todas as rotas, menos `POST /auth/login` e `/health`, exigem `Authorization: Bearer <token>`.

### 4.1 Usuário (morador e visitante)

| Tela | Status | Rotas | O que a tela precisa fazer / validar |
|---|---|---|---|
| **U1 Login** | ✅ | `POST /auth/login` `{login, senha}` → `{token, usuario}` | Feito. `login` aceita e-mail ou CPF com ou sem pontuação. |
| **U2 Início** ("Olá, Maria", próxima autorização) | 🟢 | `GET /me/authorizations` | Nome vem de `AuthService.instancia.usuario`. "Sua próxima autorização" = primeiro item com `situacao == 'ATIVA'`. Mostrar `dataFim`, `horaInicio`–`horaFim` e `usosRestantes` de `maxUsos`. |
| **U3 Scanner de QR** | 🟢 (falta config) | nenhuma; só lê o QR | `mobile_scanner` já está no pubspec. O conteúdo do QR **é** o token que o terminal mostra (texto curto assinado, `P1.…`, ~78 caracteres; ver `docs/terminal-iot.md`); vale cerca de 30 s e troca a cada 10 s. Mandar o texto lido sem alterar. Falta permissão de câmera (P2.1). |
| **U4 Validando** | 🟢 | `POST /access/qr` `{token, latitude, longitude}` | Pegar a posição com `geolocator` (já no pubspec) **antes** de enviar. Sem posição, a API nega com `LOCALIZACAO_AUSENTE`. A resposta é sempre **200**, mesmo negado: decidir pela flag `liberado`. |
| **U5 Acesso liberado** | 🟢 | resposta do `POST /access/qr` | `liberado: true`, `catraca.nome`, `catraca.caminho` ("Edifício › Portaria › Porta"), `usosRestantes`, `em`. |
| **U6 Acesso negado** | 🟢 | resposta do `POST /access/qr` | `liberado: false`; a API já manda `titulo` e `oQueFazer` com o texto do design. Usar `motivo` só para escolher ícone/cor. |
| **U7 Minhas autorizações** | 🟡 | `GET /me/authorizations` | Agrupar "Ativas" × "Encerradas" pela `situacao` (`ATIVA`, `AGENDADA`, `ESGOTADA`, `EXPIRADA`, `CANCELADA`). **Falta no backend:** a resposta só traz `catraca: {id, nome}`, sem "Torre Norte · Edifício Atlântico" (P3.3). |
| **U8 Detalhe da autorização** | 🟡 | item da lista acima | Não existe `GET /me/authorizations/:id`; usar o item da lista. Mesmo problema do caminho do local. |
| **U9 Perfil / Sair** | 🟢 / ✅ | `GET /auth/me` | Nome, e-mail, CPF mascarado e `tags[]` (mostrar "final 4F2A" com os 4 últimos do `uid`). Sair já está integrado nos menus. |
| Histórico de acessos (menu) | 🟢 | `GET /me/access-events?de&ate&resultado&metodo&limite&pular` | Resposta `{itens, total, liberados, negados}`. Cada item tem `motivo` só como **código**: o app precisa da tabela código → texto (P2.4). |
| Acessos negados (menu) | 🟢 | `GET /me/access-events?resultado=NEGADO` | Igual ao histórico, filtrado. |
| Minha tag NFC (menu) | 🟡 | `GET /auth/me` → `tags[]` | **Ver** dá. **Bloquear** não: `PATCH /users/:id/tags/:tagId` é só da equipe (P3.4). |
| Meus visitantes (menu) | 🔴 | nenhuma | Morador não pode criar usuário nem autorização: as duas rotas são só da equipe (P3.5). |
| Ajuda (menu) | ⚪ | nenhuma | Texto fixo com o contato da portaria. |

### 4.2 Motivos de negação (N1–N4) e o código que a API devolve

A tela de "Acesso negado" é a mesma; muda o texto, que já vem pronto em `titulo` e `oQueFazer`.

| Tela | `motivo` da API | Quando |
|---|---|---|
| U6 | `FORA_DO_HORARIO` | Fora da janela `horaInicio`–`horaFim` (aceita virar a meia-noite, ex. 22:00–06:00) |
| N1 | `AUTORIZACAO_EXPIRADA` | Hoje depois de `dataFim` |
| N2 | `SEM_USOS` | `usosRealizados >= maxUsos` |
| N3 | `LONGE_DO_TERMINAL` | Mais longe que `raioMetros` da catraca (padrão 100 m); a resposta traz `distanciaMetros` |
| N4 | `AUTORIZACAO_CANCELADA` | A equipe cancelou |
| — | `AUTORIZACAO_NAO_INICIADA` | Antes de `dataInicio` (sem tela no design) |
| — | `SEM_AUTORIZACAO` | Nenhuma autorização para aquela catraca |
| E8 | `LOCALIZACAO_AUSENTE` | O app não mandou latitude/longitude |
| — | `QR_INVALIDO`, `QR_EXPIRADO`, `QR_JA_UTILIZADO` | QR errado, velho (> 30 s) ou já usado: "Tentar novamente" deve reabrir o scanner |
| — | `USUARIO_INATIVO`, `TERMINAL_DESCONHECIDO` | Cadastro desativado ou catraca sem terminal |
| — | `TAG_DESCONHECIDA`, `TAG_BLOQUEADA` | Só no NFC, aparecem no histórico e no terminal |

### 4.3 Estados obrigatórios (E1–E8)

| Tela | Status | Como fazer |
|---|---|---|
| E1 Carregando | ⚪ | Mostrar enquanto o `Future` da chamada não volta (o login já faz isso no botão). |
| E2 Sem internet | ✅ no login / 🟢 nas outras | `on ApiException catch (e) when (e.semConexao)`. A mensagem já vem pronta. |
| E3 Scanner sem internet | 🟢 | Mesma checagem; o design sugere usar a tag NFC no terminal. |
| E4 Autorizações vazias | 🟢 | `GET /me/authorizations` devolve `[]`. |
| E5 Senha errada | ✅ | Feito: mostra a mensagem do 401. |
| E7 Câmera negada | ⚪ | Permissão do `mobile_scanner` (P2.1). |
| E8 Localização negada | ⚪ | Permissão do `geolocator` (P2.1). |

### 4.4 Administrador e controlador de acesso

"Equipe" = `ADMIN` e `CONTROLADOR_ACESSO`. Morador e visitante levam **403** nessas rotas.

| Tela / opção do menu | Status | Rotas | O que a tela precisa fazer / validar |
|---|---|---|---|
| **A1 Painel** | 🟢 | `GET /dashboard` | `{acessosHoje, negadosHoje, negadosRecentes[5], autorizacoesAtivas}`. Nome do prédio: `GET /locations`. |
| A2 Menu aberto | ⚪ | — | Já existe (menus em grade). |
| **A3 Usuários** (lista e busca) | 🟢 | `GET /users?busca=&perfil=` | `busca` procura em nome, e-mail e CPF. Cada usuário vem com `tags[]`. Não tem paginação; o total é o tamanho da lista. |
| **A4 Usuário · formulário** | 🟢 | `POST /users` · `PATCH /users/:id` | Regras da API: `nome` ≥ 3 caracteres, `email` válido, `cpf` com 11 números (aceita pontuação), `senha` ≥ 6, `perfil` entre os 4. No `PATCH`, todos opcionais e mais `ativo` (true/false). E-mail ou CPF repetido dá **409**. O **controlador só cria e edita `CONDOMINO` e `VISITANTE`** (403 para os outros): esconder Admin/Controlador no seletor quando quem está logado é controlador. "Esqueci minha senha" se resolve aqui com `PATCH {senha}`. |
| **Tags NFC** (menu) | 🟢 | `POST /users/:id/tags {uid}` · `PATCH /users/:id/tags/:tagId {ativa}` · `DELETE /users/:id/tags/:tagId` | `uid` em hexadecimal, 4 a 40 caracteres, aceita `:`, `-` e espaço (a API normaliza para `04A1B2C3`). Tag já vinculada a outra pessoa dá 409. Não há lista só de tags: usar `GET /users` (vem `tags[]`). A `busca` **não** procura por UID. `nfc_manager` já está no pubspec para ler o UID pelo celular. |
| **Visitantes** (menu) | 🟢 | `POST /users` (perfil `VISITANTE`) + `POST /authorizations` | Fluxo em 2 passos. Não tem rota única de "visitante". |
| **A5/A6 Locais** (Edifício › Portaria › Porta › Catraca) | 🟡 | `GET /locations` (árvore) · `POST /locations/buildings` `{nome, endereco}` · `POST /locations/gates` `{nome, buildingId}` · `POST /locations/doors` `{nome, gateId}` · `POST /locations/access-points` | Criar é **só admin**. **Falta no backend:** editar ou apagar edifício, portaria e porta (P3.6). |
| **A7 Editar catraca** (localização) | 🟢 (sem mapa) | `GET /locations/access-points/:id` · `PATCH /locations/access-points/:id` | `latitude` −90..90, `longitude` −180..180, `raioMetros` 10..1000 (padrão 100). O `GET` já traz `edificio`, `portaria` e `porta`. "Toque no mapa" pede um pacote de mapa, que não está no pubspec (P2.3); dá para começar com campos de texto. |
| **A8 Autorizações** (lista e filtros) | 🟢 | `GET /authorizations?userId&accessPointId&situacao&de&ate` | `situacao` aceita só `ATIVA`, `EXPIRADA` e `CANCELADA` (o design pede essas mais "Todas", que é não mandar). Cada item vem com `user {id, nome, perfil}`, `catraca {id, nome}`, `situacao` e `usosRestantes`. Atenção ao filtro `ATIVA` (P3.7). |
| **A9 Autorização · formulário** | 🟢 | `POST /authorizations` · `PATCH /authorizations/:id` | Corpo: `userId`, `accessPointId`, `dataInicio`/`dataFim` em `AAAA-MM-DD`, `horaInicio`/`horaFim` em `HH:MM`, `maxUsos` 1..10000. Regras: `dataFim ≥ dataInicio`; `horaInicio ≠ horaFim`; na edição não dá para trocar `userId`, `maxUsos` não pode ficar abaixo de `usosRealizados` e autorização cancelada não se edita (409). Seletores: pessoas de `GET /users`, catracas de `GET /locations`. |
| **A10 Cancelar autorização** | 🟢 | `POST /authorizations/:id/cancel` | Cancelar de novo não dá erro. Depois de cancelada, só criando outra. |
| **A11/A12 Histórico de acessos** | 🟢 | `GET /access-events?de&ate&resultado&metodo&userId&accessPointId&limite&pular` | `de`/`ate` aceitam data ou data e hora ISO. `limite` 1..200 (padrão 50). Resposta `{itens, total, liberados, negados}`: "260 registros · 248 liberados, 12 negados" sai direto daí. Precisa da tabela código → texto do `motivo` (P2.4). |
| **Acessos negados** (menu) | 🟢 | `GET /access-events?resultado=NEGADO` | Igual ao histórico, filtrado. |
| **Terminais** (menu) | 🟢 | `GET /terminals` · `POST /terminals {nome, accessPointId}` · `POST /terminals/:id/rotate-key` | A lista traz `online` (sinal nos últimos 90 s) e `ultimoSinal`. Cadastrar e trocar chave são **só admin**, e a `chave` aparece **uma única vez** na resposta: a tela precisa mostrar e pedir para copiar. Uma catraca só tem um terminal (409). |
| Relatórios (admin) | 🟡 | `GET /access-events` com `de`/`ate`/`accessPointId` | Dá para montar com os totais do histórico. Não há rota de relatório agregado (por dia, por local). |
| Comunicados (admin) | 🔴 | nenhuma | Não existe no backend nem no banco (P3.8). |
| Configurações (admin) | 🔴 | nenhuma | Não há tabela de configurações. Horário e usos são por autorização; raio é por catraca (P3.8). |

### 4.5 Terminal de acesso (T1–T3)

A pasta `lib/views/terminal/` existe vazia. O terminal se autentica com os cabeçalhos `X-Terminal-Id` e `X-Terminal-Key`, não com JWT.

| Tela | Status | Rotas | Observação |
|---|---|---|---|
| **T1 Aguardando leitura** (QR que troca a cada 10 s) | 🟡 | `GET /terminal/qr-token` → `{token, expiraEm, trocarEmSegundos}` · `POST /terminal/heartbeat {latitude?, longitude?}` | Para desenhar o QR falta um pacote (ex.: `qr_flutter`) (P2.2). Mandar heartbeat a cada < 90 s, senão aparece fora do ar em "Terminais". Falta uma tela de configuração para guardar o Id e a chave do terminal no aparelho. |
| **T2/T3 Liberado/Negado · 3 s** | 🟢 | `GET /terminal/decisions?apos=<seq>` (QR) · `POST /terminal/nfc {uid}` (NFC) | QR: consultar as decisões periodicamente guardando o último `seq` recebido. NFC: a resposta do POST já é a decisão. `acao: ABRIR/NEGAR`, `mensagem` e `nome` (primeiro nome). |

---

## 5. Pendências para fazer manualmente

Ordem sugerida: P1 libera o fluxo principal, P2 é configuração do app, P3 depende de mudança no backend.

### P1 — Decisões e ajustes nas telas que já existem

1. **Cadastro pelo app (RegisterView).** A API não tem cadastro público; quem cria conta é a equipe (`POST /users`). O design (U1) diz "Primeiro acesso? Peça seu cadastro na portaria." Escolher um caminho:
   - **(a)** Criar `POST /auth/register` no backend, público, sempre com perfil `CONDOMINO` (de preferência `ativo: false` até a portaria aprovar), e trocar a chamada em `AuthService.registrar`; **ou**
   - **(b)** Seguir o design: tirar o botão "Registrar" do login, apagar `register_view.dart` e `register_controller.dart` e mostrar o texto do U1.

   Hoje a tela abre e, ao enviar, avisa para pedir o cadastro na portaria.
2. **Regras do cadastro diferentes do backend.** App: senha ≥ 8 e nome só não vazio. API: senha ≥ 6 e nome ≥ 3. Se ficar com a opção (a), alinhar (a API aceita senha de 6, então o app ser mais rígido não quebra nada, mas o nome de 1–2 letras vai dar 400).
3. **"Entrar com NFC" no login.** A API só valida tag no terminal da catraca (`POST /terminal/nfc`); não existe login por NFC. Tirar o botão ou trocar a função (ex.: ler o UID da própria tag com `nfc_manager` para a portaria vincular).
4. ~~**Menu do visitante.**~~ Feito: `VisitorMenuView`, ligado em `lib/core/routes/rotas.dart`. As opções ainda mostram "tela em construção" (item 5).
5. **Ligar cada opção dos menus a uma tela.** Hoje todas mostram "tela em construção". O `abrir(opcao)` de cada controller é o ponto de navegação; a seção 4 diz qual rota cada tela usa.
6. **Sessão vencida nas próximas telas.** O login já trata o 401. Nas telas novas, quando uma chamada der `e.naoAutenticado`, chamar `AuthService.instancia.sair()` e voltar ao `LoginView` (mesmo código do `_sair` dos menus). Se ficar repetitivo, centralizar num callback do `ApiClient`.
7. **Código legado.** `lib/views/user/menu_view.dart` e `lib/controllers/menu_controller.dart` ("1. Entrar, 2. Registrar, 3. Criar conta, 4. Fechar") não são usados por nenhuma tela. Apagar (e o `test/views/user/menu_view_test.dart`) ou reaproveitar.

### P2 — Configuração do app para as próximas telas

1. **Permissões** que faltam para U3/U4, E7/E8 e Tags NFC:
   - `android/app/src/main/AndroidManifest.xml`: `CAMERA`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `NFC`.
   - `ios/Runner/Info.plist`: `NSCameraUsageDescription`, `NSLocationWhenInUseUsageDescription`, `NFCReaderUsageDescription` (e a capability de NFC no Xcode).
2. **Desenhar o QR no terminal (T1):** adicionar um pacote como `qr_flutter`.
3. **Mapa na A7 (opcional):** `flutter_map` ou `google_maps_flutter`. Sem isso, latitude e longitude em campos de texto já funcionam.
4. **Textos dos motivos no histórico:** o `POST /access/qr` já devolve `titulo`/`oQueFazer`, mas os eventos (`/access-events`, `/me/access-events`) só têm o código em `motivo`. Copiar a tabela `MOTIVOS` de `backend/src/modules/access/access.rules.ts` para uma constante no app (ex.: `lib/core/constants/motivos.dart`), ou pedir ao backend para devolver o texto junto (P3.2).
5. **iOS por HTTP:** o iOS bloqueia `http://` (ATS). Para testar no simulador com a API local, liberar no `Info.plist` só em debug, ou usar HTTPS. Não testado aqui (sem Mac).
6. **Linux desktop:** o `flutter_secure_storage` no Linux precisa de `libsecret-1-dev` instalado e de um chaveiro ativo. Para desenvolver, usar Chrome ou Android.
7. **Modelos das próximas telas:** criar `Autorizacao`, `EventoAcesso`, `Local`/`Catraca`, `Terminal` e `DecisaoAcesso` com `fromJson` no mesmo padrão de `Usuario`. As respostas reais estão na seção 4 e no teste de fumaça `backend/scripts/smoke.mjs`.

### P3 — Precisa de mudança no backend

1. **Cadastro público** (ver P1.1, opção a).
2. **Texto do motivo nos eventos**: incluir `titulo`/`oQueFazer` em cada item de `/access-events` e `/me/access-events` (evita duplicar a tabela no app).
3. **Caminho do local na autorização**: hoje vem `catraca: {id, nome}`. U7/U8 mostram "Torre Norte · Edifício Atlântico" e "Portaria Principal › Porta A", e o morador não pode chamar `/locations/access-points/:id` (só equipe). Incluir `edificio`, `portaria` e `porta` no `include` das autorizações (`comRefs` em `repositories.prisma.ts`).
4. **Morador bloquear a própria tag** ("Minha tag NFC"): criar algo como `PATCH /me/tags/:tagId {ativa: false}`.
5. **Morador cadastrar visitante** ("Meus visitantes"): não existe. Definir a regra (ex.: o morador cria um visitante com autorização só para as catracas que ele mesmo pode usar) e criar as rotas em `/me`.
6. **Editar e apagar locais**: só existe `PATCH` para catraca. Faltam `PATCH`/`DELETE` para edifício, portaria e porta, e `DELETE` para catraca e terminal.
7. **Filtro `situacao=ATIVA`**: em `GET /authorizations` ele traz tudo que não foi cancelado e ainda não passou do `dataFim`, então inclui as `AGENDADA` e `ESGOTADA`, embora cada item diga a própria `situacao`. O número `autorizacoesAtivas` do `/dashboard` vem desse filtro e também conta essas. Decidir se é isso mesmo ou se o filtro deve bater com o campo `situacao`.
8. **Comunicados e Configurações**: não existem no banco nem na API. Se forem entrar, precisam de modelo Prisma, migration e rotas. Senão, tirar dos menus.
9. **Esqueci minha senha**: não há rota de recuperação. Hoje o app manda falar com a portaria, que troca a senha pela A4 (`PATCH /users/:id {senha}`). Recuperação por e-mail precisaria de envio de e-mail no backend.
10. **Usuário desativado continua com o token**: o middleware `autenticar` só confere o JWT; não olha se o usuário ainda está `ativo`. Quem for desativado continua usando as rotas da equipe até o token vencer (8 h). A validação de acesso na catraca já bloqueia (`USUARIO_INATIVO`). Para corrigir, conferir `ativo` no middleware ou reduzir a validade do token.
11. **MQTT**: o `Fluxo.pdf` mostra um broker MQTT para o terminal. Hoje só existe a consulta por HTTP (`GET /terminal/decisions`); o `CompositeTerminalNotifier` já está pronto para receber um notificador MQTT.
12. **Paginação de usuários**: `GET /users` devolve todos. Com muitos cadastros, a A3 vai precisar de `limite`/`pular` como no histórico.

### Observação solta

- O comentário do `backend/prisma/seed.ts` cita `frontend/Contas.MD`, que não existe. As contas agora estão documentadas na seção 2 e em `lib/services/auth_service.dart`.

---

## 6. Como usar a camada de integração numa tela nova

```dart
import '../../services/api_client.dart';
import '../../services/auth_service.dart';

final api = ApiClient.instancia;

Future<void> carregar() async {
  try {
    final lista = await api.get('/me/authorizations') as List<dynamic>;
    // lista.map((json) => Autorizacao.fromJson(json))...
  } on ApiException catch (e) {
    if (e.naoAutenticado) {
      await AuthService.instancia.sair();
      // voltar ao LoginView com pushAndRemoveUntil, como no _sair dos menus
    } else if (e.semConexao) {
      // estado E2 "Sem conexão com a internet"
    } else {
      // e.mensagem já vem em português, pronta para a tela.
      // Nos 400, e.campos['horaInicio'] traz o erro de cada campo do formulário.
    }
  }
}
```

- Filtros vão em `query`: `api.get('/access-events', query: {'resultado': 'NEGADO', 'limite': '20'})`.
- Datas para a API: `AAAA-MM-DD`; horários: `HH:MM` (fuso do prédio, `America/Sao_Paulo`).
- Para testar a tela sem backend, use `test/support/api_falsa.dart` como modelo: `ApiClient(cliente: MockClient(...))`.
