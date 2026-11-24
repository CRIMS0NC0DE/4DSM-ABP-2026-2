# Passe · Sprint 3

O que mudou de 11/11 a 23/11/2026, depois da Sprint Review 2. O levantamento foi feito em 23/11
na `main` (`61146c8`), nas outras branches, no GitHub Actions e na bancada do kit.

## Resumo

A Sprint 3 foi de documentação e de hardware. O código do backend, do app e do firmware na `main`
não mudou desde 11/11.

- **A documentação técnica ficou completa.** São nove documentos, com 7,3 mil linhas: API,
  aplicativo, backend, banco, Docker e CI/CD, firmware, instalação, MQTT e QR/NFC. As rotas
  descritas na documentação da API batem com as do código.
- **Arquitetura e diagramas UML.** Há diagramas de casos de uso, de classes, de sequência do QR e
  do NFC, de atividade e de componentes. Isso fecha o RP07 (card #35).
- **O kit começou a ser montado** (card #34), com o hardware mudado. Um display OLED 0,96" I2C entrou
  no lugar do TFT, e saíram o relé e o buzzer. Os LEDs e o display já foram testados; o leitor NFC
  está em montagem.

Ficam para a Sprint 4 o GPS no terminal (#33), a eficiência energética (#36) e o deploy (#37). O
deploy está parado porque o CI da `main` está vermelho desde 11/11, por uma mudança do Flutter e
não do nosso código.

## Sprint 2 × Sprint 3

| | Sprint 2 (11/11) | Sprint 3 (23/11) |
|---|---|---|
| Kit do terminal | Firmware pronto, kit não montado | Em montagem: LEDs e display ok, leitor NFC em andamento |
| Hardware do terminal | TFT 1,54", relé e buzzer | OLED 0,96" I2C, sem relé e sem buzzer |
| Documentação técnica | README e documentos avulsos | 9 documentos técnicos e 4 de arquitetura |
| Diagramas (RP07) | Pendentes | Casos de uso, classes, sequência, atividade e componentes |
| Código na `main` | — | Sem mudanças; continuam os 110 testes do backend e os 251 do app |
| CI na `main` | 7 jobs verdes | Job do Frontend vermelho desde 11/11 e deploy parado |

## O que entregamos

### 1. Documentação técnica (Eric França, 11/11 e 23/11)

Em [`docs/documentacao-tecnica/`](../documentacao-tecnica/):

| Documento | O que cobre |
|---|---|
| `api.md` | Contrato de todas as rotas: autenticação, perfis, erros, QR, usuários, locais, autorizações, histórico e a API do terminal |
| `aplicativo.md` | Arquitetura do app Flutter, navegação por perfil, telas, cliente HTTP e fluxo do QR |
| `backend.md` | Camadas da API, autenticação, fluxo de validação, variáveis de ambiente e testes |
| `banco-de-dados.md` | Diagrama entidade-relacionamento, dicionário de dados, índices, concorrência, migrations e seed |
| `docker-cicd.md` | Docker Compose de desenvolvimento, broker com ACL e TLS, jobs do CI e deploy |
| `firmware-esp32.md` | Pinagem, ambientes de compilação, estados do terminal e integração com a API e o MQTT |
| `instalacao-ambiente.md` | Passo a passo para rodar o projeto do zero, no Docker ou direto no Node |
| `mqtt.md` | Tópico, payload, QoS, ACL, TLS e a consulta HTTP de reserva |
| `qr-code-nfc.md` | Os dois métodos de acesso lado a lado: geração, assinatura, leitura e decisão |

Conferimos as rotas citadas na `api.md` contra o código do backend: todas existem. A documentação
não tem senha nem chave; os exemplos de conexão usam valores genéricos.

### 2. Arquitetura e diagramas (Vinicius Ledro, 11/11, card #35)

Em [`docs/arquitetura/`](../arquitetura/) estão a arquitetura geral, a infraestrutura, o modelo de
dados e o diagrama de componentes, mais quatro diagramas UML:

- **Casos de uso:** o que cada um dos quatro perfis faz no sistema.
- **Classes:** as entidades do domínio (usuário, tag, local, autorização, evento e terminal) e
  como se relacionam.
- **Sequência:** o acesso por QR e o acesso por NFC no mesmo diagrama.
- **Atividade:** a tentativa de acesso do começo ao fim, com cada ponto em que ela é negada.

### 3. Montagem do kit (Thiago Nunes, card #34)

- **Hardware novo.** O display passou a ser um OLED 0,96" I2C (SSD1306, 128×64), e o relé e o
  buzzer saíram. Na demonstração, a tela e os LEDs mostram se o acesso foi liberado ou negado. O
  terminal continua recebendo `ABRIR`, então numa catraca de verdade basta ligar o atuador.
- **Guia de montagem refeito** ([`docs/montagem-terminal.html`](../montagem-terminal.html)). Agora
  são 4 etapas (ESP32, LEDs, display e leitor) e 17 fios em vez de 23, e o leitor NFC vai direto
  no ESP32.
- **Firmware ajustado para o OLED.** Os avisos "Conectando" e "Sem servidor" não apareciam no OLED,
  e "Pode passar" e "Acesso negado" se sobrepunham ao texto de baixo. As duas falhas foram
  corrigidas, e o teste de bancada ganhou uma versão para o OLED (`pio run -e teste-oled`). O
  firmware do TFT não mudou.
- **Situação em 22/11:**
  - LEDs funcionando.
  - O display responde no I2C e mostrou as imagens enviadas pelo computador.
  - O leitor NFC estava sendo montado.

O guia e os ajustes do firmware ainda não estão na `main`: falta abrir o PR.

## O que não entregamos

| Card | Situação |
|---|---|
| #34 Kit montado | Em andamento: falta o leitor NFC, gravar o firmware com o OLED e testar com o app |
| #33 GPS no terminal (RF11) | Não começou. Hoje a posição da catraca é cadastrada pelo `provisionar-terminal.mjs` |
| #36 Eficiência energética (RNF07) | Não começou |
| #37 Deploy | Parado: o deploy só roda com o CI verde |

Da lista que a Sprint 2 deixou, também continuam abertos:

- **App:** "Entrar com NFC" no login ainda diz "em construção", algumas opções dos menus também, e o
  nome do app no Android continua "public".
- **Backend:** editar e apagar edifício, portaria e porta, e a rota de relatório agregado.
- **GitHub:** as issues #7 a #10 continuam abertas. A #8 e a #10 já foram entregues na Sprint 2.

## Problemas encontrados no review

1. **O CI da `main` está vermelho desde 11/11.** Quem falha é o job "Frontend · análise e testes".
   O workflow usa o Flutter `stable` sem versão fixa. O Flutter 3.50.1 marcou
   `package:flutter/material.dart` como obsoleto, e o `flutter analyze` passou a acusar 62 avisos e
   falhar. O app não mudou. Com o CI vermelho, o deploy não roda.
   **Correção:** fixar a versão do Flutter em `.github/workflows/ci-cd.yml` e em `ios-ipa.yml`, ou
   ignorar o aviso `deprecated_member_use` no `analysis_options.yaml` até migrar.
2. **A documentação descreve o hardware antigo.** O `firmware-esp32.md` cita relé, buzzer ou TFT 58
   vezes. Também falam deles `qr-code-nfc.md`, `instalacao-ambiente.md`, `docker-cicd.md`,
   `mqtt.md`, `arquitetura-geral.md`, `diagrama-componentes.md`, `hardware.md`, `terminal-iot.md` e
   o README. Os diagramas de sequência e de atividade dizem "acionar relé". O firmware ainda aciona
   os pinos do relé e do buzzer. Isso não atrapalha, mas a decisão de manter ou tirar esse código
   precisa ficar registrada.
3. **Há um commit local que não pode subir.** Na `dev-thiago` local, o commit `4edaf48` ("merge",
   21/11) adiciona 2.267 arquivos de build do PlatformIO (`arduino/.pio/`, 700 mil linhas) e o
   `arduino/include/credenciais.h`. O `credenciais.h` está igual ao exemplo, então nenhuma senha
   vazou. Mesmo assim, os dois estão no `.gitignore` e não devem ir para o repositório, que é
   público.
4. **O QR fica pequeno no OLED.** O QR do sistema tem 33×33 módulos, e o OLED tem 64 pontos de
   altura. Sobra 1 ponto por módulo, e o QR inteiro fica com uns 6 mm. Ele precisa ser testado com o
   app antes da apresentação. Encurtar o token em 1 caractere permite um QR de 29×29, com 2 pontos
   por módulo e uns 10 mm.
5. **Faltam os manuais.** `docs/documentacao-tecnica/documentacao.txt` e `docs/manuais/manuais.txt`
   estão vazios: o manual do usuário ainda não existe.

## Para a Sprint 4

| Prioridade | O quê |
|---|---|
| 1 | Consertar o CI e confirmar o Render recebendo a versão nova (#37) |
| 2 | Terminar o kit: leitor NFC, firmware com OLED gravado e QR lido pelo app. Abrir o PR do guia e do firmware (#34) |
| 3 | Atualizar a documentação, os diagramas e o README para o OLED sem relé e sem buzzer |
| 4 | GPS no terminal (#33) e eficiência energética (#36), ou combinar com o professor se saem do escopo |
| 5 | App: "Entrar com NFC" e nome do app. Backend: editar e apagar locais |
| 6 | Manual do usuário; fechar as issues #8 e #10 |

## Fotos para tirar

Salve em `docs/sprint-3/fotos/`, com os mesmos cuidados da Sprint 2: foto em `.jpg` de até 1 MB, e
nada de chave do terminal, senha do Wi-Fi ou `.env` na imagem.

| Arquivo | O que mostrar |
|---|---|
| `kit-montado.jpg` | O kit de cima, com o QR no OLED e os fios visíveis |
| `oled-liberado.jpg` | O display com "OK / Pode passar" e o LED verde aceso |
| `app-lendo-oled.jpg` | O celular lendo o QR do OLED |
| `ci-verde.png` | O GitHub Actions verde de novo, depois da correção |
