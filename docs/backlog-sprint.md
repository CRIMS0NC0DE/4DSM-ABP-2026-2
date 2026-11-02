# Backlog da sprint — Passe

Levantamento de 26/10/2026, feito na `main` depois do PR #17 (validação de QR no app): o que falta
no backend e no app, dividido em frentes para distribuir no grupo.

Referências: telas do `docs/Design.pdf`, pendências P1–P3 do `docs/integracao-frontend-backend.md`
e o guia da issue do QR em `docs/apresentacao-validacao-qr.md`.

**Como está hoje**

| | Situação |
|---|---|
| Backend | Rotas iguais às do doc de integração (17/10). 82 testes passando. |
| App | 110 testes passando. Todas as opções dos menus, menos "Escanear QR Code", mostram "tela em construção". |
| Telas do design | 12 de 35 prontas: U1, U3, U4, U5, U6, N1–N4, E5, E7 e E8. O E2 (sem internet) só existe no login. |

**Tamanho** (estimativa): P = pequeno, M = médio, G = grande.

---

## 0. Fechar a issue do QR

| Tarefa | Situação |
|---|---|
| Teste manual no celular (critério de aceite 1) | Falta |
| Atualizar `docs/integracao-frontend-backend.md` | Desatualizado: ainda diz "2 de 35 telas", "70 testes", U3–U6 como 🟢, permissões (P2.1) e `DecisaoAcesso` (P2.7) como pendentes, e MQTT (P3.11) como pendente, mas ele já está ligado em `backend/src/server.ts`. A numeração das telas A6–A8 também não bate com o design. |

---

## 1. Backend

| # | Tarefa | O que desbloqueia | Tamanho |
|---|---|---|---|
| B1 | **Caminho do local na autorização** (P3.3). Hoje a resposta só traz `catraca: {id, nome}`; falta incluir edifício, portaria e porta em `comRefs` (`src/database/repositories.prisma.ts`) | U7 e U8 completas | P |
| B2 | **Texto do motivo nos eventos** (P3.2): `titulo` e `oQueFazer` em `/access-events` e `/me/access-events` | Telas de histórico, sem copiar a tabela de motivos para o app | P |
| B3 | **Usuário desativado continua com o token** (P3.10). O `autenticar` em `src/shared/http/auth.ts` não confere `ativo` | Segurança | P |
| B4 | **Filtro `situacao=ATIVA`** (P3.7) também conta autorizações AGENDADA e ESGOTADA, inclusive no número do `/dashboard` | A1 e A7 com números corretos | P (precisa da decisão D6) |
| B5 | **Editar e apagar locais** (P3.6): `PATCH`/`DELETE` de edifício, portaria e porta; `DELETE` de catraca e terminal | Editar na A5/A6 | M |
| B6 | **Morador bloquear a própria tag** (P3.4): `PATCH /me/tags/:tagId` | "Minha tag NFC" completa | P |
| B7 | **Paginação de `GET /users`** (P3.12) | A3 com muitos usuários | P |
| B8 | **"Meus visitantes" do morador** (P3.5): rotas em `/me` | Opção do menu do morador | G (precisa da decisão D4) |
| B9 | **Cadastro público** (P3.1) | Só se a decisão D1 for criar a rota | M |
| B10 | **Comunicados e Configurações** (P3.8): modelo, migration e rotas | Só se a decisão D3 for manter no menu | G |
| B11 | O comentário de `prisma/seed.ts` cita `frontend/Contas.MD`, que não existe | — | P |

---

## 2. App: telas que já têm backend

### Frente Usuário (morador e visitante, rotas `/me` e `/auth/me`)

| Tela | Rota | Depende de |
|---|---|---|
| U2 Início + E1 carregando + E2 sem internet | `GET /me/authorizations` | Decisão D2 |
| U7 Minhas autorizações + E3 carregando + E4 vazio | `GET /me/authorizations` | B1 para o caminho do local |
| U8 Detalhe da autorização | Item da lista | B1 |
| U9 Perfil | `GET /auth/me` | — |
| Histórico de acessos / Acessos negados | `GET /me/access-events` | B2, ou a F3 |
| Minha tag NFC | `GET /auth/me` → `tags[]` | Ver: nada. Bloquear: B6 |
| Ajuda | Nenhuma (texto fixo) | — |

