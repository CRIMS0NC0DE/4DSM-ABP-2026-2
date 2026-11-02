# Telas pendentes do app Passe

Levantamento de 02/11/2026, feito na branch `dev-thiago` (commit `42a1e8f`), rodando o projeto de verdade: API, banco, broker e app no navegador.

O código-base para copiar e colar está em [`telas-pendentes-codigo-base.md`](telas-pendentes-codigo-base.md). Nenhum arquivo existente do projeto foi alterado.

## 1. Resumo

- **Faltam 18 das 35 telas do design**, e mais 10 opções de menu que não têm tela no design.
- **Hoje nada abre nos menus da equipe.** Todas as opções do admin (12) e da portaria (8) mostram "tela em construção". No morador faltam 6 de 8 e no visitante, 5 de 7.
- **A maior parte não depende de backend novo.** Das 19 telas listadas abaixo, 13 já têm todas as rotas prontas ou nem usam API, e 3 funcionam em parte. Só **Meus visitantes**, **Comunicados** e **Configurações** dependem totalmente de backend que não existe.
- **Comece pela fundação e pelo Histórico.** A fundação evita repetir código nas outras telas, e o Histórico sozinho libera 8 opções de menu nos 4 perfis.

| Situação das telas do design | Quantidade | Quais |
|---|---:|---|
| Prontas | 17 | U1, U3–U8, N1–N4, E3, E4, E5, E7, E8 e A2 (menu em grade) |
| Faltam | 18 | U2, U9, E1, E2, A1, A3–A12, T1–T3 |

## 2. Como ler as listas

| Marca | Backend |
|---|---|
| 🟢 | **Pronto.** As rotas existem e responderam na sonda da API. Só falta a tela. |
| 🟡 | **Parcial.** A tela funciona, mas uma parte depende de mudança no backend. |
| 🔴 | **Falta criar.** A rota não existe (a API responde 404). Sem backend, a tela não funciona. |
| ⚪ | **Não usa.** Tela sem chamada à API. |

**Tamanho** é uma estimativa do esforço de ajustar e testar a partir do código-base: P (pequeno), M (médio), G (grande). **Base** indica se o código-base traz a tela.

## 3. Antes das telas: a fundação

Faça primeiro, porque quase toda tela nova usa. Está na seção 1 do código-base.

| O que é | Para que serve |
|---|---|
| Modelos `EventoAcesso`, `UsuarioCadastro`, `TagNfc`, `Edificio`/`Portaria`/`Porta`/`Catraca`, `Terminal`, `AutorizacaoEquipe`, `Painel` | Ler as respostas da API (F1 do backlog) |
| `carrega_dados.dart` | Estados de carregando e erro, e a sessão vencida (401) num lugar só (F2) |
| `motivos.dart` | Texto de cada motivo de negação, enquanto a B2 não sai (F3) |
| `tela_base.dart`, `estado_vazio.dart`, `selo.dart`, `campo_selecao.dart`, `item_evento.dart` | As partes que se repetem em todas as telas |

## 4. Lista A: telas complexas, com sub-telas

Em ordem de prioridade.

| # | Tela | Sub-telas | Perfis | Backend | Tam. | Base |
|---:|---|---|---|---|---:|---:|
| C1 | **Histórico de acessos e Acessos negados** | Lista paginada (A11), sem resultados (A12), painel de filtros, "Carregar mais" | Todos | 🟢 | M | Sim |
| C2 | **Autorizações** | Lista (A7), filtros (A8), formulário de criar e editar (A9), confirmar cancelamento (A10) | Admin, portaria | 🟢 | G | Sim |
| C3 | **Usuários** | Lista com busca e filtro (A3), formulário de criar e editar (A4), desativar, trocar senha | Admin, portaria | 🟢 | G | Sim |
| C4 | **Visitantes** | Lista, passo 1 (dados da pessoa), passo 2 (autorização) | Admin, portaria | 🟢 | M | Sim |
| C5 | **Locais** | Árvore (A5), novo edifício, portaria e porta, editar catraca (A6) | Admin | 🟡 B5 | G | Sim |
| C6 | **Tags NFC** | Lista com busca por UID, vincular, bloquear, remover | Admin, portaria | 🟢 | M | Sim |
| C7 | **Terminais** | Lista, cadastrar, chave mostrada uma vez, trocar chave | Admin, portaria (só consulta) | 🟢 | M | Sim |
| C8 | **Relatórios** | Período, totais, por local, por motivo | Admin | 🟡 B12 | M | Sim |
| C9 | **Meus visitantes** | Lista, avisar visitante, cancelar | Morador | 🔴 B8 | G | Não |
| C10 | **Comunicados** | Lista, criar, editar | Admin (leitura para os outros) | 🔴 B10 | G | Não |
| C11 | **Terminal no Flutter** | Aguardando leitura (T1), liberado (T2), negado (T3), configuração do aparelho | Terminal | 🟢 | G | Não |

