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
