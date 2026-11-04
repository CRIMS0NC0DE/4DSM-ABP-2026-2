# Montagem do terminal da catraca (ESP32): contexto para analisar as fotos do kit

## O que eu preciso de você

Você vai me ajudar a montar o hardware do terminal físico da catraca do projeto **Passe**.
O firmware já está pronto e compila no CI (o código completo está no fim deste documento).
Falta montar o kit e ligar tudo do jeito que o firmware espera.

Junto com este texto vão fotos das peças do kit. Com elas, quero que você:

1. **Identifique cada peça** nas fotos (modelo, chip, tamanho, nomes dos pinos impressos na
   placa) e monte uma tabela de inventário: *peça esperada → o que veio no kit → serve?*
   (sim / serve com ajuste / não serve / não achei na foto).
2. **Aponte o que não bate** com o que o firmware espera (lista em "Pontos para conferir nas
   fotos"). Se uma peça não servir, diga o que trocar ou qual mudança mínima fazer no código
   (`config.h`, `platformio.ini` ou `tela.cpp`).
3. **Monte a tabela de ligação para as minhas peças**: pino impresso no módulo → pino impresso
   no ESP32, com cor de jumper sugerida (vermelho = 3V3/5V, preto = GND) e onde fica na protoboard.
4. **Me passe a montagem em etapas**, uma peça por vez, com um teste no fim de cada etapa.
   Para os testes, me dê sketches curtos usando os mesmos pinos do `config.h`.
5. **Me dê uma checagem para fazer antes de ligar na energia**: curto entre 3V3/5V e GND,
   5 V onde não pode, polaridade de LED e buzzer.
6. Quando eu mandar fotos da montagem pronta, **confira fio por fio** contra a tabela e diga o
   que estiver errado.

Regras:

- Responda em português.
- Use os nomes de pino **impressos nas placas das fotos**, não a posição no desenho deste
  documento. Se não der para ler um rótulo, diga qual e peça outra foto em vez de chutar.
- Não mude a lógica do firmware. Só pinagem, display ou detalhes de hardware, quando a peça exigir.
- Destaque em **negrito** tudo que pode queimar uma peça (5 V no RC522, curto 3V3–GND, relé
  ligado direto no GPIO).

## O projeto em poucas linhas

O Passe é um controle de acesso de condomínio (ABP da FATEC, 4º semestre de DSM). O terminal
fica na catraca: mostra um QR Code que troca a cada 10 s, o morador lê com o app, a API decide e
manda `ABRIR` ou `NEGAR` para o terminal pelo MQTT. O terminal também lê tag NFC e manda o UID
para a API. **Quem decide é sempre o backend.** O terminal só desenha o QR, aciona relé, LEDs e
buzzer, e repassa o UID da tag.

```
App (celular) ──HTTP──▶ API (no PC, porta 3000) ──MQTT (porta 1883)──▶ ESP32 (terminal)
                              ▲                                            │
                              └────────── HTTP: QR, NFC e heartbeat ───────┘
```

O firmware usa PlatformIO com framework Arduino e placa `esp32dev`. **Tem que ser ESP32**, por
causa do Wi-Fi. Arduino Uno e Nano não servem.

## Peças que o firmware espera

| Item | Modelo previsto | Para quê |
|---|---|---|
| Microcontrolador | ESP32 DevKit V1 (ESP32-WROOM-32, 30 ou 38 pinos) | Wi-Fi, MQTT, HTTP |
| Display | TFT ST7789 240×240 1.54" **com pino CS** (ou ILI9341 2.4"/2.8" 240×320) | Mostrar o QR rotativo |
| Leitor NFC | MFRC522 (RC522) 13,56 MHz + tags/cartões MIFARE | Acesso por tag |
| Relé | Módulo relé 1 canal 5 V com optoacoplador | "Abrir" a catraca |
| Catraca simulada | LED ou servo 9 g no relé (ou trava solenoide 12 V) | Mostrar a abertura |
| Sinalização | LED verde, LED vermelho, 2 resistores de 220 Ω, buzzer **ativo** 5 V | Feedback visual e sonoro |
| Montagem | Protoboard 830 pontos + jumpers M-M e M-F | |
| Alimentação | Cabo USB **de dados** + fonte USB 5 V 2 A; fonte 12 V só se usar trava | |

Sobre o display: o QR tem 33×33 módulos (versão 4) e precisa de pelo menos uns 4 px por módulo
para o celular ler a uns 20 cm. Um TFT de 240 px dá 5 px por módulo. O OLED 0,96" (128×64) dá
1 px por módulo: serve para teste de bancada, não para a apresentação.

## Pinagem que o firmware espera (`firmware/include/config.h`)

O display e o NFC dividem o mesmo barramento SPI (VSPI), cada um com o seu CS.

| Sinal | GPIO do ESP32 | Liga em |
|---|---|---|
| SPI SCK | 18 | TFT SCL/SCK · RC522 SCK |
| SPI MOSI | 23 | TFT SDA/MOSI · RC522 MOSI |
| SPI MISO | 19 | RC522 MISO (o TFT não usa) |
| TFT CS | 5 | TFT CS |
| TFT DC | 16 | TFT DC/RS |
| TFT RST | 17 | TFT RES/RST |
| TFT luz de fundo | 3V3 | TFT BLK/BL/LED (sempre ligada) |
| NFC SS | 32 | RC522 SDA/SS |
| NFC RST | 13 | RC522 RST |
| Relé | 26 | IN do módulo relé |
| LED verde | 25 | resistor 220 Ω → LED verde → GND |
| LED vermelho | 27 | resistor 220 Ω → LED vermelho → GND |
| Buzzer | 4 | + do buzzer ativo (− no GND) |
| OLED SDA / SCL | 21 / 22 | só no ambiente `oled` |

Alimentação: TFT e RC522 no **3V3** do DevKit. Módulo relé no **VIN (5 V)**, com o jumper
JD-VCC/VCC no lugar. **GND comum para tudo.** O firmware considera o relé ativo em LOW
(`RELE_LIGADO LOW`), que é o caso da maioria dos módulos.

Pinos evitados de propósito: 0, 2, 12 e 15 (definem o modo de boot), 6 a 11 (memória flash),
34 a 39 (só entrada). Se precisar remanejar algum sinal, não use esses.

Desenho de referência. **É um desenho lógico, não a posição física dos pinos**: a ordem muda
entre placas de 30 e 38 pinos, então confie no rótulo impresso na placa.

```
                 ESP32 DevKit V1
             ┌─────────────────────┐
   TFT CS ───┤ 5               3V3 ├─── TFT VCC/BLK, RC522 3.3V
  SPI SCK ───┤ 18              GND ├─── GND comum
 SPI MISO ───┤ 19              VIN ├─── Relé VCC (5 V)
 SPI MOSI ───┤ 23               13 ├─── RC522 RST
   TFT DC ───┤ 16               32 ├─── RC522 SDA/SS
  TFT RST ───┤ 17               26 ├─── Relé IN
   Buzzer ───┤ 4                25 ├─── LED verde
             │                  27 ├─── LED vermelho
             └─────────────────────┘
```

## Pontos para conferir nas fotos

1. **Placa.** O firmware é para ESP32-WROOM-32 (está escrito na blindagem metálica do chip).
   - **ESP32-WROVER:** os GPIO 16 e 17 são usados pela PSRAM, então o TFT DC e o RST precisam ir
     para outros pinos.
   - **ESP32-S2, S3 ou C3, ESP8266/NodeMCU:** a placa no `platformio.ini` e a pinagem mudam.
   - **Arduino Uno ou Nano:** não têm Wi-Fi e não servem.
   - Muitas placas escrevem `RX2`/`TX2` em vez de 16/17, e `D5`, `D18` etc. em vez do número puro.
   - Chip perto do USB: CP2102 ou CH340 (define o driver no PC).
2. **Display.** Qual é o driver (ST7789, ILI9341, ST7735, SSD1306, LCD 16x2...), a resolução, e se
   tem pino CS.
   - ST7789 240×240 → ambiente `tft`. ST7789 240×320 → ambiente `tft` com `TFT_ALTURA 320`.
   - ILI9341 → ambiente `ili9341`. Os pinos de touch (`T_*`) e do cartão SD ficam soltos.
   - SSD1306 OLED → ambiente `oled` (I2C nos pinos 21/22, QR pequeno demais para a apresentação).
   - **ST7789 1.3" sem pino CS:** não divide o SPI com o NFC.
   - ST7735 1.8" (128×160): não tem ambiente pronto. A biblioteca da Adafruit já suporta, mas é
     preciso adaptar o `tela.cpp`, e o QR fica com uns 3 px por módulo.
   - LCD 16x2 não desenha QR Code.
   - Nos TFTs SPI, `SCL` é o SCK e `SDA` é o MOSI. **Não é I2C**, mesmo com esses nomes.
     `RES` = RST, `DC` = RS/A0, `BLK` = BL/LED.
3. **RC522.** **Só 3,3 V: em 5 V ele queima.** O pino `SDA` dele é o SS do SPI (não é I2C). O `IRQ` fica solto.
4. **Relé.** Ativo em LOW ou HIGH? Tem jumper de nível de acionamento (H/L)? Onde está o jumper
   JD-VCC? Alguns módulos de 5 V não desligam direito com o HIGH de 3,3 V do ESP32. Se o relé
   ficar sempre ligado, me diga como resolver. O módulo tem que ter transistor ou optoacoplador:
   **bobina de relé ligada direto no GPIO queima o pino.**
5. **Buzzer.** O código liga o buzzer com `digitalWrite(HIGH)`, então ele tem que ser **ativo**.
   Para diferenciar: o ativo costuma ter a parte de baixo fechada com resina preta; no passivo dá
   para ver a plaquinha verde. Em 5 V direto, o ativo apita sem parar e o passivo só dá um clique.
   Se for passivo, me diga a troca para `tone()`.
6. **LEDs e resistores.** Perna longa (anodo) do lado do GPIO, perna curta no GND. O resistor de
   220 Ω tem as faixas vermelho-vermelho-marrom (4 faixas) ou vermelho-vermelho-preto-preto (5 faixas).
7. **Protoboard.** O DevKit é largo: numa protoboard só, sobra uma fileira de furos de um lado.
   Diga como encaixar com as peças que eu tenho (duas protoboards lado a lado, ou jumpers M-F
   direto nos pinos). Em muitas protoboards de 830 pontos, as linhas de alimentação são cortadas
   no meio.
8. **Cabo USB.** Precisa ser cabo de dados: cabo só de carga não grava o ESP32.

## Ordem de montagem que eu imagino (mude se achar melhor)

1. Só o ESP32 no USB: gravar um sketch de teste e ver o Serial.
2. LEDs e buzzer.
3. Relé (com um LED ou servo fazendo o papel da catraca).
4. Display.
5. RC522: ler o UID de uma tag no Serial.
6. Firmware completo com o backend rodando no PC.

Teste útil da etapa 6 sem o backend: com o Wi-Fi conectado e a API fora do ar, encostar uma tag
deve mostrar `Tag XXXX` no Serial, tela vermelha "Sem servidor", LED vermelho e dois bipes. Isso
testa NFC, display, LED e buzzer de uma vez. O relé só liga com uma decisão `ABRIR` vinda da API,
então ele precisa de sketch próprio para teste.

## O que aparece na tela e no Serial (115200 baud)

| Situação | Tela | Serial |
|---|---|---|
| Ligando | "Conectando" + nome da rede | `....` até conectar (trava aqui se a rede não existir) |
| Wi-Fi conectado | — | `Wi-Fi ok, IP 192.168.x.x` |
| API fora do ar ou IP errado | "Sem servidor / Tentando de novo..." | `GET /terminal/qr-token: <erro do HTTPClient>` |
| Chave do terminal errada | "Sem servidor / Chave do terminal recusada" | — |
| QR recebido | QR preto em fundo branco + rodapé azul "<nome> - aponte o app Passe" | — |
| MQTT conectado | — | `MQTT conectado, ouvindo passe/terminais/<id>/decisoes` |
| MQTT falhou | — | `MQTT falhou (estado N); usando consulta HTTP` (−2: não alcançou o broker; 4 ou 5: usuário/senha ou ACL) |
| Tag lida | — | `Tag 04A1B2C3` |
| Liberado | Tela verde "OK / Pode passar / Bem-vindo(a), Nome"; LED verde, relé por 3 s, 1 bipe | `Decisao: ABRIR - Pode passar` |
| Negado | Tela vermelha "X / Acesso negado"; LED vermelho, 2 bipes | `Decisao: NEGAR - ...` |
| Wi-Fi caiu | "Sem Wi-Fi / Reconectando..." | — |

## Como eu gravo e rodo

```bash
cd firmware
cp include/credenciais.exemplo.h include/credenciais.h   # Wi-Fi, IP do PC, Id e chave do terminal
pio run -e tft -t upload        # ST7789 (padrão); ou -e ili9341 / -e oled
pio device monitor              # Serial a 115200
```

Rede: o PC (API + broker no Docker) e o ESP32 ficam no mesmo Wi-Fi, que tem que ser
**2,4 GHz** (o ESP32 não conecta em 5 GHz). A rede da faculdade isola os aparelhos entre si,
então uso o hotspot do celular. No Windows, as portas 3000 e 1883 são liberadas por
`scripts/preparar-rede-windows.ps1`.

## Fotos que estou mandando

A ordem das fotos anexadas é esta. Se faltar alguma ou alguma não der para ler, me peça de novo.

1. O kit inteiro espalhado na mesa.
2. ESP32 de cima (o nome no chip e os rótulos dos pinos dos dois lados).
3. ESP32 de baixo, se os rótulos estiverem lá.
4. Display de frente e de trás (nomes dos pinos, chip ou etiqueta).
5. Leitor RC522 com os nomes dos pinos.
6. Módulo relé dos dois lados (jumpers e o que está escrito no relé azul).
7. Buzzer de baixo; LEDs; resistores com as faixas de cor visíveis.
8. Protoboard, jumpers, cabo USB e fonte.

Depois da montagem, mando fotos de cima com os fios visíveis para você conferir.

---

## Código do firmware

Arquivos de `firmware/`. A biblioteca `lib/qrcodegen` (nayuki, MIT) e o certificado CA ficaram de
fora porque não mudam nada na montagem. O `credenciais.exemplo.h` só tem os valores de demonstração
do seed.

### `firmware/platformio.ini`

```ini
; Firmware do terminal da catraca (ESP32). Escolha o ambiente pelo display:
;   pio run -e tft -t upload       ST7789 240x240 ou 240x320 (recomendado)
;   pio run -e ili9341 -t upload   ILI9341 240x320
;   pio run -e oled -t upload      SSD1306 128x64 (QR fica pequeno: só para teste)
; Antes: copie include/credenciais.exemplo.h para include/credenciais.h.

[platformio]
default_envs = tft

[env]
platform = espressif32@6.9.0
board = esp32dev
framework = arduino
monitor_speed = 115200
lib_deps =
  knolleary/PubSubClient@^2.8
  bblanchon/ArduinoJson@^7.2.1
  miguelbalboa/MFRC522@^1.4.11
  adafruit/Adafruit GFX Library@^1.11.11

[env:tft]
lib_deps =
  ${env.lib_deps}
  adafruit/Adafruit ST7735 and ST7789 Library@^1.10.4
build_flags = -DTELA_ST7789

[env:ili9341]
lib_deps =
  ${env.lib_deps}
  adafruit/Adafruit ILI9341@^1.6.1
build_flags = -DTELA_ILI9341

[env:oled]
lib_deps =
  ${env.lib_deps}
  adafruit/Adafruit SSD1306@^2.5.13
build_flags = -DTELA_SSD1306
```

### `firmware/include/config.h`

```cpp
#pragma once
// Pinagem e tempos do terminal. O esquema de ligação está em docs/hardware.md.

// ---------- Display ----------
// SPI (VSPI) compartilhado entre o display TFT e o leitor NFC: SCK 18, MISO 19, MOSI 23.
#define PINO_TFT_CS 5
#define PINO_TFT_DC 16
#define PINO_TFT_RST 17
// ST7789: 240x240 (1.3"/1.54") ou 240x320 (2.0"). O ILI9341 é sempre 240x320.
#define TFT_LARGURA 240
#define TFT_ALTURA 240

// OLED SSD1306 (I2C): SDA 21, SCL 22.
#define OLED_ENDERECO 0x3C

// ---------- Leitor NFC (MFRC522, SPI) ----------
#define PINO_NFC_SS 32
#define PINO_NFC_RST 13

// ---------- Catraca e sinalização ----------
#define PINO_RELE 26
#define PINO_LED_VERDE 25
#define PINO_LED_VERMELHO 27
#define PINO_BUZZER 4
// A maioria dos módulos de relé chinês liga com LOW. Troque se o seu for ativo em HIGH.
#define RELE_LIGADO LOW
#define RELE_DESLIGADO HIGH

// ---------- Tempos (ms) ----------
#define TEMPO_RELE_MS 3000          // quanto tempo a catraca fica liberada
#define TEMPO_DECISAO_MS 4000       // quanto tempo a tela de liberado/negado fica visível
#define INTERVALO_SINAL_MS 30000    // heartbeat (a API considera offline após 90 s)
#define INTERVALO_CONSULTA_MS 2000  // consulta HTTP das decisões quando o MQTT cai
#define ESPERA_ERRO_MS 3000         // nova tentativa depois de falha na API
#define ESPERA_MQTT_MS 5000         // nova tentativa de conectar no broker
#define TIMEOUT_HTTP_MS 5000
#define NFC_REPETICAO_MS 3000       // ignora a mesma tag lida de novo nesse intervalo
```

### `firmware/include/credenciais.exemplo.h`

```cpp
#pragma once
// Copie para credenciais.h (fora do git) e preencha. O script
// backend/scripts/provisionar-terminal.mjs preenche TERMINAL_ID e TERMINAL_KEY.

// ---------- Wi-Fi ----------
#define WIFI_SSID "nome-da-rede"
#define WIFI_SENHA "senha-da-rede"

// ---------- API ----------
// IP do PC na rede local (veja docs/rede-do-prototipo.md), sem barra no fim.
// Na nuvem: "https://passe-api-vlzh.onrender.com" (docs/deploy-nuvem.md).
#define API_URL "http://192.168.0.10:3000"
// Só para https: CA do servidor em PEM. Sem ela, o ESP32 não confere o certificado.
// #define API_CA_CERT "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----\n"

// ---------- Broker MQTT ----------
#define MQTT_HOST "192.168.0.10"
#define MQTT_PORT 1883
// Com TLS: porta 8883 e o conteúdo de docker/mosquitto/certs/ca.crt.
// #define MQTT_CA_CERT "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----\n"
// Na nuvem (EMQX Cloud): MQTT_HOST "re211f91.ala.eu-central-1.emqxsl.com", porta 8883 e
//   #include "ca_digicert_g2.h"
//   #define MQTT_CA_CERT CA_DIGICERT_GLOBAL_ROOT_G2

// ---------- Terminal ----------
// Login no broker: usuário = TERMINAL_ID, senha = TERMINAL_KEY.
// Valores do terminal de demonstração do seed; troque pelo terminal provisionado.
#define TERMINAL_ID "00000000-0000-4000-8000-000000000005"
#define TERMINAL_KEY "chave-demo-terminal-catraca-1"
```

### `firmware/src/main.cpp`

```cpp
// Terminal da catraca do Passe (ESP32). Faz o mesmo que o simulador web
// (backend/public/simulador): pede o QR à API, desenha, troca antes de vencer,
// recebe ABRIR/NEGAR pelo MQTT e aciona o relé. Sem broker, consulta
// GET /terminal/decisions. Lê tags NFC e manda o UID para a API decidir.
//
// Quem decide é sempre o backend: o terminal não guarda segredo de QR nem regra
// de acesso, só a própria chave para se identificar.
#include <Arduino.h>
#include <ArduinoJson.h>
#include <HTTPClient.h>
#include <MFRC522.h>
#include <PubSubClient.h>
#include <SPI.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>

#include "config.h"
#include "credenciais.h"
#include "tela.h"

enum class Modo { AVISO, QR, DECISAO };

static WiFiClient tcpApi;
static WiFiClientSecure tlsApi;
#ifdef MQTT_CA_CERT
static WiFiClientSecure tcpMqtt;
#else
static WiFiClient tcpMqtt;
#endif
static PubSubClient mqtt(tcpMqtt);
static MFRC522 nfc(PINO_NFC_SS, PINO_NFC_RST);

static const String TOPICO = String("passe/terminais/") + TERMINAL_ID + "/decisoes";

static Modo modo = Modo::AVISO;
static String nomeTerminal = "Passe";
static uint32_t proximoQr = 0, proximoSinal = 0, proximaConsulta = 0, proximoMqtt = 0;
static uint32_t fimDecisao = 0, fimRele = 0;
static uint32_t ultimoSeq = 0;
static bool filaIniciada = false;
static String ultimaTag;
static uint32_t ultimaTagEm = 0;

// ---------- API ----------

// Chama a API com os cabeçalhos do terminal. Devolve o status HTTP (ou < 0 se nem conectou).
static int chamarApi(const char* metodo, const String& caminho, const String& corpo, JsonDocument& resposta) {
  HTTPClient http;
  const String url = String(API_URL) + caminho;
  const bool https = url.startsWith("https://");
  if (!(https ? http.begin(tlsApi, url) : http.begin(tcpApi, url))) return -1;
  http.setTimeout(TIMEOUT_HTTP_MS);
  http.addHeader("X-Terminal-Id", TERMINAL_ID);
  http.addHeader("X-Terminal-Key", TERMINAL_KEY);
  http.addHeader("Content-Type", "application/json");

  const int status = strcmp(metodo, "GET") == 0 ? http.GET() : http.POST(corpo);
  if (status > 0) {
    const DeserializationError erro = deserializeJson(resposta, http.getString());
    if (erro) Serial.printf("%s %s: JSON invalido (%s)\n", metodo, caminho.c_str(), erro.c_str());
  } else {
    Serial.printf("%s %s: %s\n", metodo, caminho.c_str(), http.errorToString(status).c_str());
  }
  http.end();
  return status;
}

// ---------- Catraca ----------

static void bipar(int vezes, int duracao) {
  for (int i = 0; i < vezes; i++) {
    digitalWrite(PINO_BUZZER, HIGH);
    delay(duracao);
    digitalWrite(PINO_BUZZER, LOW);
    if (i + 1 < vezes) delay(duracao);
  }
}

static void aplicarDecisao(bool liberado, const String& titulo, const String& texto) {
  Serial.printf("Decisao: %s - %s\n", liberado ? "ABRIR" : "NEGAR", titulo.c_str());
  tela::mostrarDecisao(liberado, titulo, texto);
  digitalWrite(PINO_LED_VERDE, liberado ? HIGH : LOW);
  digitalWrite(PINO_LED_VERMELHO, liberado ? LOW : HIGH);
  if (liberado) {
    digitalWrite(PINO_RELE, RELE_LIGADO);
    fimRele = millis() + TEMPO_RELE_MS;
    bipar(1, 120);
  } else {
    bipar(2, 80);
  }
  modo = Modo::DECISAO;
  fimDecisao = millis() + TEMPO_DECISAO_MS;
}

// Decisão vinda do MQTT ou da consulta HTTP: {acao, metodo, mensagem, nome?}.
static void tratarDecisao(JsonVariantConst d) {
  // As decisões de NFC já chegam na resposta do POST /terminal/nfc.
  if (String(d["metodo"] | "") == "NFC") return;
  const bool abrir = String(d["acao"] | "") == "ABRIR";
  const String nome = d["nome"] | "";
  const String mensagem = d["mensagem"] | "";
  if (abrir) {
    aplicarDecisao(true, "Pode passar", nome.length() ? "Bem-vindo(a), " + nome : mensagem);
  } else {
    aplicarDecisao(false, "Acesso negado", mensagem);
  }
}

// ---------- QR ----------

static void buscarQr() {
  JsonDocument r;
  const int status = chamarApi("GET", "/terminal/qr-token", "", r);
  if (status != 200 || !r["token"].is<const char*>()) {
    tela::mostrarAviso("Sem servidor", status == 401 ? "Chave do terminal recusada" : "Tentando de novo...");
    modo = Modo::AVISO;
    proximoQr = millis() + ESPERA_ERRO_MS;
    return;
  }
  const String token = r["token"].as<String>();
  const uint32_t trocar = (r["trocarEmSegundos"] | 10) * 1000UL;
  if (tela::mostrarQr(token, nomeTerminal + " - aponte o app Passe")) modo = Modo::QR;
  proximoQr = millis() + trocar;
}

// ---------- Decisões ----------

static void aoReceberMqtt(char* topico, uint8_t* payload, unsigned int tamanho) {
  JsonDocument d;
  if (deserializeJson(d, payload, tamanho)) {
    Serial.println("MQTT: mensagem ilegivel");
    return;
  }
  tratarDecisao(d.as<JsonVariantConst>());
}

static void conectarMqtt() {
  if (mqtt.connected() || millis() < proximoMqtt) return;
  proximoMqtt = millis() + ESPERA_MQTT_MS;
  const String clientId = String("passe-terminal-") + String(TERMINAL_ID).substring(0, 8);
  // Login no broker: usuário = Id do terminal, senha = chave (a ACL só libera o tópico dele).
  if (mqtt.connect(clientId.c_str(), TERMINAL_ID, TERMINAL_KEY)) {
    mqtt.subscribe(TOPICO.c_str(), 1);
    Serial.printf("MQTT conectado, ouvindo %s\n", TOPICO.c_str());
  } else {
    Serial.printf("MQTT falhou (estado %d); usando consulta HTTP\n", mqtt.state());
  }
}

// Acompanha a fila de decisões. Só age por ela quando o MQTT está fora do ar;
// com o MQTT conectado, só avança o número para não repetir decisões depois.
static void consultarDecisoes() {
  JsonDocument r;
  if (chamarApi("GET", "/terminal/decisions?apos=" + String(ultimoSeq), "", r) != 200) return;
  const bool viaMqtt = mqtt.connected();
  for (JsonVariantConst item : r.as<JsonArrayConst>()) {
    ultimoSeq = max<uint32_t>(ultimoSeq, item["seq"] | 0);
    // Na primeira consulta, ignora o que já estava na fila antes de ligar.
    if (filaIniciada && !viaMqtt) tratarDecisao(item["decisao"]);
  }
  filaIniciada = true;
}

// ---------- NFC ----------

static void lerTag() {
  if (!nfc.PICC_IsNewCardPresent() || !nfc.PICC_ReadCardSerial()) return;
  String uid;
  for (byte i = 0; i < nfc.uid.size; i++) {
    if (nfc.uid.uidByte[i] < 0x10) uid += '0';
    uid += String(nfc.uid.uidByte[i], HEX);
  }
  uid.toUpperCase();
  nfc.PICC_HaltA();

  if (uid == ultimaTag && millis() - ultimaTagEm < NFC_REPETICAO_MS) return;
  ultimaTag = uid;
  ultimaTagEm = millis();
  Serial.printf("Tag %s\n", uid.c_str());

  JsonDocument r;
  const int status = chamarApi("POST", "/terminal/nfc", "{\"uid\":\"" + uid + "\"}", r);
  if (status != 200) {
    aplicarDecisao(false, "Sem servidor", "Tente de novo");
    return;
  }
  // Resposta: {liberado, titulo, oQueFazer?}
  aplicarDecisao(r["liberado"] | false, r["titulo"] | "", r["oQueFazer"] | "");
}

// ---------- Ciclo ----------

static void conectarWifi() {
  WiFi.mode(WIFI_STA);
  WiFi.setAutoReconnect(true);
  WiFi.begin(WIFI_SSID, WIFI_SENHA);
  tela::mostrarAviso("Conectando", WIFI_SSID);
  while (WiFi.status() != WL_CONNECTED) {
    delay(250);
    Serial.print('.');
  }
  Serial.printf("\nWi-Fi ok, IP %s\n", WiFi.localIP().toString().c_str());
}

static void enviarSinal() {
  JsonDocument r;
  if (chamarApi("POST", "/terminal/heartbeat", "{}", r) == 200 && r["nome"].is<const char*>()) {
    nomeTerminal = r["nome"].as<String>();
  }
}

void setup() {
  Serial.begin(115200);
  pinMode(PINO_RELE, OUTPUT);
  digitalWrite(PINO_RELE, RELE_DESLIGADO);
  pinMode(PINO_LED_VERDE, OUTPUT);
  pinMode(PINO_LED_VERMELHO, OUTPUT);
  pinMode(PINO_BUZZER, OUTPUT);

  SPI.begin();
  tela::iniciar();
  nfc.PCD_Init();

#ifdef API_CA_CERT
  tlsApi.setCACert(API_CA_CERT);
#else
  tlsApi.setInsecure();  // protótipo: sem CA, https cifra mas não confere o servidor
#endif
#ifdef MQTT_CA_CERT
  tcpMqtt.setCACert(MQTT_CA_CERT);
#endif
  mqtt.setServer(MQTT_HOST, MQTT_PORT);
  mqtt.setCallback(aoReceberMqtt);
  mqtt.setBufferSize(512);
  mqtt.setSocketTimeout(3);

  conectarWifi();
  enviarSinal();
  consultarDecisoes();
}

void loop() {
  const uint32_t agora = millis();

  if (WiFi.status() != WL_CONNECTED) {
    tela::mostrarAviso("Sem Wi-Fi", "Reconectando...");
    modo = Modo::AVISO;
    proximoQr = 0;
    delay(1000);
    return;
  }

  conectarMqtt();
  mqtt.loop();

  if (fimRele && (int32_t)(agora - fimRele) >= 0) {
    digitalWrite(PINO_RELE, RELE_DESLIGADO);
    fimRele = 0;
  }

  if (modo == Modo::DECISAO) {
    if ((int32_t)(agora - fimDecisao) < 0) return;
    digitalWrite(PINO_LED_VERDE, LOW);
    digitalWrite(PINO_LED_VERMELHO, LOW);
    proximoQr = 0;  // o QR anterior pode ter sido usado: mostra um novo na hora
  }

  if ((int32_t)(agora - proximoQr) >= 0) buscarQr();
  if ((int32_t)(agora - proximoSinal) >= 0) {
    enviarSinal();
    proximoSinal = agora + INTERVALO_SINAL_MS;
  }
  if ((int32_t)(agora - proximaConsulta) >= 0) {
    consultarDecisoes();
    proximaConsulta = agora + INTERVALO_CONSULTA_MS;
  }
  lerTag();
}
```

### `firmware/src/tela.h`

```cpp
#pragma once
#include <Arduino.h>

// Telas do terminal. O mesmo código desenha no TFT (ST7789/ILI9341) e no OLED;
// o display é escolhido no build (ambientes do platformio.ini).
namespace tela {

void iniciar();

// Desenha o texto como QR Code. O backend gera o conteúdo (token assinado);
// o terminal só transforma o texto em módulos na tela.
bool mostrarQr(const String& texto, const String& rodape);

void mostrarDecisao(bool liberado, const String& titulo, const String& texto);

void mostrarAviso(const String& titulo, const String& texto);

// Remove acentos: a fonte padrão da Adafruit GFX só tem ASCII.
String semAcento(const String& texto);

}  // namespace tela
```

### `firmware/src/tela.cpp`

```cpp
#include "tela.h"

#include <SPI.h>
#include <qrcodegen.h>

#include "config.h"

#if defined(TELA_ST7789)
#include <Adafruit_ST7789.h>
static Adafruit_ST7789 display(PINO_TFT_CS, PINO_TFT_DC, PINO_TFT_RST);
static const bool COLORIDA = true;
#elif defined(TELA_ILI9341)
#include <Adafruit_ILI9341.h>
static Adafruit_ILI9341 display(PINO_TFT_CS, PINO_TFT_DC, PINO_TFT_RST);
static const bool COLORIDA = true;
#elif defined(TELA_SSD1306)
#include <Adafruit_SSD1306.h>
#include <Wire.h>
static Adafruit_SSD1306 display(128, 64, &Wire, -1);
static const bool COLORIDA = false;
#else
#error "Escolha o display: -DTELA_ST7789, -DTELA_ILI9341 ou -DTELA_SSD1306 (veja platformio.ini)"
#endif

// Cores RGB565; no OLED tudo vira branco sobre preto.
static const uint16_t BRANCO = 0xFFFF;
static const uint16_t PRETO = 0x0000;
static const uint16_t VERDE = COLORIDA ? 0x05E6 : BRANCO;
static const uint16_t VERMELHO = COLORIDA ? 0xD8A3 : BRANCO;
static const uint16_t AZUL = COLORIDA ? 0x1B3A : BRANCO;

// O token do backend (~78 caracteres alfanuméricos) cabe na versão 4 (33x33).
// A versão máxima deixa folga caso o formato cresça.
static const int QR_VERSAO_MAX = 6;

static void atualizar() {
#if defined(TELA_SSD1306)
  display.display();
#endif
}

static void escreverCentralizado(const String& texto, int16_t y, uint8_t tamanho, uint16_t cor) {
  String limpo = tela::semAcento(texto);
  display.setTextSize(tamanho);
  display.setTextColor(cor);
  display.setTextWrap(false);
  int16_t x1, y1;
  uint16_t w, h;
  display.getTextBounds(limpo, 0, 0, &x1, &y1, &w, &h);
  // Texto maior que a tela: quebra em linhas pelo próprio GFX, a partir da margem.
  if (w > display.width()) {
    display.setTextWrap(true);
    display.setCursor(2, y);
  } else {
    display.setCursor((display.width() - w) / 2, y);
  }
  display.print(limpo);
}

namespace tela {

void iniciar() {
#if defined(TELA_ST7789)
  display.init(TFT_LARGURA, TFT_ALTURA);
  display.setRotation(0);
#elif defined(TELA_ILI9341)
  display.begin();
  display.setRotation(0);
#elif defined(TELA_SSD1306)
  Wire.begin();
  if (!display.begin(SSD1306_SWITCHCAPVCC, OLED_ENDERECO)) Serial.println("OLED nao encontrado");
#endif
  display.fillScreen(PRETO);
  atualizar();
}

bool mostrarQr(const String& texto, const String& rodape) {
  static uint8_t qr[qrcodegen_BUFFER_LEN_FOR_VERSION(QR_VERSAO_MAX)];
  static uint8_t temp[qrcodegen_BUFFER_LEN_FOR_VERSION(QR_VERSAO_MAX)];
  // Correção M: aguenta reflexo e um pouco de sujeira na tela.
  if (!qrcodegen_encodeText(texto.c_str(), temp, qr, qrcodegen_Ecc_MEDIUM, 1, QR_VERSAO_MAX, qrcodegen_Mask_AUTO, true)) {
    Serial.printf("QR grande demais (%u caracteres)\n", texto.length());
    return false;
  }

  const int modulos = qrcodegen_getSize(qr);
  const bool pequena = display.height() < 128;
  const int alturaRodape = pequena ? 0 : 28;
  const int margem = pequena ? 2 : 4;  // zona de silêncio, em módulos
  const int area = min<int>(display.width(), display.height() - alturaRodape);
  const int escala = max(1, area / (modulos + 2 * margem));
  const int lado = modulos * escala;
  const int x0 = (display.width() - lado) / 2;
  const int y0 = (display.height() - alturaRodape - lado) / 2;

  // QR escuro sobre fundo branco, como o leitor do celular espera.
  display.fillScreen(BRANCO);
  for (int y = 0; y < modulos; y++) {
    for (int x = 0; x < modulos; x++) {
      if (qrcodegen_getModule(qr, x, y)) display.fillRect(x0 + x * escala, y0 + y * escala, escala, escala, PRETO);
    }
  }
  if (!pequena) escreverCentralizado(rodape, display.height() - alturaRodape + 8, 1, AZUL);
  atualizar();
  return true;
}

void mostrarDecisao(bool liberado, const String& titulo, const String& texto) {
  const uint16_t fundo = liberado ? VERDE : VERMELHO;
  const uint16_t frente = COLORIDA ? BRANCO : PRETO;
  display.fillScreen(COLORIDA ? fundo : BRANCO);
  const bool pequena = display.height() < 128;
  escreverCentralizado(liberado ? "OK" : "X", pequena ? 2 : 40, pequena ? 3 : 6, frente);
  escreverCentralizado(titulo, pequena ? 30 : 120, 2, frente);
  escreverCentralizado(texto, pequena ? 50 : 160, 1, frente);
  atualizar();
}

void mostrarAviso(const String& titulo, const String& texto) {
  display.fillScreen(PRETO);
  const bool pequena = display.height() < 128;
  escreverCentralizado(titulo, pequena ? 10 : 90, 2, BRANCO);
  escreverCentralizado(texto, pequena ? 40 : 130, 1, BRANCO);
  atualizar();
}

String semAcento(const String& texto) {
  static const char* de[] = {"á", "à", "â", "ã", "é", "ê", "í", "ó", "ô", "õ", "ú", "ç", "Á", "À", "Â", "Ã", "É", "Ê", "Í", "Ó", "Ô", "Õ", "Ú", "Ç", "›"};
  static const char* para[] = {"a", "a", "a", "a", "e", "e", "i", "o", "o", "o", "u", "c", "A", "A", "A", "A", "E", "E", "I", "O", "O", "O", "U", "C", ">"};
  String r = texto;
  for (size_t i = 0; i < sizeof(de) / sizeof(de[0]); i++) r.replace(de[i], para[i]);
  return r;
}

}  // namespace tela
```
