# Roteiro: kit do terminal e demonstração

A parte do kit na Sprint Review 3, em ordem. Uns 5 minutos de fala, mais a demonstração.
O roteiro da equipe toda está em [`roteiro-sprint-review-3.md`](roteiro-sprint-review-3.md).

A linha da fala: **montamos o terminal com o kit, achamos e corrigimos quatro problemas, e o
fluxo funcionou de ponta a ponta: app, API, MQTT e ESP32.**

---

## Antes de sair de casa

- [ ] **Rede.** O ESP32 está gravado com o Wi-Fi de casa e o IP do PC de casa. Na FATEC os dois
      mudam, e a rede da faculdade pode isolar os aparelhos. Use o roteador do celular:
      1. Ligue o PC no roteador do celular e anote o IP do PC (`ip -4 addr`).
      2. Troque `WIFI_SSID`, `WIFI_SENHA`, `API_URL` e `MQTT_HOST` em `arduino/include/credenciais.h`.
      3. Grave: `pio run -e oled -t upload`.
      4. **Teste em casa, no dia anterior, já com o roteador do celular.**
- [ ] **Backend no ar:** `docker compose -f docker-compose.dev.yml up -d database mqtt backend`, e
      `http://<IP do PC>:3000/health` respondendo.
- [ ] **Levar:** o kit, o **cabo USB que funcionou** (o outro só carrega), as duas tags e o
      notebook carregado.
- [ ] **Tags cadastradas no banco local:** `6EACD706` (Maria, morador@passe.com) e `5C521206`
      (Thiago Nunes, thiago@passe.com). Se usar outro banco, ou a nuvem, cadastre de novo.
- [ ] **Catraca:** confira se a coordenada da Catraca 1 está na portaria (Google Maps, botão direito,
      copiar coordenadas, tela **Locais**). O raio é de 300 m.
- [ ] **Testar o QR do OLED com a câmera do celular.** É a única parte que ainda não foi testada.
- [ ] **Plano B aberto no navegador:** `http://<IP do PC>:3000/simulador/`.

---

## Ordem da fala

### 1. O que é o terminal (30 s)

- É o aparelho que fica na catraca: mostra o QR, lê o cartão e avisa se pode passar.
- **Quem decide é sempre o servidor.** O terminal só mostra e lê.

### 2. O hardware (1 min)

| Peça | Para que serve | Ligação |
|---|---|---|
| ESP32 | O cérebro: Wi-Fi, API e MQTT | USB no PC |
| OLED 0,96" (I2C) | Mostra o QR e "Pode passar" / "Acesso negado" | SDA D21, SCL D22 |
| LED verde e LED vermelho | Liberado e negado | D25 e D27, com resistor de 220 Ω |
| Leitor RC522 (NFC) | Lê o cartão ou o chaveiro | SDA D32, SCK D18, MOSI D23, MISO D19, RST D13 |

- **Saíram o relé e o buzzer.** O terminal continua recebendo `ABRIR`: numa catraca de verdade, é
  só ligar o atuador no pino D26.
- 17 fios, montados em 4 etapas.

### 3. Como montamos (30 s)

- Guia passo a passo: `docs/montagem-terminal.html`. Mostre aberto por 10 segundos.
- **Uma peça por vez, com um teste em cada etapa:** ESP32, LEDs, display e leitor.
- O teste de bancada (`pio run -e teste-oled`) tem um menu na serial: 1 testa os LEDs, 4 o display
  e 5 o leitor.

### 4. Problemas que achamos e como resolvemos (1 a 2 min)

É a parte mais interessante. Conte como uma investigação.

| Sintoma | Causa | Solução |
|---|---|---|
| O PC não reconhecia o ESP32 | O cabo USB só carregava | Trocar por cabo de dados |
| Os LEDs pararam depois de montar o display | O fio do GND tinha saído do trilho − | Encaixar de novo; o teste da etapa achou na hora |
| Display com tela preta | O firmware gravado era de outro display (TFT colorido). E o branco do código (`0xFFFF`) não desenha no OLED, que só aceita 1 ou 0 | Fizemos backup do firmware, achamos a causa, corrigimos o branco e gravamos a versão para o OLED |
| Leitor respondendo valores diferentes a cada leitura (0x00, 0xFF, 0xEE) | A barra de pinos do leitor estava só encaixada, sem solda | Soldar. Depois disso: versão estável (0x82) e o cartão foi lido |

