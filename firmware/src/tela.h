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
