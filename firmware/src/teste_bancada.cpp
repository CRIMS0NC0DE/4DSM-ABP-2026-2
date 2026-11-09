// Teste de bancada do terminal: confere a montagem peça por peça, sem Wi-Fi,
// sem backend e sem credenciais.h. Usa os mesmos pinos do config.h e as mesmas
// telas do firmware de verdade (tela.cpp).
//
//   pio run -e teste -t upload
//   pio device monitor              (115200; digite o número do teste)
//
// Quando tudo passar, grave o firmware normal: pio run -e tft -t upload
#include <Arduino.h>
#include <MFRC522.h>
#include <SPI.h>

#include "config.h"
#include "tela.h"

// LED azul da própria placa (DevKit V1). Algumas placas não têm.
static const int PINO_LED_PLACA = 2;

static MFRC522 nfc(PINO_NFC_SS, PINO_NFC_RST);
static String ultimaTag;
static uint32_t ultimaTagEm = 0;

static void bipar(int vezes, int duracao) {
  for (int i = 0; i < vezes; i++) {
    digitalWrite(PINO_BUZZER, HIGH);
    delay(duracao);
    digitalWrite(PINO_BUZZER, LOW);
    if (i + 1 < vezes) delay(duracao);
  }
}

static void menu() {
  Serial.println();
  Serial.println("===== Teste de bancada do terminal Passe =====");
  Serial.println("Digite o numero do teste:");
  Serial.println("  1  LEDs        (verde e vermelho piscam 3 vezes)");
  Serial.println("  2  Buzzer      (3 bipes)");
  Serial.println("  3  Rele        (liga e desliga 3 vezes, com clique)");
  Serial.println("  4  Display     (tela verde, tela vermelha e um QR de teste)");
  Serial.println("  5  Leitor NFC  (procura o chip; depois encoste uma tag)");
  Serial.println("  0  Todos em sequencia");
  Serial.println("Encostar uma tag no leitor funciona a qualquer momento.");
}

static void testarLeds() {
  Serial.println("[1] LEDs: verde e vermelho piscam 3 vezes, um de cada vez.");
  for (int i = 0; i < 3; i++) {
    digitalWrite(PINO_LED_VERDE, HIGH);
    delay(400);
    digitalWrite(PINO_LED_VERDE, LOW);
    digitalWrite(PINO_LED_VERMELHO, HIGH);
    delay(400);
    digitalWrite(PINO_LED_VERMELHO, LOW);
  }
  Serial.println("    Nao acendeu? LED virado (perna longa vai do lado do resistor) ou fio no pino errado.");
}

static void testarBuzzer() {
  Serial.println("[2] Buzzer: 3 bipes curtos.");
  bipar(3, 150);
  Serial.println("    So um clique fraco? O buzzer e passivo: precisa ser ativo.");
}

static void testarRele() {
  Serial.println("[3] Rele: liga 1 s e desliga, 3 vezes. Ouca o clique e veja a luz do modulo.");
  for (int i = 0; i < 3; i++) {
    digitalWrite(PINO_RELE, RELE_LIGADO);
    Serial.println("    ligado");
    delay(1000);
    digitalWrite(PINO_RELE, RELE_DESLIGADO);
    Serial.println("    desligado");
    delay(1000);
  }
  Serial.println("    Ficou ligado o tempo todo? Veja 'Rele nao desliga' no guia de montagem.");
}

static void testarDisplay() {
  Serial.println("[4] Display: tela verde, tela vermelha e um QR de teste.");
  tela::mostrarDecisao(true, "Pode passar", "Teste do display");
  delay(2000);
  tela::mostrarDecisao(false, "Acesso negado", "Teste do display");
  delay(2000);
  if (tela::mostrarQr("PASSE TESTE OK", "Teste - aponte a camera")) {
    Serial.println("    Aponte a camera do celular para o QR: deve aparecer PASSE TESTE OK.");
  }
  Serial.println("    Tela toda branca ou preta? Confira VCC, GND, SCL, SDA, CS, DC e RES.");
}

static void testarNfc() {
  nfc.PCD_Init();
  const byte versao = nfc.PCD_ReadRegister(MFRC522::VersionReg);
  if (versao == 0x00 || versao == 0xFF) {
    Serial.printf("[5] Leitor NFC NAO encontrado (resposta 0x%02X).\n", versao);
    Serial.println("    Confira SDA->D32, SCK->D18, MOSI->D23, MISO->D19, RST->D13, 3.3V e GND.");
  } else {
    Serial.printf("[5] Leitor NFC encontrado (versao 0x%02X). Encoste uma tag no leitor.\n", versao);
  }
}

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
  Serial.printf("Tag %s lida. Anote esse codigo para cadastrar a tag no sistema.\n", uid.c_str());
  digitalWrite(PINO_LED_VERDE, HIGH);
  bipar(1, 120);
  delay(300);
  digitalWrite(PINO_LED_VERDE, LOW);
}

void setup() {
  Serial.begin(115200);
  pinMode(PINO_RELE, OUTPUT);
  digitalWrite(PINO_RELE, RELE_DESLIGADO);
  pinMode(PINO_LED_VERDE, OUTPUT);
  pinMode(PINO_LED_VERMELHO, OUTPUT);
  pinMode(PINO_BUZZER, OUTPUT);
  pinMode(PINO_LED_PLACA, OUTPUT);

  // Pisca o LED azul da placa e dá tempo de abrir o monitor serial.
  for (int i = 0; i < 3; i++) {
    digitalWrite(PINO_LED_PLACA, HIGH);
    delay(250);
    digitalWrite(PINO_LED_PLACA, LOW);
    delay(250);
  }

  SPI.begin();
  tela::iniciar();
  tela::mostrarAviso("Teste de bancada", "Siga o menu no Serial");

  Serial.println();
  Serial.println("Placa ok: o ESP32 ligou e o Serial funciona.");
  testarNfc();
  menu();
}

void loop() {
  if (Serial.available()) {
    const char opcao = Serial.read();
    switch (opcao) {
      case '1': testarLeds(); break;
      case '2': testarBuzzer(); break;
      case '3': testarRele(); break;
      case '4': testarDisplay(); break;
      case '5': testarNfc(); break;
      case '0':
        testarLeds();
        testarBuzzer();
        testarRele();
        testarDisplay();
        testarNfc();
        break;
      case '\r':
      case '\n':
        return;
      default:
        menu();
        return;
    }
    Serial.println("Pronto. Digite outro numero (qualquer outra tecla mostra o menu).");
  }
  lerTag();
}
