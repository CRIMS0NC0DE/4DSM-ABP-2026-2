# Relatório de modificações · dia da apresentação (25/11/2026)

O que foi verificado, corrigido, criado e melhorado no Passe no dia da apresentação, com o
checklist geral do projeto e o passo a passo para deixar tudo pronto na sala. O roteiro da fala para
os visitantes está em [`roteiro-visitantes.md`](roteiro-visitantes.md).

Tudo está **na branch `feature/celular-nfc`, ainda sem commit** (seção 11 tem os comandos).

---

## 1. Resumo

| | Antes (manhã de 25/11) | Depois |
|---|---|---|
| CI da `main` | Vermelho desde 11/11 (job do Frontend) e deploy parado | Flutter fixo em 3.47.8 no workflow: o job passa localmente com a mesma versão |
| Terminal ESP32 | Ia mostrar "Sem servidor": a chave do banco não batia com a do firmware | Chave única no banco, no broker e no firmware, e a causa corrigida |
| QR no OLED | 33×33 módulos, 1 ponto cada, uns 6 mm | 29×29 módulos, 2 pontos cada, uns 10 mm (o dobro de cada módulo) |
| App no celular | Sem jeito pronto de abrir com câmera e GPS (exigem HTTPS) | `bash scripts/app-no-celular.sh`: HTTPS em um comando, com QR do endereço |
| Opções "em construção" | Meus visitantes, Comunicados, Configurações, Entrar com NFC, Registrar | Nenhuma: as três primeiras existem, o NFC no login saiu e o cadastro virou pedido à portaria |
| Backend | 134 testes | 171 testes, mais 22 verificações num Postgres de verdade |
| App | 263 testes | 363 testes, `flutter analyze` sem nenhum aviso |
| Firmware | 5 ambientes compilam | 5 ambientes compilam, com o QR novo do OLED |

## 2. Estrutura das branches

