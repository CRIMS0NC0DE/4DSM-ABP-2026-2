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