**Por que nessa ordem**

- **C1 vem primeiro** porque é uma tela só, reaproveitada por todos os perfis.
- **C2 e C3** são o coração do sistema (RF01, RF03 a RF05): sem elas, a equipe não consegue liberar ninguém pelo app.
- **C4 depende de C2 e C3**, porque reaproveita os dois formulários.
- **C9, C10 e C11 ficam por último** porque dependem de uma decisão do grupo (seção 7). C9 e C10 também precisam de backend novo, e C11 precisa do pacote `qr_flutter`.

## 5. Lista B: telas simples, uma interface já resolve

Em ordem de prioridade.

| # | Tela | O que mostra | Perfis | Backend | Tam. | Base |
|---:|---|---|---|---|---:|---:|
| S1 | **Painel (A1)** | Três números, negados recentes e atalhos. Usa C1 e C2 | Admin, portaria | 🟢 | P | Sim |
| S2 | **Histórico do morador** | A mesma tela do C1: 1 linha no menu | Morador, visitante | 🟢 | P | Sim |
| S3 | **Acessos negados do morador** | A mesma tela do C1, com o que fazer | Morador, visitante | 🟢 | P | Sim |
| S4 | **Ajuda** | Contato da portaria e dúvidas comuns. Troque o telefone de exemplo | Morador, visitante | ⚪ | P | Sim |
| S5 | **Perfil (U9)** | Nome, e-mail, CPF mascarado, tag, Sair | Morador, visitante | 🟢 | P | Sim |
| S6 | **Minha tag NFC** | Ver a tag: pronto. Bloquear: depende da B6 | Morador, visitante (só ver) | 🟡 B6 | P | Sim |
| S7 | **Início (U2, E1, E2)** | Próxima autorização e atalho para o scanner. Depende da decisão D2 | Morador, visitante | 🟢 | P | Sim |
| S8 | **Configurações** | Regras e horários de acesso. Recomendo tirar do menu (D3) | Admin | 🔴 B10 | P | Não |

## 6. Telas que precisam do backend

### 6.1 Precisam de mudança no backend

| Tela | Mudança | Código | O que acontece sem ela |
|---|---|---|---|
| Meus visitantes (C9) | **B8:** rotas em `/me` e regra de negócio | Contrato proposto | A tela não funciona |
| Comunicados (C10) | **B10:** modelo, migration e rotas | Contrato proposto | A tela não funciona |
| Configurações (S8) | **B10:** tabela e rotas | Não | A tela não funciona |
| Minha tag NFC (S6) | **B6:** `PATCH /me/tags/:tagId` | Testado | Só ver, sem bloquear |
| Locais (C5) | **B5:** `PATCH` e `DELETE` de edifício, portaria e porta; `DELETE` de catraca | Não | Cria tudo e edita a catraca, mas não edita nem apaga o resto |
| Relatórios (C8) | **B12 (novo):** rota agregada | Não | Detalhes somados só sobre os 200 acessos mais recentes |
| Painel e Autorizações (S1, C2) | **B4:** filtro `situacao=ATIVA` | Testado | O número "Autorizações ativas" do painel sai errado. A lista já se corrige no app |
| Histórico (C1, S2, S3) | **B2:** texto do motivo nos eventos | Testado | Funciona com a tabela `motivos.dart` copiada no app |
| Todas da equipe | **B3:** conferir `ativo` a cada chamada | Testado | Quem foi desativado continua entrando até o token vencer (8 h) |