- **Lição:** testar etapa por etapa encontra o problema na hora, e o backup antes de gravar deixa
  voltar atrás.

### 5. O que validamos (1 min)

Teste de ponta a ponta em 23 e 24/11:

| Teste | Resultado |
|---|---|
| QR com morador autorizado | ✅ Liberado: a API decidiu e o ESP32 recebeu pelo MQTT |
| QR fora do horário | ✅ Negado: "Fora do horário permitido" |
| Cartão sem cadastro | ✅ Negado: "Tag não cadastrada" |
| Cartão vinculado ao morador | ✅ Liberado, LED verde |
| Pessoa nova criada pelo admin, com autorização e tag | ✅ Liberado |
| Chave do terminal trocada pelo admin | ✅ O terminal antigo parou na hora ("Sem servidor") |
| Terminal no painel | ✅ Online, com todos os acessos no histórico |

- No teste, o QR foi enviado por um script com as mesmas chamadas do app. **A leitura com a câmera
  do celular ainda falta.**

### 6. Demonstração ao vivo

| Passo | O que fazer | O que falar | Resultado esperado |
|---|---|---|---|
| 1 | Ligar o USB | "Ele entra no Wi-Fi, conecta no broker e pede um QR à API." | "Conectando" e depois o QR |
| 2 | Esperar 10 s | "O QR troca a cada 10 segundos, é assinado e só vale uma vez." | QR novo |
| 3 | Passar o cartão da Maria (`6EACD706`) | "No cartão, a decisão volta na própria resposta da API." | LED verde, "Acesso liberado" |
| 4 | No app, como morador, **bloquear** a própria tag (Minha tag NFC) | "Perdi o cartão: eu mesmo bloqueio." | — |
| 5 | Passar o mesmo cartão | — | LED vermelho, "Sua tag está bloqueada" |
| 6 | Desbloquear e passar de novo | — | Verde de novo |
| 7 | Ler o QR do OLED com o app | "No QR, a decisão chega ao terminal pelo MQTT." | Verde e "Pode passar" |
| 8 | Abrir o histórico no app (admin) | "Toda tentativa vira um evento, liberada ou negada." | Os acessos que acabamos de fazer |

**Plano B:** se o QR não ler, faça o passo 7 pelo simulador (`/simulador/`). Ele também mostra o
"QR reutilizado" e o "celular longe da catraca".

### 7. O que ainda falta (30 s)

- Ler o QR do OLED com a câmera do celular. O QR fica com uns 6 mm. Se não ler bem, o plano é
  encurtar o token em 1 caractere, o que dobra o tamanho de cada módulo.
- Abrir o PR com o guia e a correção do firmware para o OLED.
- Atualizar a documentação, que ainda fala de relé, buzzer e TFT.

---

## Se o professor perguntar

**Sem relé, como a catraca abre?** O terminal recebe `ABRIR` e acende o LED verde. O código do relé
continua no firmware (D26): numa catraca de verdade, é só ligar o atuador.

**E se a internet cair?** Sem MQTT, o terminal consulta as decisões pela API a cada 2 segundos.
Sem Wi-Fi, a tela mostra "Sem Wi-Fi" e ele tenta reconectar.

**Dá para falsificar um "ABRIR"?** Não. O broker exige usuário e senha, e pela ACL só a API publica
decisões. Cada terminal só lê o próprio tópico.

**E se roubarem a chave do terminal?** O admin troca a chave pelo app, e a antiga para na hora.
Testamos isso.

**Por que o raio é de 300 m?** Na FATEC a sala fica a uns 200 m da portaria, e o GPS dentro do
prédio erra dezenas de metros. O raio muda pela tela Locais.

**Por que o leitor responde 0x82, e não 0x92?** É um clone do RC522. O que importa é o valor ficar
estável e ler o cartão, e os dois acontecem.

---

## Se algo der errado na hora

| Na tela ou no LED | Provável causa | O que fazer |
|---|---|---|
| "Sem Wi-Fi" | A rede gravada não é a da sala | Ligar o roteador do celular que foi gravado |
| "Sem servidor" | API fora do ar, IP do PC mudou ou chave trocada | Ver `/health`; conferir o IP no `credenciais.h` |
| Cartão não faz nada | Fio do leitor solto (MISO, D19) | Apertar os fios do leitor; plano B |
| LEDs não acendem | GND solto do trilho − | Encaixar o fio preto do GND |
| QR não lê | QR pequeno no OLED | Chegar mais perto; plano B (simulador) |
