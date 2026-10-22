#pragma once
// Copie para credenciais.h (fora do git) e preencha. O script
// backend/scripts/provisionar-terminal.mjs preenche TERMINAL_ID e TERMINAL_KEY.

// ---------- Wi-Fi ----------
#define WIFI_SSID "nome-da-rede"
#define WIFI_SENHA "senha-da-rede"

// ---------- API ----------
// IP do PC na rede local (veja docs/rede-do-prototipo.md), sem barra no fim.
#define API_URL "http://192.168.0.10:3000"
// Só para https: CA do servidor em PEM. Sem ela, o ESP32 não confere o certificado.
// #define API_CA_CERT "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----\n"

// ---------- Broker MQTT ----------
#define MQTT_HOST "192.168.0.10"
#define MQTT_PORT 1883
// Com TLS: porta 8883 e o conteúdo de docker/mosquitto/certs/ca.crt.
// #define MQTT_CA_CERT "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----\n"

// ---------- Terminal ----------
// Login no broker: usuário = TERMINAL_ID, senha = TERMINAL_KEY.
// Valores do terminal de demonstração do seed; troque pelo terminal provisionado.
#define TERMINAL_ID "00000000-0000-4000-8000-000000000005"
#define TERMINAL_KEY "chave-demo-terminal-catraca-1"