### 6.2 Usam rotas que já existem

| Tela | Rotas |
|---|---|
| Histórico e negados da equipe | `GET /access-events`, `GET /locations` |
| Histórico e negados do morador | `GET /me/access-events` |
| Autorizações | `GET`, `POST`, `PATCH /authorizations`, `POST /authorizations/:id/cancel`, `GET /users`, `GET /locations` |
| Usuários | `GET`, `POST`, `PATCH /users` |
| Visitantes | `GET /users?perfil=VISITANTE`, `POST /users`, `POST /authorizations` |
| Tags NFC | `GET /users`, `POST`, `PATCH`, `DELETE /users/:id/tags` |
| Terminais | `GET`, `POST /terminals`, `POST /terminals/:id/rotate-key`, `GET /locations` |
| Painel | `GET /dashboard`, `GET /locations` |
| Perfil, Minha tag | `GET /auth/me` |
| Início | `GET /me/authorizations` |
| Terminal no Flutter | `GET /terminal/qr-token`, `POST /terminal/heartbeat`, `GET /terminal/decisions`, `POST /terminal/nfc` |

### 6.3 Não usam backend

Ajuda e a parte "Sobre o Passe" do Perfil.

## 7. Decisões do grupo

São as mesmas do `backlog-sprint.md`. Elas mudam o que entra na lista, então vale fechar antes de dividir o trabalho.

| # | Decisão | Minha recomendação |
|---|---|---|
| D1 | Cadastro pelo app: criar rota ou seguir o design? | Seguir o design: tirar "Registrar" e mostrar "Peça seu cadastro na portaria". A tela de hoje só avisa que não está disponível |
| D2 | A U2 Início vira a tela depois do login? | Só no fim. A `InicioView` funciona, mas trocar a tela inicial muda testes que já existem |
| D3 | Comunicados e Configurações ficam no menu? | Tirar. Exigem modelo, migration e rotas, e no código não há RF ligado a eles |
| D4 | Meus visitantes: qual a regra? | Tirar do menu nesta entrega. A portaria já cobre com a tela Visitantes (C4) |
| D5 | T1–T3 no Flutter são necessárias? | Não fazer, a menos que a disciplina exija. O simulador web e o ESP32 já fazem esse papel |
| D6 | `situacao=ATIVA` conta agendadas e sem usos? | Não. Ativa deve ser o que vale hoje, que é o que o selo da tela mostra. A correção tem uma linha (B4) |

## 8. Ajustes em telas que já existem

| Tela | Ajuste | Backend |
|---|---|---|
| Login | "Entrar com NFC" ainda diz "em construção", e o design não tem esse botão. Tirar | Não |
| Login | "Registrar" abre uma tela que só avisa que não está disponível (D1) | Só com a B9 |
| Login | "Esqueci minha senha" só mostra um aviso, o que é suficiente: a portaria troca a senha no formulário de Usuário | Não |
| Menus | Depois de ligar as telas, atualizar o comentário "Protótipo: as opções ainda não abrem telas" nos 4 controllers | Não |
| Código sem uso | `menu_view.dart`, `menu_controller.dart` e o teste deles (F5) | Não |
| Android | O nome do app no celular aparece como "public" (`android:label`). Trocar para "Passe" | Não |
| Android e iOS | Falta a permissão de NFC. Só importa se a tela Tags NFC for ler a tag pelo celular; o código-base usa digitação do UID | Não |

## 9. O que a revisão encontrou

### 9.1 O que foi rodado