| Branch | Situação | O que fazer |
|---|---|---|
| `main` (`e808541`) | Igual à `origin/main`. CI vermelho no último push (só o job do Frontend) | Recebe o PR desta entrega |
| `feature/celular-nfc` (atual) | 1 commit à frente da `main` (`d923171`, celular como chave), **nunca enviado**, então o CI nunca rodou nela. Por cima, todo o trabalho de hoje, sem commit | Commit, push e PR para a `main` (seção 11) |
| `kit-oled` | Já mesclada (PR #24) | Pode apagar (local e remota) |
| `davi-dev`, `dev-thiago` (remotas) | Já mescladas; 31 e 36 commits atrás da `main` | Antes de voltar a usar, atualizar a partir da `main` |
| `dev-thiago` (local) | 1 commit à frente da remota: `4edaf48` "merge", com 2.267 arquivos de build do PlatformIO (`arduino/.pio/`) e o `credenciais.h` | **Não enviar.** Voltar a local para a remota: `git branch -f dev-thiago origin/dev-thiago` (fora dela) |
| `feature/tela-admin`, `feature/terminal-esp32`, `fix/analise-estatica`, `branchMarcin` (remotas) | Todas já mescladas na `main` (0 commits à frente) | Podem ser apagadas no GitHub |
| `refs/agents/…` (12 refs locais) | Pontos de controle de uma sessão de agente de 24/11; não são branches e não sobem no push | Podem ficar; para limpar: `git for-each-ref --format='%(refname)' refs/agents \| xargs -n1 git update-ref -d` |

Arquivos fora do git que importam: `arduino/include/credenciais.h` (Wi-Fi e chave do terminal),
`.env` da raiz (novo, guarda a chave do terminal de demonstração) e `docs/gabarito-caixa-terminal.pdf`
(o gabarito da caixa, de 24/11; decida se entra no repositório).

## 3. Checklist geral

✅ pronto e verificado · ⚠️ pronto, com ressalva · ❌ não feito ou não testado

### Backend

- ✅ Lint, tipos e 171 testes passando (`npm run lint && npm run typecheck && npm test`)
- ✅ Migration `20261125000000_apresentacao` aplicada no banco de desenvolvimento e num Postgres descartável
- ✅ Teste de fumaça do CI (`scripts/smoke.mjs`) passando num Postgres descartável
- ✅ 22 escritas novas conferidas num Postgres de verdade (cadastro, convite, comunicados, configurações, locais, terminais, relatório)
- ✅ Chave do terminal: banco, broker e `credenciais.h` iguais (confirmado pela checagem)
- ⚠️ `POST /auth/register` é pública e não tem limite de tentativas. As contas nascem inativas, então não dão acesso a nada, mas alguém pode encher a lista de pedidos

### App (Flutter)

- ✅ `flutter analyze` sem nenhum aviso e 363 testes passando (9 pulados, que já eram pulados)
- ✅ Nenhuma opção de menu mostra mais "tela em construção"
- ✅ Build web feito e servido em HTTPS; app, API e leitor de QR (ZXing) respondem pelo nginx
- ⚠️ As telas novas foram testadas por testes de widget e as rotas contra a API real, mas **ninguém clicou nelas num navegador ou celular** ainda
- ❌ Build do APK Android: esta máquina não tem Android SDK nem JDK

### Terminal (ESP32)

- ✅ Os 5 ambientes compilam (`tft`, `ili9341`, `oled`, `teste`, `teste-oled`)
- ✅ QR do OLED simulado no PC com o mesmo código do firmware e lido por um decodificador nas 12 condições testadas (o antigo falhava com foco ruim em baixa resolução)
- ❌ **A placa não está com o firmware novo**: o ESP32 não estava ligado no PC. Precisa gravar (seção 6, passo 3)
- ❌ Leitura do QR do OLED pela câmera do celular: nunca foi feita, nem com o QR antigo
- ⚠️ O RC522 respondia 0x00 depois da montagem na caixa (24/11). Confira com o teste de bancada se não ler a tag

### Infra e CI

- ✅ Flutter 3.47.8 fixo em `ci-cd.yml` e `ios-ipa.yml`
- ⚠️ O CI só vai ficar verde de verdade depois do push (seção 11). O deploy no Render roda no merge da `main`, e a migration nova roda sozinha no `start:prod`

### Celular como chave (HCE)

- ⚠️ Protocolo validado por emulador em 25/11 (sessão anterior); a correção do WTX no `arduino/src/celular.cpp` entra nesta entrega
- ❌ O Kotlin nunca foi compilado, e o Redmi Note 14 do Thiago não tem NFC. Na apresentação, trate como "em teste"

## 4. Bugs graves encontrados e corrigidos

### 4.1 O terminal ia mostrar "Sem servidor" na demo

- **Sintoma:** depois do teste de "trocar a chave" de 24/11, o `credenciais.h` e o broker ficaram com a
  chave nova (`c5d5…`), mas o banco voltou para a chave padrão. O ESP32 entraria no MQTT e levaria
  **401** em toda chamada à API.
- **Causa:** o compose roda o seed a cada subida do backend, e o seed regravava a chave do terminal
  de demonstração com o valor fixo `chave-demo-terminal-catraca-1`. Rodar o seed fora do Docker
  fazia o mesmo.
- **Correção:**
  - o compose passa `TERMINAL_DEMO_KEY` ao backend, lido do `.env` da raiz (fora do git);
  - o `provisionar-terminal.mjs --trocar-chave` grava a chave nova nesse `.env`, além do
    `credenciais.h` e do `passwd` do broker;
  - o `demo.ts` também lê esse `.env` quando o seed ou a API rodam direto no Node;
  - hoje criei o `.env` com a chave que o broker e o `credenciais.h` já usavam e recriei o backend.
- **Verificado:** a checagem confirma API e broker aceitando a chave do `credenciais.h`, inclusive
  depois de rodar o seed de novo fora do Docker.
- **Por que não voltei tudo para a chave padrão:** isso exigia descartar a mudança local do
  `docker/mosquitto/passwd`, e o comando foi bloqueado pela proteção contra ações destrutivas. A
  correção acima chega ao mesmo resultado sem descartar nada.

### 4.2 CI vermelho desde 11/11

- **Causa:** o workflow usava o Flutter `stable` sem versão. O 3.50 marcou `package:flutter/material.dart`
  como obsoleto, e o `flutter analyze` passou a achar 62 avisos.
- **Correção:** `flutter-version: 3.47.8` (a mesma da máquina local) em `ci-cd.yml` e `ios-ipa.yml`.

### 4.3 QR pequeno demais no OLED (o maior risco da demo)

- **Causa:** o token tinha 78 caracteres. Com a correção M, isso pede a versão 4 do QR (33×33 módulos),
  e no OLED de 64 pontos de altura sobrava 1 ponto por módulo.
- **Correção:**
  - **Backend** (`qr-token.ts`): assinatura HMAC de 14 bytes em vez de 15. O token fica com 77
    caracteres, o máximo da versão 3 (29×29) com correção L. A assinatura continua com 112 bits,
    para um código que vale 30 segundos.
  - **Firmware** (`tela.cpp`): no OLED usa correção L e 1 módulo de margem. O QR fica com 58 pontos
    de lado (2 por módulo). O TFT continua igual (correção M, versão 4).
- **Verificado:**
  - o teste unitário garante no máximo 77 caracteres;
  - compilei o `qrcodegen` do firmware no PC, desenhei a tela 128×64 do OLED com um token real e li
    a imagem com um decodificador (jsQR) em 12 condições de resolução e foco: o novo leu em todas e
    devolveu o token exato; o antigo falhou com foco ruim em baixa resolução.

### 4.4 O leitor de QR do app web dependia da internet

O `mobile_scanner` baixa a biblioteca ZXing do `unpkg.com` na hora de abrir a câmera. Numa rede sem
internet (rede da sala, roteador do celular sem dados), a leitura falharia. A biblioteca agora vem
junto com o app (`frontend/web/vendor/zxing-library-0.23.0.min.js`, licença Apache-2.0), e o
`main.dart` aponta para ela.

### 4.5 Câmera e GPS no celular exigem HTTPS

Pelo `http://IP:porta`, o navegador do celular não libera câmera nem localização, e o nginx de teste
de 24/11 tinha sido removido. Agora isso é permanente:

- `scripts/app-no-celular.sh` faz tudo: build web, certificado para o IP do dia, nginx e QR do
  endereço no terminal;
- o nginx é o serviço `app-https` do compose, no perfil `celular`, com a configuração em
  `docker/app-https/nginx.conf`;
- a API passa pelo mesmo endereço (`/api`): o app web aceita `API_URL` relativo, então o mesmo build
  serve em qualquer rede.

### 4.6 Histórico cortava o último dia

`GET /access-events?ate=2026-11-25` lia a data como meia-noite UTC: os acessos do próprio dia 25
ficavam de fora. Agora `de` e `ate` só com a data valem do início ao fim do dia no fuso do prédio, e
data impossível (31/02) dá 400 em vez de virar 03/03.

### 4.7 Mensagens de erro em inglês

O zod respondia "Too small: expected number to be >=10". Agora as mensagens padrão saem em português
(`z.locales.pt()`), e latitude e longitude têm mensagem própria ("A latitude vai de -90 a 90").

### 4.8 Correção do celular como chave (da sessão anterior, ainda sem commit)

No `arduino/src/celular.cpp`, cada pedido de mais tempo do celular (S(WTX)) gastava uma das 16 voltas,
e o terminal desistia em uns 500 ms na primeira aproximação. Agora o limite é de 3 s por APDU. Entra
nesta entrega junto com o ajuste no `celular-nfc.md`.

## 5. O que estava em construção e agora existe

### 5.1 Meus visitantes (morador)

- **App:** lista dos convites (situação, catraca, período, usos, cancelar) e formulário (nome,
  e-mail, CPF, catraca, dias e horário). Depois de criar, mostra a **senha provisória** uma única vez,
  com botão de copiar.
- **Backend:** `GET/POST /me/visitors`, `GET /me/visitors/catracas` e `POST /me/visitors/:id/cancel`,
  só para `CONDOMINO`. Regras:
  - o morador só convida para as catracas e o período da autorização dele;
  - a visita dura até `visitanteDiasMax` dias e tem `visitanteMaxUsos` usos, as duas regras das
    Configurações;
  - um visitante que já tem cadastro (mesmo e-mail e CPF) é reaproveitado, sem senha nova;
  - a autorização guarda quem a criou (`criadaPorId`), o que vale também para as criadas pela equipe.
- **Verificado de ponta a ponta no Postgres:** o morador convida, o visitante entra com a senha
  provisória e passa pelo QR, e o morador cancela.

### 5.2 Comunicados (admin)

O admin publica e apaga avisos; todos leem. O comunicado mais recente aparece num cartão no **Início**
do morador e do visitante, que abre a lista. O seed cria o "Bem-vindo ao Passe". Rotas:
`GET/POST /announcements` e `DELETE /announcements/:id`.

### 5.3 Configurações (admin)

Nome do condomínio, contato da portaria (que aparece na **Ajuda**), se o morador pode convidar,
usos por visita e duração máxima da visita. Embaixo, só para leitura: fuso, troca e validade do QR e
raio padrão. Rotas: `GET /settings` (todos) e `PATCH /settings` (admin). A migration cria a linha com
os valores padrão; o seed põe "FATEC Jacareí" e o ramal da portaria.

### 5.4 Cadastro pelo app ("Registrar")

Virou **"Solicitar cadastro"**. `POST /auth/register` cria um morador **inativo**; a portaria libera
em Usuários ("Cadastro ativo"). Antes disso, o login avisa "Seu cadastro está desativado ou aguarda
liberação. Fale com a portaria.".

### 5.5 "Entrar com NFC" no login

Saiu. Não existe login por tag na API, e nem deveria: o UID de uma tag pode ser copiado. A tag
funciona direto na catraca, sem o app.

## 6. Passo a passo do dia da apresentação

Na ordem, na sala. Cada passo diz como saber que deu certo.

1. **Rede.** Ligue o PC na rede onde o ESP32 vai ficar: o Wi-Fi da sala ou o roteador do celular.
   - Pronto quando: `ip -4 addr` mostra um IP nessa rede.
2. **Backend.** `docker compose -f docker-compose.dev.yml up -d database mqtt backend`.
   - Pronto quando: `curl localhost:3000/health` responde `{"status":"ok",…}`.
3. **Firmware.** Ligue o ESP32 com o cabo de dados e rode `bash scripts/gravar-terminal.sh`. Se a
   rede não for a "LAB 108", passe o Wi-Fi junto:
   `WIFI_SSID="nome" WIFI_SENHA="senha" bash scripts/gravar-terminal.sh`.
   - O script troca o IP do PC no `credenciais.h`, avisa se o PC está em outra rede e grava o
     ambiente `oled`. Feche antes qualquer monitor serial (e o projeto `surpresa-jully`, que usa a
     mesma porta).
   - Pronto quando: o OLED mostra "Conectando" e depois o QR, agora maior.
4. **App no celular.** `bash scripts/app-no-celular.sh` (com `--build` só se o código do app mudar).
   - Abra o endereço `https://<IP>:8443` no celular da demo, ou leia o QR que o script desenha.
   - No aviso de segurança, toque em "Avançado" e "Continuar".
   - Entre como `morador@passe.com` (senha `passe123`) e permita câmera e localização.
5. **Checagem.** `node backend/scripts/checar-apresentacao.mjs`.
   - Pronto quando: termina em "✅ Nenhum problema". Cada aviso diz o que fazer.
   - Ela confere: API e contas; chave do terminal na API e no broker; IP e Wi-Fi do `credenciais.h`;
     terminal online; as duas tags; horário e usos da Maria; coordenada e raio da catraca; app HTTPS.
6. **Coordenada da catraca.** Se o celular disser "Você está longe da catraca", ajuste no admin
   (**Locais** → Catraca 1 → latitude e longitude da sala; raio de 300 m).
7. **Teste completo uma vez.** Ler o QR do OLED com o app, encostar a tag, bloquear e desbloquear a
   tag, abrir o histórico (o roteiro dos visitantes segue essa ordem).
8. **Plano B aberto:** `http://localhost:3000/simulador/` numa aba do notebook.

## 7. Melhorias e ajustes

| Onde | O que mudou |
|---|---|
| Locais (app e API) | O admin edita o nome de edifício, portaria e porta, e o endereço do edifício. Também apaga os quatro níveis, com confirmação. A API recusa (409) quando ainda há filhos, terminal ou autorizações, e o histórico nunca é apagado |
| Terminais (app e API) | O admin remove um terminal (`DELETE /terminals/:id`): a chave para na hora e os eventos ficam. É o que permite apagar uma catraca que tinha terminal |
| Relatórios (app e API) | `GET /reports/access` agrega no servidor, por dia (no fuso do prédio, inclusive dias zerados), por método, por catraca e por motivo. Antes o app somava só os 200 acessos mais recentes. A tela tem períodos (Hoje, 7 e 30 dias), filtro de catraca, gráfico de barras por dia e taxa de liberação |
| Ajuda | Mostra o contato da portaria das Configurações. Sem internet, mostra o texto fixo de antes |
| Nome do app | "Passe" no Android (`android:label`), no iOS (`CFBundleDisplayName`) e na web (título e manifesto). Antes era "public" |
| Checagem da apresentação | `backend/scripts/checar-apresentacao.mjs`: confere tudo o que a demo usa e diz o que fazer em cada falha. Não muda nada |
| Gravação do terminal | `scripts/gravar-terminal.sh`: IP do PC e Wi-Fi no `credenciais.h` (com as aspas escapadas) e gravação, com avisos de rede e de porta ocupada |
| Documentação | `api.md` com as rotas novas e a tabela-resumo; tamanho do QR atualizado em `qr-code-nfc.md`, `terminal-iot.md`, `firmware-esp32.md`, `hardware.md` e `montagem-terminal.html`; README com a seção "Dia da apresentação"; nota de atualização no `telas-pendentes.md` |

## 8. Arquivos

**Backend (novos):**
- módulos `src/modules/visitors/`, `announcements/`, `settings/` e `reports/`;
- a migration `prisma/migrations/20261125000000_apresentacao/`;
- o script `scripts/checar-apresentacao.mjs`;
- os testes `tests/api/apresentacao.test.ts` e `tests/api/locais-relatorios.test.ts`.

**Backend (alterados):**
- `prisma/schema.prisma` e `prisma/seed.ts`;
- `src/app.ts`, `src/container.ts` e os repositórios (Prisma e em memória);
- os módulos `auth`, `users`, `authorizations`, `locations`, `events` e `terminals` (mais o
  `qr-token.ts`);
- em `src/shared/`: `clock.ts`, `errors.ts`, `security.ts`, `http/schemas.ts` e `http/validate.ts`;
- `src/database/demo.ts` e `scripts/provisionar-terminal.mjs`;
- três testes que já existiam.

**App (novos):**
- telas: `meus_visitantes_view.dart`, `visitante_form_view.dart`, `comunicados_view.dart` e
  `configuracoes_view.dart`;
- controllers e modelos de cada uma, mais `relatorios_controller.dart` e `relatorio_acessos.dart`;
- o `web/vendor/zxing-library-0.23.0.min.js`;
- 4 arquivos de teste.

**App (alterados):**
- login, cadastro, Início, Ajuda, Locais, Relatórios e Terminais;
- os menus do admin e do morador;
- `api_client.dart`, `api_constants.dart`, `auth_service.dart` e `main.dart`;
- o nome do app no Android, no iOS e na web;
- os testes dessas telas.

**Firmware:**
- `src/tela.cpp`: o QR do OLED;
- `src/celular.cpp`: a correção do WTX.

**Infra e documentação:**
- os workflows `ci-cd.yml` e `ios-ipa.yml`;
- `docker-compose.dev.yml`, `docker/app-https/nginx.conf` e `.gitignore`;
- os scripts `scripts/app-no-celular.sh` e `scripts/gravar-terminal.sh`;
- `docs/apresentacao/` (este relatório e o roteiro dos visitantes);
- o README e os documentos da seção 7.

Ao todo, 74 arquivos alterados (+2.503 e −406 linhas, sem contar o `passwd`, que fica fora do commit) e 37 novos.

## 9. Como foi verificado

| O quê | Resultado |
|---|---|
| Backend: `npm run lint`, `npm run typecheck`, `npm test`, `npm run build` | Sem erros; 171 testes (14 arquivos) |
| App: `flutter analyze`, `flutter test` | Nenhum issue; 363 passando, 9 pulados. O arquivo de Meus visitantes rodou 4 vezes seguidas sem falha |
| Firmware: `pio run` nos 5 ambientes | Todos compilam |
| Postgres descartável (127.0.0.1:56543): migrations, seed, `smoke.mjs` do CI e 22 escritas novas | Tudo passou; o banco foi apagado no fim |
| Banco de desenvolvimento | Migration aplicada pelo backend no Docker; só leituras pelos testes de hoje (nenhum dado de teste ficou nele) |
| App pelo HTTPS (`https://192.168.1.93:8443`) | App, ZXing, simulador e as rotas novas respondendo pelo nginx |
| QR do OLED | Simulado com o `qrcodegen` do firmware e lido pelo jsQR em 12 de 12 condições |
| Checagem da apresentação | "Nenhum problema"; os 3 avisos eram da rede de casa e do ESP32 desligado |

## 10. Riscos que continuam

1. **O QR do OLED nunca foi lido por uma câmera de verdade.** A simulação indica que melhorou, mas
   teste antes de abrir a mesa. Se não ler: aproxime o celular (5 a 10 cm), segure firme até o foco
   ajustar e, em último caso, use o simulador.
2. **A placa precisa ser gravada de novo** (seção 6, passo 3): sem isso, o QR continua pequeno e o
   firmware não tem a correção do celular.
3. **O certificado HTTPS é do próprio PC.** O celular mostra um aviso uma vez. Se algum navegador não
   deixar continuar, use o Chrome no Android.
4. **A coordenada da Catraca 1** (-23,3053; -45,9658) é aproximada. Com raio de 300 m, confira na
   sala com o próprio app.
5. **Celular como chave:** sem APK compilado e sem um Android com NFC, fica como "em teste".
6. O backend no Docker gera `backend/src/generated/prisma` como root. Se o `npx prisma generate` do
   PC der EACCES:
   `docker run --rm -v $PWD/backend/src/generated:/g alpine:3 chown -R 1000:1000 /g`.

## 11. Como subir as mudanças

**Não inclua `docker/mosquitto/passwd`** no commit. A versão local tem o hash da chave trocada em
24/11, e o job "Broker MQTT" do CI testa com a chave de demonstração: ele quebraria. O `.env` e o
`credenciais.h` já estão no `.gitignore`.

```bash
git add -A -- . ':!docker/mosquitto/passwd' ':!docs/gabarito-caixa-terminal.pdf'
git commit -m "Dia da apresentação: telas em construção, chave do terminal, QR do OLED e CI" \
  -m "Meus visitantes, comunicados, configurações e cadastro pelo app; locais editáveis, relatório agregado e remover terminal; chave do terminal de demonstração no .env; QR de 77 caracteres (versão 3 no OLED); app web em HTTPS para o celular; Flutter fixo no CI." \
  -m "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
git push -u origin feature/celular-nfc
gh pr create --base main --title "Dia da apresentação: telas, terminal, QR do OLED e CI" \
  --body $'Ver docs/apresentacao/relatorio-modificacoes.md\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)'
```

Depois do CI verde, o merge na `main` publica a imagem e dispara o deploy no Render. A migration roda
sozinha no `start:prod`.
