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