| Verificação | Resultado |
|---|---|
| Backend: lint, tipos e testes | Sem erros. 83 de 83 testes passaram |
| App: `flutter analyze` | Nenhum problema |
| App: `flutter test` | 152 passaram e 8 foram pulados (os 8 precisam da API real) |
| App contra a API real | Os 8 pulados passaram |
| API real: rotas de cada tela | Respostas e erros 400, 401, 403, 404 e 409 conferidos |
| Fluxo do QR na API real | Liberado, QR reutilizado e pessoa a 1 km: os três corretos |
| App no navegador (Chromium, 390×844) | Login nos 4 perfis e toque em cada opção de menu |

### 9.2 Problemas confirmados rodando

| # | Problema | Como apareceu | Onde tratar |
|---|---|---|---|
| 1 | **Quem é desativado continua usando a API** até o token vencer | Portaria desativada chamou `GET /users` e recebeu 200 | B3 |
| 2 | **O painel conta autorização agendada como ativa** | Criar uma autorização para 2027 mudou o número de 2 para 3 | B4 |
| 3 | **Filtrar o histórico só com a data corta o dia inteiro** (novo) | `ate=2026-11-02` trouxe 0 registros; com a hora, 3. A API lê a data como meia-noite em UTC | O código-base já manda data e hora |
| 4 | **`GET /terminals` não traz o nome da catraca** (novo) | A resposta só tem `accessPointId` | O código-base cruza com `GET /locations` |
| 5 | **Eventos só trazem o código do motivo** | `motivo: "FORA_DO_HORARIO"`, sem texto | B2, ou `motivos.dart` |
| 6 | **Mensagem de erro em inglês** (novo) | Raio abaixo de 10 responde "Too small: expected number to be >=10". O mesmo vale para latitude e longitude | Dar mensagem em português no schema. O formulário já valida antes |
| 7 | **A autorização do seed nega fora das 06:00–23:00** | QR às 00:08 voltou `FORA_DO_HORARIO`. Cuidado ao demonstrar à noite | Crie uma autorização com janela maior |

### 9.3 Documentos desatualizados

| Documento diz | Hoje |
|---|---|
| `backlog-sprint.md`: 110 testes no app | 152 |
| `backlog-sprint.md`: 12 de 35 telas prontas | 17, contando A2. U7, U8, E3 e E4 já foram feitas |
| `backlog-sprint.md`: B1 (caminho do local) pendente | Feita no commit `42a1e8f` |
| `backlog-sprint.md`, B11: `frontend/Contas.MD` não existe | Existe, mas não tem a conta de visitante |
| `backlog-sprint.md`, F7: 4 pacotes sem uso | São 6: faltavam `intl` e `google_fonts` |
| `integracao-frontend-backend.md`: `de` e `ate` aceitam só a data | Aceitam, mas `ate` corta o dia (problema 3) |

## 10. Como o código-base foi testado

O código foi escrito e testado numa cópia do projeto, fora do repositório.

| Verificação | Resultado |
|---|---|
| `flutter analyze` com todo o código colado | Nenhum problema |
| `flutter test` com todo o código colado | 223 passaram, 8 pulados (152 de antes + 71 novos). 4 testes antigos precisam de ajuste, já incluído |
| Telas novas no navegador contra a API real | 26 de 26 etapas, nos 4 perfis e no modo escuro, sem erro no navegador |
| Gravações conferidas na API | 16 de 16: criar edifício, editar catraca, visitante em 2 passos, cancelar autorização, vincular, bloquear e remover tag, cadastrar terminal, trocar chave |
| Trechos de backend (B2, B3, B4, B6) | Lint e tipos sem erros, 87 de 87 testes (83 + 4 novos). Sem as trocas, os 4 novos falham |
| Fonte em 2× e modo escuro | Sem estouro de layout nas 15 telas com API |
| Passo a passo do código-base numa cópia limpa do commit | Todos os blocos extraídos do `.md` e aplicados na ordem: 39 arquivos novos e 24 trocas, com `flutter analyze` limpo a cada seção |

**O que não foi testado**

- Celular de verdade: câmera, GPS e NFC. O navegador não tem câmera, e o scanner caiu na tela de permissão (E7).
- Android e iOS: só o build web foi rodado.
- Terminal físico (ESP32).
- As telas C9, C10, C11 e S8, que não têm código-base.