### Frente Admin 1 (cadastros)

| Tela | Rota |
|---|---|
| A3 Usuários + A4 formulário | `/users` (o controlador só cria morador e visitante) |
| Tags NFC | `/users/:id/tags` |
| A5 Locais + A6 Local · localização | `/locations`, `PATCH /locations/access-points/:id` (editar o resto depende de B5) |
| Terminais | `/terminals` (a chave aparece uma vez só) |

### Frente Admin 2 (acompanhamento)

| Tela | Rota |
|---|---|
| A1 Painel | `GET /dashboard` |
| A7 Autorizações + A8 Filtros + A9 formulário + A10 cancelar | `/authorizations` |
| A11 Histórico + A12 sem resultados + Acessos negados | `/access-events` |
| Visitantes (equipe) | `POST /users` + `POST /authorizations` |
| Relatórios | `/access-events` (não existe rota de relatório agregado) |

### Frente Terminal (T1–T3)

A pasta `lib/views/terminal/` está vazia e falta o pacote `qr_flutter`. Depende da decisão D5.

As regras de cada rota (campos, limites, erros) estão na seção 4 do
`docs/integracao-frontend-backend.md`.

---

## 3. App: base e limpeza

**A base (F1–F3) vem antes das telas**, para as frentes não criarem o mesmo modelo cada uma do seu
jeito.

| # | Tarefa |
|---|---|
| F1 | Modelos `Autorizacao`, `EventoAcesso`, `Local`/`Catraca` e `Terminal` com `fromJson`, e as rotas novas na `test/support/api_falsa.dart` |
| F2 | Tratar a sessão vencida (401) num lugar só. Hoje só a validação do QR trata; cada tela nova vai repetir o código |
| F3 | Tabela de motivos no app (`lib/core/constants/motivos.dart`), se o grupo não fizer a B2 |
| F4 | O botão "Entrar com NFC" no login ainda diz "em construção" (P1.3): tirar ou mudar a função |
| F5 | Código sem uso: `views/user/menu_view.dart`, `controllers/menu_controller.dart` e o teste deles (P1.7) |
| F6 | Permissão de NFC no Android e no iOS (P2.1), para a frente de Tags NFC |
| F7 | Pacotes no `pubspec.yaml` que nenhum arquivo usa: `go_router`, `provider`, `connectivity_plus`, `nfc_manager`. Decidir se usam ou tiram |
| F8 | O iOS bloqueia `http://` (P2.5). Só importa se alguém tiver Mac |

---

## 4. Decisões do grupo (antes de dividir)

| # | Decisão |
|---|---|
| D1 | Cadastro pelo app: criar a rota no backend (B9) ou seguir o design e apagar `register_view.dart` (P1.1)? |
| D2 | A U2 Início vira a tela depois do login, com o menu em grade como A2 "Menu aberto"? Ou o menu continua sendo a tela inicial? |
| D3 | Comunicados e Configurações entram (B10) ou saem do menu do admin? |
| D4 | "Meus visitantes": qual a regra (B8)? Ou sai do menu? |
| D5 | T1–T3 no Flutter são necessárias? O simulador web e o ESP32 já fazem o papel do terminal |
| D6 | `situacao=ATIVA` deve contar AGENDADA e ESGOTADA (B4)? |

---

## 5. Sugestão de divisão

| Frente | Tarefas | Começa quando |
|---|---|---|
| **Base** (1 pessoa, primeiro) | F1, F2, F3 e o doc da seção 0 | Já |
| **Backend** (1 pessoa) | B1, B2, B3, B4, B11, depois B6, B7, B5 | Já, em paralelo com a Base |
| **Usuário** (1 pessoa) | U2, U7, U8, U9, E1–E4, históricos, tag, ajuda | Depois da F1; U7/U8 completas depois da B1 |
| **Admin 1** (1 pessoa) | A3, A4, Tags NFC, A5, A6, Terminais, F6 | Depois da F1 |
| **Admin 2** (1 pessoa) | A1, A7–A12, Visitantes, Relatórios | Depois da F1 |
| Limpeza (quem terminar antes) | F4, F5, F7 | Qualquer hora |

B8, B9, B10 e a Frente Terminal só entram depois das decisões D1, D3, D4 e D5.
